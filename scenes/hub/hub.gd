extends Node2D
## Grandma's penthouse: decorate it with things bought with seashells or earned as rewards.
## Normal mode: tap decor for a little reaction. Decorate mode: tap an empty slot to place/buy,
## tap placed decor to move, flip or put it away. The Catalog lists everything.

const TYPE_ORDER := {"rug": 0, "wall": 1, "table": 2, "floor_small": 3, "floor_large": 3}
const DEFAULT_MAX := {"floor_large": Vector2(470, 440), "floor_small": Vector2(230, 440), "wall": Vector2(260, 260), "table": Vector2(170, 170), "rug": Vector2(820, 170)}

var room_view: RoomView
var ui: CanvasLayer
var decorating := false
var moving_from := ""

var _decor_layer: Node2D
var _spots: Node2D
var _sprites: Dictionary = {}
var _decorate_button: Button
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _counters_holder: Control


func _ready() -> void:
	GameState.ensure_starter_decor()
	room_view = RoomView.new()
	add_child(room_view)
	room_view.setup("hub")
	room_view.sunrise_t = float(room_view.room.get("sunrise", 0.88))
	_decor_layer = Node2D.new()
	room_view.props_layer.add_child(_decor_layer)
	_spots = Node2D.new()
	room_view.stage.add_child(_spots)
	_build_ui()
	refresh()
	Events.decor_changed.connect(refresh)
	Events.seashells_changed.connect(func(_t: int) -> void: _refresh_counters())
	AudioManager.play_music(str(room_view.room.get("music", "hub_penthouse")))
	if not bool(SaveManager.data.get("hub_tip_seen", false)):
		SaveManager.data["hub_tip_seen"] = true
		toast(tr("HUB_TIP"), 4.5)


# ======================================================================= drawing decor + slots

func refresh() -> void:
	for c in _decor_layer.get_children():
		c.queue_free()
	for c in _spots.get_children():
		c.queue_free()
	_sprites.clear()
	var placed := GameState.placed_decor()
	var slots: Array[Dictionary] = []
	for s: Dictionary in room_view.room.get("decor_slots", []):
		slots.append(s)
	slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var oa := int(TYPE_ORDER.get(str(a["type"]), 3))
		var ob := int(TYPE_ORDER.get(str(b["type"]), 3))
		if oa != ob:
			return oa < ob
		return float(a["anchor"][1]) < float(b["anchor"][1]))
	for s in slots:
		var slot_id := str(s["id"])
		var rect := Rect2()
		if placed.has(slot_id):
			var entry: Dictionary = placed[slot_id]
			var item := GameState.decor(str(entry["id"]))
			if item.is_empty():
				continue
			var tex := UIKit.texture(str(item.get("sprite", "")))
			if tex == null:
				continue
			rect = slot_rect(s, tex.get_size())
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.centered = false
			sprite.position = rect.position
			sprite.scale = rect.size / tex.get_size()
			if bool(entry.get("flipped", false)):
				sprite.flip_h = true
			_decor_layer.add_child(sprite)
			_sprites[slot_id] = sprite
		else:
			var max_size: Vector2 = _max_size(s)
			rect = slot_rect(s, Vector2(minf(max_size.x, 200), minf(max_size.y, 200)))
		_add_spot(s, rect, placed.has(slot_id))


## Where an item of `item_size` goes in a slot (scaled down to the slot's max size).
func slot_rect(slot: Dictionary, item_size: Vector2) -> Rect2:
	var max_size := _max_size(slot)
	var k := minf(1.0, minf(max_size.x / item_size.x, max_size.y / item_size.y))
	var sz := item_size * k
	var anchor := Vector2(float(slot["anchor"][0]), float(slot["anchor"][1]))
	if str(slot["type"]) == "wall":
		return Rect2(anchor - sz / 2.0, sz)
	return Rect2(anchor - Vector2(sz.x / 2.0, sz.y), sz)


func _max_size(slot: Dictionary) -> Vector2:
	if slot.has("max"):
		return Vector2(float(slot["max"][0]), float(slot["max"][1]))
	return DEFAULT_MAX.get(str(slot["type"]), Vector2(200, 200))


func _add_spot(slot: Dictionary, rect: Rect2, filled: bool) -> void:
	var slot_id := str(slot["id"])
	var show_marker := decorating and (not filled) and (moving_from == "" or _same_type(moving_from, slot_id))
	if not filled and not show_marker:
		return
	var spot := SlotSpot.new()
	spot.position = rect.position
	spot.size = rect.size
	spot.filled = filled
	spot.show_marker = show_marker
	spot.highlight = moving_from == slot_id
	spot.pressed.connect(_on_slot_pressed.bind(slot_id, filled))
	_spots.add_child(spot)


