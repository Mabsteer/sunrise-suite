extends LockWidget
## "What comes next?": a row of numbers or symbols with gaps. Tap a gap, then fill it in with the
## number pad (numbers) or the symbol buttons (symbols), then "Open".

const SYMBOL_ORDER: PackedStringArray = ["sun", "shell", "wave", "star", "leaf", "heart"]

var _kind := "numbers"
var _terms: Array = []
var _blanks: Array[int] = []
var _values: Dictionary = {}
var _gap_buttons: Dictionary = {}
var _selected := -1


func _build() -> void:
	_kind = str(config().get("kind", "numbers"))
	_terms = config().get("terms", [])
	for b: Variant in config().get("blanks", []):
		_blanks.append(int(b))
	add_child(UIKit.label(tr("PATTERN_HELP"), 30, Palette.color("ink_soft")))
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", brass_plate(18))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	plate.add_child(row)
	var cell_size := 112.0 if _terms.size() <= 8 else 96.0
	for i in _terms.size():
		if _blanks.has(i):
			var b := Button.new()
			b.custom_minimum_size = Vector2(cell_size, cell_size)
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", 50)
			b.expand_icon = true
			b.pressed.connect(_select.bind(i))
			row.add_child(b)
			_gap_buttons[i] = b
		else:
			var tile := PanelContainer.new()
			tile.add_theme_stylebox_override("panel", UIKit.box(Palette.color("cream"), 16, Palette.color("wood_light"), 3, 6))
			tile.custom_minimum_size = Vector2(cell_size, cell_size)
			row.add_child(tile)
			if _kind == "symbols":
				var icon := TextureRect.new()
				icon.texture = _symbol_texture(str(_terms[i]))
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tile.add_child(icon)
			else:
				var l := UIKit.label(str(_terms[i]), 48, Palette.color("ink"))
				l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				tile.add_child(l)
	var pad := GridContainer.new()
	pad.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pad.add_theme_constant_override("h_separation", 10)
	pad.add_theme_constant_override("v_separation", 10)
	add_child(pad)
	if _kind == "symbols":
		pad.columns = 6
		for key in SYMBOL_ORDER:
			var sb := UIKit.icon_button(str((Data.get_dict("symbols").get(key, {}) as Dictionary).get("sprite", "")), 96, text.symbol_name(key) if text else key)
			sb.pressed.connect(_enter.bind(key))
			pad.add_child(sb)
	else:
		pad.columns = 6
		for d in 10:
			var db := make_button(str(d), 96)
			db.pressed.connect(_enter.bind(str(d)))
			pad.add_child(db)
		var back := make_button("<", 96)
		back.pressed.connect(_erase)
		pad.add_child(back)
	var open := make_button(tr("LOCK_OPEN"))
	open.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	open.pressed.connect(func() -> void: submitted.emit(answer()))
	add_child(open)
	if not _blanks.is_empty():
		_select(_blanks[0])


func answer() -> String:
	var out: PackedStringArray = []
	for b in _blanks:
		out.append(str(_values.get(b, "")))
	return ",".join(out)


## Fills in the gaps (used by tests and the autoplay bot).
func set_answer(value: String) -> void:
	var parts := value.split(",")
	for i in mini(parts.size(), _blanks.size()):
		_values[_blanks[i]] = parts[i]
	_refresh()


func _select(i: int) -> void:
	_selected = i
	AudioManager.play_sfx("ui_click", 0.05)
	_refresh()


func _enter(v: String) -> void:
	if _selected < 0:
		return
	if _kind == "symbols":
		_values[_selected] = v
		AudioManager.play_sfx("note_" + v)
		var at := _blanks.find(_selected)
		if at >= 0 and at < _blanks.size() - 1:
			_selected = _blanks[at + 1]
	else:
		var cur := str(_values.get(_selected, ""))
		if cur.length() < 3:
			_values[_selected] = cur + v
		AudioManager.play_sfx("lock_digit", 0.08)
	_refresh()


func _erase() -> void:
	if _selected >= 0:
		var cur := str(_values.get(_selected, ""))
		_values[_selected] = cur.substr(0, maxi(cur.length() - 1, 0))
		_refresh()


func show_wrong() -> void:
	super.show_wrong()


func _refresh() -> void:
	for i: int in _gap_buttons.keys():
		var b: Button = _gap_buttons[i]
		var v := str(_values.get(i, ""))
		var selected := i == _selected
		var sb := UIKit.box(Palette.color("peach_light") if selected else Palette.color("white_warm"), 16,
			Palette.color("coral") if selected else Palette.color("wood_light"), 6 if selected else 3, 6)
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(state, sb)
		if _kind == "symbols":
			b.icon = _symbol_texture(v) if v != "" else null
			b.text = "" if v != "" else "?"
		else:
			b.text = v if v != "" else "?"


func _symbol_texture(key: String) -> Texture2D:
	return UIKit.texture(str((Data.get_dict("symbols").get(key, {}) as Dictionary).get("sprite", "")))
