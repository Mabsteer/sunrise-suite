extends TestCase
## Zooming the room (F7): the spot under the finger stays put, the view stays on the stage, and
## zoom 1 is exactly the normal, centred room.

var _view: RoomView


func before_each() -> void:
	SaveManager.settings["reduce_motion"] = true
	_view = RoomView.new()
	tree.root.add_child(_view)
	_view.setup("lounge")


func after_each() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	SaveManager.settings["reduce_motion"] = false


func _near(a: Vector2, b: Vector2, message: String) -> void:
	assert_true(a.distance_to(b) < 1.5, "%s: %s vs %s" % [message, a, b])


func test_zoom_keeps_the_point_under_the_finger() -> void:
	var screen := _view.get_viewport().get_visible_rect().size
	var at := screen / 2.0 + Vector2(-200, 120)
	var before := _view.to_stage(at)
	_view.zoom_view_at(at, 2.0)
	assert_eq(_view.stage.scale, Vector2(2, 2))
	_near(_view.to_stage(at), before, "same stage point under the finger")


func test_back_to_one_is_the_normal_room() -> void:
	var normal := _view.stage.position
	_view.zoom_view_at(Vector2(300, 300), 2.2)
	_view.pan_view(Vector2(500, -300))
	_view.zoom_view_at(Vector2(800, 500), 1.0)
	_near(_view.stage.position, normal, "centred again")
	assert_eq(_view.stage.scale, Vector2.ONE)


func test_the_view_stays_on_the_stage() -> void:
	_view.zoom_view_at(Vector2(960, 540), 2.0)
	_view.pan_view(Vector2(-99999, -99999))
	var screen := _view.get_viewport().get_visible_rect().size
	var right_edge := _view.stage.get_global_transform_with_canvas() * Vector2(RoomView.STAGE_SIZE.x, 0)
	assert_true(right_edge.x >= screen.x - 1.0, "no gap on the right (%s)" % right_edge)
	_view.pan_view(Vector2(99999, 99999))
	var left_edge := _view.stage.get_global_transform_with_canvas() * Vector2.ZERO
	assert_true(left_edge.x <= 1.0, "no gap on the left (%s)" % left_edge)


func test_zoom_is_limited() -> void:
	var z := RoomZoom.new(_view)
	_view.add_child(z)
	z.animate_to(9.0, Vector2(960, 540), 0.0)
	assert_eq(z.zoom(), RoomZoom.MAX_ZOOM)
	z.zoom_out()
	assert_true(z.zoom() < RoomZoom.MAX_ZOOM)
	z.reset(0.0)
	assert_eq(z.zoom(), 1.0)


## Real input through the level scene: the wheel zooms, a drag looks around without opening
## anything, and a plain tap still opens what's under it.
func test_gestures_in_a_level() -> void:
	_view.queue_free()
	# The test window is square, so the "turn your phone" card would cover the room.
	Router.set("_rotate_hint_dismissed", true)
	Router.call("_update_rotate_hint")
	Router.params = {"level": Data.get_dict("levels/test_lounge"), "mode": "test"}
	var scene := (load("res://scenes/level/level.tscn") as PackedScene).instantiate() as LevelScene
	tree.root.add_child(scene)
	await tree.process_frame
	var vp := scene.get_viewport()
	var target: Control = scene.hotspots["lock:door"]
	var at := target.get_global_rect().get_center()
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = at
	vp.push_input(wheel, true)
	assert_true(scene.room_zoom.zoom() > 1.0, "the wheel zooms in")
	scene.room_zoom.animate_to(2.0, at, 0.0)
	at = target.get_global_rect().get_center()
	var stage_before := scene.room_view.stage.position
	_mouse(vp, at, true)
	for i in 6:
		var m := InputEventMouseMotion.new()
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		m.relative = Vector2(-20, 0)
		m.position = at + Vector2(-20 * (i + 1), 0)
		vp.push_input(m, true)
	_mouse(vp, at + Vector2(-120, 0), false)
	assert_true(scene.room_view.stage.position.x < stage_before.x - 50, "dragging moved the view")
	assert_false(scene.closeup.is_open(), "a drag doesn't open the door")
	at = target.get_global_rect().get_center()
	_mouse(vp, at, true)
	_mouse(vp, at, false)
	assert_true(scene.closeup.is_open(), "a tap still opens it")
	scene.queue_free()
	await tree.process_frame


func _mouse(vp: Viewport, at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	e.global_position = at
	vp.push_input(e, true)
