extends LockWidget
## Number lock: a brass plate with digit wheels (tap the arrows) and an "Open" button.

var _digits: Array[int] = []
var _labels: Array[Label] = []


func _build() -> void:
	var count := int(config().get("digits", str(lock.get("answer", "000")).length()))
	_digits.resize(count)
	_digits.fill(0)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", brass_plate())
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	plate.add_child(row)
	for i in count:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		row.add_child(col)
		var up := UIKit.icon_button("ui/arrow_up.svg", 92)
		up.pressed.connect(_change.bind(i, 1))
		col.add_child(up)
		var window := PanelContainer.new()
		window.add_theme_stylebox_override("panel", UIKit.box(Palette.color("ink"), 14, Palette.color("brass_dark"), 4, 6))
		window.custom_minimum_size = Vector2(92, 118)
		col.add_child(window)
		var digit := UIKit.label("0", 84, Palette.color("cream"))
		digit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		window.add_child(digit)
		_labels.append(digit)
		var down := UIKit.icon_button("ui/arrow_down.svg", 92)
		down.pressed.connect(_change.bind(i, -1))
		col.add_child(down)
	var open := make_button(tr("LOCK_OPEN"))
	open.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	open.pressed.connect(func() -> void: submitted.emit(answer()))
	add_child(open)


func answer() -> String:
	var s := ""
	for d in _digits:
		s += str(d)
	return s


## Sets all digits at once (used by tests and the autoplay bot).
func set_answer(code: String) -> void:
	for i in mini(code.length(), _digits.size()):
		_digits[i] = int(code[i])
		_labels[i].text = str(_digits[i])


func _change(index: int, delta: int) -> void:
	_digits[index] = posmod(_digits[index] + delta, 10)
	_labels[index].text = str(_digits[index])
	AudioManager.play_sfx("lock_digit", 0.08)
