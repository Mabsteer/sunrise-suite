class_name LevelValidator
extends RefCounted
## Checks that a level is well-formed and solvable. Used by the generator (retry until valid),
## the validator test scene and the unit tests.


## Returns { "ok": bool, "errors": PackedStringArray, "steps": int }.
static func validate(level: Dictionary, tier_cfg: Dictionary = {}) -> Dictionary:
	var errors: PackedStringArray = []
	var room := Data.get_dict("rooms/" + str(level.get("room", "")))
	var props := Data.get_dict("props")
	var items_db := Data.get_dict("items")
	if room.is_empty():
		errors.append("unknown room '%s'" % level.get("room", ""))
		return {"ok": false, "errors": errors, "steps": 0}

	var lock_ids := {}
	for l: Dictionary in level.get("locks", []):
		lock_ids[str(l["id"])] = l
	var item_ids := {}
	for i: Dictionary in level.get("items", []):
		item_ids[str(i["id"])] = i
	var clue_ids := {}
	for c: Dictionary in level.get("clues", []):
		clue_ids[str(c["id"])] = c

	# --- exactly one door
	var doors := 0
	for l: Dictionary in level.get("locks", []):
		if bool(l.get("is_door", false)):
			doors += 1
	if doors != 1:
		errors.append("expected 1 door, found %d" % doors)

	# --- locations point at real containers, no cycles
	var all_things: Array[Dictionary] = []
	for key in ["locks", "items", "clues", "decoys"]:
		for t: Dictionary in level.get(key, []):
			all_things.append(t)
	var pc: Dictionary = level.get("postcard", {})
	if not pc.is_empty():
		all_things.append(pc)
	for t in all_things:
		var loc := str(t.get("location", "room"))
		if loc != "room" and loc != "recipe" and not lock_ids.has(loc):
			errors.append("%s is inside unknown lock '%s'" % [t.get("id", "?"), loc])
	for id: String in lock_ids.keys():
		var seen := {}
		var cur := id
		while cur != "room" and lock_ids.has(cur):
			if seen.has(cur):
				errors.append("location cycle at %s" % id)
				break
			seen[cur] = true
			cur = str((lock_ids[cur] as Dictionary).get("location", "room"))

	# --- hosts are valid and not double-booked
	var used_slots := {}
	var used_spots := {}
	for t in all_things:
		var host: Dictionary = t.get("host", {})
		var loc := str(t.get("location", "room"))
		var tid := str(t.get("id", "?"))
		match str(host.get("kind", "")):
			"furniture":
				var spot := _spot(room, str(host.get("furniture", "")), str(host.get("spot", "")))
				if spot.is_empty():
					errors.append("%s: unknown furniture spot %s:%s" % [tid, host.get("furniture", ""), host.get("spot", "")])
					continue
				var key := "%s:%s" % [host["furniture"], host["spot"]]
				if used_spots.has(key):
					errors.append("%s: furniture spot %s used twice" % [tid, key])
				used_spots[key] = true
				if lock_ids.has(tid) and not _host_takes(spot.get("locks", []), str(t.get("type", ""))):
					errors.append("%s: spot %s can't hold a %s lock" % [tid, key, t.get("type", "")])
				if clue_ids.has(tid) and not bool(spot.get("clue", false)):
					errors.append("%s: spot %s can't carry a clue" % [tid, key])
			"prop":
				var prop_id := str(host.get("prop", ""))
				if not props.has(prop_id):
					errors.append("%s: unknown prop %s" % [tid, prop_id])
					continue
				var prop: Dictionary = props[prop_id]
				if lock_ids.has(tid) and not _host_takes(prop.get("locks", []), str(t.get("type", ""))):
					errors.append("%s: prop %s can't hold a %s lock" % [tid, prop_id, t.get("type", "")])
				if host.has("count"):
					var count := int(host["count"])
					if count < 1 or count > 9 or not prop.has("sprite_count"):
						errors.append("%s: prop %s can't show %d things" % [tid, prop_id, count])
				if loc == "room":
					var slot := str(host.get("slot", ""))
					if not _slot_accepts(room, slot, str(prop.get("place", "surface"))):
						errors.append("%s: prop %s doesn't fit slot '%s'" % [tid, prop_id, slot])
					if used_slots.has(slot):
						errors.append("%s: slot %s used twice" % [tid, slot])
					used_slots[slot] = true
				elif str(prop.get("place", "surface")) != "surface":
					errors.append("%s: wall prop %s can't be inside a container" % [tid, prop_id])
			"door":
				if not lock_ids.has(tid):
					errors.append("%s: only locks can be the door" % tid)
			"":
				if not item_ids.has(tid):
					errors.append("%s has no host" % tid)
	for i: Dictionary in level.get("items", []):
		if not items_db.has(str(i.get("type", ""))):
			errors.append("%s: unknown item type %s" % [i.get("id", "?"), i.get("type", "")])
		if str(i.get("location", "room")) == "room":
			var slot := str(i.get("slot", ""))
			if not _slot_accepts(room, slot, "surface"):
				errors.append("%s: item slot '%s' is not a surface slot" % [i.get("id", "?"), slot])
			if used_slots.has(slot):
				errors.append("%s: slot %s used twice" % [i.get("id", "?"), slot])
			used_slots[slot] = true

	# --- clue text: every placeholder was filled in (symbol icons like {sun} stay)
	var symbols := Data.get_dict("symbols")
	for c: Dictionary in level.get("clues", []):
		var text := str(c.get("text", ""))
		var at := text.find("{")
		while at >= 0:
			var close := text.find("}", at)
			var token := text.substr(at + 1, close - at - 1) if close > at else ""
			if not symbols.has(token) or token.begins_with("_"):
				errors.append("%s: unfilled placeholder in %s" % [c.get("id", "?"), text])
				break
			at = text.find("{", close)

	# --- lock requirements make sense
	for l: Dictionary in level.get("locks", []):
		var t := str(l.get("type", ""))
		var lid := str(l.get("id", "?"))
		if not LevelSession.ALL_TYPES.has(t):
			errors.append("%s: unknown lock type %s" % [lid, t])
		if t in LevelSession.KNOWLEDGE_TYPES:
			var cl: Array = l.get("clues", [])
			if cl.is_empty():
				errors.append("%s: %s lock without clues" % [lid, t])
			for c: Variant in cl:
				if not clue_ids.has(str(c)):
					errors.append("%s: missing clue %s" % [lid, c])
		if t in LevelSession.ITEM_TYPES and not item_ids.has(str(l.get("item", ""))):
			errors.append("%s: %s lock without its item" % [lid, t])
		if str(l.get("answer", "x")) == "" and not t in ["key", "tool", "hidden"]:
			errors.append("%s: empty answer" % lid)
		for a: Variant in l.get("after", []):
			if not lock_ids.has(str(a)):
				errors.append("%s: comes after unknown lock %s" % [lid, a])
		errors.append_array(_puzzle_errors(l))
	# Puzzles that build on each other: a code read from a number square must match its shaded squares.
	for c: Dictionary in level.get("clues", []):
		if c.has("source") and lock_ids.has(str(c["source"])) and lock_ids.has(str(c.get("for", ""))):
			var sq: Dictionary = lock_ids[str(c["source"])]
			var code := ""
			for cell: Variant in (sq.get("config", {}) as Dictionary).get("shaded", []):
				code += str(sq.get("answer", ""))[int(cell)]
			if code != str((lock_ids[str(c["for"])] as Dictionary).get("answer", "")):
				errors.append("%s: the shaded squares of %s don't give the code" % [c.get("id", "?"), c["source"]])
	# Keys are always the reward of a solved puzzle: never lying around, never in a plain search spot.
	for i: Dictionary in level.get("items", []):
		if str(items_db.get(str(i.get("type", "")), {}).get("kind", "")) != "key":
			continue
		var loc := str(i.get("location", "room"))
		if not lock_ids.has(loc) or not LevelGenerator.REWARD_CONTAINERS.has(str((lock_ids[loc] as Dictionary).get("type", ""))):
			errors.append("%s: a key must be the reward of a puzzle (it is in '%s')" % [i.get("id", "?"), loc])
	# Searching is not a difficulty knob.
	if tier_cfg.has("max_hidden"):
		var hidden := 0
		for l: Dictionary in level.get("locks", []):
			if str(l.get("type", "")) == "hidden":
				hidden += 1
		if hidden > int(tier_cfg["max_hidden"]):
			errors.append("%d search spots, at most %d allowed" % [hidden, int(tier_cfg["max_hidden"])])
	var needed := {}
	for l: Dictionary in level.get("locks", []):
		var it := str(l.get("item", ""))
		if it != "":
			if needed.has(it):
				errors.append("item %s is needed by two locks" % it)
			needed[it] = true

	# --- solvable, using every step
	var result := LevelSolver.solve(level)
	if not bool(result["solvable"]):
		errors.append("not solvable: %s" % result["error"])
	elif not bool(result["all_steps"]):
		errors.append("only %d of %d steps are needed" % [result["solved_steps"], result["total_steps"]])
	var steps := int(result["total_steps"])
	if tier_cfg.has("steps"):
		var r: Array = tier_cfg["steps"]
		if steps < int(r[0]) or steps > int(r[1]) + 1:
			errors.append("%d steps, tier wants %d-%d" % [steps, int(r[0]), int(r[1])])
	var estimate := LevelSolver.estimate_seconds(level, result["actions"], int(tier_cfg.get("riddle", level.get("riddle", 1))))
	return {"ok": errors.is_empty(), "errors": errors, "steps": steps, "estimate": estimate}


