#!/usr/bin/env bash
# Runs the Godot 4.7.2 console binary with the given arguments, from any shell (Git Bash on Windows, Linux CI).
# Resolution order: $GODOT, `godot` on PATH (CI container), the winget console exe on PATH, the winget install folder.
# Usage: tools/godot.sh --headless --path . --import
set -euo pipefail

find_godot() {
  if [[ -n "${GODOT:-}" ]]; then echo "$GODOT"; return; fi
  if command -v godot >/dev/null 2>&1; then command -v godot; return; fi
  if command -v Godot_v4.7.2-stable_win64_console.exe >/dev/null 2>&1; then
    command -v Godot_v4.7.2-stable_win64_console.exe; return
  fi
  if [[ -n "${LOCALAPPDATA:-}" ]]; then
    local base
    base="$(cygpath -u "$LOCALAPPDATA" 2>/dev/null || echo "$LOCALAPPDATA")/Microsoft/WinGet/Packages"
    local exe
    exe="$(ls -1 "$base"/GodotEngine.GodotEngine_*/Godot_v4.7.2-stable_win64_console.exe 2>/dev/null | head -n 1 || true)"
    if [[ -n "$exe" ]]; then echo "$exe"; return; fi
  fi
  echo "tools/godot.sh: Godot 4.7.2 not found. Install it (winget install GodotEngine.GodotEngine) or set GODOT=/path/to/godot" >&2
  exit 127
}

exec "$(find_godot)" "$@"
