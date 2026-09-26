extends LockWidget
## Key locks and hidden spots that need a tool. Tap the plate (or drop an item on it) with an item selected.

const TOOL_TEXT := {
	"flashlight": "TOOL_TEXT_FLASHLIGHT",
	"trowel": "TOOL_TEXT_TROWEL",
	"screwdriver": "TOOL_TEXT_SCREWDRIVER",
	"fishing_magnet": "TOOL_TEXT_MAGNET",
}

var _target: Button


func _build() -> void:
	var is_key := str(lock.get("type", "")) == "key"
	_target = Button.new()
	_target.focus_mode = Control.FOCUS_NONE
	_target.custom_minimum_size = Vector2(300, 330) if is_key else Vector2(420, 300)
	_target.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_target.icon = UIKit.texture("puzzles/keyhole.svg") if is_key else _host_texture()
	_target.expand_icon = true
	_target.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target.pressed.connect(func() -> void: use_requested.emit())
	add_child(_target)
	var message := ""
	if is_key:
		message = tr("KEY_TEXT")
	else:
		var tool_type := str(text.session.items.get(text.session.lock_item(str(lock["id"])), {}).get("type", "")) if text else ""
		message = tr(TOOL_TEXT.get(tool_type, "TOOL_TEXT_GENERIC"))
	var l := UIKit.label(message, 34, Palette.color("ink"))
	l.custom_minimum_size.x = 760
	add_child(l)
	var help := UIKit.label(tr("USE_ITEM_HELP"), 28, Palette.color("ink_soft"))
	help.custom_minimum_size.x = 760
	add_child(help)


func _host_texture() -> Texture2D:
	var host: Dictionary = lock.get("host", {})
	if str(host.get("kind", "")) == "prop":
		var prop: Dictionary = Data.get_dict("props").get(str(host.get("prop", "")), {})
		return UIKit.texture(str(prop.get("sprite", "")))
	if str(host.get("kind", "")) == "furniture" and text:
		return UIKit.texture(str(text.furniture(str(host.get("furniture", ""))).get("sprite", "")))
	return UIKit.texture("ui/sparkle.svg")


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("item")


## The level uses the selected item; InventoryBar selects the item when a drag starts.
func _drop_data(_at: Vector2, _data: Variant) -> void:
	use_requested.emit()
