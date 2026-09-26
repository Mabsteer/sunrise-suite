class_name LevelGenerator
extends RefCounted
## Builds an escape-room level from (room, tier, seed). Deterministic: same inputs give the same level.
##
## It works backwards from the balcony door. Every requirement (a key, a tool, a clue...) is either
## placed somewhere in the room, or hidden inside a new container (a lock), or made from two parts
## (a recipe). New containers have their own requirements, which are handled the same way until the
## step budget from tiers.json is used up. Afterwards the level is checked by LevelValidator; if it
## fails, the generator retries with a derived seed.
##
## Difficulty comes from thinking, not searching (see docs/DECISIONS.md, v2): riddles get deeper
## (RiddleMaker), puzzles feed each other (a number square that gives a code), and puzzle types get
## bigger. Keys are always the reward of a solved puzzle, and there is at most one search spot.

const DOOR_TYPES: PackedStringArray = ["combo", "sequence", "clock", "key"]
const CONTAINER_TYPES: PackedStringArray = ["combo", "sequence", "clock", "switches", "key", "hidden", "slider", "order", "sudoku", "pattern", "rotate", "dog", "sniff", "care"]
## Chloé's lock types; only in levels where she's with Juliette (options.companion).
const DOG_TYPES: PackedStringArray = ["dog", "sniff", "care"]
## A key is only ever found inside one of these (a puzzle you solved), never lying around.
const REWARD_CONTAINERS: PackedStringArray = ["combo", "sequence", "clock", "switches", "order", "sudoku", "pattern", "rotate", "slider", "tool", "care"]
## Puzzles that need nothing from elsewhere: they're solved on the spot (or Chloé just does it).
const FREE_TYPES: PackedStringArray = ["slider", "sudoku", "pattern", "rotate", "dog"]
const SUDOKU_PROPS: PackedStringArray = ["newspaper", "number_box"]
const ROTATE_PICTURES: PackedStringArray = ["puzzles/slider_sunrise.svg", "puzzles/picture_lemon_tree.svg", "puzzles/picture_market.svg"]
const KEY_TYPES: PackedStringArray = ["brass_key", "tiny_key", "shell_key", "old_key"]
const SYMBOLS: PackedStringArray = ["sun", "shell", "wave", "star", "leaf", "heart"]
const CLUE_PROPS_SURFACE: PackedStringArray = ["note", "open_book", "photo_stand"]
const CLUE_PROPS_WALL: PackedStringArray = ["photo_frame", "corkboard", "painting", "calendar"]
const REPEATABLE_PROPS: PackedStringArray = ["note"]
const MAX_ATTEMPTS := 30
const MAX_CONTENTS := 3

var cfg: Dictionary
var room: Dictionary
var rng := RandomNumberGenerator.new()
var props_db: Dictionary
var items_db: Dictionary
var recipes_db: Array
var clue_db: Dictionary

var locks: Array[Dictionary] = []
var items: Array[Dictionary] = []
var clues: Array[Dictionary] = []
var recipes: Array[Dictionary] = []
var decoys: Array[Dictionary] = []
var used_spots: Dictionary = {}
var used_slots: Dictionary = {}
var used_props: Dictionary = {}
var used_item_types: Dictionary = {}
var contents: Dictionary = {}
var steps := 0
var _next_id := 0
var _failed := false


# ================================================================== public API

## Generates a validated level. Returns {} (and logs an error) if no valid level could be made.
static func generate(room_id: String, tier: int, seed_value: int, options: Dictionary = {}) -> Dictionary:
	var tier_cfg := tier_config(tier)
	var last_error := ""
	for attempt in MAX_ATTEMPTS:
		var g := LevelGenerator.new()
		var level := g.build(room_id, tier_cfg, _mix(seed_value, attempt), options)
		if level.is_empty():
			last_error = "build failed"
			continue
		var report := LevelValidator.validate(level, tier_cfg)
		if bool(report["ok"]):
			level["seed"] = seed_value
			level["attempt"] = attempt
			return level
		last_error = str(report["errors"])
	push_error("LevelGenerator: no valid level for %s tier %d seed %d (%s)" % [room_id, tier, seed_value, last_error])
	return {}


## Settings for a tier (1..10 from tiers.json; 11+ are Endless tiers grown from tier 10).
static func tier_config(tier: int) -> Dictionary:
	var data := Data.get_dict("tiers")
	var tiers: Array = data.get("tiers", [])
	if tiers.is_empty():
		return {"tier": tier, "steps": [3, 3], "types": ["combo", "key", "order"], "par_time": 300}
	var last: Dictionary = tiers[tiers.size() - 1]
	if tier <= tiers.size():
		return (tiers[maxi(tier, 1) - 1] as Dictionary).duplicate(true)
	var endless: Dictionary = data.get("endless", {})
	var c := last.duplicate(true)
	var extra := tier - tiers.size()
	var grow := int(extra / maxi(int(endless.get("steps_every", 3)), 1))
	var max_steps := int(endless.get("max_steps", 14))
	var s: Array = last.get("steps", [11, 12])
	c["tier"] = tier
	c["steps"] = [mini(int(s[0]) + grow, max_steps - 1), mini(int(s[1]) + grow, max_steps)]
	c["herrings"] = mini(int(last.get("herrings", 4)) + grow, int(endless.get("max_herrings", 5)))
	c["par_time"] = int(last.get("par_time", 900)) + extra * int(endless.get("par_time_per_tier", 60))
	return c


