# Plan v3: third playtest round (2026-09-26)

This plan turns the owner's third playtest into work that an agent can build step by step without asking again. Every decision below was confirmed by the owner. When something here conflicts with older docs (`PROMPT.md`, `STORY.md`, `DATA_FORMAT.md`, `PROGRESS.md`), **this plan wins**. Update the older doc as part of the step that changes it.

## 0. How to work through this plan

- Before starting, read `CLAUDE.md`, `PROMPT.md`, `docs/STORY.md`, `docs/DATA_FORMAT.md`, `docs/ART_STYLE.md` and this file.
- **First step (G0):**
  - Add a "v3: third playtest" section to `docs/PROGRESS.md` with the milestones G1–G17 as checkboxes.
  - Add the decisions in section 2 to `docs/DECISIONS.md`, one line each with the reason.
- Milestones run in order. Each one ends like this:
  1. `bash tools/check.sh` is green.
  2. One commit named `G<n>: <title>`.
  3. `git push`, then `gh run watch` until the CI run is green.
  4. Tick the box in `PROGRESS.md`.
- **Three playtest checkpoints** (after G9, G14 and G17). At each one:
  1. Write a short "What to test" list under the checkpoint in `PROGRESS.md`: which dev-mode jumps to use and what to look for.
  2. Tell the owner.
  3. **Stop and wait for feedback** before starting the next phase.
- Keep to the project conventions: static typing, tabs, data in `data/*.json`, UI text through `tr()`, ThorVG-safe SVGs in palette colours, seeded RNGs only.

## 1. What the owner said (summary)

1. **Linear main story.** Endless is fine, but it's not the goal.
2. **Notes are far too direct.** They name the lock and explain how to read the code. They must become cryptic memories. The owner's examples are the standard (section 3.4).
3. **No symbol icons in notes, and no ordered symbol lists** ("the sea one first, then the star"). Symbols can come back vaguely inside memories ("when we used to ride the waves", "looking at the stars"). The symbols on the lock widget itself are fine.
4. **No icons on things that can be opened** (padlock, puzzle, tool and paw badges). Finding out what opens is part of the game.
5. **Chloé is too obvious.**
   - Her actions appear as a button when you tap a spot.
   - Tapping her makes her bark at the next step.
   - Her care cards say exactly what she needs.
   - In the hall she's a visible blob you click straight away.
   - Instead: tap Chloé, then tap a place. She can come back with nothing.
6. **The last letter only at the end of chapter 3.** Replaying the 7 rooms needs a clear "Next chapter" moment. Right now the order is: last letter → "when you were small" → "when you were big". That feels wrong.
7. **Doors lead nowhere.** Opening a door should show the next room behind it, and you walk into it. Exits must make physical sense: up the stairs to the bedroom, through the hall to the living room.
8. **The hall stairs aren't physically right.**
9. **A way to turn on lights.**
10. **Item bar:** it hides things. It should be see-through and collapsible.
11. **Notes should be picked up**, so you don't have to reopen the same cupboard to reread a clue.
12. **Everything is silent.** Sound must work again. Suno music comes later.
13. **A dev mode**, so the owner can see later rooms without playing everything.
14. "14,000 levels" sounded like overkill. Those are only test puzzles in the check, not content. They'll be trimmed locally (see G9).

## 2. Decisions (confirmed by the owner)

