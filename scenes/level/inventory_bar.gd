class_name InventoryBar
extends PanelContainer
## Bottom bar with the items you carry.
##  - tap an item: select it (then tap something in the room to use it)
##  - tap the selected item again: look at it
##  - with one selected, tap another: combine them (or drag one onto the other)
##  - the bag button folds the bar away (it peeks open when something new goes in)
## It's see-through while you're not using it, so the room behind it stays visible.

signal item_tapped(item_id: String)
signal combine_requested(a: String, b: String)
signal inspect_requested(item_id: String)

const SLOT := 112.0
const VISIBLE_SLOTS := 6
## How long the folded-away bar stays open after something new goes in.
const PEEK_SECONDS := 4.0
const IDLE_ALPHA := 0.55

var selected := ""
## Folded away: only the bag button shows.
var collapsed := false
var _row: HBoxContainer
var _slots: Dictionary = {}
var _text: LevelText
var _empty_label: Label
var _scroll: ScrollContainer
var _bag: Button
var _show_empty_text := false
var _hovered := false
var _peeking := false
var _idle_box: StyleBoxFlat
var _active_box: StyleBoxFlat


## show_empty_text: the "Things you pick up will appear here" line (only in the tutorial).
func setup(level_text: LevelText, show_empty_text: bool = false) -> void:
	_text = level_text
	_show_empty_text = show_empty_text
	_active_box = UIKit.card(14)
	_idle_box = _active_box.duplicate() as StyleBoxFlat
	_idle_box.bg_color.a = IDLE_ALPHA
	_idle_box.border_color.a = IDLE_ALPHA
	_idle_box.shadow_color.a *= 0.3
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	add_child(h)
	_bag = UIKit.icon_button("ui/bag.svg", SLOT, tr("BAG"))
	_bag.name = "Bag"
	_bag.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		set_collapsed(not collapsed, true))
	h.add_child(_bag)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(SLOT * VISIBLE_SLOTS + (VISIBLE_SLOTS - 1) * 10, SLOT + 8)
	h.add_child(_scroll)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 10)
	_scroll.add_child(_row)
	_empty_label = UIKit.label(tr("INVENTORY_EMPTY"), 28, Palette.color("ink_soft"))
	_empty_label.custom_minimum_size = Vector2(SLOT * VISIBLE_SLOTS, SLOT)
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_row.add_child(_empty_label)
	mouse_entered.connect(func() -> void:
		_hovered = true
		_update_look())
	mouse_exited.connect(func() -> void:
		_hovered = false
		_update_look())
	collapsed = bool(SaveManager.settings.get("bag_collapsed", false))
	_update_look()


## Folds the bar away (just the bag button) or opens it. `remember`: keep it that way in later rooms.
func set_collapsed(on: bool, remember: bool = false) -> void:
	collapsed = on
	_peeking = false
	if remember:
		SaveManager.settings["bag_collapsed"] = on
		SaveManager.save_settings()
	_update_look()


## Opens the folded-away bar for a few seconds (something new went in), then folds it again.
func peek() -> void:
	if not collapsed or not is_inside_tree():
		return
	_peeking = true
	_update_look()
	await get_tree().create_timer(PEEK_SECONDS).timeout
	if _peeking and selected == "":
		_peeking = false
		_update_look()


## True while the items are showing (not folded away).
func is_open() -> bool:
	return not collapsed or _peeking


func add_item(item_id: String, from_global: Vector2 = Vector2.INF) -> void:
	if _slots.has(item_id):
		return
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
	_update_look()
	peek()
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
	_update_look()


func select(item_id: String) -> void:
	selected = item_id
	for id: String in _slots.keys():
		_style(_slots[id], id == item_id)
	_update_look()


func deselect() -> void:
	select("")


func _update_look() -> void:
	if _scroll == null:
		return
	var empty := _slots.is_empty()
	_empty_label.visible = empty and _show_empty_text
	_scroll.visible = is_open() and not (empty and not _show_empty_text)
	var active := _hovered or selected != ""
	add_theme_stylebox_override("panel", _active_box if active else _idle_box)


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
	if not is_instance_valid(slot) or not is_instance_valid(ghost):
		# The item was used up right away (the bar was rebuilt): no flight.
		if is_instance_valid(ghost):
			ghost.queue_free()
		return
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
