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
`{ name, sprite, sprite_open?, size: [w,h], place: "wall"|"wall_small"|"surface", locks?: [types], tools?: [...], clue?: bool, reveal? }`

## `data/items.json`: inventory items
`{ name, sprite (128×128), kind: "key"|"tool"|"part"|"clue", text }`

## `data/recipes.json`: combinations
`{ "recipes": [ { "a": item type, "b": item type, "result": item type } ] }`

## `data/symbols.json`: symbols for sequence/switch locks
`{ name, color (palette name), sprite }`. Write `{sun}` in clue text to show the icon inline.

## `data/levels/<id>.json`: levels (hand-made, and what the generator produces)
```json
{
  "id": "test_lounge", "room": "lounge", "tier": 3, "seed": 1, "par_time": 600,
  "locks":   [ { "id", "type", "host", "location", "answer"?, "clues"?: [clue ids], "item"?: item id, "config"?: {}, "is_door"?: true } ],
  "items":   [ { "id", "type" (items.json key), "location", "slot"? } ],
  "recipes": [ { "a": item id, "b": item id, "result": item id } ],
  "clues":   [ { "id", "host", "location", "for": lock id, "text", "item"?: item id } ],
  "decoys":  [ { "id", "host", "location", "text" } ],
  "postcard": { "id", "host", "location" }
}
```
- **location**: `"room"` (visible from the start), a **lock id** (inside that lock's container, reachable once it's open), or `"recipe"` (items made by combining).
- **host**: where the thing is.
  - `{ "kind": "door" }`
  - `{ "kind": "furniture", "furniture": id, "spot": spot id }`
  - `{ "kind": "prop", "prop": props.json id, "slot": slot id }` (the slot is only needed in the room)
- **Lock types** and their `answer`:
  - `combo`: digits `"4729"`, config `{ "digits": 4 }`
  - `sequence`: symbols `"sun,shell,wave"`, config `{ "length": 3 }`
  - `clock`: `"7:30"`
  - `switches`: pattern `"1010"`, config `{ "symbols": [...] }`
  - `slider`: `"solved"`, config `{ "size": 3, "picture", "scramble" }`
  - `key`: needs `item`
  - `hidden`: needs `item` (a tool) or nothing (just search)
- **Clues** can be carried by an item (`"item"`). The clue is then read by looking at that item in the bag.
- Every lock and every recipe is one **step**. The sunrise progress is `solved steps / all steps`.

## `data/daily.json`
`rooms` rotation, `weekday_tiers` (Sunday first), `streak_rewards` (streak length → decor id).

## `data/decor.json`: penthouse decor
`items`: `{ "name", "sprite", "size": [w, h], "slot": "floor_large" | "floor_small" | "wall" | "table" | "rug", "price": seashells or null (earned only), "text", "idle"? }`.
`idle` adds a small loop in the penthouse: `"breathe"` (grows a little from the floor, like a sleeping cat) or `"sway"` (swings from its top edge, like lanterns). Players who turn on *Reduce motion* don't see it.
`slots`: where decor can stand in the penthouse (`id`, `type`, `anchor` [x, y], optional `max` [w, h]).

## `data/clues.json`: clue wording
Per lock type, lists of phrasings by how indirect they are (`"0"` names the lock and gives the answer, `"3"` makes you think), plus `first`/`last` halves for split clues. See `_help` in the file for all placeholders. Add as many phrasings as you like; the level validator fails if a placeholder is misspelled. `decoys` are harmless notes that don't open anything.