## A spot or prop lists the lock types it can hold; "hidden" spots with tools also take "tool" locks.
static func _host_takes(list: Array, type: String) -> bool:
	return list.has(type) or (type == "tool" and list.has("hidden"))


## Checks the data of the self-contained puzzles (and orders): they must have exactly one answer.
static func _puzzle_errors(l: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var lid := str(l.get("id", "?"))
	var cfg: Dictionary = l.get("config", {})
	var answer := str(l.get("answer", ""))
	match str(l.get("type", "")):
		"order":
			var items := answer.split(",")
			var unique := {}
			for s in items:
				unique[s] = true
			if items.size() < 3 or unique.size() != items.size():
				out.append("%s: an order needs 3+ different things (%s)" % [lid, answer])
		"sudoku":
			var givens := str(cfg.get("givens", ""))
			if not PuzzleMath.sudoku_valid(answer, givens):
				out.append("%s: the number square's answer is wrong" % lid)
			else:
				var grid: Array[int] = []
				for ch in givens:
					grid.append(0 if ch == "." else int(ch))
				if PuzzleMath.sudoku_count(grid, 2) != 1:
					out.append("%s: the number square has more than one answer" % lid)
		"pattern":
			var terms: Array = cfg.get("terms", [])
			var blanks: Array = cfg.get("blanks", [])
			var expect: PackedStringArray = []
			for b: Variant in blanks:
				if int(b) < 0 or int(b) >= terms.size():
					out.append("%s: pattern gap %s is outside the pattern" % [lid, b])
					return out
				expect.append(str(terms[int(b)]))
			if blanks.is_empty() or ",".join(expect) != answer:
				out.append("%s: the pattern's answer doesn't match its gaps" % lid)
		"rotate":
			var n := int(cfg.get("size", 0))
			if n < 2 or n > 4 or not ResourceLoader.exists("res://assets/sprites/" + str(cfg.get("picture", ""))):
				out.append("%s: rotate puzzle needs a size 2-4 and a picture" % lid)
	return out


static func _spot(room: Dictionary, furniture_id: String, spot_id: String) -> Dictionary:
	for f: Dictionary in room.get("furniture", []):
		if str(f["id"]) == furniture_id:
			for s: Dictionary in f.get("spots", []):
				if str(s["id"]) == spot_id:
					return s
	return {}


static func _slot_accepts(room: Dictionary, slot_id: String, place: String) -> bool:
	if place == "surface":
		for s: Dictionary in room.get("surface_slots", []):
			if str(s["id"]) == slot_id:
				return true
		return false
	for s: Dictionary in room.get("wall_slots", []):
		if str(s["id"]) == slot_id:
			return (s.get("accepts", []) as Array).has(place)
	return false
