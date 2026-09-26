# Data formats

All game content lives in human-editable JSON files in `data/`. Sprite paths are relative to `assets/sprites/`.
Keys starting with `_` (like `_help`) are comments and are ignored.

## `data/rooms/<room>.json`: room templates
| Key | Meaning |
|---|---|
| `id`, `name` | Room id (used by levels) and display name |
| `background`, `light`, `view_far`, `balcony` | Layer sprites (2400×1440, see ART_STYLE.md) |
| `horizon_y`, `sun_x` | Where the horizon and the sun are, in stage pixels |
| `music` | Music track name (see SUNO_PROMPTS.md) |
| `sky_rect` | Where the sunrise sky shader is drawn (only behind windows indoors; the whole sky outdoors) |
| `outdoor` | `true` for the garden and the front garden (no walls; sky above) |
| `door` | `{ "name", "rect": [x, y, w, h] }`: the room's exit (to the next room on the route), the final lock of every level |
| `dog_spot` | `[x, y]`: where Chloé sits in this room (bottom-centre) |
| `furniture` | Always-present furniture: `{ id, name, sprite, pos: [x,y], size: [w,h], spots: [...], flavor }` |
| `furniture[].spots` | Places on the furniture that can hold something: `{ id, name, rect: [x,y,w,h] (furniture-local), locks: [types], tools: [null or item type], clue: bool, reveal, dog_action? }`. A spot that lists `"dog"` in its locks is a place where Chloé can help; `dog_action` says how: `"fetch"` (she crawls under or into it, the default) or `"dig"` (soft soil). A `"hidden"` spot can also hold a `"sniff"` lock (a smell only she can find). |
| `wall_slots` | Where wall props go: `{ id, rect: [x,y,w,h], accepts: ["wall", "wall_small"] }` |
| `surface_slots` | Where small props or items stand: `{ id, anchor: [x, y] (bottom-centre), max: [w, h], name }` |

## `data/props.json`: props levels can place
`{ name, sprite, sprite_open?, sprite_count?, size: [w,h], place: "wall"|"wall_small"|"surface", locks?: [types], tools?: [...], clue?: bool, reveal? }`
- **Counter props** (`shell_jar`, `daisy_vase`, `boat_photo`, `bird_picture`) show a number of things to count. They have `sprite_count` with `{n}` in it (`props/counters/shell_jar_{n}.svg`, n = 1-9); a level picks the number with `"count"` in the host. How riddles name them is in `data/clues.json` → `counters`.

