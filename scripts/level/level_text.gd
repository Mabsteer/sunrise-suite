class_name LevelText
extends RefCounted
## Turns level data into words for the player: names of things, where they are, answers and hints.

var session: LevelSession
var room: Dictionary
var _items_db: Dictionary
var _props_db: Dictionary
var _symbols_db: Dictionary


func _init(level_session: LevelSession, room_data: Dictionary) -> void:
	session = level_session
	room = room_data
	_items_db = Data.get_dict("items")
	_props_db = Data.get_dict("props")
	_symbols_db = Data.get_dict("symbols")


# ---------------------------------------------------------------- names

func host_name(host: Dictionary) -> String:
	match str(host.get("kind", "")):
		"door":
			return str((room.get("door", {}) as Dictionary).get("name", "the balcony door"))
		"furniture":
			var spot := furniture_spot(str(host.get("furniture", "")), str(host.get("spot", "")))
			if not spot.is_empty():
				return str(spot.get("name", "it"))
			return str(furniture(str(host.get("furniture", ""))).get("name", "it"))
		"prop":
			return str(_props_db.get(str(host.get("prop", "")), {}).get("name", "it"))
		"dog":
			return "Chloé"
	return "it"


## The sprite for a prop host: its open version, or the one showing `count` things (counter props).
static func prop_sprite(host: Dictionary, open: bool = false) -> String:
	var prop: Dictionary = Data.get_dict("props").get(str(host.get("prop", "")), {})
	if host.has("count") and prop.has("sprite_count"):
		return str(prop["sprite_count"]).replace("{n}", str(int(host["count"])))
	if open and prop.has("sprite_open"):
		return str(prop["sprite_open"])
	return str(prop.get("sprite", ""))


func lock_name(lock_id: String) -> String:
	return host_name(session.locks[lock_id].get("host", {}))


func item_name(item_id: String) -> String:
	var type := str(session.items.get(item_id, {}).get("type", item_id))
	return str(_items_db.get(type, {}).get("name", type.replace("_", " ")))


func item_type_data(item_id: String) -> Dictionary:
	var type := str(session.items.get(item_id, {}).get("type", item_id))
	return _items_db.get(type, {})


func clue_place(clue_id: String) -> String:
	var c: Dictionary = session.clues[clue_id]
	if str(c.get("item", "")) != "":
		return "the " + item_name(str(c["item"]))
	return _thing_place(c)


## Where an item or clue can be found, e.g. "on the credenza" or "inside the lockbox".
func item_place(item_id: String) -> String:
	var it: Dictionary = session.items[item_id]
	var loc := str(it.get("location", "room"))
	if loc != "room" and loc != "recipe":
		return _inside(loc)
	return "on " + slot_name(str(it.get("slot", "")))


func slot_name(slot_id: String) -> String:
	for s: Dictionary in room.get("surface_slots", []):
		if str(s.get("id", "")) == slot_id:
			return str(s.get("name", "the table"))
	return "the wall"


func furniture(id: String) -> Dictionary:
	for f: Dictionary in room.get("furniture", []):
		if str(f.get("id", "")) == id:
			return f
	return {}


func furniture_spot(furniture_id: String, spot_id: String) -> Dictionary:
	for s: Dictionary in furniture(furniture_id).get("spots", []):
		if str(s.get("id", "")) == spot_id:
			return s
	return {}


func symbol_name(symbol: String) -> String:
	return str(_symbols_db.get(symbol, {}).get("name", symbol))


## Human-readable answer, e.g. "4-7-2-9", "sun, shell, wave", "7:30".
func answer_text(lock_id: String) -> String:
	var lock: Dictionary = session.locks[lock_id]
	var answer := str(lock.get("answer", ""))
	match str(lock.get("type", "")):
		"combo":
			return "-".join(answer.split(""))
		"sequence":
			var names: PackedStringArray = []
			for s in answer.split(","):
				names.append(symbol_name(s))
			return ", ".join(names)
		"clock":
			return LevelSession.normalize_answer("clock", answer)
		"switches":
			var symbols: Array = (lock.get("config", {}) as Dictionary).get("symbols", [])
			var on: PackedStringArray = []
			for i in mini(answer.length(), symbols.size()):
				if answer[i] == "1":
					on.append(symbol_name(str(symbols[i])))
			return "only the %s lamps on" % " and ".join(on)
		"order":
			var names: PackedStringArray = []
			for s in answer.split(","):
				names.append(symbol_name(s))
			return "from left to right: " + ", ".join(names)
		"slider":
			return "the whole picture"
		"rotate":
			return "every tile turned the right way up"
		"sudoku":
			var rows: PackedStringArray = []
			for r in 4:
				rows.append(answer.substr(r * 4, 4))
			return "row by row: " + " / ".join(rows)
		"pattern":
			var kind := str((lock.get("config", {}) as Dictionary).get("kind", "numbers"))
			var parts: PackedStringArray = []
			for p in answer.split(","):
				parts.append(symbol_name(p) if kind == "symbols" else p)
			return " and ".join(parts)
	return answer


## Replaces {sun}-style tokens with inline icons for a RichTextLabel.
func rich(text: String, icon_size: int = 44) -> String:
	return UIKit.symbol_icons(text, icon_size)


## Plain version of a text with {sun}-style tokens spelled out.
func plain(text: String) -> String:
	var out := text
	for key: String in _symbols_db.keys():
		out = out.replace("{%s}" % key, symbol_name(key))
	return out


