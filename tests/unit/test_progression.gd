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


func test_star_gate_blocks_walk_two() -> void:
	for e in Campaign.levels():
		if int(e["walk"]) == 1:
			_finish(str(e["id"]), 1)
	assert_eq(GameState.total_stars(), 7)
	assert_false(GameState.is_level_unlocked("w2_kitchen"), "walk 2 needs 12 stars")
	assert_eq(GameState.lock_reason("w2_kitchen"), "stars:12")
	_finish("w1_kitchen", 3)
	_finish("w1_hall", 3)
	_finish("w1_bedroom", 3)
	assert_eq(GameState.total_stars(), 13)
	assert_true(GameState.is_level_unlocked("w2_kitchen"))


func test_walk_levels_share_one_morning() -> void:
	var a := Campaign.build("w1_kitchen")
	var b := Campaign.build("w1_front_garden")
	assert_between(float(a["sunrise_range"][0]), 0.0, 0.2, "the first room starts before dawn")
	assert_eq(float(b["sunrise_range"][1]), 1.0, "the last room ends with the sun up")
	assert_true(bool(b.get("finale", false)), "the front garden is the finale")


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
