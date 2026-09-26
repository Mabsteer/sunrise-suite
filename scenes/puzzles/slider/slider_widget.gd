extends LockWidget
## Sliding-tile picture puzzle. Tap a tile next to the gap to slide it. Solving emits "solved".

const BOARD_PX := 480.0

var _n := 3
var _tiles: Array[int] = []   # _tiles[cell] = tile number, -1 = gap
var _buttons: Array[TextureButton] = []
var _textures: Array[Texture2D] = []
var _grid: GridContainer
var _done := false


func _build() -> void:
	_n = clampi(int(config().get("size", 3)), 2, 5)
	var picture := UIKit.texture(str(config().get("picture", "puzzles/slider_sunrise.svg")))
	var cell_src := (picture.get_size().x / _n) if picture else 100.0
	for i in _n * _n:
		var at := AtlasTexture.new()
		at.atlas = picture
		at.region = Rect2((i % _n) * cell_src, (i / _n) * cell_src, cell_src, cell_src)
		_textures.append(at)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", brass_plate(16))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(plate)
	_grid = GridContainer.new()
	_grid.columns = _n
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	plate.add_child(_grid)
	var cell := BOARD_PX / _n
	for i in _n * _n:
		var b := TextureButton.new()
		b.custom_minimum_size = Vector2(cell, cell)
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.pressed.connect(_tap.bind(i))
		_grid.add_child(b)
		_buttons.append(b)
	_scramble()
	_refresh()


## Solved layout: tile k in cell k, gap in the last cell. Scramble with legal moves so it is always solvable.
func _scramble() -> void:
	_tiles.clear()
	for i in _n * _n - 1:
		_tiles.append(i)
	_tiles.append(-1)
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var moves := int(config().get("scramble", 20 * _n))
	var prev := -1
	var done := 0
	var guard := 0
	while (done < moves or _is_solved()) and guard < 2000:
		guard += 1
		var gap := _tiles.find(-1)
		var options := _neighbours(gap).filter(func(c: int) -> bool: return c != prev)
		var pick: int = options[rng.randi_range(0, options.size() - 1)]
		_tiles[gap] = _tiles[pick]
		_tiles[pick] = -1
		prev = gap
		done += 1


func _neighbours(cell: int) -> Array[int]:
	var out: Array[int] = []
	var r := cell / _n
	var c := cell % _n
	if r > 0:
		out.append(cell - _n)
	if r < _n - 1:
		out.append(cell + _n)
	if c > 0:
		out.append(cell - 1)
	if c < _n - 1:
		out.append(cell + 1)
	return out


func _tap(cell: int) -> void:
	if _done:
		return
	var gap := _tiles.find(-1)
	if not _neighbours(gap).has(cell):
		return
	_tiles[gap] = _tiles[cell]
	_tiles[cell] = -1
	AudioManager.play_sfx("lock_digit", 0.1)
	_refresh()
	if _is_solved():
		_done = true
		_buttons[_n * _n - 1].texture_normal = _textures[_n * _n - 1]
		submitted.emit("solved")


func _is_solved() -> bool:
	for i in _n * _n - 1:
		if _tiles[i] != i:
			return false
	return true


func _refresh() -> void:
	for i in _tiles.size():
		var t := _tiles[i]
		_buttons[i].texture_normal = _textures[t] if t >= 0 else null
		_buttons[i].modulate = Color.WHITE if t >= 0 else Color(1, 1, 1, 0)


## Test/bot helper: puts every tile in place (as if the player solved it).
func solve_instantly() -> void:
	for i in _n * _n - 1:
		_tiles[i] = i
	_tiles[_n * _n - 1] = -1
	_refresh()
	_done = true
	submitted.emit("solved")
