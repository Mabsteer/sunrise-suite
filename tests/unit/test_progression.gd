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
	assert_true(GameState.is_level_unlocked("main_01"))
	assert_false(GameState.is_level_unlocked("main_02"))
	assert_eq(GameState.lock_reason("main_02"), "previous")


func test_finishing_unlocks_next() -> void:
	var result := _finish("main_01", 3)
	assert_eq(int(result["stars"]), 3)
	assert_true(GameState.is_level_unlocked("main_02"))
	assert_true((result["unlocks"] as Array).size() > 0, "tells the player the next level opened")


func test_seashells_first_clear_and_replay() -> void:
	var first := _finish("main_01", 1)
	assert_eq(int(first["seashells"]), GameState.SHELLS_FIRST_CLEAR + GameState.SHELLS_PER_NEW_STAR, "first clear + 1 new star")
	var again := _finish("main_01", 3)
	assert_eq(int(again["seashells"]), GameState.SHELLS_REPLAY + 2 * GameState.SHELLS_PER_NEW_STAR)
	assert_eq(GameState.level_stars("main_01"), 3, "best stars are kept")
	var worse := _finish("main_01", 1)
	assert_eq(GameState.level_stars("main_01"), 3, "a worse run doesn't lower stars")
	assert_eq(int(worse["new_stars"]), 0)


func test_star_gate_blocks_tier_four() -> void:
	for i in 9:
		_finish("main_%02d" % (i + 1), 1)
	assert_eq(GameState.total_stars(), 9)
	assert_false(GameState.is_level_unlocked("main_10"), "tier 4 needs 12 stars")
	assert_eq(GameState.lock_reason("main_10"), "stars:12")
	_finish("main_01", 3)
	_finish("main_02", 3)
	assert_eq(GameState.total_stars(), 13)
	assert_true(GameState.is_level_unlocked("main_10"))


func test_current_level_moves_on() -> void:
	assert_eq(GameState.current_level_id(), "main_01")
	_finish("main_01", 2)
	assert_eq(GameState.current_level_id(), "main_02")
	assert_eq(GameState.next_level_id("main_29"), "main_30")
	assert_eq(GameState.next_level_id("main_30"), "")
