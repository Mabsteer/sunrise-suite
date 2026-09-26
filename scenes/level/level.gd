class_name LevelScene
extends Node2D
## One escape-room level. Router params:
##   { "level_id": "test_lounge" }                          a hand-made level in data/levels/
##   { "level": {...}, "mode": "main"|"replay"|"daily"|"endless", "record_id": "main_03" }
## The public "controller" methods (tap, use_selected_on, submit, take, combine_items, select_item)
## are what the player's taps call, and what the autoplay bot calls too.

signal finished_level(result: Dictionary)

const BADGE := "ui/unlocked.svg"

var session: LevelSession
var text: LevelText
var room_view: RoomView
var level: Dictionary
var mode := "main"
var record_id := ""

var inventory: InventoryBar
var closeup: CloseupPanel
var ui: CanvasLayer
var hotspots: Dictionary = {}
var host_sprites: Dictionary = {}

var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _hint_panel: PanelContainer
var _hint_label: RichTextLabel
var _timer_label: Label
var _pause_menu: Control
var _results: Control
var _paused := false
var _pending_from := Vector2.INF
var _props_layer: Node2D
var _spots_layer: Node2D


func _ready() -> void:
	var params := Router.params
	mode = str(params.get("mode", "main"))
	record_id = str(params.get("record_id", ""))
	if params.has("level"):
		level = params["level"]
	else:
		level = Data.get_dict("levels/" + str(params.get("level_id", "test_lounge")))
	if level.is_empty():
		push_error("Level: no level data")
		return
	start(level)


## Builds everything for a level (also used by tests/autoplay directly).
func start(level_data: Dictionary) -> void:
	level = level_data
	session = LevelSession.new(level)
	room_view = RoomView.new()
	add_child(room_view)
	room_view.setup(str(level.get("room", "lounge")))
	room_view.sunrise_t = 0.0
	text = LevelText.new(session, room_view.room)
	_props_layer = room_view.props_layer
	_spots_layer = Node2D.new()
	_spots_layer.name = "Hotspots"
	room_view.stage.add_child(_spots_layer)
	_build_ui()
	_build_room_things()
	session.lock_opened.connect(_on_lock_opened)
	session.item_picked.connect(_on_item_picked)
	session.item_consumed.connect(func(id: String) -> void: inventory.remove_item(id))
	session.items_combined.connect(_on_items_combined)
	session.completed.connect(_on_completed)
	AudioManager.play_music(str(room_view.room.get("music", "level_lounge")))
	AudioManager.play_ambience("ambience_ocean")


func _process(delta: float) -> void:
	if session and not session.finished and not _paused:
		session.elapsed += delta
		if _timer_label and _timer_label.visible:
			_timer_label.text = _format_time(session.elapsed)


# ======================================================================= controller API

## Handles a tap on something in the room (or in a close-up) by its key, e.g. "lock:safe", "item:i_key".
func tap(key: String) -> void:
	if session.finished:
		return
	var kind := key.get_slice(":", 0)
	var id := key.substr(kind.length() + 1)
	match kind:
		"background":
			inventory.deselect()
		"item":
			_pending_from = _hotspot_center(key)
			inventory.deselect()
			if session.pick_up(id):
				AudioManager.play_sfx("item_pickup", 0.05)
				toast(tr("PICKED_UP") % text.item_name(id))
		"lock":
			if inventory.selected != "":
				use_selected_on(id)
			else:
				AudioManager.play_sfx("ui_click")
				closeup.show_lock(id)
		"clue", "decoy":
			if inventory.selected != "":
				_nothing_here()
				return
			AudioManager.play_sfx("page_turn")
			closeup.show_thing(kind, id)
			if kind == "clue":
				session.see_clue(id)
		"postcard":
			take("postcard", id, _hotspot_center(key))
		"flavor":
			if inventory.selected != "":
				_nothing_here()
				return
			var parts := id.split(":")
			var f := text.furniture(parts[0])
			var flavor := str(f.get("flavor", ""))
			if parts.size() > 1:
				flavor = tr("NOTHING_HIDDEN") % text.furniture_spot(parts[0], parts[1]).get("name", f.get("name", "")) if flavor == "" else flavor + "\n" + tr("NOTHING_HIDDEN_SHORT")
			AudioManager.play_sfx("ui_click")
			closeup.show_thing("flavor", key)
			closeup.showing = {"kind": "flavor", "id": key, "title": str(f.get("name", "")), "text": flavor, "sprite": str(f.get("sprite", ""))}
			closeup.refresh()


