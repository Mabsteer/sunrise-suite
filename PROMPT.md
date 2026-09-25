# Sunrise Suite — Autonomous Build Brief

You are building **Sunrise Suite**, a cozy 2D point-and-click escape-room puzzle game, in **Godot 4.7.2 (GDScript)** in `C:\Game`.
**You are working unattended for many hours.** The owner is away and will follow progress through the live web build on their phone.

## 0. How to work
- **Never stop to ask questions.** If something is unclear, choose what best fits the vision below, log it in `docs/DECISIONS.md` (decision + why, one line) and continue.
- **Resumability:** keep `docs/PROGRESS.md` current (milestone status, next steps, known issues, blocked items). At the start of every session and after any context compaction, re-read `PROMPT.md`, `CLAUDE.md` and `docs/PROGRESS.md` before doing anything else. Create `CLAUDE.md` in M0 with conventions + exact commands.
- **Commit rhythm:** small, clearly worded commits. End of every milestone: `bash tools/check.sh` all green, then update PROGRESS.md, commit, `git push`, `gh run watch`, and fix CI until green. `main` must always be playable. The live build is the owner's only window into your work.
- If a push-notification tool is available, send a one-line notification when a milestone is live.
- **Permissions — don't get stuck waiting for approval:** `.claude/settings.json` pre-approves git, gh, npm/npx/node, `bash tools/…`, basic file commands (ls, cat, mkdir, cp, mv, rm, find, grep, sed, unzip, curl…) and edits inside `C:\Game`. Run Godot **only** through `bash tools/godot.sh …`. Put any multi-step shell logic into a script under `tools/` and run it with `bash tools/<name>.sh`, rather than long one-off command chains that include programs not on the list.
- **Guardrails:** stay inside `C:\Game`. Never force-push, rewrite history, change repo settings or delete anything on GitHub. Never commit `builds/` or `node_modules/` (do commit Godot `*.import` files and generated SFX WAVs). Only use assets you create or that are CC0/OFL, and list every third-party asset + license in `CREDITS.md`.
- Stuck on the same problem after ~3 serious attempts? Log it under "Blocked" in PROGRESS.md, choose a simpler approach, move on.

## 1. Environment (already set up — do not reinstall)
- Windows 11 with Git Bash. Godot 4.7.2 standard (not .NET) is installed. **Always call it via `bash tools/godot.sh <args>`**. The wrapper finds the console binary locally and uses `godot` in CI. Export templates 4.7.2 (Windows x86_64 + Web) are installed in `%APPDATA%\Godot\export_templates\4.7.2.stable\`.
- The PC's system language is Dutch, so Godot's CLI progress messages may be in Dutch. `ERROR:`/`WARNING:` prefixes stay English, so grep for those. Write `export_presets.cfg` with every standard key (including `include_filter`/`exclude_filter`), because a hand-trimmed preset file makes Godot log errors.
- Node 24 + npm, `jsfxr` installed. `npm run sfx` generates sound effects (§7).
- Git + GitHub CLI logged in as `Mabsteer`. Remote `origin` = `https://github.com/Mabsteer/sunrise-suite` (public). GitHub Pages is set to deploy from GitHub Actions → `https://mabsteer.github.io/sunrise-suite/`.
- Already in the repo: `tools/godot.sh`, `tools/sfx/` (generator + `sfx.json` + `LINKS.md`), `assets/audio/sfx/*.wav` (23 starter sounds), `docs/SUNO_PROMPTS.md`, `.claude/settings.json`, `.gitignore`, `.gitattributes`, `package.json`, this file.

## 2. Vision
**Mood:** cozy, calm, warm. A luxury beachside penthouse at dawn: floor-to-ceiling windows, the ocean, palm silhouettes, a sky that moves from deep indigo → lavender → peach → gold. Plants, linen, warm wood, rattan, terracotta, brass, soft light. No fail states, nothing scary, no visible timers by default.

**Premise:** you're house-sitting for **Grandma June**, an adventurous, puzzle-loving world traveler who adores sunrises. Every morning she "locks" you in a room with a trail of riddles; solve it to open the balcony door just as the sun rises. Postcards hidden in levels slowly tell her story and why sunrises matter to her. Warm, a bit funny, gently bittersweet, never sad.

**Signature mechanic — the sunrise is the progress bar:** every solved step advances the room's `sunrise_t` (sky gradient, sun height, light tint and shadows in the room). The final lock opens the balcony door as the sun clears the horizon, then a short celebratory sunrise moment, then the results screen.

