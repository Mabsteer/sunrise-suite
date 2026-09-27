extends TestCase

var _saved: Dictionary


func before_each() -> void:
	_saved = SaveManager.data
	SaveManager.data = SaveManager.default_save()


func after_each() -> void:
	SaveManager.data = _saved


func _finish(level_id: String, stars_target: int) -> Dictionary:
	var level := {"id": level_id, "par_time": 600, "tier": 1, "locks": [], "items": []}
	var session := LevelSession.new(level)
	session.hints_used = 0 if stars_target >= 2 else 5
	session.elapsed = 100.0 if stars_target >= 3 else 9999.0
	return GameState.record_level_result(level, level_id, "main", session)


func test_first_level_is_open_others_locked() -> void:
	assert_true(GameState.is_level_unlocked("w1_kitchen"))
	assert_false(GameState.is_level_unlocked("w1_hall"))
	assert_eq(GameState.lock_reason("w1_hall"), "previous")


func test_finishing_unlocks_next() -> void:
	var result := _finish("w1_kitchen", 3)
	assert_eq(int(result["stars"]), 3)
	assert_true(GameState.is_level_unlocked("w1_hall"))
	assert_true((result["unlocks"] as Array).size() > 0, "tells the player the next level opened")


func test_seashells_first_clear_and_replay() -> void:
	var first := _finish("w1_kitchen", 1)
	assert_eq(int(first["seashells"]), GameState.SHELLS_FIRST_CLEAR + GameState.SHELLS_PER_NEW_STAR, "first clear + 1 new star")
	var again := _finish("w1_kitchen", 3)
	assert_eq(int(again["seashells"]), GameState.SHELLS_REPLAY + 2 * GameState.SHELLS_PER_NEW_STAR)
	assert_eq(GameState.level_stars("w1_kitchen"), 3, "best stars are kept")
	var worse := _finish("w1_kitchen", 1)
	assert_eq(GameState.level_stars("w1_kitchen"), 3, "a worse run doesn't lower stars")
	assert_eq(int(worse["new_stars"]), 0)


func test_the_story_is_linear_across_days() -> void:
	for e in Campaign.levels():
		if int(e["walk"]) == 1 and str(e["id"]) != "w1_front_garden":
			_finish(str(e["id"]), 1)
	assert_false(GameState.is_level_unlocked("w2_kitchen"), "Day 2 waits for the last room of Day 1")
	assert_false(GameState.side_modes_open(), "Daily and the shoebox wait for Day 1 too")
	var result := _finish("w1_front_garden", 1)
	assert_true(GameState.is_level_unlocked("w2_kitchen"), "no star gates: one star everywhere is enough")
	assert_true(GameState.side_modes_open(), "Day 1 done: Daily and the shoebox open")
	assert_true((result["unlocks"] as Array).has(tr("UNLOCK_SIDE_MODES")), "and the player is told")
	assert_false(GameState.is_level_unlocked("w2_hall"), "one room at a time")


func test_three_days_of_seven_rooms() -> void:
	var walks := Campaign.walks()
	assert_eq(walks.size(), 3, "three days")
	for w in walks:
		assert_eq((w["levels"] as Array).size(), 7, "Day %d walks the seven rooms" % int(w["id"]))
		assert_false(str(w.get("title", "")).is_empty(), "Day %d has its title from story.json" % int(w["id"]))
		for i in 7:
			assert_eq(str(w["levels"][i]["room"]), Campaign.ROUTE[i], "Day %d follows the route" % int(w["id"]))


func test_only_the_last_room_of_the_last_day_is_the_finale() -> void:
	for e in Campaign.levels():
		var last := int(e["walk"]) == 3 and int(e["step"]) == 6
		assert_eq(bool(e.get("finale", false)), last, "%s finale" % e["id"])


func test_every_day_is_one_morning() -> void:
	for d in [1, 2, 3]:
		var a := Campaign.build("w%d_kitchen" % d)
		var b := Campaign.build("w%d_front_garden" % d)
		assert_between(float(a["sunrise_range"][0]), 0.0, 0.2, "Day %d starts before dawn" % d)
		assert_eq(float(b["sunrise_range"][1]), 1.0, "Day %d ends with the sun up" % d)


func test_old_saves_start_the_new_story_over() -> void:
	var old := {"version": 2, "levels": {"w1_kitchen": {"stars": 3}}, "seashells": 99, "memories": ["hall_bus"], "chloe_found": true, "postcards": ["kyoto"]}
	var migrated := SaveManager.migrate_save(old)
	assert_eq((migrated["levels"] as Dictionary).size(), 0, "levels start over")
	assert_eq((migrated["memories"] as Array).size(), 0, "memories start over")
	assert_false(bool(migrated["chloe_found"]), "Chloé hides again")
	assert_eq(int(migrated["seashells"]), 99, "seashells stay")
	assert_eq(migrated["postcards"], ["kyoto"], "postcards stay")
	assert_eq(int(migrated["version"]), SaveManager.SAVE_VERSION)


func test_current_level_moves_on() -> void:
	assert_eq(GameState.current_level_id(), "w1_kitchen")
	_finish("w1_kitchen", 2)
	assert_eq(GameState.current_level_id(), "w1_hall")
	assert_eq(GameState.next_level_id("w3_shed"), "w3_front_garden")
	assert_eq(GameState.next_level_id("w3_front_garden"), "")


func test_new_best_time_only_when_faster() -> void:
	var first := _finish("w1_kitchen", 1)
	assert_false(bool(first["new_best_time"]), "the first clear has nothing to beat")
	var faster := _finish("w1_kitchen", 3)
	assert_true(bool(faster["new_best_time"]))
	var slower := _finish("w1_kitchen", 1)
	assert_false(bool(slower["new_best_time"]))
	assert_eq(float(GameState.level_record("w1_kitchen")["best_time"]), 100.0)