## One attempt. Returns {} if it painted itself into a corner.
func build(room_id: String, tier_cfg: Dictionary, seed_value: int, options: Dictionary = {}) -> Dictionary:
	cfg = tier_cfg
	room = Data.get_dict("rooms/" + room_id)
	props_db = Data.get_dict("props")
	items_db = Data.get_dict("items")
	recipes_db = Data.get_dict("recipes").get("recipes", [])
	clue_db = Data.get_dict("clues")
	rng.seed = seed_value
	if room.is_empty():
		return {}
	var companion := bool(options.get("companion", false))
	if companion:
		# Chloé is here: her locks join the tier's lock types.
		cfg = cfg.duplicate(true)
		var types: Array = cfg.get("types", [])
		types.append_array(Array(DOG_TYPES))
		cfg["types"] = types
	var step_range: Array = cfg.get("steps", [3, 3])
	var target := rng.randi_range(int(step_range[0]), int(step_range[1]))

	if bool(options.get("find_dog", false)):
		# Chloé is hiding: the door's key is in the pocket of the cardigan she's sleeping on.
		if not _build_find_dog(target):
			return {}
	else:
		var door_types := _allowed(DOOR_TYPES)
		var door := _new_lock(_pick(door_types), {"kind": "door"}, "room")
		door["is_door"] = true
		steps = 1
		_provide_requirements(door, target - 1)
	if _failed:
		return {}
	_add_decoys(int(cfg.get("herrings", 0)))
	if options.has("postcard"):
		_add_postcard(str(options["postcard"]))
	if _failed:
		return {}
	return {
		"id": str(options.get("id", "%s_t%d_%d" % [room_id, int(cfg.get("tier", 1)), seed_value])),
		"room": room_id,
		"tier": int(cfg.get("tier", 1)),
		"seed": seed_value,
		"par_time": int(cfg.get("par_time", 600)),
		"locks": locks,
		"items": items,
		"recipes": recipes,
		"clues": clues,
		"decoys": decoys,
		"postcard": _postcard,
		"companion": "chloe" if companion else "",
	}


## Finding Chloé: a key door, the key in a care lock where she hides (a spot that takes "care"),
## opened with Gaston, her squeaky seagull; Gaston itself comes from the rest of the level.
func _build_find_dog(target: int) -> bool:
	var spot_host := {}
	for f: Dictionary in room.get("furniture", []):
		for spot: Dictionary in f.get("spots", []):
			if spot_host.is_empty() and (spot.get("locks", []) as Array).has("care"):
				spot_host = {"kind": "furniture", "furniture": f["id"], "spot": spot["id"]}
				used_spots["%s:%s" % [f["id"], spot["id"]]] = true
	if spot_host.is_empty():
		return false
	var door := _new_lock("key", {"kind": "door"}, "room")
	door["is_door"] = true
	var key := _new_item(_unused_item_type(KEY_TYPES))
	door["item"] = key["data"]["id"]
	var hiding := _new_lock("care", spot_host, "room")
	hiding["finds_dog"] = true
	_put_inside(key, str(hiding["id"]))
	var toy := _new_item("gaston")
	hiding["item"] = toy["data"]["id"]
	steps = 2
	_provide_thing(toy, maxi(target - 2, 0))
	return true


# ================================================================== the recursive core

var _postcard: Dictionary = {}


## Creates and places whatever `lock` needs. Returns steps used.
func _provide_requirements(lock: Dictionary, budget: int) -> int:
	var reqs := _requirements(lock, budget)
	if reqs.is_empty():
		return 0
	var shares := _split(budget, reqs.size())
	var used := 0
	for i in reqs.size():
		used += _provide_thing(reqs[i], shares[i])
	return used


## Places one thing (item / clue / portable lock) using up to `budget` steps. Returns steps used.
func _provide_thing(thing: Dictionary, budget: int) -> int:
	if _failed:
		return 0
	if bool(thing.get("chain", false)):
		# A puzzle made while writing a clue (e.g. the number square that gives a code) is a step itself.
		thing.erase("chain")
		return 1 + _provide_thing(thing, budget - 1)
	var reward := _is_reward(thing)
	if reward:
		budget = maxi(budget, 1) # keys are never just lying around
	elif budget <= 0:
		if _place_in_room(thing):
			return 0
		budget = 1 # no room left: hide it in a container anyway
	# A recipe can make items (the parts become two branches).
	if str(thing["kind"]) == "item" and not reward and bool(cfg.get("combine", false)):
		var recipe := _recipe_for(str(thing["data"]["type"]))
		if not recipe.is_empty() and rng.randf() < 0.45:
			return _make_by_recipe(thing, recipe, budget)
	return _hide_in_container(thing, budget, reward)


