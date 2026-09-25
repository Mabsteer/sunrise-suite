#!/usr/bin/env bash
# Sunrise Suite quality gate. Run before every commit (Git Bash locally, bash in CI):
#   bash tools/check.sh              all checks + Web and Windows exports
#   bash tools/check.sh --no-export  skip the exports (faster while iterating)
# Every step writes a log to builds/logs/<step>.log. Any Godot ERROR/WARNING line fails the step.
set -uo pipefail
cd "$(dirname "$0")/.."

EXPORT=1
for arg in "$@"; do
  case "$arg" in
    --no-export) EXPORT=0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

LOG_DIR="builds/logs"
mkdir -p "$LOG_DIR"
# Keep Godot from importing the exported web build's own files.
touch builds/.gdignore

GODOT=(bash tools/godot.sh)
ERROR_PATTERN='(^|[^A-Za-z_])(SCRIPT ERROR|USER ERROR|ERROR|SCRIPT WARNING|USER WARNING|WARNING):|Parse Error|^FAIL |LOAD FAILED'
# Known-harmless lines (one regex per line) in tools/check_ignore.txt.
IGNORE_FILE="tools/check_ignore.txt"

strip_ansi() { sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g'; }

problems() {
  local log="$1"
  if [ -s "$IGNORE_FILE" ]; then
    grep -E "$ERROR_PATTERN" "$log" | grep -v -E -f <(grep -v '^\s*#' "$IGNORE_FILE" | grep -v '^\s*$') || true
  else
    grep -E "$ERROR_PATTERN" "$log" || true
  fi
}

step() {
  local name="$1"; shift
  local log="$LOG_DIR/$name.log"
  local start=$SECONDS
  "$@" 2>&1 | strip_ansi > "$log"
  local code=${PIPESTATUS[0]}
  local found
  found="$(problems "$log")"
  if [ "$code" -ne 0 ] || [ -n "$found" ]; then
    echo "  FAIL  $name (exit $code, $((SECONDS - start))s) — log: $log"
    if [ -n "$found" ]; then
      echo "$found" | head -40 | sed 's/^/        /'
    else
      tail -30 "$log" | sed 's/^/        /'
    fi
    exit 1
  fi
  local summary
  summary="$(grep -E '^(TESTS|LOAD_ALL|VALIDATOR|AUTOPLAY):' "$log" | tail -1)"
  echo "  ok    $name ($((SECONDS - start))s) ${summary}"
}

scene_exists() { [ -f "${1#res://}" ]; }

echo "Sunrise Suite checks"
# On a fresh checkout the first import logs errors for not-yet-imported files (theme, fonts, translations).
# Warm up once without judging, then require a clean second import.
if [ ! -d .godot/imported ]; then
  "${GODOT[@]}" --headless --path . --import > "$LOG_DIR/import_warmup.log" 2>&1 || true
fi
step import "${GODOT[@]}" --headless --path . --import
step load_all "${GODOT[@]}" --headless --path . res://tests/load_all.tscn
step unit_tests "${GODOT[@]}" --headless --path . res://tests/test_runner.tscn
if scene_exists res://tests/validate_levels.tscn; then
  step validator "${GODOT[@]}" --headless --path . res://tests/validate_levels.tscn
fi
if scene_exists res://tests/autoplay.tscn; then
  step autoplay "${GODOT[@]}" --headless --path . res://tests/autoplay.tscn
fi

if [ "$EXPORT" -eq 1 ]; then
  mkdir -p builds/web builds/windows
  step export_web "${GODOT[@]}" --headless --path . --export-release "Web" builds/web/index.html
  step export_windows "${GODOT[@]}" --headless --path . --export-release "Windows Desktop" builds/windows/SunriseSuite.exe
  [ -f builds/web/index.html ] || { echo "  FAIL  web export produced no index.html"; exit 1; }
  [ -f builds/windows/SunriseSuite.exe ] || { echo "  FAIL  windows export produced no exe"; exit 1; }
fi
echo "All checks passed."
