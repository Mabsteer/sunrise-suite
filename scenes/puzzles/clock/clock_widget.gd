extends LockWidget
## Clock lock: set the hour and minute hands, then press "Set the time".

var _hour := 12
var _minute := 0
var _face: ClockFace
var _readout: Label


class ClockFace extends Control:
	var hour := 12
	var minute := 0
	var _hands: Hands

	func _init() -> void:
		custom_minimum_size = Vector2(380, 380)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face := TextureRect.new()
		face.texture = UIKit.texture("puzzles/clock_face.svg")
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(face)
		_hands = Hands.new()
		_hands.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_hands.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_hands)

	func update_hands() -> void:
		_hands.hour = hour
		_hands.minute = minute
		_hands.queue_redraw()


class Hands extends Control:
	var hour := 12
	var minute := 0

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		var minute_angle := TAU * minute / 60.0
		var hour_angle := TAU * ((hour % 12) + minute / 60.0) / 12.0
		_hand(c, hour_angle, r * 0.46, 16.0, Palette.color("ink"))
		_hand(c, minute_angle, r * 0.68, 10.0, Palette.color("ink_soft"))
		draw_circle(c, 14.0, Palette.color("coral"))
		draw_circle(c, 5.0, Palette.color("gold_light"))

	func _hand(c: Vector2, angle: float, length: float, width: float, color: Color) -> void:
		var tip := c + Vector2(sin(angle), -cos(angle)) * length
		draw_line(c, tip, color, width, true)
		draw_circle(tip, width / 2.0, color)


func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 36)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	_face = ClockFace.new()
	row.add_child(_face)
	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 14)
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(controls)
	_readout = UIKit.label("12:00", 72, Palette.color("ink"))
	controls.add_child(_readout)
	controls.add_child(_stepper(tr("CLOCK_HOURS"), func(d: int) -> void: _hour = posmod(_hour - 1 + d, 12) + 1))
	controls.add_child(_stepper(tr("CLOCK_MINUTES"), func(d: int) -> void: _minute = posmod(_minute + d * 5, 60)))
	var set_button := make_button(tr("CLOCK_SET"))
	set_button.pressed.connect(func() -> void: submitted.emit(answer()))
	add_child(set_button)
	set_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_refresh()


func answer() -> String:
	return "%d:%02d" % [_hour, _minute]


func set_answer(time: String) -> void:
	var parts := time.split(":")
	if parts.size() == 2:
		_hour = clampi(int(parts[0]), 1, 12)
		_minute = posmod(int(parts[1]), 60)
		_refresh()


func _stepper(caption: String, change: Callable) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var down := UIKit.icon_button("ui/arrow_down.svg", 88)
	var up := UIKit.icon_button("ui/arrow_up.svg", 88)
	var l := UIKit.label(caption, 30, Palette.color("ink_soft"))
	l.custom_minimum_size.x = 150
	down.pressed.connect(func() -> void:
		change.call(-1)
		_refresh())
	up.pressed.connect(func() -> void:
		change.call(1)
		_refresh())
	box.add_child(down)
	box.add_child(l)
	box.add_child(up)
	return box


func _refresh() -> void:
	_readout.text = answer()
	_face.hour = _hour
	_face.minute = _minute
	_face.update_hands()
	AudioManager.play_sfx("lock_digit", 0.1, -6.0)