func _make_by_recipe(thing: Dictionary, recipe: Dictionary, budget: int) -> int:
	var result: Dictionary = thing["data"]
	result["location"] = "recipe"
	result.erase("slot")
	var part_a := _new_item(str(recipe["a"]))
	var part_b := _new_item(str(recipe["b"]))
	recipes.append({"a": part_a["data"]["id"], "b": part_b["data"]["id"], "result": result["id"]})
	steps += 1
	var shares := _split(budget - 1, 2)
	return 1 + _provide_thing(part_a, shares[0]) + _provide_thing(part_b, shares[1])


func _hide_in_container(thing: Dictionary, budget: int, reward: bool = false) -> int:
	var after := budget - 1
	var choice := _choose_container(after, thing, reward)
	if choice.is_empty():
		# Nothing can hold it: try the room (never for a key), else give up this attempt.
		if not reward and _place_in_room(thing):
			return 0
		_failed = true
		return 0
	var container := _new_lock(str(choice["type"]), choice["host"], "room")
	_put_inside(thing, str(container["id"]))
	steps += 1
	var used := 1
	var needs_nothing := _requirement_free(container)
	if bool(choice.get("portable", false)):
		# Portable boxes may sit inside yet another container.
		var nest := 0
		if after > 0 and (needs_nothing or rng.randf() < float(cfg.get("nesting", 0.0))):
			nest = after if needs_nothing else rng.randi_range(1, after)
		var nest_used := _provide_thing({"kind": "lock", "data": container}, nest)
		used += nest_used
		after -= nest_used
	used += _provide_requirements(container, maxi(after, 0))
	return used


# ================================================================== requirements of a lock

