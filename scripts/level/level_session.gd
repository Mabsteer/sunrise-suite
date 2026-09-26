class_name LevelSession
extends RefCounted
## The rules of one escape-room level, with no nodes involved. The level scene and the autoplay bot
## both play through this same API: pick_up, see_clue, combine, use_item, search, submit_answer.
## Level format: docs/DATA_FORMAT.md ("Levels").

signal lock_opened(lock_id: String)
signal item_picked(item_id: String)
signal item_consumed(item_id: String)
signal clue_seen(clue_id: String)
signal items_combined(a: String, b: String, result: String)
signal step_solved(solved: int, total: int)
signal completed()

## Locks opened with knowledge from clues (codes, tunes, times, lamps, orders).
const KNOWLEDGE_TYPES: PackedStringArray = ["combo", "sequence", "clock", "switches", "order"]
## Puzzles solved right there, needing nothing from elsewhere.
const SELF_TYPES: PackedStringArray = ["slider", "sudoku", "pattern", "rotate"]
## Locks opened by using an item on them (a key, or a tool on something you can see).
const ITEM_TYPES: PackedStringArray = ["key", "tool"]
const ALL_TYPES: PackedStringArray = ["combo", "sequence", "clock", "switches", "order", "key", "tool", "hidden", "slider", "sudoku", "pattern", "rotate"]

var level: Dictionary
var locks: Dictionary = {}
var items: Dictionary = {}
var clues: Dictionary = {}
var decoys: Dictionary = {}
var recipes: Array[Dictionary] = []

var opened: Dictionary = {}
var inventory: Array[String] = []
var picked: Dictionary = {}
var consumed: Dictionary = {}
var seen: Dictionary = {}
var combined_recipes: Dictionary = {}
var solved_steps := 0
var total_steps := 0
var hints_used := 0
var elapsed := 0.0
var finished := false
var postcard_taken := false

var _hint_target := ""
var _hint_level := 0


func _init(level_data: Dictionary) -> void:
	level = level_data
	for l: Dictionary in level.get("locks", []):
		locks[str(l["id"])] = l
	for i: Dictionary in level.get("items", []):
		items[str(i["id"])] = i
	for c: Dictionary in level.get("clues", []):
		clues[str(c["id"])] = c
	for d: Dictionary in level.get("decoys", []):
		decoys[str(d["id"])] = d
	for r: Dictionary in level.get("recipes", []):
		recipes.append(r)
	total_steps = locks.size() + recipes.size()


# ---------------------------------------------------------------- queries

func is_open(lock_id: String) -> bool:
	return opened.has(lock_id)


## "room" is always reachable; anything else is the id of a lock whose container must be open.
func accessible(location: String) -> bool:
	return location == "room" or opened.has(location)


func lock_visible(lock_id: String) -> bool:
	return locks.has(lock_id) and accessible(str(locks[lock_id].get("location", "room")))


func item_available(item_id: String) -> bool:
	if not items.has(item_id) or picked.has(item_id):
		return false
	var loc := str(items[item_id].get("location", "room"))
	return loc != "recipe" and accessible(loc)


## A clue is available when its carrier can be seen (or, for clue items, when the item is in the inventory).
func clue_available(clue_id: String) -> bool:
	if not clues.has(clue_id):
		return false
	var c: Dictionary = clues[clue_id]
	var carrier_item := str(c.get("item", ""))
	if carrier_item != "":
		return inventory.has(carrier_item) or consumed.has(carrier_item)
	return accessible(str(c.get("location", "room")))


func decoy_available(decoy_id: String) -> bool:
	return decoys.has(decoy_id) and accessible(str(decoys[decoy_id].get("location", "room")))


func lock_type(lock_id: String) -> String:
	return str(locks[lock_id].get("type", ""))


## The item (instance id) a key/hidden lock needs, or "" if none.
func lock_item(lock_id: String) -> String:
	var v: Variant = locks[lock_id].get("item", "")
	return "" if v == null else str(v)


func lock_clues(lock_id: String) -> Array[String]:
	var out: Array[String] = []
	for c: Variant in locks[lock_id].get("clues", []):
		out.append(str(c))
	return out


