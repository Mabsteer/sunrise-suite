extends LockWidget
## Rotation puzzle: a picture cut into tiles, some turned. Tap a tile to turn it a quarter; when every
## tile is the right way up, it emits "solved".

const BOARD_PX := 480.0

var _n := 2
var _turns: Array[int] = []
var _buttons: Array[TextureButton] = []
var _done := false


func _build() -> void:
	_n = clampi(int(config().get("size", 2)), 2, 4)
	var picture := UIKit.texture(str(config().get("picture", "puzzles/slider_sunrise.svg")))
	var cell_src := (picture.get_size().x / _n) if picture else 100.0
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i in _n * _n:
		_turns.append(rng.randi_range(0, 3))
	# At least half the tiles start turned.
	var need := int(ceil(_n * _n / 2.0))
	var i2 := 0
	while _turns.count(0) > _n * _n - need and i2 < 100:
		_turns[rng.randi_range(0, _n * _n - 1)] = rng.randi_range(1, 3)
		i2 += 1
	add_child(UIKit.label(tr("ROTATE_HELP"), 30, Palette.color("ink_soft")))
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", brass_plate(16))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(plate)
	var grid := GridContainer.new()
	grid.columns = _n
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	plate.add_child(grid)
	var cell := BOARD_PX / _n
	for i in _n * _n:
		var at := AtlasTexture.new()
		at.atlas = picture
		at.region = Rect2((i % _n) * cell_src, (i / _n) * cell_src, cell_src, cell_src)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(cell, cell)
		grid.add_child(holder)
		var b := TextureButton.new()
		b.texture_normal = at
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.size = Vector2(cell, cell)
		b.pivot_offset = Vector2(cell, cell) / 2.0
		b.rotation_degrees = 90.0 * _turns[i]
		b.pressed.connect(_tap.bind(i))
		holder.add_child(b)
		_buttons.append(b)


func _tap(i: int) -> void:
	if _done:
		return
	_turns[i] = (_turns[i] + 1) % 4
	AudioManager.play_sfx("slider_move", 0.1)
	var b := _buttons[i]
	var target := 90.0 * _turns[i]
	if _turns[i] == 0:
		b.rotation_degrees -= 360.0
	if bool(SaveManager.settings.get("reduce_motion", false)):
		b.rotation_degrees = target
	else:
		b.create_tween().tween_property(b, "rotation_degrees", target, 0.15).set_trans(Tween.TRANS_SINE)
	if _turns.count(0) == _turns.size():
		_done = true
		submitted.emit("solved")


## Test/bot helper: turns every tile the right way up.
func solve_instantly() -> void:
	for i in _turns.size():
		_turns[i] = 0
		_buttons[i].rotation_degrees = 0.0
	_done = true
	submitted.emit("solved")
