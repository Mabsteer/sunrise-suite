extends LockWidget
## Chloé's locks, seen through Juliette's eyes. Nothing here says what Chloé can do: she's sent by
## tapping her and then a spot (see LevelScene.send_chloe), and she's given things by selecting
## them and tapping her. The one card left is her hiding place: something shuffles in the dark,
## and you can hold something out to it (select an item, tap the card).


func _build() -> void:
	var t := str(lock.get("type", ""))
	if t == "care" and bool(lock.get("finds_dog", false)):
		var target := Button.new()
		target.focus_mode = Control.FOCUS_NONE
		target.custom_minimum_size = Vector2(420, 220)
		target.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		target.add_theme_stylebox_override("normal", UIKit.box(Palette.color("indigo_deep"), 28, Palette.color("wood_dark"), 4, 16))
		target.add_theme_stylebox_override("hover", UIKit.box(Palette.color("indigo"), 28, Palette.color("wood_dark"), 4, 16))
		target.add_theme_stylebox_override("pressed", UIKit.box(Palette.color("indigo"), 28, Palette.color("wood_dark"), 4, 16))
		target.pressed.connect(func() -> void: use_requested.emit())
		add_child(target)
		_add_text(tr("DOG_HIDING"))
		_add_text(tr("USE_ITEM_HELP"), 28, Palette.color("ink_soft"))
		return
	_add_text(tr("NOTHING_SPECIAL"))


func _add_text(message: String, size: int = 34, color: Color = Palette.color("ink")) -> void:
	var l := UIKit.label(message, size, color)
	l.custom_minimum_size.x = 780
	add_child(l)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("item") and bool(lock.get("finds_dog", false))


func _drop_data(_at: Vector2, _data: Variant) -> void:
	use_requested.emit()
