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

## Next
- v1 is done (see the summary at the end). Ideas for later: more rooms, a proper Suno soundtrack (docs/SUNO_PROMPTS.md), more postcards.

## Known issues
- Portrait phones show a "turn your phone sideways" card (it can be dismissed); the game is designed for landscape.

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

## Blocked
- (none)

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
