class_name Campaign
extends RefCounted
## The 30 main levels (data/campaign.json) plus Replay, Daily and Endless levels, all built by LevelGenerator.

const ROOMS: PackedStringArray = ["lounge", "kitchen", "study"]

static var _cache: Dictionary = {}


static func levels() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in Data.get_dict("campaign").get("levels", []):
		out.append(e)
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


static func room_available(room_id: String) -> bool:
	return FileAccess.file_exists("res://data/rooms/%s.json" % room_id)


## Total stars needed before a tier can be started (soft gates from campaign.json).
static func star_gate(tier: int) -> int:
	var gates: Dictionary = Data.get_dict("campaign").get("star_gates", {})
	var need := 0
	for k: String in gates.keys():
		if tier >= int(k):
			need = maxi(need, int(gates[k]))
	return need


## Builds a main level (cached).
static func build(level_id: String) -> Dictionary:
	if _cache.has(level_id):
		return _cache[level_id]
	var e := entry(level_id)
	if e.is_empty() or not room_available(str(e["room"])):
		return {}
	var options := {"id": level_id}
	if e.has("postcard"):
		options["postcard"] = str(e["postcard"])
	var level := LevelGenerator.generate(str(e["room"]), int(e["tier"]), int(e["seed"]), options)
	if not level.is_empty():
		level["title"] = level_id
		level["tutorial"] = bool(e.get("tutorial", false))
		_cache[level_id] = level
	return level


## Same room and tier as a main level, but a fresh puzzle.
static func build_replay(level_id: String, replay_seed: int) -> Dictionary:
	var e := entry(level_id)
	if e.is_empty():
		return {}
	return LevelGenerator.generate(str(e["room"]), int(e["tier"]), replay_seed, {"id": "%s_replay_%d" % [level_id, replay_seed]})


static func build_daily(day_key: String) -> Dictionary:
	var d := Daily.level_for(day_key)
	var room := str(d["room"])
	if not room_available(room):
		room = ROOMS[0]
	return LevelGenerator.generate(room, int(d["tier"]), int(d["seed"]), {"id": "daily_" + day_key})


## Endless level n (1, 2, 3, ...): tiers keep growing past 10, rooms rotate.
static func build_endless(n: int, seed_value: int) -> Dictionary:
	var rooms: Array[String] = []
	for r in ROOMS:
		if room_available(r):
			rooms.append(r)
	var room := rooms[(n - 1) % rooms.size()]
	return LevelGenerator.generate(room, 10 + n, seed_value, {"id": "endless_%d_%d" % [n, seed_value]})


static func clear_cache() -> void:
	_cache.clear()
