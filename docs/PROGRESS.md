# Progress

Live build: https://mabsteer.github.io/sunrise-suite/

## Milestones
- [x] **M0 Scaffold & pipeline**: project, autoloads, export presets, `tools/check.sh`, test runner, CI + GitHub Pages
- [x] **M1 Look & feel**: sunrise sky/sea shader, Sunrise Lounge art (room, balcony, view, 7 furniture pieces), RoomView, screenshot tour, title screen backdrop
- [x] **M2 Escape-room core**: LevelSession (rules), LevelSolver, LevelText (names/hints), level scene with hotspots, close-ups, inventory (select/inspect/combine/drag), 8 lock widgets, 3-level hints, results + seashells, hand-made test level
- [x] **M3 Generator**: tiers.json (10 tiers + Endless), clue templates (clues.json), backwards DAG generator with recipes/nesting/split clues/decoys/postcards, LevelValidator, validator scene (200 seeds x room x tier), autoplay bot through the real UI, campaign.json (30 levels)
- [ ] M4 Rooms
- [ ] M5 Progression
- [ ] M6 Hub & decorating
- [ ] M7 Daily Sunrise
- [ ] M8 Story
- [ ] M9 Audio
- [ ] M10 Onboarding & polish

## Next
- M4: Kitchen & Bar + Grandma's Study: backgrounds, furniture with spots, room JSON; all 3 rooms x 10 tiers must validate.

## Known issues
- Portrait phones show the room small with empty bands above and below. Plan: "rotate your phone" hint (M10).
- The title screen has a temporary "Try the test room" button until the real menu arrives (M5).

## Polish backlog
- Door visibly opening at the end of a level (slide/glow).
- Rotate-your-phone hint in portrait.

## Blocked
- (none)
