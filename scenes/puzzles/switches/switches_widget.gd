extends LockWidget
## Light switches: flip switches so the right lamps glow, then pull the chain.

var _symbols: Array = []
var _states: Array[bool] = []
var _lamps: Array[PanelContainer] = []
var _toggles: Array[Button] = []


func _build() -> void:
	_symbols = config().get("symbols", ["sun", "shell", "star", "wave"])
	_states.resize(_symbols.size())
	_states.fill(false)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", brass_plate(26))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	plate.add_child(row)
	var db := Data.get_dict("symbols")
	for i in _symbols.size():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 12)
		row.add_child(col)
		var lamp := PanelContainer.new()
		lamp.custom_minimum_size = Vector2(110, 110)
		col.add_child(lamp)
		var icon := TextureRect.new()
		icon.texture = UIKit.texture(str((db.get(str(_symbols[i]), {}) as Dictionary).get("sprite", "")))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lamp.add_child(icon)
		_lamps.append(lamp)
		var toggle := Button.new()
		toggle.custom_minimum_size = Vector2(110, 96)
		toggle.focus_mode = Control.FOCUS_NONE
		toggle.pressed.connect(_flip.bind(i))
		col.add_child(toggle)
		_toggles.append(toggle)
	var pull := make_button(tr("SWITCHES_PULL"))
	pull.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pull.pressed.connect(func() -> void: submitted.emit(answer()))
	add_child(pull)
	_refresh()


func answer() -> String:
	var s := ""
	for on in _states:
		s += "1" if on else "0"
	return s


func set_answer(pattern: String) -> void:
	for i in mini(pattern.length(), _states.size()):
		_states[i] = pattern[i] == "1"
	_refresh()


func _flip(i: int) -> void:
	_states[i] = not _states[i]
	AudioManager.play_sfx("ui_click", 0.1)
	_refresh()


func _refresh() -> void:
	for i in _states.size():
		var on := _states[i]
		var glow := UIKit.box(Palette.color("gold_light") if on else Palette.color("ink_soft"), 55, Palette.color("gold") if on else Palette.color("ink"), 5, 14)
		if on:
			glow.shadow_color = Color(0.965, 0.769, 0.325, 0.7)
			glow.shadow_size = 22
		_lamps[i].add_theme_stylebox_override("panel", glow)
		_lamps[i].modulate = Color.WHITE if on else Color(0.8, 0.8, 0.85)
		_toggles[i].text = tr("SWITCH_ON") if on else tr("SWITCH_OFF")
