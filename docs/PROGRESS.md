# Progress

Live build: https://mabsteer.github.io/sunrise-suite/

## Milestones
- [x] **M0 Scaffold & pipeline**: project, autoloads, export presets, `tools/check.sh`, test runner, CI + GitHub Pages
- [x] **M1 Look & feel**: sunrise sky/sea shader, Sunrise Lounge art (room, balcony, view, 7 furniture pieces), RoomView, screenshot tour, title screen backdrop
- [x] **M2 Escape-room core**: LevelSession (rules), LevelSolver, LevelText (names/hints), level scene with hotspots, close-ups, inventory (select/inspect/combine/drag), 8 lock widgets, 3-level hints, results + seashells, hand-made test level
- [x] **M3 Generator**: tiers.json (10 tiers + Endless), clue templates (clues.json), backwards DAG generator with recipes/nesting/split clues/decoys/postcards, LevelValidator, validator scene (200 seeds x room x tier), autoplay bot through the real UI, campaign.json (30 levels)
- [x] **M4 Rooms**: Kitchen & Bar (zellige backsplash, mint fridge, sage counter, island, espresso, spice rack, fruit bowl) and Grandma's Study (French doors, velvet curtains, world map, grandfather clock, desk + typewriter, globe, bookcase, trunk). 6000 levels validate, 62 autoplay
- [x] **M5 Progression**: main menu (play/continue, daily, counters), Grandma's Sunrise Book level select (10 tier rows x 3 room cards with room thumbnails, stars, padlocks, postcard stamps, star gates), replay (same or fresh puzzle), Endless Sunrise, results with Next sunrise / unlock messages, progression tests
- [x] **M6 Hub & decorating**: airy penthouse hub (arched windows, beams), 24 decor items (16 buyable, 8 earned), 12 decor slots, Decorate mode (place, buy, move, flip, put away), Grandma's Catalog, starter decor, level rewards (mango cat, sunburst mirror, telescope, golden sun), decor tests
- [x] **M7 Daily Sunrise**: UTC-date seeded daily level (room rotation + weekday difficulty), streaks with one free sleep-in per week (several weeks can each cover a missed day), streak rewards (3/7/14 days), Sunrise Calendar with sky-painted day tiles, daily results; screen smoke test added to the gate
- [x] **M8 Story**: 5 illustrated postcards (Lisbon, Kyoto, Santorini, Marrakech, Reykjavik) with Grandma June's messages, postcard pickup in levels 3/9/15/21/27, scrapbook with flip-over backs, final letter, Grandma's portrait reward; autoplay also collects postcards through the UI
- [x] **M9 Audio**: 37 jsfxr sounds (music-box notes per symbol, clock ticks, switches, tiles, key/tool/search, purchase, streak...), music per screen (menu, rooms, hub, daily), one-shot sunrise stinger that ducks the music, Settings panel (4 volume sliders, fullscreen, timer, reduce motion, text size, credits, start over) from the menu and pause menu; audio test checks every sound name used in code exists
- [x] **M10 Onboarding & polish**: hand-made tutorial level 1 with a step-by-step guide (data/tutorial.json), dust motes in the sunbeams, settle-in zoom, door glow + lean toward the door on completion, bouncing boxes, rotate-your-phone hint, Esc everywhere, sky shader limited to window areas (web performance), README with recipes

## v3: third playtest (2026-09-26)
The owner's third playtest: a linear story over three chapters (days) of seven hand-made rooms, cryptic notes, no helper icons, a new way to work with Chloé, walking from room to room, lights, a notebook for notes, a see-through bag, sound and a dev mode. The full plan with every decision is `docs/PLAN_V3.md`; it wins over older docs. Each milestone ends with `bash tools/check.sh`, a commit, a push and a green CI run.

### Phase A: foundation
- [x] **G0** Plan in PROGRESS.md and DECISIONS.md
- [ ] **G1** Sound: resume audio on the first tap (web), audio status, test-sound button
- [ ] **G2** Dev mode (tap the version 5 times in Settings)
- [ ] **G3** Helpers off by default ("Show helpers" setting)
- [ ] **G4** See-through, collapsible bag and Mamie's notebook (notes are taken along)
- [ ] **G5** Chloé the new way: tap her, then a spot; hidden in the hall; care through behaviour
- [ ] **G6** Walking from room to room: exits with a view of the next room, new hall stairs, toast per room
- [ ] **G7** Lights (and things only visible in the dark)
- [ ] **G8** Generated room ambience
- [ ] **G9** Faster local check (30 seeds locally, 200 in CI)
- [ ] **Playtest checkpoint 1**

