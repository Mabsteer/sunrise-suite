class_name InventoryBar
extends PanelContainer
## Bottom bar with the items you carry.
##  - tap an item: select it (then tap something in the room to use it)
##  - tap the selected item again: look at it
##  - with one selected, tap another: combine them (or drag one onto the other)

signal item_tapped(item_id: String)
signal combine_requested(a: String, b: String)
signal inspect_requested(item_id: String)

const SLOT := 112.0

var selected := ""
var _row: HBoxContainer
var _slots: Dictionary = {}
var _text: LevelText
var _empty_label: Label


func setup(level_text: LevelText) -> void:
	_text = level_text
	add_theme_stylebox_override("panel", UIKit.card(14))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(SLOT * 8 + 7 * 10, SLOT + 8)
	add_child(scroll)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 10)
	scroll.add_child(_row)
	_empty_label = UIKit.label(tr("INVENTORY_EMPTY"), 28, Palette.color("ink_soft"))
	_empty_label.custom_minimum_size = Vector2(SLOT * 8, SLOT)
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_row.add_child(_empty_label)


func add_item(item_id: String, from_global: Vector2 = Vector2.INF) -> void:
	if _slots.has(item_id):
		return
	_empty_label.visible = false
	var slot := ItemSlot.new()
	slot.item_id = item_id
	slot.bar = self
	slot.custom_minimum_size = Vector2(SLOT, SLOT)
	slot.icon = UIKit.texture(str(_text.item_type_data(item_id).get("sprite", "")))
	slot.expand_icon = true
	slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.focus_mode = Control.FOCUS_NONE
	slot.tooltip_text = _text.item_name(item_id)
	slot.pressed.connect(_on_slot_pressed.bind(item_id))
	_row.add_child(slot)
	_slots[item_id] = slot
	_style(slot, false)
	if from_global != Vector2.INF and not bool(SaveManager.settings.get("reduce_motion", false)):
		_fly_in(slot, from_global)
	else:
		UIKit.pop_in(slot)


func remove_item(item_id: String) -> void:
	if not _slots.has(item_id):
		return
	var slot: Control = _slots[item_id]
	_slots.erase(item_id)
	if selected == item_id:
		selected = ""
	slot.queue_free()
	_empty_label.visible = _slots.is_empty()


func select(item_id: String) -> void:
	selected = item_id
	for id: String in _slots.keys():
		_style(_slots[id], id == item_id)


func deselect() -> void:
	select("")


func has_item(item_id: String) -> bool:
	return _slots.has(item_id)


func slot_global_center(item_id: String) -> Vector2:
	if not _slots.has(item_id):
		return global_position + size / 2.0
	var s: Control = _slots[item_id]
	return s.global_position + s.size / 2.0


func _on_slot_pressed(item_id: String) -> void:
	AudioManager.play_sfx("ui_click")
	if selected == "":
		select(item_id)
		item_tapped.emit(item_id)
	elif selected == item_id:
		inspect_requested.emit(item_id)
	else:
		combine_requested.emit(selected, item_id)


func _style(slot: Button, is_selected: bool) -> void:
	var bg := Palette.color("peach_light") if is_selected else Palette.color("cream")
	var border := Palette.color("coral") if is_selected else Palette.color("sand")
	var sb := UIKit.box(bg, 22, border, 5 if is_selected else 3, 10)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		slot.add_theme_stylebox_override(state, sb)


func _fly_in(slot: Control, from_global: Vector2) -> void:
	# A ghost icon flies from where the item was to its slot.
	slot.modulate.a = 0.0
	var ghost := TextureRect.new()
	ghost.texture = (slot as Button).icon
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.size = Vector2(SLOT, SLOT)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.top_level = true
	add_child(ghost)
	ghost.global_position = from_global - ghost.size / 2.0
	await get_tree().process_frame
	var target := slot.global_position
	var t := ghost.create_tween().set_parallel(true)
	t.tween_property(ghost, "global_position", target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(ghost, "scale", Vector2(1.15, 1.15), 0.2)
	t.chain().tween_callback(func() -> void:
		ghost.queue_free()
		if is_instance_valid(slot):
			slot.modulate.a = 1.0
			UIKit.pop_in(slot, 0.15))


## One inventory slot. Supports drag-and-drop combining.
class ItemSlot extends Button:
	var item_id := ""
	var bar: InventoryBar

	func _get_drag_data(_at: Vector2) -> Variant:
		bar.select(item_id)
		var preview := TextureRect.new()
		preview.texture = icon
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = Vector2(96, 96)
		preview.modulate.a = 0.85
		set_drag_preview(preview)
		return {"item": item_id}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and (data as Dictionary).has("item") and str(data["item"]) != item_id

	func _drop_data(_at: Vector2, data: Variant) -> void:
		bar.combine_requested.emit(str(data["item"]), item_id)