| # | Topic | Decision |
|---|---|---|
| D1 | Story structure | 3 chapters × the same 7 rooms = 21 rooms. **Each chapter is one period of Céline's life.** Ch1 = her last years and the summers with Juliette (2001–2025). Ch2 = Henri, Margot and the first years (1960–2001). Ch3 = the flower stall and her childhood (1938–1960), ending with the last letter. The whole story runs backwards in time. |
| D2 | Hand-made | All 21 story rooms are hand-made (notes, riddles, difficulty). Generated levels are only for Endless and Daily. |
| D3 | Linear | The next room unlocks when you finish the current one, and the next chapter when you finish the chapter. **No star gates.** Finished rooms can be replayed from the book. |
| D4 | Side modes | Endless and Daily unlock **after chapter 1**. |
| D5 | Shoebox | The old walks 2 and 3 ("when you were small / big") are removed from the story. **Endless becomes "Mamie's shoebox"**: her old treasure hunts, generated, getting harder. |
| D6 | Sunrise | **A new morning per chapter.** Juliette stays three days. Each chapter goes from dark in the kitchen to the sun up in the front garden. The chapter card says "Day 2 · 1960–2001". |
| D7 | Route | Keep the order kitchen → hall → bedroom → living room → garden → shed → front garden, with **physically logical exits** (section 3.7). A new chapter starts back through the front door into the kitchen. |
| D8 | Exits | The exit opens onto a **painted view of the next room**. The camera walks in (zoom through the opening, crossfade), and on stairs there's a short climb or descent. |
| D9 | Results | **A small toast per room** (stars, seashells) while you walk on. **A full results card per chapter**, then "Next chapter". |
| D10 | Lights | Every room has a light (switch or lamp) you have to find yourself. It makes the room brighter **and some puzzles use it** (something only visible in the dark or in the light). |
| D11 | Item bar | **Semi-transparent and narrower**, fully opaque while in use. A bag button collapses it, and it opens by itself when you pick something up. |
| D12 | Notes | Reading a note **takes it along into Mamie's notebook** (the top-right button, which also holds the hints). You can reread it any time. The item bar is for items only. |
| D13 | Hints | Notes are cryptic. Hints build up in 3 steps: **1) a nudge in Mamie's voice, 2) which object it belongs to, 3) how to read it.** |
| D14 | Difficulty curve | The ch1 kitchen stays the gentle tutorial (it may be explicit). After that it gets more cryptic and more layered room by room. Ch3 is the hardest: split clues, puzzles that feed each other, and one note from the previous room needed again. |
| D15 | Symbols | Notes contain **no symbol icons and no ordered symbol lists**. Symbols only come back vaguely inside a memory, and the order follows from the story itself. **Lock widgets keep their symbol icons.** |
| D16 | Helpers | Badges (padlock, puzzle, tool, paw), sparkles on loose items, and Chloé barking at the next step are **off by default**. A setting, "Show helpers" (off), turns them all back on. |
| D17 | Chloé control | **Tap Chloé (she stands up, ready), then tap any spot.** She goes there and does whatever fits (crawl under, dig, sniff around). There is no action menu. Scent: give her an item with a smell (select the item, tap Chloé), then she follows the trail on her own. |
| D18 | Empty trips | Where there's nothing, she comes back empty. Now and then (seeded) she brings something silly (sock, leaf, shell, cork) that is not usable. |
| D19 | Hiding | In the ch1 hall she is **invisible**. Now and then you hear a soft whimper or sniff near her hiding place. When zoomed in, a tuft of white fur shows. Gaston coaxes her out. |
| D20 | Care | **No text** about what she needs. She shows it through behaviour: sits by her empty bowl, pants in the shade, scratches at the door, bumps into things with her fringe in her eyes. |
| D21 | Placeholder audio | **Generated ambience per room** (sea, gulls, birds, a ticking clock, a humming fridge, wind and creaks) until the Suno music arrives. |
| D22 | Dev mode | **Hidden in the live build:** tap the version number in Settings 5 times. |
| D23 | Generated notes | **Half-cryptic.** Template notes point to the object in Mamie's words ("where the spoons sleep") instead of naming the lock. The validator guarantees each note can only belong to one lock. |
| D24 | Check size | Locally the validator checks 30 seeds per room/tier (2,100 levels). CI keeps checking 200 (14,000). |
| D25 | Playtests | Stop for the owner at 3 checkpoints: after the foundation (G9), after the new chapter 1 (G14), after chapters 2 and 3 (G17). |

## 3. Target design (how it should work when done)

### 3.1 Chapters and progression
- `data/campaign.json` gets `"chapters"` instead of `"walks"`. Three chapters, each with `id`, `day` (1–3), `title`, `years`, `levels` (7, in route order) and, on chapter 3 only, `finale: true` on the front garden.
- Unlock rule: level N+1 unlocks when level N is completed, and chapter 2's kitchen when chapter 1's front garden is completed. No `star_gate`. `GameState.is_level_unlocked`, `lock_reason` and `next_level_id` follow this rule.
- Daily and Endless (the shoebox) are locked (with a kind "Finish chapter 1 first" message) until the ch1 front garden is done.
- Chloé is found in the **ch1 hall**. In chapters 2 and 3 she's there from the first room (`companion: true`).
- The sky: the sunrise progress runs from room 1 to room 7 **within one chapter**, and every chapter starts dark again.

### 3.2 Flow between rooms and chapters
1. The last lock of a room opens (the exit).
2. The exit opens and **shows the next room behind it** (section 3.7). A small **results toast** slides in: stars, seashells, "new best time" if that applies.
3. The camera zooms into the opening, crossfades (≈0.6 s) to the next room, and the next room starts with a short "settle in" zoom-out. This replaces the results card between rooms.
4. After room 7:
   1. the **chapter results card** (stars per room, total time, seashells);
   2. then **"Next chapter"**;
   3. then the **Day card** of the next chapter ("Day 2 · Henri and Margot · 1960–2001" + intro line + "Begin");
   4. then the kitchen.
5. After chapter 3's front garden:
   1. the time capsule;
   2. the **last letter**;
   3. the chapter results card;
   4. a short "The end" moment;
   5. the sunroom (hub).