### Phase B: structure and chapter 1
- [ ] **G10** Story bible for three chapters (STORY.md, story.json)
- [ ] **G11** Chapter structure: linear, Day cards, chapter results, finale after chapter 3, save v3
- [ ] **G12** Hand-written hints and the notes lint
- [ ] **G13** Chapter 1 rewritten
- [ ] **G14** Half-cryptic generated notes, Endless becomes Mamie's shoebox
- [ ] **Playtest checkpoint 2**

### Phase C: chapters 2 and 3
- [ ] **G15** Chapter 2
- [ ] **G16** Chapter 3 and the finale
- [ ] **G17** Polish and the v3 summary
- [ ] **Playtest checkpoint 3**

## v2: playtest feedback (2026-09-26)
The owner's playtest feedback changes the direction: difficulty must come from thinking, not searching; more kinds of puzzles; one route through a whole house; a new story (Juliette inherits her late grandmother Céline's house) told through the notes; Chloé the dog as a helper; zooming. Work in this order, each milestone ends with `bash tools/check.sh`, commit, push and a green CI run.

- [x] **F1 Bug**: the missing `NOTHING_HIDDEN_SHORT` text and the `NOTHING_HIDDEN` placeholder. New unit test: every text key the code uses exists, and keys formatted with `%` have a placeholder.
- [x] **F2 Story**: `docs/STORY.md` (premise, people, timeline, one life period per room, the notes as memories with riddles woven in, Chloé, the postcards, the scrapbook, the last letter). Rewrite the postcards, the final letter and every "Grandma June / penthouse" text to fit.
- [x] **F3 Puzzle system and difficulty**
  - New locks you *do* something with: **order** (arrange things, solved with a logic note), **sudoku** (small 4×4 number square), **pattern** (what comes next?), **rotate** (turn the tiles until the picture is right), **tool** (use an item on something you can see).
  - Riddle notes: the code is never written plainly above tier 1. Digits come from facts, from counting things in the room (jars of shells, birds in a painting...), from sums, and from logic statements (for symbol, lamp and order locks).
  - Puzzles build on each other: a solved puzzle can reveal the code for the next one.
  - A key is always the reward of a solved puzzle, never lying around.
  - Hiding is no longer a difficulty knob: at most one search spot per level, never holding a key.
  - `tiers.json` reworked around thinking: number of puzzles, which puzzle types, riddle depth, chaining, puzzle size. Validator, solver, hints, autoplay and par-time model updated. `DATA_FORMAT.md` documents every new lock.
- [x] **F4 The house route**
  - Seven rooms in one route: kitchen → hall → bedroom → living room → garden → shed → front garden. Five new rooms (hall, bedroom, garden, shed, front garden) with their own art, furniture and puzzle flavours; the kitchen and living room are adapted; the study retires.
  - The campaign becomes walks through the house: walk 1 is the story, walks 2 and 3 are Mamie's old treasure hunts (generated, harder). Each room's exit leads to the next room, and the sunrise spans the whole walk.
  - Level select shows the route; chapter cards at the start and end of each story room; the scrapbook becomes Céline's life (memories and postcards per period, the last letter at the end).
  - Daily, Endless and Replay use all seven rooms. Save migration for old progress.
- [x] **F5 Chloé**
  - White Maltese sprites (sit, walk, sniff, dig, sleep). She is found in the hall, then follows Juliette and is visible in every later room (and in the sunroom).
  - Dog actions in levels: fetch (under furniture, through small gaps), dig, sniff (give her a scent to follow), bark at what matters, and care tasks (food, water, leash, her toy). Generator support and `DATA_FORMAT.md`.
- [x] **F6 Story levels**: the seven hand-made story levels with the memories and riddles from `STORY.md`, a new kitchen tutorial, postcards in rooms 2–6, and the last letter at the front garden gate.
- [x] **F7 Zoom**: pinch and mouse-wheel zoom, drag to pan, zoom buttons, double-tap to zoom in on a spot.
- [x] **F8 Polish and summary**: scrapbook memories show symbols as icons, the "memory for the scrapbook" toast waits until the note is put down, Chloé's spots sit above the bag in every room, the screenshot tour waits for the first screen, and this summary.

## Next
- v3 (see above and `docs/PLAN_V3.md`).

