extends TestCase
## Walking from room to room: every room has an exit that leads to the next room on the route,
## the exit opens onto a view of that room, and a first time through walks straight on.

var _data: Dictionary


func before_each() -> void:
	_data = SaveManager.data.duplicate(true)
	SaveManager.persist = false
	SaveManager.reset_progress()


func after_each() -> void:
	SaveManager.data = _data


func test_every_room_exit_leads_to_the_next_room_on_the_route() -> void:
	var route := Campaign.ROUTE
	for i in route.size():
		var room := Data.get_dict("rooms/" + route[i])
		var ex: Dictionary = room.get("exit", {})
		assert_false(ex.is_empty(), "%s has an exit" % route[i])
		assert_eq(str(ex.get("to", "")), route[(i + 1) % route.size()], "%s leads on along the route" % route[i])
		if ex.has("view_center"):
			var shown := str(ex.get("view_room", ex.get("to", "")))
			assert_false(Data.get_dict("rooms/" + shown).is_empty(), "%s shows a real room through its exit" % route[i])


func test_the_hall_goes_up_the_stairs() -> void:
	var ex: Dictionary = Data.get_dict("rooms/hall").get("exit", {})
	assert_eq(str(ex.get("kind", "")), "stairs_up", "the way to the bedroom is up the stairs")
	var bedroom: Dictionary = Data.get_dict("rooms/bedroom").get("exit", {})
	assert_eq(str(bedroom.get("kind", "")), "stairs_down", "and back down to the living room")


func test_a_first_time_through_walks_on_and_the_door_shows_the_next_room() -> void:
	Router.params = {"level": Campaign.build("w1_kitchen"), "mode": "main", "record_id": "w1_kitchen"}
	var scene := (load("res://scenes/level/level.tscn") as PackedScene).instantiate() as LevelScene
	tree.root.add_child(scene)
	await tree.process_frame
	assert_eq(scene.call("_walk_next_level", {"first_clear": true}), "", "the hall isn't open before the kitchen is done")
	SaveManager.data["levels"] = {"w1_kitchen": {"stars": 3, "completions": 1, "best_time": 100.0}}
	assert_eq(scene.call("_walk_next_level", {"first_clear": true}), "w1_hall", "walks on into the hall")
	assert_eq(scene.call("_walk_next_level", {"first_clear": false}), "", "a replay shows the results card instead")
	scene.call("_play_exit", true)
	assert_true(scene.host_sprites.has("exit_view"), "the door opens onto the hall")
	scene.queue_free()
	await tree.process_frame


func test_the_last_room_of_a_walk_ends_it() -> void:
	Router.params = {"level": Campaign.build("w2_front_garden"), "mode": "main", "record_id": "w2_front_garden"}
	var scene := (load("res://scenes/level/level.tscn") as PackedScene).instantiate() as LevelScene
	tree.root.add_child(scene)
	await tree.process_frame
	assert_true(scene.call("_ends_walk", {"first_clear": true}), "the front garden ends the walk")
	assert_eq(scene.call("_walk_next_level", {"first_clear": true}), "", "no walking into the next chapter by itself")
	scene.queue_free()
	await tree.process_frame