## Uses the selected inventory item on a lock.
func use_selected_on(lock_id: String) -> void:
	var item := inventory.selected
	if item == "":
		closeup.show_lock(lock_id)
		return
	var result := session.use_item(item, lock_id)
	match result:
		"opened":
			AudioManager.play_sfx("lock_open")
		"wrong":
			AudioManager.play_sfx("item_fail")
			toast(tr("ITEM_WRONG") % text.item_name(item))
			if closeup.widget:
				UIKit.wiggle(closeup.widget)
		_:
			_nothing_here()


## Submits an answer for a code/sequence/clock/switch/slider lock (or "search" for hidden spots).
func submit(lock_id: String, answer: String) -> bool:
	var ok := false
	if answer == "search":
		ok = session.search(lock_id)
	else:
		ok = session.submit_answer(lock_id, answer)
	if not ok and closeup.widget:
		closeup.widget.show_wrong()
	return ok


## Takes an item / reads a clue / picks up the postcard shown inside a container.
func take(kind: String, id: String, from_global: Vector2 = Vector2.INF) -> void:
	match kind:
		"item":
			_pending_from = from_global
			if session.pick_up(id):
				AudioManager.play_sfx("item_pickup", 0.05)
				closeup.refresh()
		"clue", "decoy":
			AudioManager.play_sfx("page_turn")
			closeup.show_thing(kind, id)
			if kind == "clue":
				session.see_clue(id)
		"postcard":
			if session.take_postcard():
				AudioManager.play_sfx("postcard_found")
				Events.postcard_found.emit(id)
				_remove_room_thing("postcard:" + id)
				closeup.show_thing("postcard", id)


func select_item(item_id: String) -> void:
	inventory.select(item_id)


func combine_items(a: String, b: String) -> void:
	var result := session.combine(a, b)
	if result == "":
		AudioManager.play_sfx("item_fail")
		toast(tr("COMBINE_FAIL"))
		inventory.select(b)


# ======================================================================= building the room

func _build_room_things() -> void:
	var room := room_view.room
	# Background catcher: tapping empty space deselects.
	_add_hotspot("background", Rect2(-400, -300, 2720, 1680), null)
	# Furniture: whole-piece flavour hotspots, then spot hotspots on top.
	for f: Dictionary in room.get("furniture", []):
		var fid := str(f["id"])
		var pos := _vec(f.get("pos", [0, 0]))
		var fsize := _vec(f.get("size", [100, 100]))
		_add_hotspot("flavor:" + fid, Rect2(pos, fsize), room_view.furniture_nodes.get(fid))
		for spot: Dictionary in f.get("spots", []):
			var r: Array = spot.get("rect", [0, 0, 10, 10])
			var rect := Rect2(pos + Vector2(float(r[0]), float(r[1])), Vector2(float(r[2]), float(r[3])))
			_add_hotspot("flavor:%s:%s" % [fid, spot["id"]], rect, room_view.furniture_nodes.get(fid))
	# Locks, clues and decoys that sit in the room.
	for id: String in LevelSession._sorted_keys(session.locks):
		var lock: Dictionary = session.locks[id]
		if str(lock.get("location", "room")) == "room":
			_place_host("lock:" + id, lock.get("host", {}), false)
	for id: String in LevelSession._sorted_keys(session.clues):
		var c: Dictionary = session.clues[id]
		if str(c.get("location", "room")) == "room" and str(c.get("item", "")) == "":
			_place_host("clue:" + id, c.get("host", {}), false)
	for id: String in LevelSession._sorted_keys(session.decoys):
		var d: Dictionary = session.decoys[id]
		if str(d.get("location", "room")) == "room":
			_place_host("decoy:" + id, d.get("host", {}), false)
	# Items lying around.
	for id: String in LevelSession._sorted_keys(session.items):
		var it: Dictionary = session.items[id]
		if str(it.get("location", "room")) == "room" and str(it.get("slot", "")) != "":
			_place_item(id, str(it["slot"]))
	var pc: Dictionary = level.get("postcard", {})
	if not pc.is_empty() and str(pc.get("location", "room")) == "room":
		_place_host("postcard:" + str(pc.get("id", "")), pc.get("host", {}), false)


