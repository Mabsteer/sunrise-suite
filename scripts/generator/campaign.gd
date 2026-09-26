class_name Campaign
extends RefCounted
## The walks through Céline's house (data/campaign.json) plus Replay, Daily and Endless levels,
## all built by LevelGenerator (or loaded from hand-made level files).

## The route through Céline's house, in story order (each room's exit leads to the next).
const ROUTE: PackedStringArray = ["kitchen", "hall", "bedroom", "lounge", "garden", "shed", "front_garden"]

## Where the morning starts in the first room of a walk (0 = night, 1 = the sun is up).
const DAWN_START := 0.15

static var _cache: Dictionary = {}


## The walks, each with its "levels" (and "id", "title", "subtitle", "star_gate", "story").
static func walks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for w: Dictionary in Data.get_dict("campaign").get("walks", []):
		out.append(w)
	return out


## Every main level in play order, walk after walk. Each entry also gets "walk" (1, 2, 3...) and
## "step" (0-6: its place on the route).
static func levels() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for w in walks():
		var step := 0
		for e: Dictionary in w.get("levels", []):
			var copy := e.duplicate()
			copy["walk"] = int(w.get("id", 1))
			copy["step"] = step
			out.append(copy)
			step += 1
	return out


static func entry(level_id: String) -> Dictionary:
	for e in levels():
		if str(e["id"]) == level_id:
			return e
	return {}


static func index_of(level_id: String) -> int:
	var list := levels()
	for i in list.size():
		if str(list[i]["id"]) == level_id:
			return i
	return -1


static func walk(walk_id: int) -> Dictionary:
	for w in walks():
		if int(w.get("id", 0)) == walk_id:
			return w
	return {}


static func room_available(room_id: String) -> bool:
	return FileAccess.file_exists("res://data/rooms/%s.json" % room_id)


## The rooms of the route that exist.
static func rooms() -> Array[String]:
	var out: Array[String] = []
	for r in ROUTE:
		if room_available(r):
			out.append(r)
	return out


## Total stars needed before a level can be started (the soft gate of its walk).
static func star_gate_for(level_id: String) -> int:
	return int(walk(int(entry(level_id).get("walk", 1))).get("star_gate", 0))


## "The bedroom · Mamie's last treasure hunt": how the UI names a main level.
static func level_label(level_id: String) -> String:
	var e := entry(level_id)
	if e.is_empty():
		return level_id
	var room_name := TranslationServer.translate(str(Data.get_dict("rooms/" + str(e["room"])).get("name", e["room"])))
	return "%s · %s" % [room_name, TranslationServer.translate(str(walk(int(e["walk"])).get("title", "")))]


static func room_name(level_id: String) -> String:
	var e := entry(level_id)
	return TranslationServer.translate(str(Data.get_dict("rooms/" + str(e.get("room", ""))).get("name", e.get("room", ""))))


## The story chapter for a room (data/story.json), or {}.
static func chapter(room_id: String) -> Dictionary:
	for c: Dictionary in Data.get_dict("story").get("chapters", []):
		if str(c.get("room", "")) == room_id:
			return c
	return {}


## Builds a main level (cached).
static func build(level_id: String) -> Dictionary:
	if _cache.has(level_id):
		return _cache[level_id]
	var e := entry(level_id)
	if e.is_empty() or not room_available(str(e["room"])):
		return {}
	var level: Dictionary
	if e.has("level_file"):
		level = Data.get_dict("levels/" + str(e["level_file"])).duplicate(true)
		if level.is_empty():
			return {}
		level["id"] = level_id
		if bool(e.get("companion", false)):
			level["companion"] = "chloe"
	else:
		var options := {"id": level_id, "companion": bool(e.get("companion", false)), "find_dog": bool(e.get("find_dog", false))}
		if e.has("postcard"):
			options["postcard"] = str(e["postcard"])
		level = LevelGenerator.generate(str(e["room"]), int(e["tier"]), int(e["seed"]), options)
		if level.is_empty():
			return {}
	level["title"] = level_id
	level["walk"] = int(e.get("walk", 1))
	level["step"] = int(e.get("step", 0))
	if e.has("chapter"):
		level["chapter"] = str(e["chapter"])
	if bool(e.get("finale", false)):
		level["finale"] = true
	# The sunrise spans the whole walk: each room brightens its own slice of the morning (the first
	# room starts just before dawn, not in pitch dark, so the kitchen is easy to see).
	var n := float(ROUTE.size())
	var k := float(e.get("step", 0))
	level["sunrise_range"] = [DAWN_START + (1.0 - DAWN_START) * k / n, DAWN_START + (1.0 - DAWN_START) * (k + 1.0) / n]
	_cache[level_id] = level
	return level


## Same room and tier as a main level, but a fresh puzzle.
static func build_replay(level_id: String, replay_seed: int) -> Dictionary:
	var e := entry(level_id)
	if e.is_empty():
		return {}
	return LevelGenerator.generate(str(e["room"]), int(e["tier"]), replay_seed, {"id": "%s_replay_%d" % [level_id, replay_seed],
		"companion": bool(e.get("companion", false)) or GameState.chloe_found(), "find_dog": bool(e.get("find_dog", false)) and not GameState.chloe_found()})


static func build_daily(day_key: String) -> Dictionary:
	var d := Daily.level_for(day_key)
	var room := str(d["room"])
	if not room_available(room):
		room = rooms()[0]
	return LevelGenerator.generate(room, int(d["tier"]), int(d["seed"]), {"id": "daily_" + day_key})


## Endless level n (1, 2, 3, ...): the hunt keeps going round the house, harder every room.
static func build_endless(n: int, seed_value: int) -> Dictionary:
	var list := rooms()
	var room := list[(n - 1) % list.size()]
	return LevelGenerator.generate(room, 10 + n, seed_value, {"id": "endless_%d_%d" % [n, seed_value], "companion": true})


static func clear_cache() -> void:
	_cache.clear()