## `data/items.json`: inventory items
`{ name, sprite (128×128), kind: "key"|"tool"|"part"|"clue"|"care"|"scent", text }`
- `care`: something Chloé needs (kibble, the water jug, her leash, her brush, Gaston the toy seagull). Given to her, not used on a spot.
- `scent`: something that smells of someone (Mamie's gardening glove, Henri's scarf, Margot's teddy). Give it to Chloé and she follows the smell to a `sniff` lock.

## `data/recipes.json`: combinations
`{ "recipes": [ { "a": item type, "b": item type, "result": item type } ] }`

## `data/symbols.json`: symbols for sequence/switch locks
`{ name, color (palette name), sprite }`. Write `{sun}` in clue text to show the icon inline.

## `data/levels/<id>.json`: levels (hand-made, and what the generator produces)
```json
{
  "id": "test_lounge", "room": "lounge", "tier": 3, "seed": 1, "par_time": 600, "riddle"?: 2,
  "locks":   [ { "id", "type", "host", "location", "answer"?, "clues"?: [clue ids], "item"?: item id, "config"?: {}, "after"?: [lock ids], "is_door"?: true } ],
  "items":   [ { "id", "type" (items.json key), "location", "slot"? } ],
  "recipes": [ { "a": item id, "b": item id, "result": item id } ],
  "clues":   [ { "id", "host", "location", "for": lock id, "text", "item"?: item id, "source"?: lock id } ],
  "decoys":  [ { "id", "host", "location", "text" } ],
  "postcard": { "id", "host", "location" }
}
```
- **location**: `"room"` (visible from the start), a **lock id** (inside that lock's container, reachable once it's open), or `"recipe"` (items made by combining).
- **host**: where the thing is.
  - `{ "kind": "door" }`
  - `{ "kind": "furniture", "furniture": id, "spot": spot id }`
  - `{ "kind": "prop", "prop": props.json id, "slot": slot id }` (the slot is only needed in the room). A counter prop also has `"count": 1-9`.
- **Lock types** and their `answer`. Locks you *know* the answer to (from clues):
  - `combo`: digits `"4729"`, config `{ "digits": 4 }`
  - `sequence`: symbols `"sun,shell,wave"`, config `{ "length": 3 }`
  - `clock`: `"7:30"`
  - `switches`: pattern `"1010"`, config `{ "symbols": [...] }`
  - `order`: things in the right order, left to right, `"shell,sun,star"`, config `{ "length": 3 }`. You swap the things around until they're right; the clue is a note with logic statements ("{sun} comes right after {shell}").
- Puzzles you *solve* on the spot (no clue needed):
  - `slider`: `"solved"`, config `{ "size": 3, "picture", "scramble" }`
  - `rotate`: `"solved"`, config `{ "size": 2-4, "picture" }`. Tiles start turned; tap to turn them upright.
  - `sudoku`: the full 4x4 square row by row `"1234341221434321"`, config `{ "givens": "12.4.41..14.4..1" ("." = empty), "shaded"?: [cell numbers 0-15] }`. The givens must have exactly one solution (the validator checks). A clue with `"source": <sudoku lock id>` inside the square says "the shaded squares open ...": its lock's code must equal the shaded digits, read row by row.
  - `pattern`: "what comes next?", config `{ "kind": "numbers"|"symbols", "terms": [all terms, as text], "blanks": [positions to fill in] }`, answer = the blank terms joined with commas (`"10,12"`).
- Locks you use an item on:
  - `key`: needs `item` (a key)
  - `tool`: needs `item` (a tool: flashlight, trowel, screwdriver, magnet on a string). You can see it needs something.
  - `hidden`: nothing needed, just search. At most one per generated level.
- **Chloé's locks** (only in levels with `"companion": "chloe"`; see the section below):
  - `dog`: she fetches or digs something out, `"action": "fetch"|"dig"`. No item; you ask her in the close-up ("Chloé, fetch!").
  - `care`: she needs something, host `{ "kind": "dog" }` (it's Chloé herself), `item` = a `care` item. You select it and tap her. When she's happy she drops what she was guarding. With `"finds_dog": true` the lock is her hiding place instead (host = a spot), and giving her Gaston brings her out.
  - `sniff`: a spot with a smell, `item` = a `scent` item. Give her the scent and she runs to the spot and finds what's there. At most one per generated level.
- **after**: this lock can only be used once all these locks are open (e.g. Chloé only helps after breakfast).
- **Keys are rewards**: an item of kind `key` must be inside a puzzle (`combo`, `sequence`, `clock`, `switches`, `order`, `sudoku`, `pattern`, `rotate`, `slider`, `tool`, `care`), never in the room or a search spot. The validator checks this for every level.
- **Clues** can be carried by an item (`"item"`). The clue is then read by looking at that item in the bag.
- Every lock and every recipe is one **step**. The sunrise progress is `solved steps / all steps`.
- **companion** (optional): `"chloe"` when Chloé is in the level. Without it, levels have no dog locks (the validator checks).
- **riddle** (optional, hand-made levels): how hard the notes are, for the par-time check (generated levels take it from `tiers.json`).

## `data/campaign.json`: the walks through the house
`walks`: `[ { "id": 1, "title", "subtitle" (text keys), "story"?: true, "star_gate": stars needed to start it, "levels": [ ... ] } ]`.
Each walk lists the seven rooms in route order (kitchen, hall, bedroom, lounge = living room, garden, shed, front_garden). A level is `{ "id", "room", "tier", "seed", "level_file"?, "postcard"?, "chapter"?, "finale"? }`:
- `level_file`: a hand-made level in `data/levels/` instead of a generated one.
- `chapter`: shows that room's chapter card (from `data/story.json`) when the level starts.
- `finale`: the end of the story; Mamie's last letter opens when it's finished.
Walk levels share one morning: each room gets its own slice of the sunrise (`sunrise_range`, filled in by the game).

- `find_dog`: Chloé is hiding in this room (walk 1: the hall). The level's key is in her hiding place; giving her Gaston (found in the level) brings her out.
- `companion`: Chloé is with Juliette in this level (every room after the hall). Replays and Endless use her once she's been found.

## Chloé, Mamie's Maltese
Chloé is found in the hall in walk 1 and then follows Juliette. She sits at the room's `dog_spot` (and naps in the sunroom). The player can:
- **tap her** with nothing selected: if she needs something, her care close-up opens; otherwise she trots to what matters now and barks at it (a free hint, it doesn't cost a star).
- **tap her with an item selected**: gives it to her (a `care` item for a `care` lock, or a `scent` for a `sniff` lock).
- **ask her** in a `dog` close-up: she fetches or digs.
Everything she does is an ordinary lock in the level, so the solver, validator, hints and autoplay treat her like any other step. A paw badge marks the spots where she can help. Her sprites are in `assets/sprites/props/chloe/` (drawn by `tools/art/chloe.mjs`); her sounds are `dog_bark`, `dog_squeak`, `dog_dig`, `dog_sniff` and `dog_happy` in `tools/sfx/sfx.json`.

## `data/story.json`: the chapters of Céline's life
`chapters`: one per room in route order, `{ "room", "title", "years", "intro", "outro", "memories"?: [ { "id", "title", "text" } ] }`. The scrapbook shows one page per chapter; `memories` are the story notes collected there (see docs/STORY.md).

## `data/daily.json`
`rooms` rotation, `weekday_tiers` (Sunday first), `streak_rewards` (streak length → decor id).

## `data/decor.json`: decor for the sunroom
`items`: `{ "name", "sprite", "size": [w, h], "slot": "floor_large" | "floor_small" | "wall" | "table" | "rug", "price": seashells or null (earned only), "text", "idle"? }`.
`idle` adds a small loop in the sunroom: `"breathe"` (grows a little from the floor, like a sleeping cat) or `"sway"` (swings from its top edge, like lanterns). Players who turn on *Reduce motion* don't see it.
`slots`: where decor can stand in the sunroom (`id`, `type`, `anchor` [x, y], optional `max` [w, h]).

## `data/clues.json`: clue wording (generated levels)
How deep a riddle goes comes from `tiers.json` → `riddle` (0-4):
- **0**: says the answer (`"0"`, `"1"` phrasings). Tier 1 only.
- **1**: a light twist: in words, backwards, an hour earlier (`"2"`, `"3"`), or two halves on two notes (`first` / `last`).
- **2+**: a real riddle. Codes are built from `facts` ("the legs on a spider"), `counters` (count the shells in the jar, placed in the room), sums (`arithmetic`), or a number pattern (`pattern`). Tunes, lamps and orders get logic sentences from `statements`, with exactly one answer. Times are worked out from `offset` / `two_steps` phrasings. From depth 3, long riddles are split over two notes.
- `riddle`, `riddle_first`, `riddle_last`: the frame around the riddle parts (`{parts}`, `{statements}`, `{count}`).
- `sudoku`: the note inside a number square whose shaded squares give another lock's code.

See `_help` in the file for all placeholders. Add as many phrasings as you like; the level validator fails if a placeholder is misspelled. `decoys` are harmless notes that don't open anything.
To see what the generator makes of it, print a level: `bash tools/godot.sh --headless --path . res://tests/validate_levels.tscn -- --print=kitchen:6:123`.