## Known issues
- Portrait phones show a "turn your phone sideways" card (it can be dismissed); the game is designed for landscape.
- Pinch-zoom is covered by unit tests with simulated input, but hasn't been tried on a real phone yet.

## Polish backlog
- [x] Pause the level timer while the browser tab or window is in the background (fair third star).
- [x] Small step counter under the room title ("2 of 6"), next to the sunrise.
- [x] Results: seashells count up, "new best time" note.
- [x] Main menu: "Next sunrise" quick button that jumps straight into the current level.
- [x] Level book: show best time on finished cards; daily card shows an easy/medium/hard label.
- [x] More clue template variety in clues.json (more phrasings per level).
- [x] Hub life: Mango the cat breathes, the lanterns sway gently.
- [x] Par-time sanity check: measure the autoplay step count per tier against par_time.
- [x] Custom web loading screen colours (sunrise gradient instead of plain background).

### v2 ideas (not started)
- [ ] Double-tap on furniture could zoom in on it instead of opening it straight away (now: double-tap zooms on empty spots only).
- [ ] Zoom in the sunroom too.
- [ ] More memories per room (the scrapbook has 3-4 per chapter).
- [ ] Walk 2/3 notes in Mamie's voice to little and teenage Juliette (they now use the generic clue templates).

## Blocked
- (none)

## Summary (v2 done)
The playtest feedback round (F1-F8) is complete, the checks are green, and every push deploys to https://mabsteer.github.io/sunrise-suite/.

- **Story:** Juliette inherits Mamie Céline's house by the sea. Walk 1 is seven hand-made story rooms, from Céline's last years in the kitchen back to her childhood in the front garden. There are 22 memories (notes that are story and riddle at once), 5 postcards, and her last letter in the time capsule under the roses. `docs/STORY.md` is the story bible.
- **Puzzles that make you think:** 15 lock types (codes, symbol tunes, clocks, lamps, orders, number squares, patterns, turning and sliding tiles, keys, tools, search spots, and Chloé's fetch/dig, care and sniff). From room 2 on, codes come from riddles, counting, sums and logic. Keys are always a puzzle's reward. Every order, lamp riddle and number square is proven to have exactly one answer.
- **The house:** one route through seven rooms (kitchen → hall → bedroom → living room → garden → shed → front garden), each with its own art and puzzles. Three walks, Replay, Endless, Daily.
- **Chloé:** Mamie's Maltese hides in the hall, then follows Juliette through every room and naps in the sunroom. She fetches, digs, sniffs and barks, and has her own care tasks.
- **Look closer:** pinch, the mouse wheel, drag, double-tap and +/- buttons zoom the room up to 2.5x.
- **Safety net:** `bash tools/check.sh` runs 77 unit tests, validates 14,000 generated levels plus the story levels (unique answers, keys as rewards, fair par times), and a bot plays 149 levels through the real UI. Web and Windows exports are built on every push.
- **What needs a human:** a playtest on a real phone (pinch, Chloé, the story walk), and the Suno music tracks (`docs/SUNO_PROMPTS.md`; the game is quiet until they're added).

## Summary (v1 done)
Sunrise Suite v1 is complete: every milestone (M0-M10) and the whole polish backlog are done, the checks are green, and every push deploys to https://mabsteer.github.io/sunrise-suite/.

- **Game:** 30 main levels (3 rooms × 10 tiers) generated from fixed seeds, a hand-made tutorial level, Replay (same or fresh puzzle), Endless Sunrise, and a Daily Sunrise with streaks and a calendar. 8 lock types, item combinations, 3-step hints, stars and seashells.
- **Reasons to come back:** decorating the penthouse (24 decor items, 12 slots), the daily streak, 5 postcards + Grandma's final letter, 3-star ratings with soft star gates.
- **Editable:** all art is SVG (one file per object, drawn by scripts in `tools/art/` or by hand in Inkscape). All content is JSON in `data/`, sounds come from `tools/sfx/sfx.json` (jsfxr, 37 sounds), music slots wait for Suno tracks (`docs/SUNO_PROMPTS.md`). README has step-by-step recipes.
- **Safety net:** `bash tools/check.sh` (also run by GitHub Actions on every push):
  - import, load every script, 48 unit tests, and open all 16 screens;
  - validate 6000 generated levels (plus campaign, daily and a par-time check);
  - a bot plays 68 levels through the real UI;
  - Web and Windows exports.
- **What needs a human:** the Suno music tracks (the game is quiet until they're added), and playtesting the feel on a real phone.