func _same_type(a: String, b: String) -> bool:
	return str(GameState.hub_slot(a).get("type", "a")) == str(GameState.hub_slot(b).get("type", "b"))


# ======================================================================= interaction

func _on_slot_pressed(slot_id: String, filled: bool) -> void:
	if not decorating:
		if filled and _sprites.has(slot_id):
			var sprite: Sprite2D = _sprites[slot_id]
			var t := sprite.create_tween()
			t.tween_property(sprite, "scale", sprite.scale * Vector2(1.04, 0.96), 0.12)
			t.tween_property(sprite, "scale", sprite.scale, 0.18).set_trans(Tween.TRANS_BACK)
			AudioManager.play_sfx("decor_pickup", 0.1)
			var item := GameState.decor(str(GameState.placed_decor()[slot_id]["id"]))
			toast("%s - %s" % [item.get("name", ""), item.get("text", "")])
		return
	if moving_from != "":
		if not filled and GameState.move_decor(moving_from, slot_id):
			AudioManager.play_sfx("decor_place")
		moving_from = ""
		refresh()
		return
	if filled:
		var item_id := str(GameState.placed_decor()[slot_id]["id"])
		var item := GameState.decor(item_id)
		UIKit.dialog(ui, str(item.get("name", "")), str(item.get("text", "")), [
			[tr("DECOR_MOVE"), func() -> void:
				moving_from = slot_id
				AudioManager.play_sfx("decor_pickup")
				toast(tr("DECOR_MOVE_HINT"))
				refresh(), true],
			[tr("DECOR_FLIP"), func() -> void:
				GameState.flip_decor(slot_id)
				AudioManager.play_sfx("decor_place")],
			[tr("DECOR_STORE"), func() -> void:
				GameState.store_decor(slot_id)
				AudioManager.play_sfx("decor_pickup")],
			[tr("CANCEL"), Callable()],
		])
	else:
		_open_picker(slot_id)


func _open_picker(slot_id: String) -> void:
	var type := str(GameState.hub_slot(slot_id).get("type", ""))
	var ids: Array[String] = []
	for id: String in GameState.decor_items().keys():
		if str(GameState.decor(id).get("slot", "")) == type:
			ids.append(id)
	_open_catalog(tr("DECOR_PICK_TITLE"), ids, slot_id)


## A panel of decor cards. With a slot id, owned items can be placed straight away.
func _open_catalog(title: String, ids: Array[String], slot_id: String = "") -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.169, 0.137, 0.314, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.card(30))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 120
	panel.offset_right = -120
	panel.offset_top = 60
	panel.offset_bottom = -60
	overlay.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UIKit.label(title, 48, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UIKit.counters())
	var close := UIKit.icon_button("ui/close.svg", 88, tr("CLOSE"))
	close.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_back")
		overlay.queue_free())
	head.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var grid := HFlowContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var pa := GameState.decor_price(a)
		var pb := GameState.decor_price(b)
		if (pa < 0) != (pb < 0):
			return pa >= 0
		return pa < pb)
	for id in ids:
		grid.add_child(_decor_card(id, slot_id, overlay))
	UIKit.pop_in(panel)


func _decor_card(id: String, slot_id: String, overlay: Control) -> Control:
	var item := GameState.decor(id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.box(Palette.color("cream"), 24, Palette.color("sand"), 3, 14))
	card.custom_minimum_size = Vector2(300, 380)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var art := TextureRect.new()
	art.texture = UIKit.texture(str(item.get("sprite", "")))
	art.custom_minimum_size = Vector2(0, 180)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(art)
	v.add_child(UIKit.label(str(item.get("name", id)), 28, Palette.color("ink")))
	var owned := GameState.owned_count(id)
	var avail := GameState.available_count(id)
	var price := GameState.decor_price(id)
	var status := ""
	if owned > 0:
		status = tr("DECOR_OWNED") % [owned, avail]
	elif price < 0:
		status = _reward_hint(id)
	else:
		status = tr("DECOR_PRICE") % price
	var s := UIKit.label(status, 24, Palette.color("ink_soft"))
	s.custom_minimum_size.x = 270
	v.add_child(s)
	var button := UIKit.text_button("", Vector2(250, 80))
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 28)
	if slot_id != "" and avail > 0:
		button.text = tr("DECOR_PLACE")
		UIKit.primary(button)
		button.pressed.connect(func() -> void:
			if GameState.place_decor(slot_id, id):
				AudioManager.play_sfx("decor_place")
			overlay.queue_free())
	elif price >= 0:
		button.text = tr("DECOR_BUY") % price
		button.disabled = not GameState.can_buy_decor(id)
		button.pressed.connect(func() -> void:
			if GameState.buy_decor(id):
				AudioManager.play_sfx("purchase")
				if slot_id != "":
					GameState.place_decor(slot_id, id)
					AudioManager.play_sfx("decor_place")
					overlay.queue_free()
				else:
					toast(tr("DECOR_BOUGHT") % str(item.get("name", id)))
					overlay.queue_free()
					_open_catalog(tr("CATALOG_TITLE"), _all_ids()))
	else:
		button.text = tr("DECOR_LOCKED")
		button.disabled = true
	v.add_child(button)
	return card