func _place_host(key: String, host: Dictionary, _open: bool) -> void:
	match str(host.get("kind", "")):
		"door":
			var r: Array = (room_view.room.get("door", {}) as Dictionary).get("rect", [1480, 110, 260, 650])
			_add_hotspot(key, Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])), null)
		"furniture":
			var f := text.furniture(str(host.get("furniture", "")))
			var spot := text.furniture_spot(str(host.get("furniture", "")), str(host.get("spot", "")))
			var pos := _vec(f.get("pos", [0, 0]))
			var r: Array = spot.get("rect", [0, 0, 10, 10])
			var rect := Rect2(pos + Vector2(float(r[0]), float(r[1])), Vector2(float(r[2]), float(r[3])))
			# The spot now has a purpose, so it replaces the flavour hotspot.
			var flavor_key := "flavor:%s:%s" % [host.get("furniture", ""), host.get("spot", "")]
			if hotspots.has(flavor_key):
				(hotspots[flavor_key] as Node).queue_free()
				hotspots.erase(flavor_key)
			_add_hotspot(key, rect, room_view.furniture_nodes.get(str(host.get("furniture", ""))))
			# A little padlock shows that this part of the furniture is locked (hidden spots stay a secret).
			if key.begins_with("lock:") and session.lock_type(key.substr(5)) not in ["hidden"]:
				var badge := Sprite2D.new()
				badge.texture = UIKit.texture("ui/padlock.svg")
				badge.scale = Vector2(0.7, 0.7)
				badge.position = rect.position + Vector2(rect.size.x - 24, rect.size.y / 2.0)
				_props_layer.add_child(badge)
				host_sprites["badge:" + key] = badge
		"prop":
			var prop: Dictionary = Data.get_dict("props").get(str(host.get("prop", "")), {})
			var rect := _slot_rect(str(host.get("slot", "")), _vec(prop.get("size", [100, 100])))
			var sprite := Sprite2D.new()
			sprite.texture = UIKit.texture(str(prop.get("sprite", "")))
			sprite.centered = false
			sprite.position = rect.position
			if sprite.texture:
				sprite.scale = rect.size / sprite.texture.get_size()
			_props_layer.add_child(sprite)
			host_sprites[key] = sprite
			_add_hotspot(key, rect.grow(10), sprite)


func _place_item(item_id: String, slot: String) -> void:
	var tex := UIKit.texture(str(text.item_type_data(item_id).get("sprite", "")))
	var rect := _slot_rect(slot, Vector2(96, 96))
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.position = rect.position
	if tex:
		sprite.scale = rect.size / tex.get_size()
	_props_layer.add_child(sprite)
	host_sprites["item:" + item_id] = sprite
	_add_hotspot("item:" + item_id, rect.grow(8), sprite)
	# A tiny sparkle so loose items are noticeable.
	var sparkle := Sprite2D.new()
	sparkle.texture = UIKit.texture("ui/sparkle.svg")
	sparkle.scale = Vector2(0.4, 0.4)
	sparkle.position = rect.position + Vector2(rect.size.x - 6, 6)
	sprite.add_child(sparkle)
	sparkle.position = Vector2(tex.get_size().x - 10, 10) if tex else Vector2.ZERO
	if not bool(SaveManager.settings.get("reduce_motion", false)):
		var t := sparkle.create_tween().set_loops()
		t.tween_property(sparkle, "modulate:a", 0.2, 1.1).set_trans(Tween.TRANS_SINE)
		t.tween_property(sparkle, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)


