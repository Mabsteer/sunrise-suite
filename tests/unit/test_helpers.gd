extends TestCase
## "Show helpers" (off by default): the room doesn't give away what opens (no badges), where the
## loose things are (no sparkles), or what to do next (Chloé doesn't bark at it).

var _settings: Dictionary


func before_each() -> void:
	_settings = SaveManager.settings.duplicate(true)


func after_each() -> void:
	SaveManager.settings = _settings


func test_helpers_are_off_by_default() -> void:
	assert_false(bool(SaveManager.default_settings()["show_helpers"]))


func test_no_badges_or_sparkles_without_helpers() -> void:
	SaveManager.settings["show_helpers"] = false
	var scene := await _open_level()
	assert_eq(_badges(scene), 0, "no badges on locked things")
	assert_eq(_sparkles(scene), 0, "no sparkles on loose items")
	scene.queue_free()
	await tree.process_frame


func test_badges_and_sparkles_with_helpers() -> void:
	SaveManager.settings["show_helpers"] = true
	var scene := await _open_level()
	assert_true(_badges(scene) > 0, "badges show what can be opened")
	assert_true(_sparkles(scene) > 0, "loose items sparkle")
	scene.queue_free()
	await tree.process_frame


## A generated level with loose items and furniture locks.
func _open_level() -> LevelScene:
	var level := {}
	for seed_value in range(1, 60):
		level = LevelGenerator.generate("kitchen", 4, seed_value)
		var loose := false
		for it: Dictionary in level["items"]:
			if str(it.get("location", "")) == "room" and str(it.get("slot", "")) != "":
				loose = true
		if loose:
			break
	Router.params = {"level": level, "mode": "test"}
	var scene := (load("res://scenes/level/level.tscn") as PackedScene).instantiate() as LevelScene
	tree.root.add_child(scene)
	await tree.process_frame
	return scene


func _badges(scene: LevelScene) -> int:
	var n := 0
	for key: String in scene.host_sprites.keys():
		if key.begins_with("badge:"):
			n += 1
	return n


func _sparkles(scene: LevelScene) -> int:
	var n := 0
	for key: String in scene.host_sprites.keys():
		if key.begins_with("item:"):
			n += (scene.host_sprites[key] as Node).get_child_count()
	return n
