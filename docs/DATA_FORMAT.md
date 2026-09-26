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
| `door` | `{ "name", "rect": [x, y, w, h] }`: the balcony door, the final lock of every level |
| `furniture` | Always-present furniture: `{ id, name, sprite, pos: [x,y], size: [w,h], spots: [...], flavor }` |
| `furniture[].spots` | Places on the furniture that can hold something: `{ id, name, rect: [x,y,w,h] (furniture-local), locks: [types], tools: [null or item type], clue: bool, reveal }` |
| `wall_slots` | Where wall props go: `{ id, rect: [x,y,w,h], accepts: ["wall", "wall_small"] }` |
| `surface_slots` | Where small props or items stand: `{ id, anchor: [x, y] (bottom-centre), max: [w, h], name }` |

## `data/props.json`: props levels can place
`{ name, sprite, sprite_open?, sprite_count?, size: [w,h], place: "wall"|"wall_small"|"surface", locks?: [types], tools?: [...], clue?: bool, reveal? }`
- **Counter props** (`shell_jar`, `daisy_vase`, `boat_photo`, `bird_picture`) show a number of things to count. They have `sprite_count` with `{n}` in it (`props/counters/shell_jar_{n}.svg`, n = 1-9); a level picks the number with `"count"` in the host. How riddles name them is in `data/clues.json` → `counters`.

## `data/items.json`: inventory items
`{ name, sprite (128×128), kind: "key"|"tool"|"part"|"clue", text }`

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
- **after**: this lock can only be used once all these locks are open (e.g. Chloé only helps after breakfast).
- **Keys are rewards**: an item of kind `key` must be inside a puzzle (`combo`, `sequence`, `clock`, `switches`, `order`, `sudoku`, `pattern`, `rotate`, `slider`, `tool`, `care`), never in the room or a search spot. The validator checks this for every level.
- **Clues** can be carried by an item (`"item"`). The clue is then read by looking at that item in the bag.
- Every lock and every recipe is one **step**. The sunrise progress is `solved steps / all steps`.
- **riddle** (optional, hand-made levels): how hard the notes are, for the par-time check (generated levels take it from `tiers.json`).

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
