# Sunrise Suite — notes for Claude

Cozy 2D point-and-click escape-room game in Godot 4.7.2 (GDScript, Compatibility renderer).
The full brief is `PROMPT.md`. Progress and next steps: `docs/PROGRESS.md`. Decisions: `docs/DECISIONS.md`.

## Commands (Git Bash)
- Godot (always through the wrapper): `bash tools/godot.sh <args>`
- Full gate before every commit: `bash tools/check.sh` (use `--no-export` while iterating)
- Unit tests only: `bash tools/godot.sh --headless --path . res://tests/test_runner.tscn -- --filter=<part of name>`
- Screenshot tour (non-headless, writes `tests/screenshots/`): `bash tools/godot.sh --path . -- --screenshot-tour`
- Sound effects: edit `tools/sfx/sfx.json`, then `npm run sfx`
- Local web test: `node tools/serve_web.mjs` → http://localhost:8060 (after an export)
- CI: `gh run watch` after `git push`. The live build is https://mabsteer.github.io/sunrise-suite/

## Conventions
- Static typing everywhere (`var x: int`, typed arrays, return types). Tabs for indentation.
- Game content is data: `data/*.json` (documented in `docs/DATA_FORMAT.md`). Sprites are referenced by path from data, never hard-coded in scripts.
- One SVG per object in `assets/sprites/<category>/`, ThorVG-safe (no filters/masks/clip-paths/text/CSS). Colours from `assets/palette.json`.
- UI text goes through `tr()` with keys in `i18n/strings.csv`.
- Use only seeded `RandomNumberGenerator`s in level generation (never global `randi()`).
- Autoloads: `Events` (signal bus), `Data` (JSON loader), `SaveManager`, `GameState`, `AudioManager`, `Daily`, `Router` (screen changes).
- Tests: `tests/unit/test_*.gd` extend `TestCase`; methods starting with `test_` run automatically.
- `tools/check.sh` fails on any Godot `ERROR:`/`WARNING:` line. Harmless lines can go in `tools/check_ignore.txt` (explain each one).
- Godot CLI progress text may be in Dutch (system locale). Error prefixes stay English.
- Never commit `builds/` or `node_modules/`. Commit `*.import` and `*.uid` files, and the generated SFX WAVs.
