class_name RoomView
extends Node2D
## Draws a room from res://data/rooms/<id>.json: sunrise sky, view outside, balcony, room background,
## furniture and sunbeams. The 1920x1080 stage is centred in the viewport; `sunrise_t` drives all lighting.

const STAGE_SIZE := Vector2(1920, 1080)
const SPRITES_DIR := "res://assets/sprites/"
const BG_OFFSET := Vector2(-240, -180)

## Lighting keyframes for t = 0, 0.5, 1.
const ROOM_TINT: Array[Color] = [Color(0.56, 0.53, 0.74), Color(0.86, 0.79, 0.86), Color(1.0, 0.98, 0.95)]
const FAR_TINT: Array[Color] = [Color(0.13, 0.11, 0.26), Color(0.33, 0.27, 0.45), Color(0.47, 0.49, 0.66)]
const GULL_TINT: Array[Color] = [Color(0.16, 0.14, 0.3), Color(0.3, 0.26, 0.42), Color(0.36, 0.34, 0.48)]

signal furniture_pressed(furniture_id: String)

@export var sunrise_t: float = 0.0:
	set(value):
		sunrise_t = value
		_apply_lighting()

var room_id: String = ""
var room: Dictionary = {}
var stage: Node2D
var sky: SkyBackdrop
var room_layer: Node2D
## Where level props (safes, notes, boxes...) are added by the level scene.
var props_layer: Node2D
var furniture_nodes: Dictionary = {}

var _view_far: Sprite2D
var _balcony: Sprite2D
var _light: Sprite2D
var _gulls: Node2D
var _sunrise_tween: Tween


func _ready() -> void:
	get_viewport().size_changed.connect(_center_stage)
	_center_stage()


## Builds the room. Call once after adding to the tree (or before; it works either way).
func setup(id: String) -> void:
	room_id = id
	room = Data.get_dict("rooms/" + id)
	if room.is_empty():
		push_error("RoomView: no room data for '%s'" % id)
		return
	for child in get_children():
		child.queue_free()
	furniture_nodes.clear()

	stage = Node2D.new()
	stage.name = "Stage"
	add_child(stage)

	sky = SkyBackdrop.new()
	sky.name = "Sky"
	sky.position = Vector2(-800, -600)
	sky.size = Vector2(3520, 2280)
	sky.horizon_y = float(room.get("horizon_y", 450))
	sky.sun_x = float(room.get("sun_x", 960))
	stage.add_child(sky)

	_gulls = Node2D.new()
	_gulls.name = "Gulls"
	stage.add_child(_gulls)
	_spawn_gulls()

	_view_far = _make_layer(str(room.get("view_far", "")), "ViewFar")
	_balcony = _make_layer(str(room.get("balcony", "")), "Balcony")

	room_layer = Node2D.new()
	room_layer.name = "Room"
	stage.add_child(room_layer)
	var bg := _sprite(str(room.get("background", "")))
	if bg:
		bg.name = "Background"
		bg.position = BG_OFFSET
		room_layer.add_child(bg)

	var furniture: Array = room.get("furniture", [])
	for f: Dictionary in furniture:
		var node := _sprite(str(f.get("sprite", "")))
		if node == null:
			continue
		node.name = str(f.get("id", "furniture"))
		var pos: Array = f.get("pos", [0, 0])
		node.position = Vector2(float(pos[0]), float(pos[1]))
		room_layer.add_child(node)
		furniture_nodes[str(f.get("id", ""))] = node

	props_layer = Node2D.new()
	props_layer.name = "Props"
	room_layer.add_child(props_layer)

	_light = _make_layer(str(room.get("light", "")), "Light")
	if _light:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_light.material = mat
		stage.move_child(_light, stage.get_child_count() - 1)

	_center_stage()
	_apply_lighting()


## Smoothly animates the sunrise to `target` over `seconds`.
func animate_sunrise_to(target: float, seconds: float = 2.5) -> void:
	if _sunrise_tween and _sunrise_tween.is_valid():
		_sunrise_tween.kill()
	if bool(SaveManager.settings.get("reduce_motion", false)):
		seconds = minf(seconds, 0.4)
	_sunrise_tween = create_tween()
	_sunrise_tween.tween_property(self, "sunrise_t", target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Converts a viewport position (e.g. from a touch) into stage coordinates.
func to_stage(viewport_pos: Vector2) -> Vector2:
	return stage.get_global_transform_with_canvas().affine_inverse() * viewport_pos if stage else viewport_pos


func _make_layer(path: String, node_name: String) -> Sprite2D:
	if path == "":
		return null
	var s := _sprite(path)
	if s == null:
		return null
	s.name = node_name
	s.position = BG_OFFSET
	stage.add_child(s)
	return s


func _sprite(path: String) -> Sprite2D:
	if path == "":
		return null
	var full := SPRITES_DIR + path
	if not ResourceLoader.exists(full):
		push_error("RoomView: missing sprite %s" % full)
		return null
	var s := Sprite2D.new()
	s.texture = load(full) as Texture2D
	s.centered = false
	return s


func _spawn_gulls() -> void:
	var tex := load(SPRITES_DIR + "sky/gull.svg") as Texture2D
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(room_id)
	for i in 3:
		var g := Sprite2D.new()
		g.texture = tex
		g.scale = Vector2.ONE * rng.randf_range(0.5, 0.9)
		g.position = Vector2(rng.randf_range(600, 1300), rng.randf_range(250, 380))
		_gulls.add_child(g)
		_fly(g, rng.randf_range(38.0, 60.0), rng.randf())


func _fly(g: Sprite2D, seconds: float, phase: float) -> void:
	const START_X := 380.0
	const END_X := 1800.0
	g.position.x = lerpf(START_X, END_X, phase)
	var first := g.create_tween()
	first.tween_property(g, "position:x", END_X, seconds * (1.0 - phase))
	first.finished.connect(func() -> void:
		g.position.x = START_X
		var loop := g.create_tween().set_loops()
		loop.tween_property(g, "position:x", END_X, seconds)
		loop.tween_callback(func() -> void: g.position.x = START_X))
	var bob := g.create_tween().set_loops()
	bob.tween_property(g, "position:y", g.position.y - 14.0, 2.2).set_trans(Tween.TRANS_SINE)
	bob.tween_property(g, "position:y", g.position.y, 2.2).set_trans(Tween.TRANS_SINE)


func _apply_lighting() -> void:
	if sky == null:
		return
	var t := clampf(sunrise_t, 0.0, 1.0)
	sky.sunrise_t = sunrise_t
	room_layer.modulate = _ramp(ROOM_TINT, t)
	if _balcony:
		_balcony.modulate = _ramp(ROOM_TINT, t).lerp(Color(0.8, 0.8, 0.95), 0.15)
	if _view_far:
		_view_far.modulate = _ramp(FAR_TINT, t)
	_gulls.modulate = _ramp(GULL_TINT, t)
	_gulls.modulate.a = smoothstep(0.1, 0.5, t)
	if _light:
		_light.modulate.a = smoothstep(0.3, 1.0, t) * 0.38


func _center_stage() -> void:
	if stage == null or not is_inside_tree():
		return
	var vp := get_viewport().get_visible_rect().size
	stage.position = ((vp - STAGE_SIZE) / 2.0).floor()


static func _ramp(colors: Array[Color], t: float) -> Color:
	if t <= 0.5:
		return colors[0].lerp(colors[1], t * 2.0)
	return colors[1].lerp(colors[2], t * 2.0 - 1.0)
