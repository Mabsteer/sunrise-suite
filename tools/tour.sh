#!/usr/bin/env bash
# Re-imports changed assets, then runs the screenshot tour (needs a real window, not headless).
#   bash tools/tour.sh                 all shots
#   bash tools/tour.sh lounge,menu     only shots whose name contains one of these words
# Screenshots land in tests/screenshots/ (git-ignored). Open them and look!
set -uo pipefail
cd "$(dirname "$0")/.."
bash tools/godot.sh --headless --path . --import > /dev/null 2>&1
ARGS=(--screenshot-tour)
if [ $# -gt 0 ]; then ARGS+=("--shots=$1"); fi
bash tools/godot.sh --path . -- "${ARGS[@]}" 2>&1 | grep -E "ERROR|WARNING|SCREENSHOTS" | grep -v -E -f <(grep -v '^\s*#' tools/check_ignore.txt | grep -v '^\s*$')
exit 0