func _reward_hint(id: String) -> String:
	var rewards := Data.get_dict("rewards")
	for level_id: String in (rewards.get("levels", {}) as Dictionary).keys():
		if str(rewards["levels"][level_id]) == id:
			return tr("REWARD_LEVEL") % (Campaign.index_of(level_id) + 1)
	for n: String in (rewards.get("streak", {}) as Dictionary).keys():
		if str(rewards["streak"][n]) == id:
			return tr("REWARD_STREAK") % int(n)
	if str(rewards.get("postcards_all", "")) == id:
		return tr("REWARD_POSTCARDS")
	return tr("REWARD_SECRET")


func _all_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in GameState.decor_items().keys():
		ids.append(id)
	return ids


# ======================================================================= UI

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	var back := UIKit.icon_button("ui/back.svg", 96, tr("BACK"))
	back.position = Vector2(28, 24)
	back.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_back")
		Router.goto("main_menu"))
	root.add_child(back)
	var title := UIKit.label(tr("HUB_TITLE"), 44, Palette.color("white_warm"))
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -500
	title.offset_right = 500
	title.offset_top = 34
	title.add_theme_color_override("font_shadow_color", Color(0.169, 0.137, 0.314, 0.6))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)
	_counters_holder = Control.new()
	_counters_holder.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_counters_holder.offset_left = -340
	_counters_holder.offset_top = 24
	_counters_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_counters_holder)
	_refresh_counters()
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	buttons.offset_left = -700
	buttons.offset_top = -130
	buttons.offset_right = -28
	buttons.offset_bottom = -24
	buttons.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(buttons)
	var catalog := UIKit.text_button(tr("CATALOG_BUTTON"), Vector2(300, 100))
	catalog.pressed.connect(func() -> void:
		AudioManager.play_sfx("page_turn")
		_open_catalog(tr("CATALOG_TITLE"), _all_ids()))
	buttons.add_child(catalog)
	_decorate_button = UIKit.primary(UIKit.text_button(tr("DECORATE"), Vector2(300, 100)))
	_decorate_button.pressed.connect(toggle_decorate)
	buttons.add_child(_decorate_button)
	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", UIKit.card(20))
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_left = -560
	_toast.offset_right = 560
	_toast.offset_top = -260
	_toast.offset_bottom = -160
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	root.add_child(_toast)
	_toast_label = UIKit.label("", 30, Palette.color("ink"))
	_toast.add_child(_toast_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if decorating:
			toggle_decorate()
		else:
			Router.goto("main_menu")


func toggle_decorate() -> void:
	decorating = not decorating
	moving_from = ""
	AudioManager.play_sfx("ui_click")
	_decorate_button.text = tr("DECORATE_DONE") if decorating else tr("DECORATE")
	if decorating:
		toast(tr("DECORATE_HINT"))
	refresh()


func toast(message: String, seconds: float = 3.0) -> void:
	_toast_label.text = message
	_toast.visible = true
	_toast.modulate.a = 1.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)


func _refresh_counters() -> void:
	for c in _counters_holder.get_children():
		c.queue_free()
	_counters_holder.add_child(UIKit.counters())


## A tappable decor slot. Draws a dashed "+" marker when empty in decorate mode.
class SlotSpot extends Control:
	signal pressed()
	var filled := false
	var show_marker := false
	var highlight := false
	var _down := Vector2.INF

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb := event as InputEventMouseButton
			if mb.pressed:
				_down = mb.position
			elif _down != Vector2.INF and mb.position.distance_to(_down) < 40.0:
				_down = Vector2.INF
				accept_event()
				pressed.emit()

	func _draw() -> void:
		if show_marker:
			var c := size / 2.0
			var r := minf(minf(size.x, size.y) / 2.0 - 6.0, 70.0)
			draw_circle(c, r, Color(1, 0.984, 0.961, 0.55))
			var segments := 24
			for i in segments:
				if i % 2 == 0:
					draw_arc(c, r, TAU * i / segments, TAU * (i + 1) / segments, 4, Palette.color("coral"), 5.0, true)
			draw_line(c - Vector2(r * 0.4, 0), c + Vector2(r * 0.4, 0), Palette.color("coral"), 8.0, true)
			draw_line(c - Vector2(0, r * 0.4), c + Vector2(0, r * 0.4), Palette.color("coral"), 8.0, true)
		if highlight:
			draw_rect(Rect2(Vector2.ZERO, size), Palette.color("gold", 0.6), false, 6.0)
