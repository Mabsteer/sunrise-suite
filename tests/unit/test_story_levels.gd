extends TestCase
## The story: three days of seven rooms (data/story.json) and the hand-made levels that tell it.


func test_every_day_has_the_seven_rooms_with_a_period() -> void:
	var days: Array = Data.get_dict("story").get("chapters", [])
	assert_eq(days.size(), 3, "three days")
	var last_start := 9999
	for c: Dictionary in days:
		var rooms: Array = c.get("rooms", [])
		assert_eq(rooms.size(), 7, "Day %d has seven rooms" % int(c["id"]))
		for i in rooms.size():
			var r: Dictionary = rooms[i]
			assert_eq(str(r["room"]), Campaign.ROUTE[i], "Day %d room %d" % [int(c["id"]), i + 1])
			for key in ["title", "years", "intro", "outro"]:
				assert_false(str(r.get(key, "")).is_empty(), "Day %d %s has a %s" % [int(c["id"]), r["room"], key])
		# The days go back in time: each day's years start before the previous day's.
		var start := int(str(c.get("years", "0")).left(4))
		assert_true(start < last_start, "Day %d is older than the day before" % int(c["id"]))
		last_start = start


func test_memories_are_unique_and_all_used() -> void:
	var ids := {}
	for sr in Campaign.story_rooms():
		for m: Dictionary in (sr["page"] as Dictionary).get("memories", []):
			assert_false(ids.has(m["id"]), "memory %s twice" % m["id"])
			ids[m["id"]] = "%d:%s" % [int(sr["day"]), str(sr["room"])]
			assert_true(str(m.get("text", "")).length() > 40, "memory %s needs a text" % m["id"])
	var used := {}
	for e: Dictionary in Campaign.levels():
		if not e.has("level_file"):
			continue
		var level := Campaign.build(str(e["id"]))
		for key in ["clues", "decoys"]:
			for c: Dictionary in level.get(key, []):
				if c.has("memory"):
					var mid := str(c["memory"])
					assert_eq(ids.get(mid, ""), "%d:%s" % [int(e["walk"]), str(e["room"])], "memory %s belongs to its day and room" % mid)
					assert_eq(str(c.get("text", "")), str(Campaign.memory(mid)["text"]), "the note shows the memory's text")
					used[mid] = true
	# Every memory of a hand-made room must be found in it (placeholder rooms can have theirs ready).
	var hand_made := {}
	for e: Dictionary in Campaign.levels():
		if e.has("level_file"):
			hand_made["%d:%s" % [int(e["walk"]), str(e["room"])]] = true
	for mid: String in ids.keys():
		if hand_made.has(ids[mid]):
			assert_true(used.has(mid), "memory %s is never found in its room" % mid)


func test_story_levels_match_the_campaign() -> void:
	for e: Dictionary in Campaign.levels():
		if not e.has("level_file"):
			continue
		var level := Campaign.build(str(e["id"]))
		assert_eq(str(level["room"]), str(e["room"]), "%s room" % e["id"])
		var pc := str((level.get("postcard", {}) as Dictionary).get("id", ""))
		assert_eq(pc, str(e.get("postcard", "")), "%s postcard" % e["id"])
		assert_eq(level.get("companion", "") == "chloe", bool(e.get("companion", false)), "%s Chloé" % e["id"])
		var hides := false
		for l: Dictionary in level["locks"]:
			hides = hides or bool(l.get("finds_dog", false))
		assert_eq(hides, bool(e.get("find_dog", false)), "%s: Chloé hides here" % e["id"])


func test_chloe_is_found_on_day_one() -> void:
	var found_in := ""
	for e: Dictionary in Campaign.levels():
		if bool(e.get("find_dog", false)):
			found_in = str(e["id"])
	assert_eq(found_in, "w1_hall", "she hides in the hall on the first day")


func test_reading_a_memory_keeps_it() -> void:
	SaveManager.data["memories"] = []
	assert_true(GameState.collect_memory("hall_bus"))
	assert_false(GameState.collect_memory("hall_bus"), "only once")
	assert_true(GameState.has_memory("hall_bus"))
	SaveManager.data["memories"] = []
