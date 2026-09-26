extends TestCase
## The hand-made story levels (walk 1) and the memories they carry.


func test_every_story_room_is_hand_made() -> void:
	for e: Dictionary in Campaign.levels():
		if int(e.get("walk", 0)) == 1:
			assert_true(e.has("level_file"), "%s should be a hand-made story level" % e["id"])


func test_memories_are_unique_and_all_used() -> void:
	var ids := {}
	for c: Dictionary in Data.get_dict("story").get("chapters", []):
		var list: Array = c.get("memories", [])
		assert_true(list.size() >= 3, "%s has %d memories" % [c["room"], list.size()])
		for m: Dictionary in list:
			assert_false(ids.has(m["id"]), "memory %s twice" % m["id"])
			ids[m["id"]] = str(c["room"])
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
					assert_eq(ids.get(mid, ""), str(e["room"]), "memory %s belongs to its room's chapter" % mid)
					assert_eq(str(c.get("text", "")), str(Campaign.memory(mid)["text"]), "the note shows the memory's text")
					used[mid] = true
	for mid: String in ids.keys():
		assert_true(used.has(mid), "memory %s is never found in a level" % mid)


func test_story_levels_match_the_campaign() -> void:
	for e: Dictionary in Campaign.levels():
		if not e.has("level_file") or int(e.get("walk", 0)) != 1:
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


func test_reading_a_memory_keeps_it() -> void:
	SaveManager.data["memories"] = []
	assert_true(GameState.collect_memory("hall_bus"))
	assert_false(GameState.collect_memory("hall_bus"), "only once")
	assert_true(GameState.has_memory("hall_bus"))
	SaveManager.data["memories"] = []