# ---------------------------------------------------------------- hints

## Text for a hint goal from LevelSession.request_hint() at its level (1..3).
func hint_text(goal: Dictionary) -> String:
	var texts := hint_texts(goal)
	return texts[clampi(int(goal.get("level", 1)), 1, 3) - 1]


func hint_texts(goal: Dictionary) -> PackedStringArray:
	match str(goal.get("action", "")):
		"pick_up":
			var id := str(goal["id"])
			var place := item_place(id)
			return [
				"Something useful is waiting %s." % place,
				"Pick up the %s %s." % [item_name(id), place],
				"Tap the %s %s to put it in your bag." % [item_name(id), place],
			]
		"combine":
			var a := str(goal["a"])
			var b := str(goal["b"])
			return [
				"Two things in your bag belong together.",
				"Try combining the %s with something else you're carrying." % item_name(a),
				"Combine the %s and the %s: drag one onto the other." % [item_name(a), item_name(b)],
			]
		"see_clue":
			var c := str(goal["id"])
			var lock := str(goal["lock"])
			return [
				"Have a closer look at %s." % clue_place(c),
				"%s holds a clue for %s." % [_cap(clue_place(c)), lock_name(lock)],
				"%s opens with %s." % [_cap(lock_name(lock)), answer_text(lock)],
			]
		"open":
			return _open_hints(str(goal["id"]))
	return [
		"Take a slow look around the room. Tap anything that catches your eye.",
		"Tap the furniture and the things on the walls. Mamie hid things everywhere.",
		"Try every drawer, frame and cushion. Something is waiting to be found.",
	]


func _open_hints(lock_id: String) -> PackedStringArray:
	var name := lock_name(lock_id)
	var t := session.lock_type(lock_id)
	var item := session.lock_item(lock_id)
	if t == "dog":
		var act := session.dog_action(lock_id)
		return [
			"Chloé could help with %s." % name,
			"Tap %s and ask Chloé to %s." % [name, act],
			"Tap %s, then \"Chloé, %s!\"" % [name, act],
		]
	if session.finds_dog(lock_id):
		var toy := item_name(session._inventory_match(item) if session._inventory_match(item) != "" else item)
		return [
			"Someone small is hiding in %s." % name,
			"Chloé won't come out for just anyone. Show her the %s." % toy,
			"Select the %s in your bag, then tap %s." % [toy, name],
		]
	if session.given_to_dog(lock_id):
		var gift := item_name(session._inventory_match(item) if session._inventory_match(item) != "" else item)
		if t == "sniff":
			return [
				"Chloé's nose can find things you can't.",
				"Let Chloé sniff the %s." % gift,
				"Select the %s, then tap Chloé. She'll lead you to %s." % [gift, name],
			]
		return [
			"Chloé keeps looking at you. She wants something.",
			"Give Chloé the %s." % gift,
			"Select the %s in your bag, then tap Chloé." % gift,
		]
	if session.needs_item(lock_id):
		var held := session._inventory_match(item)
		var what := item_name(held if held != "" else item)
		return [
			"The %s in your bag is waiting to be used." % what,
			"Try the %s on %s." % [what, name],
			"Select the %s, then tap %s." % [what, name],
		]
	if t == "hidden":
		return [
			"Mamie loved hiding things. Search around the room.",
			"Search %s." % name,
			"Tap %s and have a good look." % name,
		]
	if t == "slider":
		return [
			"%s is a sliding picture puzzle." % _cap(name),
			"Slide the tiles next to the gap until the sunrise picture is whole.",
			"Solve it one row at a time: top row first, then the left column.",
		]
	if t == "rotate":
		return [
			"%s is a picture in little tiles, some of them turned." % _cap(name),
			"Tap a tile to turn it. Turn them all until the picture looks right.",
			"Look for the horizon and the sun: every tile should line up with its neighbours.",
		]
	if t == "sudoku":
		return [
			"%s is a little number square, like Henri's in the paper." % _cap(name),
			"Every row, every column and every 2x2 box needs 1, 2, 3 and 4 exactly once.",
			"The answer, %s." % answer_text(lock_id),
		]
	if t == "pattern":
		return [
			"%s shows a pattern with gaps. What's the rule?" % _cap(name),
			"Look at how each one changes into the next, then keep going.",
			"The gaps are %s." % answer_text(lock_id),
		]
	var clue_list := session.lock_clues(lock_id)
	var where := clue_place(clue_list[0]) if not clue_list.is_empty() else "the room"
	if clue_list.size() > 1:
		where = "%s and %s" % [clue_place(clue_list[0]), clue_place(clue_list[1])]
	return [
		"You've found everything %s needs." % name,
		"Use the clue from %s on %s." % [where, name],
		"%s opens with %s." % [_cap(name), answer_text(lock_id)],
	]


func _thing_place(thing: Dictionary) -> String:
	var loc := str(thing.get("location", "room"))
	var host: Dictionary = thing.get("host", {})
	var what := host_name(host) if not host.is_empty() else "a note"
	if loc != "room":
		return "%s %s" % [what, _inside(loc)]
	return what


## "inside the drawer", or "with Chloé" for what she's guarding.
func _inside(lock_id: String) -> String:
	if session.locks.has(lock_id) and session.given_to_dog(lock_id):
		return "with Chloé"
	return "inside " + lock_name(lock_id)


static func _cap(text: String) -> String:
	return text if text.is_empty() else text[0].to_upper() + text.substr(1)
