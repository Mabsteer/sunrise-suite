extends LockWidget
## Order lock: things stand in the wrong order. Tap two of them to swap them, then "Open".
## The note with the logic statements says which order is right.

var _order: Array[String] = []
var _slots: Array[Button] = []
var _picked := -1


func _build() -> void:
	var answer := str(lock.get("answer", "")).split(",")
	for s in answer:
		_order.append(s)
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var guard := 0
	while ",".join(_order) == ",".join(answer) and guard < 20:
		guard += 1
		for i in range(_order.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := _order[i]
			_order[i] = _order[j]
			_order[j] = tmp
	add_child(UIKit.label(tr("ORDER_HELP"), 30, Palette.color("ink_soft")))
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", brass_plate(22))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	plate.add_child(row)
	for i in _order.size():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		row.add_child(col)
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 170)
		b.focus_mode = Control.FOCUS_NONE
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.pressed.connect(_tap.bind(i))
		col.add_child(b)
		_slots.append(b)
		col.add_child(UIKit.label(str(i + 1), 26, Palette.color("cream")))
	var open := make_button(tr("LOCK_OPEN"))
	open.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	open.pressed.connect(func() -> void: submitted.emit(answer_text()))
	add_child(open)
	_refresh()


func answer_text() -> String:
	return ",".join(_order)


## Puts the things in a given order (used by tests and the autoplay bot).
func set_answer(order: String) -> void:
	var parts := order.split(",")
	if parts.size() == _order.size():
		for i in parts.size():
			_order[i] = parts[i]
		_refresh()


func _tap(i: int) -> void:
	if _picked == -1:
		_picked = i
		AudioManager.play_sfx("ui_click", 0.05)
	elif _picked == i:
		_picked = -1
	else:
		var tmp := _order[i]
		_order[i] = _order[_picked]
		_order[_picked] = tmp
		_picked = -1
		AudioManager.play_sfx("slider_move", 0.1)
	_refresh()


func _refresh() -> void:
	var symbols := Data.get_dict("symbols")
	for i in _slots.size():
		var b := _slots[i]
		b.icon = UIKit.texture(str((symbols.get(_order[i], {}) as Dictionary).get("sprite", "")))
		b.tooltip_text = text.symbol_name(_order[i]) if text else _order[i]
		var picked := i == _picked
		var sb := UIKit.box(Palette.color("peach_light") if picked else Palette.color("cream"), 26,
			Palette.color("coral") if picked else Palette.color("wood_light"), 6 if picked else 4, 16)
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(state, sb)
