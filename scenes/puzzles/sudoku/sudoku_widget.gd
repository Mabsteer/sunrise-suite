extends LockWidget
## A 4x4 number square. Tap an empty square to cycle 1, 2, 3, 4, empty. Every row, column and 2x2 box
## needs 1-4 once. Shaded squares (config "shaded") are the ones a note may ask you to read afterwards.
## When every square is filled, the answer is checked.

const CELL := 104.0

var _values: Array[int] = []
var _givens := ""
var _cells: Array[Button] = []
var _done := false


func _build() -> void:
	_givens = str(config().get("givens", "................"))
	for i in 16:
		_values.append(0 if _givens[i] == "." else int(_givens[i]))
	add_child(UIKit.label(tr("SUDOKU_HELP"), 30, Palette.color("ink_soft")))
	add_child(_grid(false))
	var clear := make_button(tr("LOCK_CLEAR"), 220)
	clear.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clear.pressed.connect(_clear)
	add_child(clear)


## Shows the finished square, read-only (after it is solved, so its shaded squares can be read).
func setup_solved(lock_data: Dictionary) -> void:
	lock = lock_data
	var answer_str := str(lock.get("answer", ""))
	_givens = str(config().get("givens", ""))
	_values.clear()
	for i in 16:
		_values.append(int(answer_str[i]) if answer_str.length() == 16 else 0)
	_done = true
	add_child(_grid(true))


func _grid(read_only: bool) -> Control:
	var shaded: Array = config().get("shaded", [])
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", brass_plate(14))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var boxes := GridContainer.new()
	boxes.columns = 2
	boxes.add_theme_constant_override("h_separation", 12)
	boxes.add_theme_constant_override("v_separation", 12)
	plate.add_child(boxes)
	_cells.clear()
	_cells.resize(16)
	for box in 4:
		var g := GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 4)
		g.add_theme_constant_override("v_separation", 4)
		boxes.add_child(g)
		for k in 4:
			var cell := ((box / 2) * 2 + k / 2) * 4 + (box % 2) * 2 + k % 2
			var b := Button.new()
			var cell_px := CELL * (0.68 if read_only else 1.0)
			b.custom_minimum_size = Vector2(cell_px, cell_px)
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", int(cell_px * 0.54))
			var given := _givens.length() == 16 and _givens[cell] != "."
			var bg := Palette.color("sand") if given else Palette.color("white_warm")
			if shaded.has(cell) or shaded.has(float(cell)):
				bg = Palette.color("lavender_light")
			var sb := UIKit.box(bg, 12, Palette.color("wood_light"), 2, 4)
			for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
				b.add_theme_stylebox_override(state, sb)
			b.add_theme_color_override("font_color", Palette.color("ink") if given else Palette.color("sea_deep"))
			b.add_theme_color_override("font_disabled_color", Palette.color("ink") if given else Palette.color("sea_deep"))
			b.disabled = given or read_only
			if not b.disabled:
				b.pressed.connect(_tap.bind(cell))
			g.add_child(b)
			_cells[cell] = b
	_refresh()
	return plate


func _tap(cell: int) -> void:
	if _done:
		return
	_values[cell] = (_values[cell] + 1) % 5
	AudioManager.play_sfx("lock_digit", 0.08)
	_refresh()
	if not _values.has(0):
		submitted.emit(answer())


func answer() -> String:
	var s := ""
	for v in _values:
		s += str(v)
	return s


func show_wrong() -> void:
	super.show_wrong()


## Test/bot helper: fills in the whole square correctly.
func solve_instantly() -> void:
	var answer_str := str(lock.get("answer", ""))
	for i in mini(16, answer_str.length()):
		_values[i] = int(answer_str[i])
	_refresh()
	_done = true
	submitted.emit(answer())


func _clear() -> void:
	for i in 16:
		if _givens[i] == ".":
			_values[i] = 0
	_refresh()


func _refresh() -> void:
	for i in _cells.size():
		if _cells[i]:
			_cells[i].text = str(_values[i]) if _values[i] > 0 else ""