- The pause menu keeps "Restart" and "Leave". Stars are still saved per room (for the book and replays).
- Replaying a finished room from the book plays just that room (with the normal results card at the end, since there's no walk-through when you replay).

### 3.3 Mamie's notebook (notes and hints)
- The top-right notepad button opens **Mamie's notebook** with two tabs: **Notes** and **Hints**.
- When you read a note (clue, decoy or memory), it closes with a "tucked into the notebook" animation. The note sprite **disappears from its spot**, and the note is in the notebook from then on.
- The notebook holds every note from the current **chapter**, newest first, grouped by room. That's needed for D14, the ch3 note from the previous room. When replaying a single room or jumping in dev mode, notes listed in the level's `requires_notes` are pre-filled.
- Memories still go into the scrapbook as they do now.

### 3.4 The notes: writing rules (replaces "Voice and rules" → "Notes" in STORY.md)
- **A note is a memory, not an instruction.**
  - It never names the lock, drawer or box it belongs to.
  - It never says how to read or enter the code. Forbidden: "opens with", "read from…", "in that order", "the code is", "set it to", "the drawer", "the lock".
- **The link lives in the memory.** The memory is about the thing, so the player connects it to the object in the room: a bus → the clock, measurements → the pencil marks on the door frame.
- **Cryptic doesn't mean missing.** When a note no longer gives the answer data, that data has to be in the room: a faded bus ticket in the beach bag, a timetable on the wall, the marks on the door frame. Every lock in a story level gets a `"_why"` field that explains the intended reasoning in one or two sentences (for reviewers and the hint writer).
- **Symbols:** no `{sun}` tokens or other icons in note text, and no ordered lists of symbols. A symbol may come back vaguely inside a memory ("the summer we rode the waves", "nights looking at the stars"). The order follows from the story's own logic: which came first in her life, time of day, the order of the seasons.
- **The owner's examples are the standard:**
  - Clock (hall). Before: *"The old clock stopped the summer you stopped coming every year. Set it to our bus again and see what it has kept for you."* After: *"You always came with the bus. But we forgot what time you came, because the clock stopped working. Maybe you can fix it again."* The time (7:15) is then found in the room, e.g. on a faded bus ticket in the beach bag.
  - Pencil marks (hall). Before: *"The console drawer opens with the three lowest marks, read from the floor up."* After: *"I'll always remember those first three measurements we took."*
- **Difficulty ramp:**
  - Ch1 kitchen: the tutorial, which may be explicit.
  - Ch1 rooms 2–7: one link per lock (memory → object → answer data in the room).
  - Ch2: also combine two notes, or read the room (count, compare, order).
  - Ch3: split clues, puzzles that feed each other, and at least one note from the previous room needed again.
- **Fairness:** everything needed is in the room, the notebook or everyday knowledge, and there is exactly one sensible answer. The validator proves unique answers as it does now.
- Length stays the same (≈60 words per note, letters ≤180).

### 3.5 Hints
- Story locks get hand-written hints in the level JSON: `"hints": ["nudge in Mamie's voice", "which object it belongs to", "how to read it"]`.
  - Hint 1 never names the object (*"Where did you measure yourself every summer?"*).
  - Hint 2 names the object (*"The pencil marks by the door frame have something to do with the console."*).
  - Hint 3 explains the reading (*"The three lowest marks, from the floor up, open the console drawer."*).
- Generated levels keep the hint builder in `scripts/level/level_text.gd`, rewritten so hint 1 is a vague nudge.
- Chloé hints: hint 2 "Chloé fits where you don't…", hint 3 "Tap Chloé, then tap <the spot>." (Hints are the only place that explains Chloé's controls.)

### 3.6 Chloé
- **Control:**
  - Tap Chloé and she stands up, ears up, tail wagging: the *ready* pose, with a short "huff". On desktop the cursor becomes a paw.
  - The next tap anywhere in the room sends her there. Tapping her again, or pressing Esc, cancels.
  - While she's ready, taps go to her and don't open hotspots.
  - With an item selected, tapping Chloé **gives** it to her (care item or scent), as it does now.
- **What happens at the spot:**
  - If the tap falls in a dog-lock spot whose conditions are met, she does the fitting action (fetch, dig or sniff-search) and comes back with the reward.
  - If the conditions are *not* met (she's thirsty or hungry, wants her leash), she goes, looks, and comes back showing her need (panting, looking at her bowl).
  - Otherwise she sniffs around and comes back empty. In about 25% of empty trips (seeded per level) she brings a silly find (sock, leaf, shell, cork), which she drops at Juliette's feet with a happy wag. It is **not** added to the bag; it just lies there briefly.
- **Scent:** give her a scented item and she follows the trail to the sniff target by herself (the current behaviour).
- **No text cards and no buttons.** Dog-lock spots no longer open a "Chloé, fetch!" widget. Tapping them as Juliette shows the normal flavour text of that spot ("It's much too narrow to reach under there."). That is the subtle hint.
- **Tapping her** (no item, not ready) no longer barks at the next goal, unless "Show helpers" is on. By default she only reacts (wag, a little pet sound).
- **Care through behaviour** (D20): the `DOG_NEEDS_*` texts go. Per need there's a pose or animation and a place to stand. The bowl, the door or gate and the shade are props that exist in the room.
- **Hiding in the ch1 hall** (D19):
  - No peek sprite. She's in the **cupboard under the stairs**, behind a closed little door.
  - Every 25–45 s (seeded, only while no close-up is open), a soft `dog_whimper` or `dog_sniff`.
  - At zoom ≥ 1.8 a small tuft of white fur shows in the gap under the cupboard door.
  - Tapping the cupboard: "Something shuffles inside. It's dark in there."
  - Using Gaston on it brings her out (the current care-lock logic).
- **The kitchen note about Chloé** (ch1) introduces her in the story ("she follows me everywhere and pokes her nose into everything"), without explaining controls.

### 3.7 The house: exits and views
Every room JSON gets an `exit`, which replaces the "balcony door" meaning of `door` (the `door` key stays as the final lock's host):
```json
"exit": { "kind": "door|stairs_up|stairs_down|garden_doors|gate", "name": "…", "rect": [x, y, w, h],
          "sprite_open": "rooms/<room>_exit_open.svg", "view": "rooms/<room>_exit_view.svg" }
```
- `view` is a painted slice of the next room as seen through the opening, lit like the start of that room. It sits behind `sprite_open`.
- Exits and transitions:

| From | Exit | What you see | Transition |
|---|---|---|---|
| kitchen | door to the hall | the hall: coloured glass of the front door, the foot of the stairs | zoom through the door |
| hall | **the stairs up** (replaces the "bedroom door") | the landing and the bedroom door ajar | pan up along the stairs, fade |
| bedroom | door to the landing, **stairs down** | the top of the stairs, the hall below | pan down, a short hall silhouette, fade into the living room |
| living room | garden doors | the garden: lemon tree, the blue shed at the back | zoom through the doors |
| garden | the blue shed door | the inside of the shed: flower cart, pegboard | zoom |
| shed | side gate | the front garden path, roses | zoom |
| front garden | (end of chapter) | — | chapter card; the next chapter starts "back in through the front door" to the kitchen |

- **The hall stairs** get new art: a stringer running parallel to the steps (rising the same way as the treads), treads attached to it, a handrail parallel to the stringer, vertical balusters from tread to rail, and the cupboard with its little door under the rising part.
- The middle "bedroom door" in the hall becomes an ordinary door (e.g. to the living room, which is walked through in the bedroom → living room transition) or is removed. The rooms still face the sunrise windows. Exits sit on walls without a window.

### 3.8 Lights
- Room JSON: `"light_switch": { "name", "rect": [x, y, w, h], "kind": "switch|lamp|lantern" }` and `"lights_on_layer": "rooms/<room>_lamps.svg"` (a warm glow overlay).
- Tapping the switch toggles the lights: the overlay plus a slightly brighter room, a `switch_click` sound, and the state is kept per level session. It starts **off**. No badge.
- Puzzle use: clues, props and marks can have `"visible_when": "dark" | "light"`. Example for the ch1 bedroom: glow-in-the-dark stars on the ceiling that Juliette stuck there as a child, only visible with the lights **off**. At least one puzzle per chapter uses the light.
- The solver, validator and autoplay treat the light switch as a free action (both states reachable) and must find the switch.

### 3.9 Room helpers ("Show helpers" setting)
- `SaveManager.settings.show_helpers` (default `false`), with a toggle in the Settings panel.
- When off:
  - no badges in `level.gd` `_place_host`;
  - no sparkle on loose items (`_place_item`);
  - tapping Chloé doesn't bark at the next goal.
- When on: exactly today's behaviour.

### 3.10 Item bar
- Narrower, and the card background at ~55% opacity when idle, 100% while hovered, dragging or with an item selected.
- A bag button at its left end collapses it into just that button (state remembered in settings).
- Picking something up opens it automatically (the fly-in animation), and it collapses again after 4 s if it was collapsed before.
- The "Things you pick up will appear here" text only shows in the tutorial room.

### 3.11 Mamie's shoebox (Endless) and Daily
- The Endless menu entry and texts become "Mamie's shoebox". Content stays generated through the 7 rooms in route order, getting harder.
- Generated notes become half-cryptic (D23):
  - Each furniture spot and prop gets a `"riddle_name"` in Mamie's words ("where the spoons sleep" for the kitchen drawers).
  - `data/clues.json` templates use `{riddle_name}` instead of `{lock}` from indirection 1 upward.
  - The validator fails a level if two locks in it share a `riddle_name`, or if a note's `riddle_name` could fit two locks.
  - Reading instructions ("in that order") may stay in generated notes where the code has a split or order.
- Helpers are off in the shoebox and Daily too, following the same setting.

### 3.12 Audio
- **The silence bug.** Findings so far:
  - In a fresh Chrome window the live build does play sound effects. A click calls `AudioBufferSourceNode.start` with the AudioContext `running` and the SFX bus at 0.8.
  - The owner hears nothing on a desktop browser and an iPhone, with the sliders up, and heard clicks in v1.
  - There were no audio code or config changes between v1 (`8776aa8`) and v2.
  - So the cause has to be found on the owner's machine (G1).
- **Ambience** (D21): each room JSON gets `"ambience": "<name>"`. Generated WAV loops live in `assets/audio/ambience/` and play on the Ambience bus. The settings slider "Ocean sounds" becomes "Room sounds". Music tracks still wait for Suno. When they arrive, ambience keeps playing quietly under the music.

### 3.13 Dev mode
- **Turning it on:** tap the version label in the Settings panel 5 times. A toast says "Dev mode on" and `settings.dev_mode = true` is stored on the device. The same gesture turns it off.
- **Where:** a "Dev" button in Settings and in the pause menu opens the dev panel:
  - **Jump to** any chapter and room. This bypasses locks, sets `chloe_found` when past the ch1 hall, and pre-fills the notebook from `requires_notes`.
  - **Unlock everything** / **Reset progress** (with confirm).
  - **Solution of this room:** every lock with its answer, the note it comes from, and its `_why`.
  - **Open the selected lock** / **Finish this room** (plays the exit transition).
  - **Show helpers** toggle (shortcut to the setting).
  - **Audio status:** AudioContext state (web), bus volumes and mutes, the last 5 sounds played, and "Play test sound" plus "Resume audio" buttons.
- Normal players never see any of it.

## 4. Milestones

Each milestone lists **why**, **what**, **files**, and **done when** (tests and checks). Unless a step says otherwise, keep existing tests green and extend them.

### Phase A: foundation (built on the current chapter 1 content)

#### G1: Sound works again
- **Why:** the game is silent for the owner (desktop browser and iPhone), with sliders up. It worked in v1.
- **What:**
  1. Add a tiny script through `export_presets.cfg` → `html/head_include` (Web preset) that:
     - wraps `window.AudioContext` / `webkitAudioContext` so every created context is kept in `window.__sunriseAudio`;
     - calls `resume()` on all of them on the first `pointerdown`, `touchend` and `keydown` (this also unlocks audio on iOS Safari).
  2. `AudioManager.audio_status() -> Dictionary`:
     - on web, uses `JavaScriptBridge.eval` to read the context state(s);
     - also returns bus volumes and mutes, and a ring buffer of the last 5 `play_sfx` names.
  3. Settings panel: a "▶" test-sound button next to "Sound effects" (plays `ui_click` then `lock_open`).
  4. Ask the owner to try the live build on their desktop browser after this deploy:
     - does the test sound play?
     - if not, what does the dev panel's audio status say (G2 ships the panel; if G2 isn't done yet, log the status to the browser console on every settings open)?
  5. Also check the obvious outside causes and write down what was found: a muted tab or site in the browser, the Windows volume mixer, the iPhone silent switch (web audio follows the silent switch on iOS by default; don't override it).
  6. Fix the real cause if it's in the game. Write the finding in `DECISIONS.md` either way.
- **Files:** `export_presets.cfg`, `autoload/audio_manager.gd`, `scenes/settings/settings_panel.gd`, `i18n/strings.csv`.
- **Done when:**
  - the owner confirms sound on their desktop browser (the iPhone may still need the silent switch off);
  - a unit test covers `audio_status()` keys, and the test sound button exists.

#### G2: Dev mode
- **What:** section 3.13, all of it, working in the web build.
- **Files:** `scenes/settings/settings_panel.gd`, a new `scenes/dev/dev_panel.gd`, `scenes/level/level.gd` (pause menu entry, finish-room hook), `autoload/game_state.gd` (jump and unlock helpers), `autoload/save_manager.gd` (`dev_mode` setting), `i18n/strings.csv`.
- **Done when:**
  - a unit test turns dev mode on through the 5-tap handler;
  - a smoke test opens the dev panel;
  - jumping to the ch1 bedroom starts it with Chloé present.

#### G3: Helpers off by default
- **What:** section 3.9. Remove the in-room icons (badges), sparkles and hint barking unless `show_helpers` is on.
- **Files:** `scenes/level/level.gd`, `autoload/save_manager.gd`, `scenes/settings/settings_panel.gd`, `i18n/strings.csv`.
- **Done when:**
  - a test builds the hall with `show_helpers = false` and finds no `badge:` host sprites and no sparkles;
  - with `true` it finds them.

#### G4: Item bar and Mamie's notebook
- **What:** sections 3.10 and 3.3.
  - Notes are taken into the notebook and vanish from their spot.
  - Add the notebook tabs (Notes and Hints).
  - Add `requires_notes` support: an empty array for now.
  - Update `data/tutorial.json` so the kitchen tutorial shows the notebook and the collapsible bag.
- **Files:** `scenes/level/inventory_bar.gd`, `scenes/level/closeup_panel.gd`, `scenes/level/level.gd`, `scripts/level/level_session.gd` (notes read per chapter), `autoload/game_state.gd`, `data/tutorial.json`, `docs/DATA_FORMAT.md`.
- **Done when:**
  - tests: reading a note adds it to the notebook and removes the hotspot; the notebook lists the notes of earlier rooms in the same chapter; the bar collapse state is saved;
  - autoplay reads notes through the notebook.

#### G5: Chloé, the new way
- **What:** section 3.6, all of it.
  - Remove the "fetch/dig" widget from dog locks.
  - Add the ready state, the send-to-point flow, empty trips and silly finds (new small SVGs: sock, leaf, cork; the shell exists), and care behaviours.
  - Hide her in the ch1 hall: no peek sprite, whimper timer, fur tuft at zoom ≥ 1.8.
  - New sprites: `chloe_ready`, `chloe_pant`, `chloe_scratch`, `chloe_fringe`, `chloe_carry`.
  - New sounds in `tools/sfx/sfx.json`: `dog_whimper`, `dog_huff`, `dog_drop`.
- **Session API:** `LevelSession.send_dog_to(point_key: String) -> String` returns `"acted" | "needs" | "empty" | "silly"`, seeded.
- **Files:** `scenes/level/level.gd` (Chloé section), `scripts/level/level_session.gd`, `scenes/puzzles/dog/dog_widget.gd` (only the care/hiding "use item" target stays, without need texts), `scripts/level/level_text.gd` (Chloé hints, see 3.5), `assets/sprites/props/chloe/`, `tools/sfx/sfx.json`, `docs/DATA_FORMAT.md`, `docs/STORY.md` (Chloé section).
- **Done when:**
  - tests cover every `send_dog_to` result;
  - no `DOG_NEEDS_*` or `DOG_FETCH*` text is shown with helpers off;
  - autoplay solves dog locks with tap-Chloé-then-spot;
  - the screenshot tour has `chloe_ready`, `chloe_hall_hidden` and `chloe_hall_hidden_zoomed`.

#### G6: Walking from room to room
- **What:** sections 3.2 (the flow) and 3.7 (exits, views, transitions).
  - Add `exit` to all 7 room JSONs, and 7 `*_exit_view.svg` plus 7 `*_exit_open.svg`.
  - **Redraw the hall stairs** and the cupboard under them.
  - Replace the per-room results card with the toast.
  - Add the chapter results card (for now: after the current walk's front garden).
  - Add an `arrive_from` Router param so the next room plays the matching arrival.
  - Autoplay and tests get a `skip_transitions` flag.
- **Files:** `data/rooms/*.json`, `assets/sprites/rooms/`, `scenes/level/level.gd` (`_open_door_glow` becomes `_play_exit`, `_show_results`), `scenes/level/room_zoom.gd`, `autoload/router.gd`, `scenes/room/room_view.gd`, `docs/DATA_FORMAT.md`, `docs/ART_STYLE.md` (exit view rules).
- **Done when:**
  - the screenshot tour shows every exit open with its view;
  - the hall shows the new stairs;
  - a test goes kitchen → hall → bedroom with transitions on and checks the arrival param;
  - completing a room still records stars.

#### G7: Lights
- **What:** section 3.8. Add a switch or lamp to all 7 rooms plus the glow overlays. Add `visible_when` for clues, props and items in the session, solver and validator. Add one demo use in the current bedroom (glow stars) so it can be playtested at checkpoint 1.
- **Files:** `data/rooms/*.json`, `assets/sprites/rooms/*_lamps.svg`, `scenes/level/level.gd`, `scripts/level/level_session.gd`, `scripts/solver/level_solver.gd`, `scripts/generator/level_validator.gd`, `docs/DATA_FORMAT.md`.
- **Done when:**
  - tests: toggling changes visibility, and the solver finds a `visible_when: dark` clue;
  - the validator rejects a level where a needed clue can never be visible.

#### G8: Room ambience
- **What:** section 3.12, ambience.
  - Build `tools/ambience/ambience.mjs`: deterministic (seeded) synthesis of loopable mono WAVs, 22,050 Hz, 12–20 s, crossfaded loop ends. Add an npm script `npm run ambience`.
  - Loops:
    - `kitchen` (fridge hum, a clock, far-off gulls)
    - `hall` (grandfather-clock tick, the house creaking)
    - `bedroom` (soft sea through the window, a curtain rustle)
    - `lounge` (sea, a faint wind)
    - `garden` (birds, bees, sea)
    - `shed` (wind, wood creaks, a fly)
    - `front_garden` (birds, far-off market murmur, sea)
  - Import them with QOA compression (`.import` compress mode) so the web build stays small (target ≤ 250 KB each).
  - Room JSON `ambience` key; `level.gd` calls `AudioManager.play_ambience`.
- **Files:** `tools/ambience/`, `package.json`, `assets/audio/ambience/`, `autoload/audio_manager.gd` (an ambience dir alongside music), `data/rooms/*.json`, `scenes/settings/settings_panel.gd` (the "Room sounds" label), `i18n/strings.csv`, README recipe.
- **Done when:**
  - the audio test checks that every room's `ambience` file exists;
  - the export size grows by ≤ 2 MB.

#### G9: Faster local check
- **What:** D24.
  - `tools/check.sh` passes `--seeds=${VALIDATE_SEEDS:-30}` to the validator.
  - The CI workflow sets `VALIDATE_SEEDS=200`.
  - The step summary prints the number of levels checked.
- **Files:** `tools/check.sh`, `.github/workflows/*.yml`, `README.md`, `CLAUDE.md` (the command list).
- **Done when:** the local check reports 2,100 generated levels and CI reports 14,000.

> **Playtest checkpoint 1:** foundation. The owner plays the current chapter 1 with:
> - sound;
> - dev mode;
> - no helpers;
> - the new bag and notebook;
> - the new Chloé (hidden in the hall, tap-then-spot);
> - walking between rooms with views;
> - the new stairs;
> - lights with the glow-star demo in the bedroom;
> - room sounds.
>
> **Stop and wait for feedback.**

### Phase B: the new structure and chapter 1

#### G10: The story bible for three chapters
- **Why:** the notes carry the story, so it has to be written before the levels (D1, D14, D15).
- **What:** rewrite `docs/STORY.md`:
  - **Structure:** 3 chapters (days) × 7 rooms. The whole story runs backwards in time. Chapters are strictly backwards (ch1 newest, ch3 oldest). Within a chapter, rooms run mostly backwards, and each chapter ends on its oldest moment.
  - **The room table:** for each of the 21 rooms, the period, the title, 2–4 memories (topic plus one line), the puzzles, where the answer data sits in the room, the props it needs, the postcard if any, and what Chloé does. Start from the draft below. Existing memories move to where they fit and are **rewritten to the new rules** (3.4).
  - **The new "Voice and rules"**, with section 3.4 as the notes part, including the owner's two before/after examples.
  - **The shoebox:** now Endless, not the story. The hall note about the shoebox now points to "when this is all over".
  - **The last letter:** unchanged in spirit (she had a beautiful life, wishes Juliette the same, hopes she builds it in this house). It's found at the end of **chapter 3** in the time capsule. Small edits so it mentions the three days.
  - **The chapter cards:** a title, years and an intro line for each of the three Day cards.
- **Draft room table** (adjust freely, but keep the rules above):

| Ch / Day | Room | Draft period and topics | Postcard |
|---|---|---|---|
| 1 / Day 1 "The summers with Juliette" (2001–2025) | kitchen | 2015–2025: mornings with Chloé, the market, lemon tart, welcome letter (tutorial) | |
| | hall | 2009–2015: Juliette grown up; pencil marks, the 7:15 bus, summer photos; Chloé hides here | Reykjavik 2013 |
| | bedroom | 2005–2009: thunderstorm nights in Mamie's bed, the glow-in-the-dark stars, bedtime stories | |
| | living room | 2003–2005: rainy-day treasure hunts, card games (Mamie loses badly), the fort | |
| | garden | 2002–2003: the red bicycle on the garden path, the crab in the bucket | |
| | shed | 2001–2002: the beach bucket and spade, the sandcastle contest ribbons | |
| | front garden | summer 2001: Juliette, five, arrives at the gate with her bucket ("you saved me that summer") | |
| 2 / Day 2 "Henri and Margot" (1960–2001) | kitchen | 1990s–2001: Henri's number puzzle and her crossword at breakfast, cheating for each other | |
| | hall | 1981–1994: Margot leaves for Montréal with her suitcase; Sunday phone calls; the travel suitcase by the door | Santorini 1994 |
| | bedroom | 1981–1990: dancing in socks, their song on the jewellery box, the wedding photo | |
| | living room | 1963–1981: story-time lamps, Sunday records, piano lessons, birthdays | Marrakech 1979 |
| | garden | 1960–1963: the wedding under the little lemon tree, the first seeds, the first lemon | Lisbon 1960 |
| | shed | 1960–1962: Henri paints the shed blue, builds the bench and Margot's cradle | |
| | front garden | 1960: the day Rose handed them the key to the house | |
| 3 / Day 3 "The girl at the flower stall" (1938–1960) | kitchen | 1957–1960: the one vase on Rose's kitchen table, a sunflower every Saturday | |
| | hall | 1958: Henri's letters from the sea through the letterbox slot | Kyoto 1958 |
| | bedroom | 1950s: Céline's girlhood room, the window where she watched for Papa's boat | |
| | living room | 1956: evenings by the radio with Maman (Papa's death, once and gently) | |
| | garden | 1950s: Rose's flower beds that supplied the stall | |
| | shed | 1955–1957: the flower cart, the price board, Maman's scales | |
| | front garden | 1938–1948: born here, waving at Papa, hopscotch, the roses, the time capsule → **the last letter** | |

- **Done when:**
  - `STORY.md` has the full 21-room table and the new rules;
  - `data/story.json` is restructured to `chapters[] → rooms[] → memories[]` (memory text for ch1 complete; ch2 and ch3 may still have topic stubs).

#### G11: The chapter structure
- **What:** sections 3.1, 3.2 (chapter card, Next chapter, Day card, finale after ch3) and 3.11 (shoebox naming and unlock).
  - `data/campaign.json` becomes `chapters`. Ch2 and ch3 temporarily reuse copies of the current story levels with placeholder notes, so the flow can be played end to end.
  - Remove the star gates.
  - Daily and shoebox unlock after ch1.
  - Level select ("the book") shows 3 chapters × 7 rooms along the route: locked rooms greyed, finished ones replayable with stars.
  - The scrapbook: pages per chapter, then per room, with the last letter after ch3.
  - Main menu "Continue" goes to the next unfinished room.
  - The sky runs per chapter.
  - Save migration v2 → v3 (`SAVE_VERSION = 3`):
    - reset `levels`, `endless`, `memories`, `chloe_found`, `final_letter_read`;
    - keep seashells, decor, postcards, the daily streak and settings.
- **Files:** `data/campaign.json`, `scripts/generator/campaign.gd`, `autoload/game_state.gd`, `autoload/save_manager.gd`, `scenes/level_select/`, `scenes/scrapbook/`, `scenes/main_menu/`, `scenes/level/level.gd` (finale gate, chapter flow), `data/story.json`, `i18n/strings.csv`, `docs/DATA_FORMAT.md`.
- **Done when:**
  - progression tests: linear unlock across the chapter boundary, no star gates, side modes locked until ch1 is done, finale only after ch3;
  - a migration test from a v2 save;
  - a screen smoke test for the Day card and the chapter results card.

#### G12: Hints and the notes lint
- **What:**
  - Add hand-written `hints` (3 per lock) and `_why` to the story level format (section 3.5).
  - Rewrite the generic hint builder so hint 1 is vague.
  - Add a **notes lint unit test** over every story memory except the ch1 kitchen. It fails on:
    - `{symbol}` tokens;
    - the forbidden phrases in 3.4;
    - the name of the lock's own host (from the room JSON);
    - any digit sequence equal to the lock's answer.
  - Add a **level lint:** every story lock has 3 hints and a `_why`.
- **Files:** `scripts/level/level_text.gd`, `scripts/level/level_session.gd`, `tests/unit/test_story_lint.gd` (new), `docs/DATA_FORMAT.md`.
- **Done when:** the lint runs in the gate (ch2 and ch3 placeholder levels are excluded until G15 and G16 through an explicit list in the test, which must be empty after G16).

#### G13: Chapter 1, rewritten
- **What:** the 7 ch1 rooms, per the `STORY.md` table:
  - new cryptic notes, puzzles, `_why` and hints;
  - answer data placed in the room (new props as needed: the bus ticket, the glow stars, …);
  - Chloé found in the hall;
  - Reykjavik in the hall.
- The ch1 kitchen stays the tutorial: its notes may be explicit, and `data/tutorial.json` is updated for the notebook, bag and lights.
- Every room uses at least 3 different lock types, and the chapter uses the light once and Chloé at least 3 times (once each: fetch, dig, scent/care).
- **Files:** `data/levels/ch1_*.json` (renamed from `story_*`), `data/story.json`, `data/props.json`, `data/items.json`, `assets/sprites/…`, `docs/STORY.md`.
- **Done when:**
  - the validator proves every ch1 level (unique answers, keys as rewards, fair par time);
  - the lint passes;
  - autoplay finishes ch1 through the UI;
  - the screenshot tour covers every ch1 room.

#### G14: Half-cryptic generated notes
- **What:** section 3.11.
  - Add `riddle_name` to all furniture spots and props in the 7 rooms.
  - Change the `clues.json` templates (from indirection 1 on).
  - Add a validator rule for unique `riddle_name`.
  - Rename Endless to "Mamie's shoebox".
- **Files:** `data/rooms/*.json`, `data/props.json`, `data/clues.json`, `scripts/generator/riddle_maker.gd`, `scripts/generator/level_generator.gd`, `scripts/generator/level_validator.gd`, `i18n/strings.csv`.
- **Done when:** the full generated set passes the validator, and a test shows no generated note above indirection 0 contains a plain lock name.

> **Playtest checkpoint 2:** the new chapter 1 from start to finish, then (through dev mode) the flow into Day 2 with placeholder rooms, and a few shoebox/Daily levels.
>
> **Stop and wait for feedback.**

### Phase C: chapters 2 and 3

#### G15: Chapter 2 (Day 2, 1960–2001)
- **What:**
  - Write the 7 ch2 rooms per `STORY.md` (memories, puzzles, `_why`, hints, props, answer data in the room). Existing bedroom, living room and garden memories move here, rewritten.
  - Postcards: Santorini, Marrakech, Lisbon.
  - Difficulty: combining two notes or reading the room in most rooms.
  - At least one light puzzle, and Chloé in at least 3 rooms.
- **Done when:** validator, lint (ch2 removed from the exclusion list), autoplay and screenshot tour are all green.

#### G16: Chapter 3 (Day 3, 1938–1960) and the finale
- **What:**
  - Write the 7 ch3 rooms. The shed and front garden memories move here, rewritten. Kyoto goes in the hall.
  - Split clues, puzzles that feed each other, and at least one `requires_notes` link to the previous room.
  - The time capsule and the last letter at the end of the ch3 front garden, then the chapter results, "The end", the sunroom.
- **Done when:**
  - validator, lint (exclusion list now empty), autoplay (the whole story, 21 rooms) and screenshot tour (finale) are green;
  - `postcards.json` and the scrapbook show everything in the right chapter.

#### G17: Polish and the v3 summary
- **What:**
  - Go through the "v2 ideas" backlog in `PROGRESS.md`, but only what fits.
  - Check par times per room against autoplay step counts.
  - Update the README recipes (how to write a story room, the notes rules, dev mode, ambience).
  - Write "Summary (v3 done)" in `PROGRESS.md`.

> **Playtest checkpoint 3:** chapters 2 and 3 and the finale (dev mode jumps to Day 2 and Day 3).
>
> **Stop and wait for feedback.**

## 5. Out of scope for this round
- Suno music (the owner makes it later; the slots in `docs/SUNO_PROMPTS.md` stay).
- New rooms beyond the seven.
- Translating the game (the hint builder's hard-coded English strings move to `tr()` only where G12 touches them anyway).
