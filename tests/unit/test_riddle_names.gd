extends TestCase
## Half-cryptic generated notes: from the second tier on, a note names its lock in Mamie's words
## ("the spoons' bedroom"), and every such name means exactly one thing in its room.


func test_every_lockable_thing_has_a_riddle_name_unique_in_its_room() -> void:
	var props := Data.get_dict("props")
	for room_id in Campaign.ROUTE:
		var room := Data.get_dict("rooms/" + room_id)
		var names := {}
		var door_name := str((room.get("door", {}) as Dictionary).get("riddle_name", ""))
		assert_ne(door_name, "", "%s's door has a riddle name" % room_id)
		names[door_name] = "door"
		for f: Dictionary in room.get("furniture", []):
			for s: Dictionary in f.get("spots", []):
				if (s.get("locks", []) as Array).is_empty():
					continue
				var n := str(s.get("riddle_name", ""))
				assert_ne(n, "", "%s %s.%s has a riddle name" % [room_id, f["id"], s["id"]])
				assert_false(names.has(n), "%s: '%s' means two things" % [room_id, n])
				names[n] = s["id"]
		for p: String in props.keys():
			if p.begins_with("_") or ((props[p] as Dictionary).get("locks", []) as Array).is_empty():
				continue
			var pn := str(props[p].get("riddle_name", ""))
			assert_ne(pn, "", "prop %s has a riddle name" % p)
			assert_false(names.has(pn), "%s: '%s' means two things" % [room_id, pn])


func test_generated_notes_avoid_plain_lock_names_above_the_first_tier() -> void:
	var checked := 0
	for room_id in Campaign.ROUTE:
		for seed_value in range(1, 8):
			var level := LevelGenerator.generate(room_id, 4, seed_value)
			var session := LevelSession.new(level)
			var text := LevelText.new(session, Data.get_dict("rooms/" + room_id))
			for c: Dictionary in level.get("clues", []):
				var lock_id := str(c.get("for", ""))
				if lock_id == "" or not session.locks.has(lock_id):
					continue
				var plain := text.lock_name(lock_id).to_lower()
				var note := str(c.get("text", "")).to_lower()
				if plain.length() > 6:
					assert_false(note.contains(plain), "%s/%d note names '%s' plainly: %s" % [room_id, seed_value, plain, note])
				checked += 1
	assert_true(checked > 20, "checked plenty of notes")


func test_the_first_tier_still_names_locks_plainly() -> void:
	var gen := LevelGenerator.new()
	gen.cfg = {"riddle": 0}
	gen.room = Data.get_dict("rooms/kitchen")
	gen.props_db = Data.get_dict("props")
	var lock := {"host": {"kind": "furniture", "furniture": "counter", "spot": "drawers"}}
	assert_eq(gen._lock_ref(lock), "the kitchen drawers")
	gen.cfg = {"riddle": 2}
	assert_eq(gen._lock_ref(lock), "the spoons' bedroom")