## Where a prop of `prop_size` goes in a wall or surface slot (scaled down to fit).
func _slot_rect(slot_id: String, prop_size: Vector2) -> Rect2:
	for s: Dictionary in room_view.room.get("wall_slots", []):
		if str(s.get("id", "")) == slot_id:
			var r: Array = s.get("rect", [0, 0, 100, 100])
			var area := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
			var k := minf(1.0, minf(area.size.x / prop_size.x, area.size.y / prop_size.y))
			var sz := prop_size * k
			return Rect2(area.position + (area.size - sz) / 2.0, sz)
	for s: Dictionary in room_view.room.get("surface_slots", []):
		if str(s.get("id", "")) == slot_id:
			var anchor := _vec(s.get("anchor", [0, 0]))
			var max_size := _vec(s.get("max", [120, 110]))
			var k := minf(1.0, minf(max_size.x / prop_size.x, max_size.y / prop_size.y))
			var sz := prop_size * k
			return Rect2(anchor - Vector2(sz.x / 2.0, sz.y), sz)
	push_warning("Level: unknown slot '%s'" % slot_id)
	return Rect2(Vector2(900, 500), prop_size)


func _add_hotspot(key: String, rect: Rect2, sprite: CanvasItem) -> Hotspot:
	var h := Hotspot.new()
	h.key = key
	h.sprite = sprite
	h.position = rect.position
	h.size = rect.size
	h.tapped.connect(tap)
	h.item_dropped.connect(func(k: String, item_id: String) -> void:
		inventory.select(item_id)
		tap(k))
	_spots_layer.add_child(h)
	hotspots[key] = h
	return h


func _remove_room_thing(key: String) -> void:
	if host_sprites.has(key):
		var s: Node = host_sprites[key]
		host_sprites.erase(key)
		var t := create_tween()
		t.tween_property(s, "modulate:a", 0.0, 0.25)
		t.tween_callback(s.queue_free)
	if hotspots.has(key):
		(hotspots[key] as Node).queue_free()
		hotspots.erase(key)


func _hotspot_center(key: String) -> Vector2:
	if not hotspots.has(key):
		return Vector2.INF
	var h: Control = hotspots[key]
	return h.get_global_transform_with_canvas() * (h.size / 2.0)


# ======================================================================= session events

func _on_lock_opened(lock_id: String) -> void:
	var lock: Dictionary = session.locks[lock_id]
	AudioManager.play_sfx("lock_open")
	if not bool(lock.get("is_door", false)):
		AudioManager.play_sfx("step_solved", 0.0, -4.0)
		room_view.animate_sunrise_to(session.sunrise_t(), 2.2)
	Events.sunrise_changed.emit(session.sunrise_t())
	var key := "lock:" + lock_id
	var host: Dictionary = lock.get("host", {})
	if host_sprites.has(key) and str(host.get("kind", "")) == "prop":
		var prop: Dictionary = Data.get_dict("props").get(str(host.get("prop", "")), {})
		if prop.has("sprite_open"):
			var sprite := host_sprites[key] as Sprite2D
			var tex := UIKit.texture(str(prop["sprite_open"]))
			if tex and sprite.texture:
				var size_before := sprite.texture.get_size() * sprite.scale
				sprite.texture = tex
				sprite.scale = size_before / tex.get_size()
	elif hotspots.has(key) and str(host.get("kind", "")) == "furniture":
		if host_sprites.has("badge:" + key):
			(host_sprites["badge:" + key] as Node).queue_free()
			host_sprites.erase("badge:" + key)
		var h: Control = hotspots[key]
		var badge := Sprite2D.new()
		badge.texture = UIKit.texture(BADGE)
		badge.scale = Vector2(0.75, 0.75)
		badge.position = h.position + Vector2(h.size.x - 20, 20)
		_props_layer.add_child(badge)
		UIKit.pop_in(badge)
	_sparkle_at(_hotspot_center(key))
	if closeup.is_open() and str(closeup.showing.get("id", "")) == lock_id:
		closeup.refresh()


