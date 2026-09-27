extends TestCase
## The room's light: some things only show with it on, others only in the dark. The solver and
## hints find the switch, and the validator checks every such thing can be seen.


func _level_with_light_clue(when: String) -> Dictionary:
	var level: Dictionary = Data.get_dict("levels/test_lounge").duplicate(true)
	(level["clues"][0] as Dictionary)["visible_when"] = when
	return level


func test_the_light_changes_what_can_be_seen() -> void:
	var s := LevelSession.new(_level_with_light_clue("light"))
	var c := str(s.level["clues"][0]["id"])
	assert_false(s.lights_on, "the light starts off")
	assert_false(s.visible_now(s.clues[c]), "the note can't be read in the dark")
	s.toggle_lights()
	assert_true(s.visible_now(s.clues[c]), "with the light on it can")


func test_the_solver_switches_the_light_on_when_it_must() -> void:
	var result := LevelSolver.solve(_level_with_light_clue("light"))
	assert_true(bool(result["solvable"]), "still solvable: %s" % result.get("error", ""))
	var used := false
	for a: Dictionary in result["actions"]:
		if str(a.get("action", "")) == "lights":
			used = true
	assert_true(used, "it found the light switch")


func test_the_hint_points_at_the_switch() -> void:
	var s := LevelSession.new(_level_with_light_clue("light"))
	var text := LevelText.new(s, Data.get_dict("rooms/lounge"))
	var goal := {}
	for i in 30:
		goal = s.next_goal()
		if str(goal.get("action", "")) == "lights":
			break
		LevelSolver.apply_goal(s, goal)
	assert_eq(str(goal.get("action", "")), "lights", "at some point the next step is the light")
	goal["level"] = 3
	assert_true(text.hint_text(goal).contains("light switch"), "the last hint names the switch")


func test_the_validator_checks_the_light() -> void:
	var bad := _level_with_light_clue("twilight")
	assert_false(bool(LevelValidator.validate(bad)["ok"]), "only light or dark")
	var ok := _level_with_light_clue("dark")
	assert_true(bool(LevelValidator.validate(ok)["ok"]), "a dark clue in a room with a light is fine: %s" % str(LevelValidator.validate(ok)["errors"]))


func test_every_room_has_a_light_to_find() -> void:
	for room in Campaign.ROUTE:
		var ls: Dictionary = Data.get_dict("rooms/" + room).get("light_switch", {})
		assert_false(ls.is_empty(), "%s has a light switch, lamp or lantern" % room)


func test_the_glow_stars_only_show_in_the_dark() -> void:
	Router.params = {"level": Campaign.build("w2_bedroom"), "mode": "test"}
	var scene := (load("res://scenes/level/level.tscn") as PackedScene).instantiate() as LevelScene
	tree.root.add_child(scene)
	await tree.process_frame
	var h: Control = scene.hotspots["decoy:d_stars"]
	assert_true(h.visible, "in the dark the stars glow")
	scene.tap("lights")
	assert_false(h.visible, "with the lamp on they're gone")
	scene.queue_free()
	await tree.process_frame