## 3. Core loop
Hub (Grandma's penthouse, decorate mode) → Level select → Escape-room level → Results (stars, seashells, unlocked decor, postcard if found) → back to Hub. Daily Sunrise challenge launched from the Hub.

## 4. Escape-room gameplay
- Mouse and touch behave identically; no hover-only information. Base resolution 1920×1080, stretch mode `canvas_items`, aspect `expand`. Must be comfortable on a phone browser in landscape (touch targets ≥ 88 px at base res).
- A room is one scene (may pan horizontally) with **hotspots**: open a **close-up** (drawer, safe, painting, shelf), pick up an item, or show short inspect text.
- **Inventory bar:** select an item, then tap a hotspot to use it. Drag an item onto another (or select + tap) to **combine**.
- **Lock/puzzle types** — each a reusable scene + script configured by data. At least these 8 in v1:
  1. Number combo lock (3–5 digits)
  2. Color+symbol sequence lock (never color alone — colorblind-safe)
  3. Key & keyhole
  4. Item combination (e.g. batteries + flashlight)
  5. Hidden compartment (inspect/search reveals it)
  6. Clock lock (set the hands to a time given by a clue)
  7. Switch/light order
  8. Sliding-tile or rotation puzzle (size/scramble scale with tier)
- **Clues** live in the room: notes, photos, book spines, a postcard date, shells in a jar, a record label. Clue text comes from templates with tier-dependent indirection (tier 1: "The code is 4-7-2"; tier 10: "Count the gulls in the painting, then add the year on the record").
- **Hints:** Grandma's notepad. Hint 1 = where to look, 2 = what to do, 3 = the answer for the current step. Always available; they only affect stars.
- Wrong answers: gentle wiggle + soft sound. Never a penalty.

## 5. Levels — hybrid generation & difficulty
- **Room templates (v1: 3):** *Sunrise Lounge* (big windows, record player, bookshelf, plants), *Kitchen & Bar* (espresso machine, fridge magnets, spice rack, fruit bowl), *Grandma's Study* (globe, typewriter, souvenirs, world map, clock). Each is a hand-authored scene with named **slots** where puzzle objects, items and clues can appear, plus the balcony door as the final lock.
- **Puzzle-chain generator:** from `(seed, room, tier)` build a dependency DAG ending at the balcony door. It chooses lock types that fit the slots, places items and clues, randomizes codes/orders/answers and adds red herrings. Deterministic: use only a seeded `RandomNumberGenerator`, never global `randi()`/`randf()`.
- **Tiers** in `data/tiers.json` (editable): steps (3 → ~12), parallel branches (1 → 3), red herrings (0 → 4), clue indirection (0 → 3), combinations allowed, sliding-puzzle size, par time. v1 ships 10 tiers.
- **Recurring levels:** the main path is 30 levels (3 rooms × 10 tiers), interleaved (Lounge T1, Kitchen T1, Study T1, Lounge T2, …), so each room returns harder. Main levels use fixed seeds. **Replay** gives a fresh seed for the same room and tier. After level 30, **Endless Sunrise** unlocks, with tiers scaling past 10 up to sane caps.
- **Validator (required):** a headless solver that generates ≥ 200 seeds for every room × tier and proves each is solvable. Checks: every lock is reachable, no item is needed before it can be obtained, no clue points to anything unreachable, no deadlocks, and step count is within the tier's bounds. Generation must take < 50 ms per level.

## 6. Reasons to come back (all four in v1)
1. **Decorate the penthouse (Hub):** earn **seashells** from stars and first clears, then spend them in *Grandma's Catalog*. At least 15 decor items (monstera, rattan chair, surfboard, record crate, lanterns, rug, hanging egg chair, shell lamp, telescope, …) placed on a snap grid/slot system, with move / flip / store. Some items are exclusive rewards (tier milestones, streaks, the full postcard set).
2. **Daily Sunrise:** one level per day, seeded from the UTC date (the same for everyone), with difficulty rotating through the week. Streak counter with one free "sleep-in" per week. **Sunrise Calendar**: each completed day becomes a tile painted in that day's sky colors.
3. **Grandma's postcards (story):** 5 postcards, each hidden behind an optional hotspot in a specific level. Read them in the **Scrapbook** (front: an illustrated place; back: handwritten-style text). All 5 unlocks a special decor item + a final letter.
4. **Stars:** ★ complete · ★ ≤ 1 hint · ★ under par time. Shown in level select. Star totals softly unlock later tiers.

## 7. Art & audio pipeline — must be easy to edit later
**Sprites are SVG, one object per file:** `assets/sprites/<category>/<name>.svg` (`rooms`, `props`, `items`, `decor`, `ui`, `sky`, `postcards`). Game objects reference sprites through data files, never hard-coded paths in scripts, so replacing art means overwriting one file.
- Write `docs/ART_STYLE.md` + `assets/palette.json` (loaded by a `Palette` class). Flat vector, soft rounded shapes, gentle gradients, consistent outline rule, limited palette: sunrise peach, coral, gold, sand, sea teal, deep indigo, cream, terracotta, sage, warm wood.
- **ThorVG-safe SVG only:** `path/rect/circle/ellipse/polygon/g`, linear/radial gradients, opacity, simple transforms. **No** filters, masks, clip-paths, `<text>`, `<style>`/CSS, external refs or embedded bitmaps. Fake soft shadows with semi-transparent shapes. Always set `viewBox`, author at one documented scale, and set import scale so sprites stay crisp on hi-DPI phones.
- The art must be inviting, not programmer art: clear silhouettes, 2–3 shading steps, highlights. Review every sprite through the screenshot tour (§9) and iterate.
- **Sky & sea backdrop:** a shader driven by `sunrise_t` (0..1) with gradient sky, sun disc + glow, sea sparkle, slow waves, drifting clouds, a few gulls and palm silhouettes. Room interiors are tinted from the same `sunrise_t`. Use the **Compatibility renderer** and keep it light for mobile web.
- Fonts: a friendly OFL UI font (e.g. Nunito/Quicksand) + an OFL handwriting font for Grandma, from Google Fonts' GitHub (`github.com/google/fonts`), stored in `assets/fonts/` with their licenses.
- All UI text goes through `tr()` with keys in `i18n/*.csv` (English only now, ready for more languages).

**Sound effects — jsfxr (already set up):**
- Definitions: `tools/sfx/sfx.json` (the `_help` block explains the format). `npm run sfx` writes `assets/audio/sfx/<name>.wav` + `tools/sfx/LINKS.md` (sfxr.me edit links). Output is deterministic.
- 23 starter sounds exist (UI, items, locks, drawers, door, hint, steps, stars, seashells, decor, postcard, page turn, level complete, daily unlock). Add an entry for **every** other sound the game uses (e.g. each lock type's specific interaction, clock hands, switches, sliding tiles, catalog purchase, streak).
- Keep them soft and cozy: sine waves, low volume, low-pass on noise, short envelopes. No laser/explosion-style sounds. Never hand-edit the WAVs; edit the JSON and regenerate.
- Code plays sounds by name: `AudioManager.play_sfx("lock_open")`. A missing file logs a warning and never crashes.

**Music — Suno (the owner adds files later):** track names are in `docs/SUNO_PROMPTS.md`. `AudioManager` looks for `assets/audio/music/<track>.{ogg,mp3,wav}` and plays silence if a file is missing. Music loops and crossfades (~1.5 s), including crossfading a track's end into its own start. Buses: Master, Music, SFX, Ambience, with sliders in Settings (saved). Music starts a few dB lower than SFX.

## 8. Architecture & conventions
- GDScript with static typing everywhere. No C#, no plugins that need compiling.
- Layout (adjust if needed, document in CLAUDE.md):
  ```
  project.godot, export_presets.cfg
  autoload/   GameState, SaveManager, AudioManager, Events (signal bus), Daily
  scenes/     main_menu/, hub/, level/, puzzles/<lock_type>/, ui/, scrapbook/
  scripts/    generator/, solver/, data/
  data/       rooms/*.json, tiers.json, items.json, decor.json, postcards.json, clues.json
  assets/     sprites/, audio/sfx/, audio/music/, fonts/, palette.json
  i18n/  tests/  tools/  docs/
  ```
- **Data-driven:** rooms, tiers, items, decor, postcards and clue templates are human-editable JSON, documented in `docs/DATA_FORMAT.md` and validated on load with clear error messages.
- **Saves:** `user://save.json`, versioned with migrations, autosave after every level, purchase and placement. Must work on web (IndexedDB-backed `user://`). Settings are saved separately.
- No errors or warnings in the output log during normal play. Handles window resize and pause safely.

## 9. Automated verification — nobody is watching, so prove it works
Put the test logic in Godot scripts (and Node where handy), so the local check and Linux CI run the same things.
1. **`tools/check.sh`** — the gate before every commit (runs in Git Bash locally and bash in CI). Fail fast, in this order:
   1. `bash tools/godot.sh --headless --path . --import` (zero import errors)
   2. Load every `.gd`/`.tscn` (no parse errors)
   3. Unit tests (a small `tests/run_tests.gd` extending `SceneTree`, or vendored GUT; log the choice)
   4. Generator validator (§5)
   5. **Autoplay bot:** loads the real level scene for sample seeds of every room × tier and solves it through the same interaction API the player uses. It asserts the balcony opens and the results screen appears.
   6. Save/load round-trip and daily-seed determinism tests
   7. Web + Windows exports to `builds/` with zero errors
2. **Screenshot tour:** run the game **non-headless** (`bash tools/godot.sh --path . -- --screenshot-tour`).
   - It visits the main menu, hub (empty + decorated), level select, each room at `sunrise_t` 0/0.5/1, every puzzle close-up, inventory, results, scrapbook, calendar and settings.
   - Sizes: 1920×1080 and 2340×1080 (phone 20:9).
   - Saves PNGs to `tests/screenshots/`, then quits.
   - **Open and inspect the PNGs** after every visual change. Fix clipping, unreadable text, overlap and ugly art.
3. **CI — `.github/workflows/build.yml`**, on every push to `main`:
   - Container `barichello/godot-ci:4.7.2` (it includes matching 4.7.2 export templates).
   - Run the headless checks via `tools/check.sh`, then export Web + Windows and upload both as artifacts.
   - Deploy Web to GitHub Pages with `actions/upload-pages-artifact` + `actions/deploy-pages`.
   - Web preset: **thread support OFF** (Pages can't send COOP/COEP headers).
   - Windows preset: `application/modify_resources=false` (no rcedit on Linux).
   - After each push, `gh run watch`, and fix failures until green.

## 10. Milestones (in order; each ends green + pushed + PROGRESS.md updated)
- **M0 Scaffold & pipeline:** project, Compatibility renderer, autoloads, export presets, `tools/check.sh`, test runner, CI + Pages deploy of a placeholder title screen. Verify the Pages URL serves it. Write CLAUDE.md. *Proving the pipeline first is mandatory.*
- **M1 Look & feel:** palette, ART_STYLE.md, sunrise sky/sea shader, Sunrise Lounge backdrop, screenshot tour. Iterate until it genuinely feels cozy.
- **M2 Escape-room core:** hotspots, close-ups, inventory, combining, all 8 lock types, hints, one hand-made test level.
- **M3 Generator:** tiers.json, DAG generator, slot placement, clue templates, red herrings, validator, autoplay bot.
- **M4 Rooms:** Kitchen & Bar + Grandma's Study with full art and slots. All 3 rooms × 10 tiers pass validation.
- **M5 Progression:** main menu, level select (30), results, stars, seashells, saves, Replay, Endless.
- **M6 Hub & decorating:** hub, catalog, ≥ 15 decor items, placement, persistence.
- **M7 Daily Sunrise:** date seed, streak + weekly sleep-in, Sunrise Calendar.
- **M8 Story:** 5 postcards + final letter, scrapbook, hidden hotspots, completion reward.
- **M9 Audio:** complete SFX list via `npm run sfx`, AudioManager, music slots + crossfade, buses, Settings (volumes, fullscreen, text size, reduce motion).
- **M10 Onboarding & polish:**
  - Tutorial in level 1: click, inspect, inventory, combine, hints.
  - Juice: tweens, dust motes in sunbeams, unlock sparkles, gentle camera easing.
  - Accessibility and web performance passes, README.

Then work through your own **polish backlog** in PROGRESS.md (juice, par-time balancing, more clue templates, more decor) until it's empty. Finish with a summary in PROGRESS.md and stop.

## 11. Editability — the owner will iterate
`README.md` must have short, non-programmer recipes:
- Replace a sprite (overwrite the SVG with the same name, e.g. edited in Inkscape)
- Add a decor item (SVG + a decor.json entry)
- Tune or add a tier (tiers.json)
- Change a sound (edit sfx.json or paste an sfxr.me link, then `npm run sfx`)
- Add Suno music (drop a correctly named file into `assets/audio/music/`)
- Edit postcard text
- Run the game and the checks
- How auto-build and deploy work, and where the web build lives

## 12. Definition of done (v1)
- M0–M10 complete. `tools/check.sh` and CI green. Web build live and playable on a phone in landscape.
- 30 main levels + Replay + Endless + Daily all work. The validator passes for all rooms × tiers.
- Progress survives page reloads on web.
- Zero errors in the Godot output during the screenshot tour and autoplay.
- README recipes, DECISIONS.md, CREDITS.md and PROGRESS.md up to date.