func _on_item_picked(item_id: String) -> void:
	if _pending_from == Vector2.INF:
		_pending_from = _hotspot_center("item:" + item_id)
	inventory.add_item(item_id, _pending_from)
	_pending_from = Vector2.INF
	_remove_room_thing("item:" + item_id)


func _on_items_combined(_a: String, _b: String, result: String) -> void:
	AudioManager.play_sfx("item_combine")
	inventory.add_item(result)
	inventory.deselect()
	toast(tr("COMBINE_OK") % text.item_name(result))


func _on_completed() -> void:
	inventory.deselect()
	closeup.close()
	_hint_panel.visible = false
	AudioManager.play_sfx("door_open")
	AudioManager.play_music("sunrise_stinger")
	room_view.animate_sunrise_to(1.12, 3.0)
	var result := GameState.record_level_result(level, record_id, mode, session)
	finished_level.emit(result)
	await get_tree().create_timer(2.6 if not bool(SaveManager.settings.get("reduce_motion", false)) else 0.6).timeout
	AudioManager.play_sfx("level_complete")
	_show_results(result)


# ======================================================================= UI

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	# Top bar
	var pause := UIKit.icon_button("ui/pause.svg", 96, tr("PAUSE"))
	pause.position = Vector2(28, 24)
	pause.pressed.connect(_toggle_pause)
	root.add_child(pause)
	var hint := UIKit.icon_button("ui/hint.svg", 110, tr("HINT"))
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hint.offset_left = -138
	hint.offset_right = -28
	hint.offset_top = 22
	hint.offset_bottom = 132
	hint.pressed.connect(show_hint)
	root.add_child(hint)
	var title := UIKit.label("%s  ·  %s" % [tr(str(room_view.room.get("name", ""))), _mode_caption()], 30, Palette.color("white_warm"))
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -500
	title.offset_right = 500
	title.offset_top = 30
	title.add_theme_color_override("font_shadow_color", Color(0.169, 0.137, 0.314, 0.6))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)
	_timer_label = UIKit.label("0:00", 30, Palette.color("white_warm"))
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.offset_left = -200
	_timer_label.offset_right = 200
	_timer_label.offset_top = 74
	_timer_label.visible = bool(SaveManager.settings.get("show_timer", false))
	_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_timer_label)

	# Close-up (below the inventory so items stay usable)
	closeup = CloseupPanel.new()
	root.add_child(closeup)
	closeup.setup(session, text)
	closeup.answer_submitted.connect(func(lock_id: String, answer: String) -> void: submit(lock_id, answer))
	closeup.use_requested.connect(use_selected_on)
	closeup.take_requested.connect(take)
	closeup.lock_requested.connect(func(lock_id: String) -> void:
		if inventory.selected != "":
			use_selected_on(lock_id)
		else:
			closeup.show_lock(lock_id))

	# Toast bubble
	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", UIKit.card(20))
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_left = -560
	_toast.offset_right = 560
	_toast.offset_top = -290
	_toast.offset_bottom = -200
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	root.add_child(_toast)
	_toast_label = UIKit.label("", 32, Palette.color("ink"))
	_toast.add_child(_toast_label)

	# Inventory
	inventory = InventoryBar.new()
	root.add_child(inventory)
	inventory.setup(text)
	inventory.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	inventory.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory.grow_vertical = Control.GROW_DIRECTION_BEGIN
	inventory.offset_bottom = -16
	inventory.item_tapped.connect(func(id: String) -> void: toast(tr("ITEM_SELECTED") % text.item_name(id)))
	inventory.combine_requested.connect(combine_items)
	inventory.inspect_requested.connect(func(id: String) -> void:
		closeup.show_thing("item", id)
		inventory.deselect())

	# Hint bubble (Grandma's notepad)
	_hint_panel = PanelContainer.new()
	_hint_panel.add_theme_stylebox_override("panel", UIKit.paper(26))
	_hint_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_hint_panel.offset_left = -760
	_hint_panel.offset_right = -40
	_hint_panel.offset_top = 150
	_hint_panel.visible = false
	root.add_child(_hint_panel)
	var hv := VBoxContainer.new()
	_hint_panel.add_child(hv)
	var htitle := UIKit.label(tr("HINT_TITLE"), 28, Palette.color("coral_dark"), HORIZONTAL_ALIGNMENT_LEFT)
	hv.add_child(htitle)
	_hint_label = UIKit.handwriting("", 44)
	_hint_label.custom_minimum_size.x = 660
	hv.add_child(_hint_label)
	var hclose := Button.new()
	hclose.text = tr("HINT_THANKS")
	hclose.size_flags_horizontal = Control.SIZE_SHRINK_END
	hclose.focus_mode = Control.FOCUS_NONE
	hclose.pressed.connect(func() -> void: _hint_panel.visible = false)
	hv.add_child(hclose)