## Things a lock needs: [{ "kind": "item"|"clue"|"lock", "data": Dictionary }]. Creates their records.
## `budget` = steps still available for this lock's needs (a chained puzzle costs one).
func _requirements(lock: Dictionary, budget: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var t := str(lock["type"])
	match t:
		"key":
			var key_type := _unused_item_type(KEY_TYPES)
			if key_type == "":
				_failed = true
				return out
			var key := _new_item(key_type)
			lock["item"] = key["data"]["id"]
			out.append(key)
		"sniff", "care":
			# Something for Chloé: a scent to follow, or her breakfast, water, leash, brush or Gaston.
			var kind := "scent" if t == "sniff" else "care"
			var pool: PackedStringArray = []
			for id: String in items_db.keys():
				if items_db[id] is Dictionary and str((items_db[id] as Dictionary).get("kind", "")) == kind and id != "gaston":
					pool.append(id)
			pool.sort()
			var it_type := _unused_item_type(pool)
			if it_type == "":
				_failed = true
				return out
			var gift := _new_item(it_type)
			lock["item"] = gift["data"]["id"]
			out.append(gift)
		"hidden", "tool":
			var tool := str(lock.get("tool", ""))
			if tool != "":
				var it := _new_item(tool)
				lock["item"] = it["data"]["id"]
				out.append(it)
		"combo", "sequence", "clock", "switches", "order":
			if t == "combo" and budget >= 1 and _allowed(["sudoku"]).has("sudoku") and str(lock["answer"]).length() <= 4 \
					and rng.randf() < float(cfg.get("chain", 0.0)):
				var chained := _sudoku_chain(lock)
				if not chained.is_empty():
					out.append(chained)
					return out
			out.append_array(_make_clues(lock))
	return out


func _requirement_free(lock: Dictionary) -> bool:
	var t := str(lock["type"])
	return FREE_TYPES.has(t) or (t == "hidden" and str(lock.get("tool", "")) == "")


func _is_reward(thing: Dictionary) -> bool:
	return str(thing["kind"]) == "item" and str(items_db.get(str(thing["data"]["type"]), {}).get("kind", "")) == "key"


## Can a furniture spot hold a lock of type t? Sniffing works wherever something can be hidden.
static func _spot_takes(list: Array, t: String) -> bool:
	if t == "sniff":
		return list.has("hidden") or list.has("sniff")
	return list.has(t)


func _count_type(type: String) -> int:
	var n := 0
	for l in locks:
		if str(l["type"]) == type:
			n += 1
	return n


## Puzzles that build on each other: a 4x4 number square whose shaded squares give `lock`'s code.
## Returns the square as a thing to place (it holds the note that says how to read it).
func _sudoku_chain(lock: Dictionary) -> Dictionary:
	var prop := ""
	for p in SUDOKU_PROPS:
		if props_db.has(p) and not used_props.has(p):
			prop = p
			break
	if prop == "":
		return {}
	var n := str(lock["answer"]).length()
	var sq := _new_lock("sudoku", {"kind": "prop", "prop": prop}, "room")
	var givens := str((sq["config"] as Dictionary)["givens"])
	var blank_cells: Array = []
	for i in 16:
		if givens[i] == ".":
			blank_cells.append(i)
	if blank_cells.size() < n:
		locks.erase(sq)
		return {}
	used_props[prop] = true
	_shuffle(blank_cells)
	var shaded := blank_cells.slice(0, n)
	shaded.sort()
	var code := ""
	for c: int in shaded:
		code += str(sq["answer"])[c]
	lock["answer"] = code
	(sq["config"] as Dictionary)["shaded"] = shaded
	steps += 1
	var templates: Array = (clue_db.get("combo", {}) as Dictionary).get("sudoku", ["{lock}: the shaded squares."])
	var note := _new_clue(lock, _fill(str(templates[rng.randi_range(0, templates.size() - 1)]), lock, ""))
	note["data"]["location"] = sq["id"]
	note["data"]["host"] = {"kind": "prop", "prop": "note"}
	note["data"]["source"] = sq["id"]
	contents[sq["id"]] = int(contents.get(sq["id"], 0)) + 1
	return {"kind": "lock", "data": sq, "chain": true}


## Puts a prop showing `count` things (shells in a jar, boats in a photo...) in the room, as a clue
## for `lock`. Returns how a riddle names it ("the shells in the jar"), or "" if nothing fits.
func place_counter(lock: Dictionary, count: int) -> String:
	var counters: Dictionary = clue_db.get("counters", {})
	var options: Array = []
	for id: String in counters.keys():
		if not id.begins_with("_") and props_db.has(id) and not used_props.has(id):
			options.append(id)
	options.sort()
	_shuffle(options)
	for id: String in options:
		var place := str((props_db[id] as Dictionary).get("place", "surface"))
		var slot := _free_surface_slot() if place == "surface" else _free_wall_slot(place)
		if slot == "":
			continue
		used_slots[slot] = true
		used_props[id] = true
		var info: Dictionary = counters[id]
		var c := _new_clue(lock, str(info.get("text", "")))
		c["data"]["host"] = {"kind": "prop", "prop": id, "slot": slot, "count": count}
		return str(info.get("phrase", id))
	return ""


# ================================================================== containers and hosts

## Picks a lock type + host that can hold `thing`. `after` = budget left for the container's needs.
## `reward`: the thing is a key, so only a real puzzle may hold it.
func _choose_container(after: int, thing: Dictionary, reward: bool = false) -> Dictionary:
	var allowed: Array = cfg.get("types", [])
	var options: Array[Dictionary] = []
	var thing_is_wall_prop := false
	if str(thing["kind"]) == "lock":
		var host: Dictionary = thing["data"].get("host", {})
		thing_is_wall_prop = str(props_db.get(str(host.get("prop", "")), {}).get("place", "")) != "surface"
	if thing_is_wall_prop:
		return {}
	# Searching is not a difficulty knob: at most `max_hidden` search spots per level, at every tier.
	var search_ok := allowed.has("hidden") and not reward and _count_type("hidden") < int(cfg.get("max_hidden", 1))
	var tool_ok := allowed.has("tool") and bool(cfg.get("tools", false))
	for t in CONTAINER_TYPES:
		if t == "hidden":
			if not search_ok and not tool_ok:
				continue
		elif not allowed.has(t):
			continue
		if t == "key" and after <= 0:
			continue # its key needs a step of its own
		if t == "sniff" and _count_type("sniff") > 0:
			continue # one sniffing trick per room is plenty
		if t == "care":
			# Chloé herself holds it (she drops it once she's happy); at most one per level.
			if _count_type("care") == 0:
				options.append({"type": "care", "tool": "", "weight": 2.5, "host": {"kind": "dog"}})
			continue
		# Furniture spots
		for f: Dictionary in room.get("furniture", []):
			for spot: Dictionary in f.get("spots", []):
				var key := "%s:%s" % [f["id"], spot["id"]]
				if used_spots.has(key) or used_spots.has(key + ":clue") or not _spot_takes(spot.get("locks", []), t):
					continue
				var tool := _tool_for(spot.get("tools", [null]), t, search_ok, tool_ok)
				if tool == "!":
					continue
				var real := "tool" if tool != "" else t
				if reward and not REWARD_CONTAINERS.has(real):
					continue
				var host := {"kind": "furniture", "furniture": f["id"], "spot": spot["id"]}
				if t == "dog":
					host["_dog_action"] = str(spot.get("dog_action", "fetch"))
				options.append({"type": real, "tool": tool, "weight": 1.2 if t == "sniff" else 3.0, "host": host, "spot_key": key})
		# Props
		for prop_id: String in props_db.keys():
			if prop_id.begins_with("_") or used_props.has(prop_id):
				continue
			var prop: Dictionary = props_db[prop_id]
			if t in DOG_TYPES or not (prop.get("locks", []) as Array).has(t):
				continue
			var tool := _tool_for(prop.get("tools", [null]), t, search_ok, tool_ok)
			if tool == "!":
				continue
			var real := "tool" if tool != "" else t
			if reward and not REWARD_CONTAINERS.has(real):
				continue
			var place := str(prop.get("place", "surface"))
			if place == "surface":
				options.append({"type": real, "tool": tool, "weight": 2.0, "portable": true,
					"host": {"kind": "prop", "prop": prop_id}, "prop": prop_id})
			else:
				var slot := _free_wall_slot(place)
				if slot != "":
					options.append({"type": real, "tool": tool, "weight": 2.5,
						"host": {"kind": "prop", "prop": prop_id, "slot": slot}, "prop": prop_id, "slot": slot})
	# Budget rules: with steps still to spend, the container must need something (or be portable so it can nest).
	var filtered: Array[Dictionary] = []
	for o in options:
		var free := FREE_TYPES.has(str(o["type"])) or (str(o["type"]) == "hidden" and str(o["tool"]) == "")
		if after > 0 and free and not bool(o.get("portable", false)):
			continue
		filtered.append(o)
	if filtered.is_empty():
		return {}
	# Prefer types we haven't used much (variety).
	for o in filtered:
		var count := 0
		for l in locks:
			if str(l["type"]) == str(o["type"]):
				count += 1
		o["weight"] = float(o["weight"]) / (1.0 + count * 1.5)
	var pick := _weighted(filtered)
	if pick.has("spot_key"):
		used_spots[pick["spot_key"]] = true
	if pick.has("prop") and not REPEATABLE_PROPS.has(str(pick["prop"])):
		used_props[pick["prop"]] = true
	if pick.has("slot"):
		used_slots[pick["slot"]] = true
	var host: Dictionary = pick["host"]
	pick["host"] = host.duplicate()
	if str(pick["tool"]) != "":
		pick["host"]["_tool"] = pick["tool"]
	return pick


## For hidden spots: which tool to require (then it becomes a visible "tool" lock). "" = none (a search
## spot), "!" = this host can't be used now.
func _tool_for(tools: Variant, t: String, search_ok: bool, tool_ok: bool) -> String:
	if t != "hidden":
		return ""
	var list: Array = tools if tools is Array else [null]
	var options: Array[String] = []
	var has_none := false
	for tool: Variant in list:
		if tool == null:
			has_none = search_ok
		elif tool_ok and not used_item_types.has(str(tool)) and _item_obtainable(str(tool)):
			options.append(str(tool))
	if not options.is_empty() and (not has_none or rng.randf() < 0.6):
		return options[rng.randi_range(0, options.size() - 1)]
	return "" if has_none else "!"


## Tools that are recipe results (flashlight, fishing_magnet) are fine as loose items too.
func _item_obtainable(item_type: String) -> bool:
	return items_db.has(item_type)


func _free_wall_slot(place: String) -> String:
	var free: Array[String] = []
	for s: Dictionary in room.get("wall_slots", []):
		var id := str(s["id"])
		if not used_slots.has(id) and (s.get("accepts", []) as Array).has(place):
			free.append(id)
	return "" if free.is_empty() else free[rng.randi_range(0, free.size() - 1)]


func _free_surface_slot() -> String:
	var free: Array[String] = []
	for s: Dictionary in room.get("surface_slots", []):
		var id := str(s["id"])
		if not used_slots.has(id):
			free.append(id)
	return "" if free.is_empty() else free[rng.randi_range(0, free.size() - 1)]



# ================================================================== placing things

func _place_in_room(thing: Dictionary) -> bool:
	var data: Dictionary = thing["data"]
	match str(thing["kind"]):
		"item":
			var slot := _free_surface_slot()
			if slot == "":
				return false
			used_slots[slot] = true
			data["location"] = "room"
			data["slot"] = slot
			return true
		"lock":
			var slot := _free_surface_slot()
			if slot == "":
				return false
			used_slots[slot] = true
			data["location"] = "room"
			data["host"]["slot"] = slot
			return true
		"clue":
			var host := _clue_host_in_room()
			if host.is_empty():
				return false
			data["location"] = "room"
			data["host"] = host
			return true
	return false


func _put_inside(thing: Dictionary, container_id: String) -> void:
	var data: Dictionary = thing["data"]
	data["location"] = container_id
	data.erase("slot")
	if str(thing["kind"]) == "lock":
		(data["host"] as Dictionary).erase("slot")
	if str(thing["kind"]) == "clue":
		data["host"] = {"kind": "prop", "prop": CLUE_PROPS_SURFACE[rng.randi_range(0, CLUE_PROPS_SURFACE.size() - 1)]}
	contents[container_id] = int(contents.get(container_id, 0)) + 1


## A carrier for a clue that sits in the room: a furniture clue spot, a wall prop, or a surface prop.
func _clue_host_in_room() -> Dictionary:
	var options: Array[Dictionary] = []
	for f: Dictionary in room.get("furniture", []):
		for spot: Dictionary in f.get("spots", []):
			var key := "%s:%s:clue" % [f["id"], spot["id"]]
			var lock_key := "%s:%s" % [f["id"], spot["id"]]
			if bool(spot.get("clue", false)) and not used_spots.has(key) and not used_spots.has(lock_key):
				# Same at every tier: where a clue sits is not what makes a level hard.
				options.append({"w": 1.0, "host": {"kind": "furniture", "furniture": f["id"], "spot": spot["id"]}, "used": key})
	for prop_id in CLUE_PROPS_WALL:
		if used_props.has(prop_id) or not props_db.has(prop_id):
			continue
		var slot := _free_wall_slot(str(props_db[prop_id].get("place", "wall")))
		if slot != "":
			options.append({"w": 2.0, "host": {"kind": "prop", "prop": prop_id, "slot": slot}, "prop": prop_id, "slot": slot})
	var surface := _free_surface_slot()
	if surface != "":
		for prop_id in CLUE_PROPS_SURFACE:
			if used_props.has(prop_id):
				continue
			options.append({"w": 3.0 if prop_id == "note" else 1.5, "host": {"kind": "prop", "prop": prop_id, "slot": surface}, "prop": prop_id, "slot": surface})
	if options.is_empty():
		return {}
	var total := 0.0
	for o in options:
		total += float(o["w"])
	var r := rng.randf() * total
	var pick: Dictionary = options[options.size() - 1]
	for o in options:
		r -= float(o["w"])
		if r <= 0.0:
			pick = o
			break
	if pick.has("used"):
		used_spots[pick["used"]] = true
	if pick.has("slot"):
		used_slots[pick["slot"]] = true
	if pick.has("prop") and not REPEATABLE_PROPS.has(str(pick["prop"])):
		used_props[pick["prop"]] = true
	return pick["host"]


# ================================================================== creating records

func _new_lock(type: String, host: Dictionary, location: String) -> Dictionary:
	_next_id += 1
	var h := host.duplicate()
	var tool := str(h.get("_tool", ""))
	h.erase("_tool")
	var dog_action := str(h.get("_dog_action", ""))
	h.erase("_dog_action")
	var lock := {"id": "l%d" % _next_id, "type": type, "host": h, "location": location}
	if tool != "":
		lock["tool"] = tool
	if type == "dog":
		lock["action"] = dog_action if dog_action != "" else "fetch"
	match type:
		"combo":
			var n := int(cfg.get("digits", 3))
			var code := ""
			while code == "" or _all_same(code):
				code = ""
				for i in n:
					code += str(rng.randi_range(0, 9))
			lock["answer"] = code
			lock["config"] = {"digits": n}
		"sequence":
			var n := clampi(int(cfg.get("sequence_length", 3)), 2, SYMBOLS.size())
			var pool := _symbol_pool()
			_shuffle(pool)
			var seq := pool.slice(0, n)
			lock["answer"] = ",".join(PackedStringArray(seq))
			lock["config"] = {"length": n}
		"clock":
			var tier := int(cfg.get("tier", 1))
			var step := 30 if tier <= 3 else (15 if tier <= 6 else 5)
			var h_ := rng.randi_range(1, 12)
			var m := rng.randi_range(0, 60 / step - 1) * step
			lock["answer"] = "%d:%02d" % [h_, m]
		"switches":
			var n := clampi(int(cfg.get("switch_count", 4)), 3, SYMBOLS.size())
			var pool := _symbol_pool()
			_shuffle(pool)
			var symbols := pool.slice(0, n)
			var pattern := ""
			while pattern == "" or not pattern.contains("1") or not pattern.contains("0"):
				pattern = ""
				for i in n:
					pattern += "1" if rng.randf() < 0.45 else "0"
			lock["answer"] = pattern
			lock["config"] = {"symbols": symbols}
		"slider":
			lock["answer"] = "solved"
			lock["config"] = {"size": int(cfg.get("slider_size", 3)), "picture": "puzzles/slider_sunrise.svg", "scramble": int(cfg.get("slider_scramble", 20))}
		"order":
			var n := clampi(int(cfg.get("order_length", 3)), 3, 5)
			var pool := _symbol_pool()
			_shuffle(pool)
			lock["answer"] = ",".join(PackedStringArray(pool.slice(0, n)))
			lock["config"] = {"length": n}
		"sudoku":
			var sq := PuzzleMath.sudoku_generate(rng, int(cfg.get("sudoku_blanks", 7)))
			lock["answer"] = str(sq["solution"])
			lock["config"] = {"givens": str(sq["givens"])}
		"pattern":
			var kind := "symbols" if rng.randf() < 0.4 else "numbers"
			var p := PuzzleMath.pattern_generate(rng, int(cfg.get("riddle", 0)), kind, _symbol_pool())
			lock["answer"] = str(p["answer"])
			lock["config"] = {"kind": kind, "terms": p["terms"], "blanks": p["blanks"]}
		"rotate":
			lock["answer"] = "solved"
			lock["config"] = {"size": clampi(int(cfg.get("rotate_size", 2)), 2, 4), "picture": ROTATE_PICTURES[rng.randi_range(0, ROTATE_PICTURES.size() - 1)]}
	locks.append(lock)
	return lock


func _new_item(type: String) -> Dictionary:
	_next_id += 1
	used_item_types[type] = true
	var it := {"id": "i%d" % _next_id, "type": type, "location": "room"}
	items.append(it)
	return {"kind": "item", "data": it}


func _new_clue(lock: Dictionary, text: String) -> Dictionary:
	_next_id += 1
	var c := {"id": "c%d" % _next_id, "for": lock["id"], "text": text, "location": "room", "host": {}}
	clues.append(c)
	var list: Array = lock.get("clues", [])
	list.append(c["id"])
	lock["clues"] = list
	return {"kind": "clue", "data": c}


func _recipe_for(item_type: String) -> Dictionary:
	for r: Dictionary in recipes_db:
		if str(r["result"]) == item_type and not used_item_types.has(str(r["a"])) and not used_item_types.has(str(r["b"])):
			return r
	return {}


func _unused_item_type(pool: PackedStringArray) -> String:
	var free: Array[String] = []
	for t in pool:
		if not used_item_types.has(t):
			free.append(t)
	return "" if free.is_empty() else free[rng.randi_range(0, free.size() - 1)]


# ================================================================== clues

## Writes the notes for a lock that needs knowledge (see RiddleMaker). Riddle depth varies a little
## around the tier's "riddle" value, so not every lock in a level is equally tricky.
func _make_clues(lock: Dictionary) -> Array[Dictionary]:
	var riddle := int(cfg.get("riddle", cfg.get("indirection", 0)))
	var depth := riddle if riddle <= 1 else rng.randi_range(riddle - 1, riddle)
	var out: Array[Dictionary] = []
	for note in RiddleMaker.new(self).notes_for(lock, depth):
		out.append(_new_clue(lock, note))
	return out


func _split_answer(type: String, answer: String, lock: Dictionary) -> PackedStringArray:
	match type:
		"combo":
			var cut := maxi(1, answer.length() / 2)
			return [_spaced(answer.substr(0, cut)), _spaced(answer.substr(cut))]
		"sequence":
			var seq := answer.split(",")
			var cut2 := maxi(1, seq.size() / 2)
			return [_tokens(seq.slice(0, cut2)), _tokens(seq.slice(cut2))]
		"switches":
			var on := _switch_symbols(lock, "1")
			var cut3 := maxi(1, on.size() / 2)
			if on.size() == 1:
				return [_tokens(on), _tokens(on)]
			return [_tokens(on.slice(0, cut3)), _tokens(on.slice(cut3))]
	return [answer, answer]


func _fill(template: String, lock: Dictionary, part: String) -> String:
	var answer := str(lock["answer"])
	var out := template
	out = out.replace("{lock}", _lock_name(lock))
	out = out.replace("{part}", part)
	match str(lock["type"]):
		"combo":
			out = out.replace("{code}", _spaced(answer))
			out = out.replace("{reversed}", _spaced(answer.reverse()))
			out = out.replace("{words}", _digit_words(answer))
		"sequence", "order":
			var seq := answer.split(",")
			out = out.replace("{seq}", _tokens(seq))
			var rev := seq.duplicate()
			rev.reverse()
			out = out.replace("{seq_reversed}", _tokens(rev))
		"clock":
			var parts := answer.split(":")
			var h := int(parts[0])
			var m := int(parts[1])
			out = out.replace("{time}", answer)
			out = out.replace("{time_words}", _time_words(h, m))
			var before := h - 1 if h > 1 else 12
			out = out.replace("{time_before}", "%d:%02d" % [before, m])
			out = out.replace("{time_after}", "%d:%02d" % [h + 1 if h < 12 else 1, m])
		"switches":
			out = out.replace("{on}", _tokens(_switch_symbols(lock, "1")))
			out = out.replace("{off}", _tokens(_switch_symbols(lock, "0")))
	return out[0].to_upper() + out.substr(1) if out.length() > 0 else out


func _switch_symbols(lock: Dictionary, state: String) -> PackedStringArray:
	var symbols: Array = (lock.get("config", {}) as Dictionary).get("symbols", [])
	var pattern := str(lock["answer"])
	var out: PackedStringArray = []
	for i in mini(pattern.length(), symbols.size()):
		if pattern[i] == state:
			out.append(str(symbols[i]))
	return out


func _time_words(h: int, m: int) -> String:
	var words: Array = clue_db.get("number_words", [])
	var tw: Dictionary = clue_db.get("time_words", {})
	var key := str(m)
	if not tw.has(key) or words.size() < 13:
		return "%d:%02d" % [h, m]
	var next_h := (h % 12) + 1
	return str(tw[key]).replace("{h}", str(words[h])).replace("{h1}", str(words[next_h]))


func _digit_words(code: String) -> String:
	var words: Array = clue_db.get("number_words", [])
	var out: PackedStringArray = []
	for ch in code:
		out.append(str(words[int(ch)]) if words.size() > 9 else ch)
	return ", ".join(out)


func _lock_name(lock: Dictionary) -> String:
	var host: Dictionary = lock.get("host", {})
	match str(host.get("kind", "")):
		"door":
			return str((room.get("door", {}) as Dictionary).get("name", "the balcony door"))
		"furniture":
			for f: Dictionary in room.get("furniture", []):
				if str(f["id"]) == str(host.get("furniture", "")):
					for s: Dictionary in f.get("spots", []):
						if str(s["id"]) == str(host.get("spot", "")):
							return str(s.get("name", f.get("name", "it")))
					return str(f.get("name", "it"))
		"prop":
			return str(props_db.get(str(host.get("prop", "")), {}).get("name", "it"))
	return "it"


static func _spaced(code: String) -> String:
	return " ".join(code.split(""))


static func _tokens(symbols: Variant) -> String:
	var out: PackedStringArray = []
	for s: Variant in symbols:
		out.append("{%s}" % str(s))
	return " ".join(out)


# ================================================================== decoys and postcards

func _add_decoys(count: int) -> void:
	var texts: Array = (clue_db.get("decoys", []) as Array).duplicate()
	_shuffle(texts)
	for i in mini(count, texts.size()):
		_next_id += 1
		var d := {"id": "d%d" % _next_id, "text": str(texts[i]), "location": "room", "host": {}}
		var host := _clue_host_in_room() if rng.randf() < 0.6 else {}
		if host.is_empty():
			var container := _random_container()
			if container == "":
				host = _clue_host_in_room()
				if host.is_empty():
					continue
			else:
				d["location"] = container
				host = {"kind": "prop", "prop": "note"}
				contents[container] = int(contents.get(container, 0)) + 1
		d["host"] = host
		decoys.append(d)


func _add_postcard(postcard_id: String) -> void:
	var container := _random_container()
	if container != "" and rng.randf() < 0.6:
		_postcard = {"id": postcard_id, "location": container, "host": {"kind": "prop", "prop": "postcard"}}
		contents[container] = int(contents.get(container, 0)) + 1
		return
	var slot := _free_surface_slot()
	if slot != "":
		used_slots[slot] = true
		_postcard = {"id": postcard_id, "location": "room", "host": {"kind": "prop", "prop": "postcard", "slot": slot}}
	elif container != "":
		_postcard = {"id": postcard_id, "location": container, "host": {"kind": "prop", "prop": "postcard"}}


func _random_container() -> String:
	var options: Array[String] = []
	for l in locks:
		if not bool(l.get("is_door", false)) and int(contents.get(str(l["id"]), 0)) < MAX_CONTENTS:
			options.append(str(l["id"]))
	return "" if options.is_empty() else options[rng.randi_range(0, options.size() - 1)]


# ================================================================== small helpers

func _allowed(types: PackedStringArray) -> Array[String]:
	var allowed: Array = cfg.get("types", [])
	var out: Array[String] = []
	for t in types:
		if allowed.has(t):
			out.append(t)
	if out.is_empty():
		out.append("combo")
	return out


## Splits `budget` into `n` shares. Up to `branches` shares get steps; the rest get 0 (placed in the room).
func _split(budget: int, n: int) -> Array[int]:
	var shares: Array[int] = []
	shares.resize(n)
	shares.fill(0)
	if n == 0 or budget <= 0:
		return shares
	var branches := clampi(int(cfg.get("branches", 1)), 1, n)
	var active := 1
	if branches > 1 and budget >= 2:
		active = rng.randi_range(1, mini(branches, budget))
	var order: Array = range(n)
	_shuffle(order)
	var left := budget
	for i in active:
		var idx: int = order[i]
		var give := left if i == active - 1 else rng.randi_range(1, left - (active - 1 - i))
		shares[idx] = give
		left -= give
	return shares


func _pick(list: Array[String]) -> String:
	return list[rng.randi_range(0, list.size() - 1)]


func _weighted(options: Array[Dictionary]) -> Dictionary:
	var total := 0.0
	for o in options:
		total += float(o.get("weight", 1.0))
	var r := rng.randf() * total
	for o in options:
		r -= float(o.get("weight", 1.0))
		if r <= 0.0:
			return o
	return options[options.size() - 1]


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## A fresh, shuffle-safe copy of SYMBOLS. (Array(SYMBOLS) shares storage with the constant, so shuffling it would reorder SYMBOLS itself.)
static func _symbol_pool() -> Array:
	var pool: Array = []
	for s in SYMBOLS:
		pool.append(s)
	return pool


static func _all_same(s: String) -> bool:
	for ch in s:
		if ch != s[0]:
			return false
	return true


static func _mix(seed_value: int, attempt: int) -> int:
	return absi(hash("%d:%d" % [seed_value, attempt])) + 1
