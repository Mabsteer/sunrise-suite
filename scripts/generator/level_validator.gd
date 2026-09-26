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
				if lock_ids.has(tid) and not (spot.get("locks", []) as Array).has(str(t.get("type", ""))):
					errors.append("%s: spot %s can't hold a %s lock" % [tid, key, t.get("type", "")])
				if clue_ids.has(tid) and not bool(spot.get("clue", false)):
					errors.append("%s: spot %s can't carry a clue" % [tid, key])
			"prop":
				var prop_id := str(host.get("prop", ""))
				if not props.has(prop_id):
					errors.append("%s: unknown prop %s" % [tid, prop_id])
					continue
				var prop: Dictionary = props[prop_id]
				if lock_ids.has(tid) and not (prop.get("locks", []) as Array).has(str(t.get("type", ""))):
					errors.append("%s: prop %s can't hold a %s lock" % [tid, prop_id, t.get("type", "")])
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
		if t == "key" and not item_ids.has(str(l.get("item", ""))):
			errors.append("%s: key lock without a key" % lid)
		if str(l.get("answer", "x")) == "" and t != "key" and t != "hidden":
			errors.append("%s: empty answer" % lid)
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
	return {"ok": errors.is_empty(), "errors": errors, "steps": steps}


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