func show_hint() -> void:
	if session.finished:
		return
	var goal := session.request_hint()
	AudioManager.play_sfx("hint")
	_hint_label.text = text.rich(text.hint_text(goal), 40)
	_hint_panel.visible = true
	UIKit.pop_in(_hint_panel)
	if int(goal.get("level", 1)) >= 2:
		var target := _goal_hotspot(goal)
		if target != "":
			_sparkle_at(_hotspot_center(target), 3)


func toast(message: String, seconds: float = 2.6) -> void:
	_toast_label.text = message
	_toast.visible = true
	_toast.modulate.a = 1.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)


func _goal_hotspot(goal: Dictionary) -> String:
	match str(goal.get("action", "")):
		"pick_up":
			var key := "item:" + str(goal["id"])
			if hotspots.has(key):
				return key
			var loc := str(session.items[str(goal["id"])].get("location", "room"))
			return "lock:" + loc if hotspots.has("lock:" + loc) else ""
		"see_clue":
			var ck := "clue:" + str(goal["id"])
			if hotspots.has(ck):
				return ck
			var cloc := str(session.clues[str(goal["id"])].get("location", "room"))
			return "lock:" + cloc if hotspots.has("lock:" + cloc) else ""
		"open":
			var lk := "lock:" + str(goal["id"])
			if hotspots.has(lk):
				return lk
			var lloc := str(session.locks[str(goal["id"])].get("location", "room"))
			return "lock:" + lloc if hotspots.has("lock:" + lloc) else ""
	return ""


func _sparkle_at(global_pos: Vector2, count: int = 1) -> void:
	if global_pos == Vector2.INF:
		return
	for i in count:
		var s := TextureRect.new()
		s.texture = UIKit.texture("ui/sparkle.svg")
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.size = Vector2(72, 72)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.position = global_pos - s.size / 2.0 + Vector2(randf_range(-40, 40), randf_range(-30, 30)) * float(i)
		s.pivot_offset = s.size / 2.0
		ui.add_child(s)
		var t := s.create_tween().set_parallel(true)
		t.tween_property(s, "scale", Vector2(1.6, 1.6), 0.9).from(Vector2(0.3, 0.3)).set_delay(i * 0.18)
		t.tween_property(s, "rotation", 1.2, 0.9).set_delay(i * 0.18)
		t.tween_property(s, "modulate:a", 0.0, 0.9).from(1.0).set_delay(i * 0.18)
		t.chain().tween_callback(s.queue_free)


func _nothing_here() -> void:
	AudioManager.play_sfx("item_fail")
	toast(tr("ITEM_NOTHING_HERE"))


func _toggle_pause() -> void:
	if _results:
		return
	_paused = not _paused
	if _pause_menu:
		_pause_menu.queue_free()
		_pause_menu = null
	if not _paused:
		return
	AudioManager.play_sfx("ui_click")
	_pause_menu = UIKit.dialog(ui, tr("PAUSE_TITLE"), "", [
		[tr("RESUME"), _toggle_pause, true],
		[tr("RESTART"), func() -> void: Router.goto("level", Router.params)],
		[tr("LEAVE"), func() -> void: Router.goto(_exit_screen())],
	])


