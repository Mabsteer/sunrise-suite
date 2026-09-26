extends TestCase

var level: Dictionary


func before_each() -> void:
	level = Data.get_dict("levels/test_lounge")


func test_test_level_is_solvable_using_every_step() -> void:
	var result := LevelSolver.solve(level)
	assert_true(bool(result["solvable"]), str(result["error"]))
	assert_true(bool(result["all_steps"]), "solved %d of %d steps" % [result["solved_steps"], result["total_steps"]])


func test_locked_contents_are_not_reachable() -> void:
	var s := LevelSession.new(level)
	assert_false(s.lock_visible("puzzle_box"), "puzzle box sits inside the closed credenza")
	assert_false(s.submit_answer("puzzle_box", "solved"))
	assert_false(s.item_available("i_brass_key"), "key is hidden under the cushion")


func test_wrong_answers_do_not_open() -> void:
	var s := LevelSession.new(level)
	assert_false(s.submit_answer("clock", "8:15"))
	assert_false(s.is_open("clock"))
	assert_true(s.submit_answer("clock", "07:30"), "07:30 means the same as 7:30")
	assert_true(s.is_open("clock"))
	assert_true(s.item_available("i_trowel"), "clock contents become reachable")


func test_combine_and_use_tool() -> void:
	var s := LevelSession.new(level)
	assert_true(s.pick_up("i_flashlight_empty"))
	assert_true(s.submit_answer("music_box", "sun,shell,wave"))
	assert_true(s.pick_up("i_batteries"))
	assert_eq(s.combine("i_batteries", "i_flashlight_empty"), "i_flashlight")
	assert_false(s.inventory.has("i_batteries"), "parts are used up")
	assert_eq(s.use_item("i_flashlight", "credenza"), "wrong", "flashlight doesn't open the credenza")
	assert_eq(s.use_item("i_flashlight", "armchair"), "opened")
	assert_true(s.item_available("i_brass_key"))


func test_sunrise_follows_steps() -> void:
	var s := LevelSession.new(level)
	assert_eq(s.sunrise_t(), 0.0)
	s.submit_answer("clock", "7:30")
	assert_between(s.sunrise_t(), 0.09, 0.11)


func test_hints_get_more_specific() -> void:
	var s := LevelSession.new(level)
	var h1 := s.request_hint()
	var h2 := s.request_hint()
	var h3 := s.request_hint()
	var h4 := s.request_hint()
	assert_eq(int(h1["level"]), 1)
	assert_eq(int(h2["level"]), 2)
	assert_eq(int(h3["level"]), 3)
	assert_eq(int(h4["level"]), 3, "caps at the answer")
	assert_eq(s.hints_used, 4)
	var text := LevelText.new(s, Data.get_dict("rooms/lounge"))
	assert_true(text.hint_text(h1).length() > 10)


func test_door_completes_level() -> void:
	var s := LevelSession.new(level)
	var done := [false]
	s.completed.connect(func() -> void: done[0] = true)
	for goal_count in 60:
		if s.finished:
			break
		LevelSolver.apply_goal(s, s.next_goal())
	assert_true(done[0])
	assert_eq(s.sunrise_t(), 1.0)


func test_answer_text() -> void:
	var s := LevelSession.new(level)
	var text := LevelText.new(s, Data.get_dict("rooms/lounge"))
	assert_eq(text.answer_text("door"), "4-7-2-9")
	assert_eq(text.answer_text("music_box"), "sun, shell, wave")
	assert_eq(text.answer_text("switches"), "only the sun and star lamps on")
	assert_eq(text.lock_name("credenza"), "the credenza's left door")
