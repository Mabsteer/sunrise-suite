extends TestCase
## The owner's dev mode: turned on by tapping the version 5 times, lists every room, jumps in with
## Chloé found, unlocks everything, and can solve a room.

var _settings: Dictionary
var _data: Dictionary


func before_each() -> void:
	_settings = SaveManager.settings.duplicate(true)
	_data = SaveManager.data.duplicate(true)
	SaveManager.persist = false


func after_each() -> void:
	SaveManager.settings = _settings
	SaveManager.data = _data


func test_five_taps_on_the_version_turn_dev_mode_on_and_off() -> void:
	SaveManager.settings["dev_mode"] = false
	var panel := SettingsPanel.new()
	tree.root.add_child(panel)
	for i in 4:
		panel.tap_version()
	assert_false(bool(SaveManager.settings["dev_mode"]), "four taps do nothing")
	panel.tap_version()
	assert_true(bool(SaveManager.settings["dev_mode"]), "the fifth tap turns dev mode on")
	for i in 5:
		panel.tap_version()
	assert_false(bool(SaveManager.settings["dev_mode"]), "five more turn it off")
	panel.free()


func test_dev_panel_lists_every_room() -> void:
	var panel := DevPanel.new()
	tree.root.add_child(panel)
	var jumps := 0
	for b in panel.find_children("*", "Button", true, false):
		if "\n" in (b as Button).text:
			jumps += 1
	assert_eq(jumps, Campaign.levels().size(), "one jump button per room")
	panel.free()


func test_jumping_past_the_hall_finds_chloe() -> void:
	SaveManager.reset_progress()
	var list := Campaign.levels()
	GameState.dev_prepare_jump(str(list[1]["id"]))
	assert_false(GameState.chloe_found(), "jumping into the hall: she still has to be found")
	GameState.dev_prepare_jump(str(list[2]["id"]))
	assert_true(GameState.chloe_found(), "jumping into the bedroom: she's with Juliette")


func test_unlock_all_needs_dev_mode() -> void:
	SaveManager.reset_progress()
	var last := str(Campaign.levels().back()["id"])
	SaveManager.settings["dev_unlock_all"] = true
	SaveManager.settings["dev_mode"] = false
	assert_false(GameState.is_level_unlocked(last), "without dev mode nothing changes")
	SaveManager.settings["dev_mode"] = true
	assert_true(GameState.is_level_unlocked(last), "dev mode + unlock all opens every room")


func test_solution_lines_cover_every_lock() -> void:
	var level := Campaign.build(str(Campaign.levels()[1]["id"]))
	var session := LevelSession.new(level)
	var text := LevelText.new(session, Data.get_dict("rooms/" + str(level["room"])))
	var lines := DevPanel.solution_lines(session, text)
	assert_eq(lines.size(), session.locks.size(), "one line per lock")


func test_finish_room_solves_the_level() -> void:
	Router.params = {"level": Campaign.build(str(Campaign.levels()[1]["id"])), "mode": "test"}
	var scene := (load("res://scenes/level/level.tscn") as PackedScene).instantiate() as LevelScene
	tree.root.add_child(scene)
	await tree.process_frame
	assert_true(scene.dev_step(), "one step can be done")
	await scene.dev_finish()
	assert_true(scene.session.finished, "the dev menu solved the whole room")
	scene.queue_free()
	await tree.process_frame