func _show_results(result: Dictionary) -> void:
	var stars := int(result.get("stars", 1))
	var card_items: Array = []
	match mode:
		"main", "replay":
			var nxt := GameState.next_level_id(record_id)
			if nxt != "" and GameState.is_level_unlocked(nxt):
				card_items.append([tr("NEXT_LEVEL"), func() -> void: Launcher.play_main(nxt), true])
			elif nxt == "" and GameState.campaign_finished():
				card_items.append([tr("ENDLESS_PLAY"), func() -> void: Launcher.play_endless(), true])
			card_items.append([tr("BACK_TO_BOOK"), func() -> void: Router.goto("level_select")])
			card_items.append([tr("REPLAY"), func() -> void: Router.goto("level", Router.params)])
		"endless":
			card_items.append([tr("NEXT_ENDLESS"), func() -> void: Launcher.play_endless(), true])
			card_items.append([tr("BACK_TO_BOOK"), func() -> void: Router.goto("level_select")])
		"daily":
			card_items.append([tr("BACK_TO_CALENDAR"), func() -> void: Router.goto(_exit_screen()), true])
			if Router.has_screen("hub"):
				card_items.append([tr("MENU_PENTHOUSE"), func() -> void: Router.goto("hub")])
		_:
			card_items.append([tr("CONTINUE"), func() -> void: Router.goto(_exit_screen()), true])
			card_items.append([tr("REPLAY"), func() -> void: Router.goto("level", Router.params)])
	_results = UIKit.dialog(ui, tr("RESULTS_TITLE"), "", card_items)
	var body: VBoxContainer = _results.get_meta("body")
	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 24)
	body.add_child(star_row)
	body.move_child(star_row, 1)
	for i in 3:
		var s := TextureRect.new()
		s.texture = UIKit.texture("ui/star_full.svg" if i < stars else "ui/star_empty.svg")
		s.custom_minimum_size = Vector2(130, 130)
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.pivot_offset = Vector2(65, 65)
		star_row.add_child(s)
		if i < stars and not bool(SaveManager.settings.get("reduce_motion", false)):
			s.scale = Vector2.ZERO
			var t := s.create_tween()
			t.tween_interval(0.35 + i * 0.35)
			t.tween_callback(func() -> void: AudioManager.play_sfx("star_%d" % (i + 1)))
			t.tween_property(s, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var lines: PackedStringArray = [
		tr("RESULTS_TIME") % _format_time(session.elapsed),
		tr("RESULTS_HINTS") % session.hints_used,
		tr("RESULTS_STAR_RULES") % _format_time(float(level.get("par_time", 600))),
	]
	var info := UIKit.label("\n".join(lines), 32, Palette.color("ink_soft"))
	body.add_child(info)
	body.move_child(info, 2)
	var shells := int(result.get("seashells", 0))
	if shells > 0:
		var sh := UIKit.label(tr("RESULTS_SHELLS") % shells, 36, Palette.color("coral_dark"))
		body.add_child(sh)
		body.move_child(sh, 3)
		AudioManager.play_sfx("seashell_gain")
	for unlock: String in result.get("unlocks", []):
		var ul := UIKit.label(unlock, 30, Palette.color("sea_deep"))
		body.add_child(ul)
		body.move_child(ul, body.get_child_count() - 2)




func _exit_screen() -> String:
	return str(Router.params.get("exit_to", "level_select" if Router.has_screen("level_select") else "main_menu"))


func _mode_caption() -> String:
	match mode:
		"daily":
			return tr("MODE_DAILY")
		"endless":
			return tr("MODE_ENDLESS") % int(level.get("tier", 1))
	return tr("MODE_TIER") % int(level.get("tier", 1))


static func _format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


static func _vec(a: Variant) -> Vector2:
	if a is Array and (a as Array).size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO
