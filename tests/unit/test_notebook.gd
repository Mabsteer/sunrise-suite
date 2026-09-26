extends TestCase
## Mamie's notebook: reading a note takes it along (a paper note leaves its spot), the notes of
## earlier rooms on the same walk are still there, and the bag can be folded away.

var _settings: Dictionary
var _data: Dictionary


func before_each() -> void:
	_settings = SaveManager.settings.duplicate(true)
	_data = SaveManager.data.duplicate(true)
	SaveManager.persist = false
	SaveManager.reset_progress()


func after_each() -> void:
	SaveManager.settings = _settings
	SaveManager.data = _data


func test_reading_a_note_puts_it_in_the_notebook_and_takes_it_along() -> void:
	var scene := await _open("w1_kitchen")
	var key := "clue:c_welcome"
	assert_true(scene.hotspots.has(key), "the welcome letter lies in the kitchen")
	scene.tap(key)
	assert_eq(scene.get("_notes").size(), 1, "the letter is in the notebook")
	assert_true(scene.hotspots.has(key), "it stays while Juliette reads it")
	scene.closeup.close()
	assert_false(scene.hotspots.has(key), "put down, it's tucked into the notebook")
	assert_eq(GameState.notebook("walk_1").size(), 1, "the walk's notebook keeps it")
	await _close(scene)


func test_the_notebook_carries_notes_to_the_next_room() -> void:
	GameState.notebook_add("walk_1", {"id": "memory:kitchen_welcome", "room": "The kitchen", "title": "Welcome home", "text": "Ma chérie..."})
	var scene := await _open("w1_hall")
	assert_eq(scene.get("_notes").size(), 1, "the kitchen letter is still in the notebook in the hall")
	await _close(scene)


func test_the_first_room_of_a_walk_starts_a_fresh_notebook() -> void:
	GameState.notebook_add("walk_1", {"id": "memory:old", "room": "x", "title": "x", "text": "x"})
	var scene := await _open("w1_kitchen")
	assert_eq(scene.get("_notes").size(), 0, "a new walk, a new notebook")
	await _close(scene)


func test_fixed_things_stay_in_the_room() -> void:
	var scene := await _open("w1_hall")
	var key := "clue:c_marks"
	scene.tap(key)
	scene.closeup.close()
	assert_true(scene.hotspots.has(key), "pencil marks on a door frame can't be taken along")
	assert_eq(scene.get("_notes").size(), 1, "but what they say is in the notebook")
	await _close(scene)


func test_the_bag_folds_away_and_remembers() -> void:
	var scene := await _open("w1_kitchen")
	var bar := scene.inventory
	assert_true(bar.is_open(), "open at first")
	bar.set_collapsed(true, true)
	assert_false(bar.is_open(), "folded away")
	assert_true(bool(SaveManager.settings["bag_collapsed"]), "remembered for the next rooms")
	bar.add_item("i_batteries")
	assert_true(bar.is_open(), "a new item peeks the bar open")
	await _close(scene)


func _open(level_id: String) -> LevelScene:
	Router.params = {"level": Campaign.build(level_id), "mode": "main", "record_id": level_id}
	var scene := (load("res://scenes/level/level.tscn") as PackedScene).instantiate() as LevelScene
	tree.root.add_child(scene)
	await tree.process_frame
	return scene


func _close(scene: LevelScene) -> void:
	scene.queue_free()
	await tree.process_frame