## Locks that must be open before this one can be used (e.g. Chloé only helps after breakfast).
func lock_after(lock_id: String) -> Array[String]:
	var out: Array[String] = []
	for a: Variant in locks[lock_id].get("after", []):
		out.append(str(a))
	return out


func needs_item(lock_id: String) -> bool:
	var t := lock_type(lock_id)
	return t in ITEM_TYPES or (t == "hidden" and lock_item(lock_id) != "")


## True when the player has everything needed to open this lock right now.
func requirement_met(lock_id: String) -> bool:
	for a in lock_after(lock_id):
		if not opened.has(a):
			return false
	var t := lock_type(lock_id)
	if t in KNOWLEDGE_TYPES:
		for c in lock_clues(lock_id):
			if not clue_available(c):
				return false
		return true
	if needs_item(lock_id):
		return _has_item(lock_item(lock_id))
	return true


## Everything whose location is `location` ("room" or a lock id): [{ "kind": "lock"|"item"|"clue"|"decoy", "id": ... }].
func things_at(location: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in locks.keys():
		if str(locks[id].get("location", "room")) == location:
			out.append({"kind": "lock", "id": id})
	for id: String in items.keys():
		if str(items[id].get("location", "room")) == location:
			out.append({"kind": "item", "id": id})
	for id: String in clues.keys():
		if str(clues[id].get("location", "room")) == location and str(clues[id].get("item", "")) == "":
			out.append({"kind": "clue", "id": id})
	for id: String in decoys.keys():
		if str(decoys[id].get("location", "room")) == location:
			out.append({"kind": "decoy", "id": id})
	var pc: Dictionary = level.get("postcard", {})
	if not pc.is_empty() and str(pc.get("location", "room")) == location:
		out.append({"kind": "postcard", "id": str(pc.get("id", ""))})
	return out


func sunrise_t() -> float:
	return float(solved_steps) / float(maxi(total_steps, 1))


func door_id() -> String:
	for id: String in locks.keys():
		if bool(locks[id].get("is_door", false)):
			return id
	return ""


# ---------------------------------------------------------------- actions

func pick_up(item_id: String) -> bool:
	if not item_available(item_id):
		return false
	picked[item_id] = true
	inventory.append(item_id)
	item_picked.emit(item_id)
	for c: String in clues.keys():
		if str(clues[c].get("item", "")) == item_id:
			see_clue(c)
	return true


func see_clue(clue_id: String) -> void:
	if clue_available(clue_id) and not seen.has(clue_id):
		seen[clue_id] = true
		clue_seen.emit(clue_id)


## Tries a code/sequence/time/pattern (or "solved" for sliders). Returns true if the lock opened.
func submit_answer(lock_id: String, answer: String) -> bool:
	if not _can_touch(lock_id):
		return false
	var t := lock_type(lock_id)
	if not (t in KNOWLEDGE_TYPES or t in SELF_TYPES):
		return false
	if normalize_answer(t, answer) != normalize_answer(t, str(locks[lock_id].get("answer", ""))):
		return false
	_open(lock_id)
	return true


## Uses an inventory item on a lock. Returns "opened", "wrong" or "unavailable".
func use_item(item_id: String, lock_id: String) -> String:
	if not inventory.has(item_id) or not _can_touch(lock_id):
		return "unavailable"
	var needed := lock_item(lock_id)
	if needed == "" or not _same_item(item_id, needed):
		return "wrong"
	_consume(item_id)
	_open(lock_id)
	return "opened"


## Searches a hidden spot that needs no tool. Returns true if it opened.
func search(lock_id: String) -> bool:
	if not _can_touch(lock_id) or lock_type(lock_id) != "hidden" or lock_item(lock_id) != "":
		return false
	_open(lock_id)
	return true


## Combines two inventory items. Returns the new item's id, or "" if they don't go together.
func combine(a: String, b: String) -> String:
	if a == b or not inventory.has(a) or not inventory.has(b):
		return ""
	for i in recipes.size():
		var r := recipes[i]
		var ra := str(r["a"])
		var rb := str(r["b"])
		if (_same_item(a, ra) and _same_item(b, rb)) or (_same_item(a, rb) and _same_item(b, ra)):
			var result := str(r["result"])
			_consume(a)
			_consume(b)
			picked[result] = true
			inventory.append(result)
			combined_recipes[i] = true
			items_combined.emit(a, b, result)
			_add_step()
			for c: String in clues.keys():
				if str(clues[c].get("item", "")) == result:
					see_clue(c)
			return result
	return ""


func take_postcard() -> bool:
	var pc: Dictionary = level.get("postcard", {})
	if pc.is_empty() or postcard_taken or not accessible(str(pc.get("location", "room"))):
		return false
	postcard_taken = true
	return true


# ---------------------------------------------------------------- hints

## Returns what the player should do next: { "target": String, "action": String, "texts": [nudge, what, answer] }.
func next_goal() -> Dictionary:
	# 1. Items lying around.
	for id: String in _sorted_keys(items):
		if item_available(id):
			return {"target": "item:" + id, "action": "pick_up", "id": id}
	# 2. Combinations ready to make.
	for i in recipes.size():
		if combined_recipes.has(i):
			continue
		var r := recipes[i]
		var a := _inventory_match(str(r["a"]))
		var b := _inventory_match(str(r["b"]))
		if a != "" and b != "":
			return {"target": "recipe:%d" % i, "action": "combine", "a": a, "b": b}
	# 3. Locks that can be opened now (door last).
	var ready: Array[String] = []
	for id: String in _sorted_keys(locks):
		if not opened.has(id) and lock_visible(id) and requirement_met(id):
			ready.append(id)
	ready.sort_custom(func(x: String, y: String) -> bool:
		return (not bool(locks[x].get("is_door", false))) and bool(locks[y].get("is_door", false)))
	if not ready.is_empty():
		var id := ready[0]
		for c in lock_clues(id):
			if not seen.has(c):
				return {"target": "clue:" + c, "action": "see_clue", "id": c, "lock": id}
		return {"target": "lock:" + id, "action": "open", "id": id}
	return {"target": "look", "action": "look"}


## Asks for a hint. Repeated requests for the same goal get more specific (1 nudge, 2 what to do, 3 the answer).
func request_hint() -> Dictionary:
	var goal := next_goal()
	if str(goal["target"]) == _hint_target:
		_hint_level = mini(_hint_level + 1, 3)
	else:
		_hint_target = str(goal["target"])
		_hint_level = 1
	hints_used += 1
	goal["level"] = _hint_level
	return goal


# ---------------------------------------------------------------- helpers

static func normalize_answer(type: String, answer: String) -> String:
	var a := answer.strip_edges().to_lower().replace(" ", "")
	match type:
		"combo":
			return a.replace("-", "")
		"clock":
			var parts := a.split(":")
			if parts.size() == 2:
				var h := int(parts[0]) % 12
				if h == 0:
					h = 12
				return "%d:%02d" % [h, int(parts[1])]
			return a
		_:
			return a


func _can_touch(lock_id: String) -> bool:
	if not locks.has(lock_id) or opened.has(lock_id) or not lock_visible(lock_id) or finished:
		return false
	for a in lock_after(lock_id):
		if not opened.has(a):
			return false
	return true


func _open(lock_id: String) -> void:
	opened[lock_id] = true
	lock_opened.emit(lock_id)
	_add_step()
	if bool(locks[lock_id].get("is_door", false)):
		finished = true
		completed.emit()


func _add_step() -> void:
	solved_steps += 1
	step_solved.emit(solved_steps, total_steps)


func _consume(item_id: String) -> void:
	inventory.erase(item_id)
	consumed[item_id] = true
	item_consumed.emit(item_id)


func _has_item(item_id: String) -> bool:
	return _inventory_match(item_id) != ""


## Finds an inventory entry that is (or is the same kind of item as) `item_id`.
func _inventory_match(item_id: String) -> String:
	if inventory.has(item_id):
		return item_id
	for held in inventory:
		if _same_item(held, item_id):
			return held
	return ""


func _same_item(a: String, b: String) -> bool:
	if a == b:
		return true
	var ta := str(items.get(a, {}).get("type", a))
	var tb := str(items.get(b, {}).get("type", b))
	return ta == tb


static func _sorted_keys(d: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for k: Variant in d.keys():
		keys.append(str(k))
	keys.sort()
	return keys
