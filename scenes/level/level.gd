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
var room_zoom: RoomZoom
var _zoom_out_button: Button
var hotspots: Dictionary = {}
var host_sprites: Dictionary = {}

var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
## How much of the next room shows through an open door (1 = exactly the door's size).
const EXIT_VIEW_SCALE := 1.6
## The walk through the exit: how far the camera zooms in, and how long it takes.
const WALK_ZOOM := 2.4
const WALK_SECONDS := 1.1

var _notebook: NotebookPanel
var _notebook_button: Button
## The notes in Mamie's notebook for this room (on a walk: every note read on the walk so far).
var _notes: Array = []
var _timer_label: Label
var _pause_menu: Control
var _results: Control
var _paused := false
var _background := false
var _letter_open := false
var _pending_from := Vector2.INF
var _props_layer: Node2D
var _spots_layer: Node2D


func _ready() -> void:
	add_to_group("level_screen")
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
	var pc_data: Dictionary = level.get("postcard", {})
	if not pc_data.is_empty() and GameState.has_postcard(str(pc_data.get("id", ""))):
		session.postcard_taken = true
	room_view = RoomView.new()
	add_child(room_view)
	room_view.setup(str(level.get("room", "lounge")))
	room_view.sunrise_t = sky_t(0.0)
	if Router.params.has("arrive_from") and not bool(SaveManager.settings.get("reduce_motion", false)):
		# Juliette just walked in: the room opens up around her.
		room_view.zoom = 1.25
		create_tween().tween_property(room_view, "zoom", 1.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		room_view.settle_in()
	text = LevelText.new(session, room_view.room)
	_props_layer = room_view.props_layer
	_spots_layer = Node2D.new()
	_spots_layer.name = "Hotspots"
	room_view.stage.add_child(_spots_layer)
	_build_ui()
	_load_notebook()
	_build_room_things()
	if bool(level.get("tutorial", false)):
		var guide := TutorialGuide.new()
		var ui_root := _notebook.get_parent()
		ui_root.add_child(guide)
		ui_root.move_child(guide, _notebook.get_index())
		guide.setup(self)
	session.lock_opened.connect(_on_lock_opened)
	session.item_picked.connect(_on_item_picked)
	session.item_consumed.connect(func(id: String) -> void: inventory.remove_item(id))
	session.items_combined.connect(_on_items_combined)
	session.completed.connect(_on_completed)
	session.dog_found.connect(_on_dog_found)
	session.dog_acted.connect(_on_dog_acted)
	_build_chloe()
	AudioManager.play_music("daily_sunrise" if mode == "daily" else str(room_view.room.get("music", "level_lounge")))
	AudioManager.play_ambience(str(room_view.room.get("ambience", "ambience_ocean")))
	if mode == "main" and level.has("chapter"):
		_show_chapter_card()


## Walk levels share one morning: each room brightens its own slice of the sunrise.
func sky_t(progress: float) -> float:
	var r: Array = level.get("sunrise_range", [0.0, 1.0])
	return lerpf(float(r[0]), float(r[1]), progress)


## The chapter card at the start of a story room: which part of Céline's life this room is.
func _show_chapter_card() -> void:
	var c := Campaign.chapter(str(level.get("chapter", "")))
	if c.is_empty():
		return
	_paused = true
	var card := UIKit.dialog(ui, tr(str(c.get("title", ""))), "", [[tr("CHAPTER_START"), func() -> void: _paused = false, true]])
	var body: VBoxContainer = card.get_meta("body")
	var top := UIKit.label(tr("CHAPTER_OF") % (int(level.get("step", 0)) + 1) + "   ·   " + str(c.get("years", "")), 28, Palette.color("coral_dark"))
	body.add_child(top)
	body.move_child(top, 0)
	var intro := UIKit.handwriting(tr(str(c.get("intro", ""))), 42)
	intro.custom_minimum_size.x = 820
	body.add_child(intro)
	body.move_child(intro, 2)


func _process(delta: float) -> void:
	if session and not session.finished and not _paused and not _background:
		# Clamp: browsers stop frames in hidden tabs, and the first frame back can have a huge delta.
		session.elapsed += minf(delta, 0.25)
	_update_info()
	_chloe_process(delta)


## The small line under the title: steps solved, plus the time if the player turned the timer on.
func _update_info() -> void:
	if _timer_label == null or session == null:
		return
	var info := tr("STEPS_INFO") % [session.solved_steps, session.total_steps]
	if bool(SaveManager.settings.get("show_timer", false)):
		info += "   ·   " + _format_time(session.elapsed)
	_timer_label.text = info


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_background = true
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_background = false


# ======================================================================= controller API

## Juliette looks at a spot where only Chloé can help: what she sees, nothing more.
func _show_dog_spot(lock_id: String) -> void:
	var t := session.lock_type(lock_id)
	var line := tr("NOTHING_SPECIAL")
	if t == "dog":
		line = tr("DOG_SPOT_DIG") if session.dog_action(lock_id) == "dig" else tr("DOG_SPOT_FETCH")
	var host: Dictionary = session.locks[lock_id].get("host", {})
	var sprite := ""
	if str(host.get("kind", "")) == "furniture":
		sprite = str(text.furniture(str(host.get("furniture", ""))).get("sprite", ""))
	closeup.show_flavor(CloseupPanel._cap(text.lock_name(lock_id)), line, sprite)


## Handles a tap on something in the room (or in a close-up) by its key, e.g. "lock:safe", "item:i_key".
func tap(key: String) -> void:
	if session.finished:
		return
	if room_zoom and room_zoom.swallow_tap():
		return
	var kind := key.get_slice(":", 0)
	var id := key.substr(kind.length() + 1)
	# Chloé is standing, ready: this tap tells her where to go.
	if chloe_ready and kind != "dog":
		send_chloe(key)
		return
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
			elif session.lock_type(id) in ["dog", "sniff"]:
				# A job only Chloé can do: to Juliette it's just a spot (the words are the only hint).
				AudioManager.play_sfx("ui_click")
				_show_dog_spot(id)
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
			_note_read(kind, id)
			_keep_memory(kind, id)
		"postcard":
			take("postcard", id, _hotspot_center(key))
		"dog":
			_tap_chloe()
		"lights":
			AudioManager.play_sfx("switch_toggle")
			session.toggle_lights()
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
	if session.given_to_dog(lock_id):
		_give_to_chloe(item)
		return
	var result := session.use_item(item, lock_id)
	match result:
		"opened":
			AudioManager.play_sfx("key_turn" if session.lock_type(lock_id) == "key" else "tool_use")
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
		AudioManager.play_sfx("search")
		ok = session.search(lock_id)
	elif answer == "dog":
		ok = session.send_dog(lock_id)
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
			_keep_memory(kind, id)
			_note_read(kind, id)
		"postcard":
			if session.take_postcard():
				AudioManager.play_sfx("postcard_found")
				var found := GameState.collect_postcard(id)
				_remove_room_thing("postcard:" + id)
				closeup.show_thing("postcard", id)
				if bool(found.get("all", false)):
					closeup.add_line(tr("POSTCARD_ALL_FOUND"))
				for decor_name: String in found.get("rewards", []):
					closeup.add_line(tr("UNLOCK_DECOR") % decor_name)


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
	if not pc.is_empty() and str(pc.get("location", "room")) == "room" and not session.postcard_taken:
		_place_host("postcard:" + str(pc.get("id", "")), pc.get("host", {}), false)
	_build_light()


# ======================================================================= the room's light

const LIGHT_GLOW_RADIUS := 720.0

var _light_glow: Sprite2D


## The room's light switch (or lamp, or lantern): no badge, you have to find it. With the light on
## there's a warm glow and the room is brighter; some things only show in the light or in the dark.
func _build_light() -> void:
	var ls: Dictionary = room_view.room.get("light_switch", {})
	if ls.is_empty():
		return
	var r: Array = ls.get("rect", [0, 0, 40, 60])
	var rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	var sprite: Sprite2D = null
	if str(ls.get("sprite", "")) != "":
		sprite = Sprite2D.new()
		sprite.texture = UIKit.texture(str(ls["sprite"]))
		sprite.centered = false
		sprite.position = rect.position
		if sprite.texture:
			sprite.scale = rect.size / sprite.texture.get_size()
		_props_layer.add_child(sprite)
		host_sprites["lights"] = sprite
	_add_hotspot("lights", rect, sprite)
	var g: Array = ls.get("glow", [960, 300])
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.86, 0.55, 0.26), Color(1.0, 0.8, 0.5, 0.0)])
	tex.gradient = grad
	_light_glow = Sprite2D.new()
	_light_glow.name = "LightGlow"
	_light_glow.texture = tex
	_light_glow.position = Vector2(float(g[0]), float(g[1]))
	_light_glow.scale = Vector2.ONE * (LIGHT_GLOW_RADIUS * 2.0 / 256.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_light_glow.material = mat
	_light_glow.modulate.a = 0.0
	room_view.stage.add_child(_light_glow)
	session.lights_changed.connect(_on_lights_changed)
	_apply_visibility()


func _on_lights_changed(on: bool) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(_light_glow, "modulate:a", 1.0 if on else 0.0, 0.25)
	t.tween_property(room_view, "lamp", 1.0 if on else 0.0, 0.25)
	_apply_visibility()


## Shows only the things that can be seen in the room's light right now ("visible_when").
func _apply_visibility() -> void:
	for pair: Array in [["clue", session.clues], ["decoy", session.decoys], ["item", session.items]]:
		var things: Dictionary = pair[1]
		for id: String in things.keys():
			var thing: Dictionary = things[id]
			if str(thing.get("visible_when", "")) == "":
				continue
			var key := "%s:%s" % [pair[0], id]
			var seen := session.visible_now(thing)
			if hotspots.has(key):
				(hotspots[key] as Control).visible = seen
			if host_sprites.has(key):
				(host_sprites[key] as CanvasItem).visible = seen


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
			# With "Show helpers" on, a little badge shows that this part of the furniture is locked, a
			# puzzle, or needs a tool (the one search spot stays a secret). Off by default: finding out
			# what opens is part of the game.
			if helpers_on() and key.begins_with("lock:") and session.lock_type(key.substr(5)) not in ["hidden", "sniff"] and not session.finds_dog(key.substr(5)):
				var badge := Sprite2D.new()
				badge.texture = UIKit.texture(_badge_for(session.lock_type(key.substr(5))))
				badge.scale = Vector2(0.7, 0.7)
				badge.position = rect.position + Vector2(rect.size.x - 24, rect.size.y / 2.0)
				_props_layer.add_child(badge)
				host_sprites["badge:" + key] = badge
		"prop":
			var prop: Dictionary = Data.get_dict("props").get(str(host.get("prop", "")), {})
			var rect := _slot_rect(str(host.get("slot", "")), _vec(prop.get("size", [100, 100])))
			var sprite := Sprite2D.new()
			sprite.texture = UIKit.texture(LevelText.prop_sprite(host))
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
	# With "Show helpers" on, a tiny sparkle makes loose items easy to notice.
	if not helpers_on():
		return
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


## "Show helpers" (Settings, off by default): badges on things that open, sparkles on loose
## items, and Chloé barking at the next thing to do.
static func helpers_on() -> bool:
	return bool(SaveManager.settings.get("show_helpers", false))


static func _badge_for(type: String) -> String:
	if type in LevelSession.SELF_TYPES or type == "order":
		return "ui/puzzle_badge.svg"
	if type == "tool":
		return "ui/tool_badge.svg"
	if type == "dog":
		return "ui/paw_badge.svg"
	return "ui/padlock.svg"


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
	_update_chloe_mood()
	var lock: Dictionary = session.locks[lock_id]
	AudioManager.play_sfx("lock_open")
	if not bool(lock.get("is_door", false)):
		AudioManager.play_sfx("step_solved", 0.0, -4.0)
		room_view.animate_sunrise_to(sky_t(session.sunrise_t()), 2.2)
	Events.sunrise_changed.emit(sky_t(session.sunrise_t()))
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
				if not bool(SaveManager.settings.get("reduce_motion", false)):
					var base_scale := sprite.scale
					var base_pos := sprite.position
					var bounce := sprite.create_tween()
					bounce.tween_property(sprite, "scale", base_scale * Vector2(1.08, 0.94), 0.1)
					bounce.parallel().tween_property(sprite, "position", base_pos + Vector2(-size_before.x * 0.04, size_before.y * 0.06), 0.1)
					bounce.tween_property(sprite, "scale", base_scale, 0.25).set_trans(Tween.TRANS_BACK)
					bounce.parallel().tween_property(sprite, "position", base_pos, 0.25).set_trans(Tween.TRANS_BACK)
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
	_notebook.visible = false
	AudioManager.play_sfx("door_open")
	AudioManager.play_stinger("sunrise_stinger")
	# The room's slice of the morning brightens a little past its end; the last room sees the sun rise.
	var r: Array = level.get("sunrise_range", [0.0, 1.0])
	room_view.animate_sunrise_to(1.12 if float(r[1]) >= 1.0 else float(r[1]) + 0.04, 3.0)
	var result := GameState.record_level_result(level, record_id, mode, session)
	finished_level.emit(result)
	# On a walk (the first time through), the exit opens onto the next room and Juliette walks in.
	var walk_next := _walk_next_level(result)
	_play_exit(walk_next != "")
	if walk_next != "" or _ends_walk(result):
		_room_toast(result)
	await get_tree().create_timer(2.6 if not bool(SaveManager.settings.get("reduce_motion", false)) else 0.6).timeout
	AudioManager.play_sfx("level_complete")
	if walk_next != "":
		_walk_through(walk_next)
		return
	if _ends_walk(result) and not (mode == "main" and bool(level.get("finale", false))):
		_show_walk_results()
		return
	if mode == "main" and bool(level.get("finale", false)):
		# The end of Mamie's treasure hunt: her last letter, then the results.
		_letter_open = true
		GameState.mark_final_letter_read()
		var letter: Dictionary = Data.get_dict("postcards").get("final_letter", {})
		UIKit.letter(ui, str(letter.get("title", "")), str(letter.get("text", "")), func() -> void:
			_letter_open = false
			if _ends_walk(result):
				_show_walk_results()
			else:
				_show_results(result))
		return
	_show_results(result)


# ======================================================================= walking from room to room

## The room's exit (data/rooms: "exit"), with the rect of the room's door filled in.
func exit_data() -> Dictionary:
	var ex: Dictionary = (room_view.room.get("exit", {}) as Dictionary).duplicate()
	if not ex.has("rect"):
		ex["rect"] = (room_view.room.get("door", {}) as Dictionary).get("rect", [1480, 110, 260, 650])
	return ex


func _exit_rect() -> Rect2:
	var r: Array = exit_data()["rect"]
	return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))


## The next room on this walk if Juliette walks straight on ("" to show the results card instead):
## only the first time through, in the story's order.
func _walk_next_level(result: Dictionary) -> String:
	if mode != "main" or not bool(result.get("first_clear", false)):
		return ""
	var nxt := GameState.next_level_id(record_id)
	if nxt == "" or not GameState.is_level_unlocked(nxt):
		return ""
	if int(Campaign.entry(nxt).get("walk", 0)) != int(level.get("walk", -1)):
		return ""
	return nxt


## True when this was the last room of a walk, played for the first time.
func _ends_walk(result: Dictionary) -> bool:
	return mode == "main" and bool(result.get("first_clear", false)) and int(level.get("step", -1)) == Campaign.ROUTE.size() - 1


## The exit opens. Through a door you see the next room as it is right now; the stair gate swings
## open; a gate (or a door with nothing to walk into) glows with morning light.
func _play_exit(show_view: bool) -> void:
	var ex := exit_data()
	var rect := _exit_rect()
	room_zoom.reset(0.5)
	if ex.has("furniture") and ex.has("sprite_open"):
		var node: Node = room_view.furniture_nodes.get(str(ex["furniture"]))
		if node is Sprite2D:
			(node as Sprite2D).texture = UIKit.texture(str(ex["sprite_open"]))
	if show_view and ex.has("view_center") and _open_door_onto(ex, rect):
		room_view.lean_toward(rect.get_center(), 1.04, 2.4)
		return
	_open_door_glow()


## Paints the next room into the doorway: a small live render of it (a SubViewport), lit like the
## start of its slice of the morning, with the door leaf swung back against its hinge.
func _open_door_onto(ex: Dictionary, rect: Rect2) -> bool:
	var next_room := str(ex.get("view_room", ex.get("to", "")))
	if next_room == "" or Data.get_dict("rooms/" + next_room).is_empty():
		return false
	var vp := SubViewport.new()
	vp.name = "ExitView"
	vp.size = Vector2i(960, 540)
	vp.size_2d_override = Vector2i(RoomView.STAGE_SIZE)
	vp.size_2d_override_stretch = true
	add_child(vp)
	var other := RoomView.new()
	vp.add_child(other)
	other.setup(next_room)
	var r: Array = level.get("sunrise_range", [0.0, 1.0])
	other.sunrise_t = float(r[1])
	var c: Array = ex["view_center"]
	var region_size := rect.size * EXIT_VIEW_SCALE
	var region := Rect2(Vector2(float(c[0]), float(c[1])) - region_size / 2.0, region_size)
	var view := Sprite2D.new()
	view.name = "ExitViewSprite"
	view.texture = vp.get_texture()
	view.centered = false
	view.region_enabled = true
	view.region_rect = Rect2(region.position * 0.5, region.size * 0.5)
	view.position = rect.position
	view.scale = rect.size / (region.size * 0.5)
	room_view.room_layer.add_child(view)
	room_view.room_layer.move_child(view, 1)
	host_sprites["exit_view"] = view
	# The door leaf, swung back against its hinge.
	var leaf := Polygon2D.new()
	var w := rect.size.x * 0.2
	var left := str(ex.get("hinge", "left")) == "left"
	var x0 := rect.position.x if left else rect.end.x
	var x1 := x0 + (w if left else -w)
	leaf.polygon = PackedVector2Array([Vector2(x0, rect.position.y), Vector2(x1, rect.position.y + rect.size.y * 0.05),
		Vector2(x1, rect.end.y - rect.size.y * 0.03), Vector2(x0, rect.end.y)])
	leaf.color = Palette.color("wood_dark")
	room_view.room_layer.add_child(leaf)
	room_view.room_layer.move_child(leaf, 2)
	view.modulate.a = 0.0
	leaf.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(view, "modulate:a", 1.0, 0.6)
	t.tween_property(leaf, "modulate:a", 1.0, 0.3)
	return true


## A small card with the room's stars and seashells, while Juliette walks on.
func _room_toast(result: Dictionary) -> void:
	var card := PanelContainer.new()
	card.name = "RoomToast"
	card.add_theme_stylebox_override("panel", UIKit.card(18))
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	card.offset_left = -300
	card.offset_right = 300
	card.offset_top = 120
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(card)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 10)
	card.add_child(h)
	var stars := int(result.get("stars", 1))
	for i in 3:
		var s := TextureRect.new()
		s.texture = UIKit.texture("ui/star_full.svg" if i < stars else "ui/star_empty.svg")
		s.custom_minimum_size = Vector2(56, 56)
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.add_child(s)
	var shells := int(result.get("seashells", 0))
	if shells > 0:
		h.add_child(UIKit.label("   " + tr("TOAST_SHELLS") % shells, 30, Palette.color("coral_dark")))
	if bool(result.get("new_best_time", false)):
		h.add_child(UIKit.label("   " + tr("RESULTS_NEW_BEST"), 26, Palette.color("sea_deep")))
	UIKit.pop_in(card)
	for i in stars:
		get_tree().create_timer(0.2 + i * 0.25).timeout.connect(func() -> void: AudioManager.play_sfx("star_%d" % (i + 1)))
	if shells > 0:
		get_tree().create_timer(1.0).timeout.connect(func() -> void: AudioManager.play_sfx("seashell_gain"))


## The camera walks through the exit (up the stairs, through the doorway), then the next room.
func _walk_through(next_id: String) -> void:
	var ex := exit_data()
	var focus := _exit_rect().get_center()
	if ex.has("walk_to"):
		var wt: Array = ex["walk_to"]
		focus = Vector2(float(wt[0]), float(wt[1]))
	var kind := str(ex.get("kind", "door"))
	if bool(SaveManager.settings.get("reduce_motion", false)):
		Launcher.play_main(next_id, {"arrive_from": kind})
		return
	room_view.zoom_focus = focus
	var t := create_tween()
	t.tween_property(room_view, "zoom", WALK_ZOOM, WALK_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	get_tree().create_timer(WALK_SECONDS * 0.7).timeout.connect(func() -> void: Launcher.play_main(next_id, {"arrive_from": kind}))


## The end of a walk (a chapter): every room's stars, the time, and on to the next chapter.
func _show_walk_results() -> void:
	var walk_id := int(level.get("walk", 1))
	var w := Campaign.walk(walk_id)
	var rooms: Array = w.get("levels", [])
	var first_next := ""
	var next_walk := Campaign.walk(walk_id + 1)
	if not next_walk.is_empty() and not (next_walk.get("levels", []) as Array).is_empty():
		first_next = str(next_walk["levels"][0]["id"])
	var items: Array = []
	if first_next != "" and GameState.is_level_unlocked(first_next):
		items.append([tr("NEXT_CHAPTER"), func() -> void: Launcher.play_main(first_next, {"arrive_from": "front_door"}), true])
	items.append([tr("BACK_TO_BOOK"), func() -> void: Router.goto("level_select")])
	if Router.has_screen("hub"):
		items.append([tr("MENU_PENTHOUSE"), func() -> void: Router.goto("hub")])
	_results = UIKit.dialog(ui, tr(str(w.get("title", ""))), "", items)
	var body: VBoxContainer = _results.get_meta("body")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)
	body.move_child(grid, 1)
	var total := 0.0
	var star_total := 0
	for e: Dictionary in rooms:
		var id := str(e["id"])
		var rec := GameState.level_record(id)
		total += float(rec.get("best_time", 0.0))
		var stars := int(rec.get("stars", 0))
		star_total += stars
		grid.add_child(UIKit.label(Campaign.room_name(id), 30, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT))
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		for i in 3:
			var s := TextureRect.new()
			s.texture = UIKit.texture("ui/star_full.svg" if i < stars else "ui/star_empty.svg")
			s.custom_minimum_size = Vector2(40, 40)
			s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			row.add_child(s)
		grid.add_child(row)
	var info := UIKit.label(tr("WALK_DONE_INFO") % [star_total, rooms.size() * 3, _format_time(total)], 30, Palette.color("ink_soft"))
	body.add_child(info)
	body.move_child(info, 2)


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
	_notebook_button = UIKit.icon_button("ui/hint.svg", 110, tr("NOTEBOOK"))
	_notebook_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_notebook_button.offset_left = -138
	_notebook_button.offset_right = -28
	_notebook_button.offset_top = 22
	_notebook_button.offset_bottom = 132
	_notebook_button.pressed.connect(toggle_notebook)
	root.add_child(_notebook_button)
	var title := UIKit.label("%s  ·  %s" % [tr(str(room_view.room.get("name", ""))), _mode_caption()], 30, Palette.color("white_warm"))
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -500
	title.offset_right = 500
	title.offset_top = 30
	title.add_theme_color_override("font_shadow_color", Color(0.169, 0.137, 0.314, 0.6))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)
	_timer_label = UIKit.label("", 26, Palette.color("cream"))
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.offset_left = -300
	_timer_label.offset_right = 300
	_timer_label.offset_top = 74
	_timer_label.add_theme_color_override("font_shadow_color", Color(0.169, 0.137, 0.314, 0.6))
	_timer_label.add_theme_constant_override("shadow_offset_y", 2)
	_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_timer_label)

	# Zoom buttons (bottom left) and the pinch / wheel / drag / double-tap handling.
	var zoom_box := VBoxContainer.new()
	zoom_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	zoom_box.offset_left = 28
	zoom_box.offset_top = -236
	zoom_box.offset_bottom = -24
	zoom_box.add_theme_constant_override("separation", 12)
	root.add_child(zoom_box)
	var zoom_in := UIKit.icon_button("ui/zoom_in.svg", 96, tr("ZOOM_IN"))
	zoom_box.add_child(zoom_in)
	_zoom_out_button = UIKit.icon_button("ui/zoom_out.svg", 96, tr("ZOOM_OUT"))
	zoom_box.add_child(_zoom_out_button)
	room_zoom = RoomZoom.new(room_view)
	room_zoom.name = "RoomZoom"
	add_child(room_zoom)
	room_zoom.blocked = func() -> bool: return closeup.is_open() or session.finished or _letter_open or get_tree().paused or _results != null
	room_zoom.over_ui = _over_ui
	room_zoom.zoom_changed.connect(func(_z: float) -> void: _update_zoom_buttons())
	zoom_in.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		room_zoom.zoom_in())
	_zoom_out_button.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		room_zoom.zoom_out())
	_update_zoom_buttons()

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
	inventory.setup(text, bool(level.get("tutorial", false)))
	inventory.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	inventory.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory.grow_vertical = Control.GROW_DIRECTION_BEGIN
	inventory.offset_bottom = -16
	inventory.item_tapped.connect(func(id: String) -> void: toast(tr("ITEM_SELECTED") % text.item_name(id)))
	inventory.combine_requested.connect(combine_items)
	inventory.inspect_requested.connect(func(id: String) -> void:
		closeup.show_thing("item", id)
		inventory.deselect())

	# Mamie's notebook: the notes read so far and the hints.
	_notebook = NotebookPanel.new()
	root.add_child(_notebook)
	_notebook.setup(text)
	_notebook.hint_requested.connect(show_hint)


func _update_zoom_buttons() -> void:
	if _zoom_out_button:
		_zoom_out_button.disabled = room_zoom.zoom() <= 1.001
		_zoom_out_button.modulate.a = 0.45 if _zoom_out_button.disabled else 1.0


## True when a screen position is over a button, the inventory bar or a dialog (not the room).
func _over_ui(at: Vector2) -> bool:
	for layer_child in ui.get_children():
		var list: Array[Node] = [layer_child]
		list.append_array(layer_child.get_children())
		for n in list:
			var c := n as Control
			if c == null or not c.is_visible_in_tree() or c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				continue
			if c.get_global_rect().has_point(at):
				return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if closeup.is_open():
			closeup.close()
		elif _notebook.visible:
			_notebook.visible = false
		elif inventory.selected != "":
			inventory.deselect()
		elif not session.finished:
			_toggle_pause()


## Warm light pours through the balcony door and the view leans toward it.
func _open_door_glow() -> void:
	var r: Array = (room_view.room.get("door", {}) as Dictionary).get("rect", [1480, 110, 260, 650])
	var rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	var glow := ColorRect.new()
	glow.color = Palette.color("gold_light")
	glow.position = rect.position
	glow.size = rect.size
	glow.modulate.a = 0.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	room_view.stage.add_child(glow)
	var t := glow.create_tween()
	t.tween_property(glow, "modulate:a", 0.45, 1.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(glow, "modulate:a", 0.25, 1.6).set_trans(Tween.TRANS_SINE)
	room_zoom.reset(0.5)
	room_view.lean_toward(rect.get_center(), 1.05, 2.8)
	_sparkle_at(_hotspot_center("lock:" + session.door_id()), 4)


## Opens or closes Mamie's notebook (the top-right button), on the notes.
func toggle_notebook() -> void:
	if _notebook.visible:
		AudioManager.play_sfx("ui_back")
		_notebook.visible = false
		return
	AudioManager.play_sfx("page_turn")
	_notebook.open(NotebookPanel.NOTES)


## Asks Mamie for a hint: it's written on the notebook's Hints page.
func show_hint() -> void:
	if session.finished:
		return
	var goal := session.request_hint()
	AudioManager.play_sfx("hint")
	_notebook.show_hint_text(text.rich(text.hint_text(goal), 40))
	if int(goal.get("level", 1)) >= 2:
		var target := _goal_hotspot(goal)
		if target != "":
			_sparkle_at(_hotspot_center(target), 3)


## Dev mode: do the next thing a player would do (pick up, read, combine or open).
func dev_step() -> bool:
	if session == null or session.finished:
		return false
	if closeup.is_open():
		closeup.close()
	var goal := session.next_goal()
	if str(goal.get("action", "")) == "look":
		return false
	return LevelSolver.apply_goal(session, goal)


## Dev mode: solve the whole room, step by step, so the ending plays as usual.
func dev_finish() -> void:
	_paused = false
	for i in 200:
		if session.finished or not dev_step():
			break
		await get_tree().create_timer(0.05).timeout


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
	if _results or _letter_open:
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
		[tr("MENU_SETTINGS"), func() -> void:
			var panel := SettingsPanel.new()
			panel.closed.connect(func() -> void:
				_paused = false)
			ui.add_child(panel)],
		[tr("RESTART"), func() -> void: Router.goto("level", Router.params)],
		[tr("LEAVE"), func() -> void: Router.goto(_exit_screen())],
	])
	if bool(SaveManager.settings.get("dev_mode", false)):
		var body: VBoxContainer = _pause_menu.get_meta("body")
		var dev := UIKit.text_button(tr("SETTINGS_DEV"), Vector2(460, 96))
		dev.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dev.pressed.connect(func() -> void:
			_pause_menu.queue_free()
			_pause_menu = null
			var panel := DevPanel.new()
			panel.closed.connect(func() -> void: _paused = false)
			ui.add_child(panel))
		body.add_child(dev)


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
	var next_index := 3
	if bool(result.get("new_best_time", false)):
		var best := UIKit.label(tr("RESULTS_NEW_BEST"), 30, Palette.color("sea_deep"))
		body.add_child(best)
		body.move_child(best, next_index)
		next_index += 1
	var shells := int(result.get("seashells", 0))
	if shells > 0:
		var sh := UIKit.label(tr("RESULTS_SHELLS") % 0, 36, Palette.color("coral_dark"))
		body.add_child(sh)
		body.move_child(sh, next_index)
		_count_up(sh, shells, 0.35 + stars * 0.35)
	for unlock: String in result.get("unlocks", []):
		var ul := UIKit.label(unlock, 30, Palette.color("sea_deep"))
		body.add_child(ul)
		body.move_child(ul, body.get_child_count() - 2)
	# In the story walk: a line on the way to the next room.
	if mode == "main" and level.has("chapter"):
		var outro := str(Campaign.chapter(str(level["chapter"])).get("outro", ""))
		if outro != "":
			var ol := UIKit.handwriting(tr(outro), 34)
			ol.custom_minimum_size.x = 680
			body.add_child(ol)
			body.move_child(ol, next_index + 1)




## Seashells tick up after the stars have popped in, with a soft sound at the start.
func _count_up(label: Label, total: int, delay: float) -> void:
	if bool(SaveManager.settings.get("reduce_motion", false)):
		label.text = tr("RESULTS_SHELLS") % total
		AudioManager.play_sfx("seashell_gain")
		return
	var t := label.create_tween()
	t.tween_interval(delay)
	t.tween_callback(func() -> void: AudioManager.play_sfx("seashell_gain"))
	t.tween_method(func(v: float) -> void: label.text = tr("RESULTS_SHELLS") % roundi(v), 0.0, float(total), clampf(total / 40.0, 0.4, 1.0)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _exit_screen() -> String:
	return str(Router.params.get("exit_to", "level_select" if Router.has_screen("level_select") else "main_menu"))


func _mode_caption() -> String:
	match mode:
		"daily":
			return tr("MODE_DAILY")
		"endless":
			return tr("MODE_ENDLESS") % int(level.get("tier", 1))
	if level.has("walk"):
		return tr("MODE_WALK") % [tr(str(Campaign.walk(int(level["walk"])).get("title", ""))), int(level.get("step", 0)) + 1]
	return tr("MODE_TIER") % int(level.get("tier", 1))


static func _format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


static func _vec(a: Variant) -> Vector2:
	if a is Array and (a as Array).size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO


## A story note read in the main story goes into the scrapbook (its chapter page).
# ======================================================================= Mamie's notebook

## Which notebook this room writes in: the walk's (kept between its rooms), or "" (only this room).
func notebook_key() -> String:
	return "walk_%d" % int(level.get("walk", 1)) if mode == "main" and level.has("walk") else ""


func _load_notebook() -> void:
	var key := notebook_key()
	if key != "" and int(level.get("step", 0)) == 0 and mode == "main":
		GameState.notebook_clear(key)
	# Notes from earlier rooms this room needs (so a replay or a dev jump still has them).
	if key != "":
		_notes = GameState.notebook(key).duplicate(true)
	for memory_id: String in level.get("requires_notes", []):
		var m := Campaign.memory(memory_id)
		var entry := {"id": "memory:" + memory_id, "room": Campaign.memory_room_name(memory_id), "title": str(m.get("title", "")), "text": str(m.get("text", ""))}
		if m.is_empty() or _notes.any(func(e: Dictionary) -> bool: return str(e.get("id", "")) == entry["id"]):
			continue
		_notes.append(entry)
		GameState.notebook_add(key, entry)
	_notebook.set_entries(_notes)


## A note was read: it goes into Mamie's notebook, and a paper note leaves its spot once it's put down.
func _note_read(kind: String, id: String) -> void:
	var thing: Dictionary = (session.clues if kind == "clue" else session.decoys).get(id, {})
	var host: Dictionary = thing.get("host", {})
	var body := str(thing.get("text", ""))
	if body == "" or host.has("count"):
		return
	var note_id := kind + ":" + id
	var memory_id := str(thing.get("memory", ""))
	if memory_id != "":
		note_id = "memory:" + memory_id
	for e: Dictionary in _notes:
		if str(e.get("id", "")) == note_id:
			return
	var title := str(Campaign.memory(memory_id).get("title", "")) if memory_id != "" else ""
	if title == "":
		title = CloseupPanel._cap(text.host_name(host))
	var entry := {"id": note_id, "room": tr(str(room_view.room.get("name", ""))), "title": title, "text": body}
	_notes.append(entry)
	GameState.notebook_add(notebook_key(), entry)
	_notebook.set_entries(_notes)
	var takeable := str(host.get("kind", "")) == "prop" and bool(Data.get_dict("props").get(str(host.get("prop", "")), {}).get("takeable", false))
	if not takeable:
		return
	session.take_note(kind, id)
	var tuck := func() -> void:
		_remove_room_thing(kind + ":" + id)
		UIKit.wiggle(_notebook_button)
	if closeup.is_open():
		closeup.closed.connect(tuck, CONNECT_ONE_SHOT)
	else:
		tuck.call()


func _keep_memory(kind: String, id: String) -> void:
	var thing: Dictionary = (session.clues if kind == "clue" else session.decoys).get(id, {})
	var memory_id := str(thing.get("memory", ""))
	if memory_id == "" or mode != "main":
		return
	if not GameState.collect_memory(memory_id):
		return
	# Said once the note is put down, so the toast doesn't cover Mamie's words.
	if closeup.is_open():
		closeup.closed.connect(func() -> void: toast(tr("MEMORY_KEPT"), 2.5), CONNECT_ONE_SHOT)
	else:
		toast(tr("MEMORY_KEPT"), 2.5)


# ======================================================================= Chloé

## Seconds between the little sounds Chloé makes while she's hiding (seeded, so not a steady beat).
const HIDING_SOUND_SECONDS := Vector2(25.0, 45.0)
## How far in you must zoom to see the tuft of fur in her hiding place.
const TUFT_ZOOM := 1.8
## Her pose for each thing she can want (a care lock given to her).
const NEED_POSES := {"kibble": "sit", "water_jug": "pant", "leash": "scratch", "dog_brush": "fringe", "gaston": "sniff"}

var _chloe: Node2D
var _chloe_sprite: Sprite2D
var _chloe_home := Vector2.ZERO
var _chloe_busy := false
## Tapped once: she's standing, waiting for Juliette to tap where she should go.
var chloe_ready := false
var _chloe_bowl: Sprite2D
var _hiding_tuft: Sprite2D
var _hiding_timer := 0.0
var _hiding_rng := RandomNumberGenerator.new()


## Chloé sits where the sun falls in this room (room "dog_spot"). If she's hiding in this room,
## nothing shows: only a soft sound now and then, and a tuft of fur for anyone who zooms in.
func _build_chloe() -> void:
	var spot: Array = room_view.room.get("dog_spot", [960, 930])
	_chloe_home = Vector2(float(spot[0]), float(spot[1]))
	_hiding_rng.seed = hash(str(level.get("id", "")) + ":chloe")
	_hiding_timer = _hiding_rng.randf_range(HIDING_SOUND_SECONDS.x * 0.4, HIDING_SOUND_SECONDS.y * 0.5)
	var hide := hiding_lock()
	if hide != "" and hotspots.has("lock:" + hide):
		var h: Control = hotspots["lock:" + hide]
		_hiding_tuft = Sprite2D.new()
		_hiding_tuft.texture = UIKit.texture("props/chloe/chloe_tuft.svg")
		_hiding_tuft.position = h.position + Vector2(h.size.x * 0.5, h.size.y - 12.0)
		_hiding_tuft.scale = Vector2(0.7, 0.7)
		_hiding_tuft.visible = false
		_props_layer.add_child(_hiding_tuft)
		room_zoom.zoom_changed.connect(func(z: float) -> void:
			if is_instance_valid(_hiding_tuft):
				_hiding_tuft.visible = z >= TUFT_ZOOM)
	if session.dog_present:
		_spawn_chloe(_chloe_home)


## The lock where Chloé is hiding in this room ("" once she's out, or if she isn't hiding here).
func hiding_lock() -> String:
	for id: String in LevelSession._sorted_keys(session.locks):
		if session.finds_dog(id) and not session.is_open(id):
			return id
	return ""


## While she's hiding: now and then a soft whimper or sniff (not while a close-up is open).
func _chloe_process(delta: float) -> void:
	if _hiding_tuft == null or not is_instance_valid(_hiding_tuft) or session.finished or _paused or closeup.is_open():
		return
	_hiding_timer -= delta
	if _hiding_timer <= 0.0:
		_hiding_timer = _hiding_rng.randf_range(HIDING_SOUND_SECONDS.x, HIDING_SOUND_SECONDS.y)
		AudioManager.play_sfx("dog_whimper" if _hiding_rng.randf() < 0.6 else "dog_sniff")


func _spawn_chloe(at: Vector2) -> void:
	_chloe = Node2D.new()
	_chloe.position = at
	_props_layer.add_child(_chloe)
	_chloe_sprite = Sprite2D.new()
	_chloe_sprite.texture = UIKit.texture("props/chloe/chloe_sit.svg")
	_chloe_sprite.offset = Vector2(0, -80)
	_chloe.add_child(_chloe_sprite)
	var h := _add_hotspot("dog:chloe", Rect2(_chloe_home - Vector2(90, 170), Vector2(180, 180)), _chloe_sprite)
	h.move_to_front()
	if not bool(SaveManager.settings.get("reduce_motion", false)):
		var t := _chloe_sprite.create_tween().set_loops()
		t.tween_property(_chloe_sprite, "scale", Vector2(1.0, 1.03), 1.2).set_trans(Tween.TRANS_SINE)
		t.tween_property(_chloe_sprite, "scale", Vector2.ONE, 1.3).set_trans(Tween.TRANS_SINE)
	_update_chloe_mood()


## Her resting pose shows what she wants (no words): sitting by her empty bowl, panting, scratching
## to go out, her fringe over her eyes, or looking around for Gaston.
func _update_chloe_mood() -> void:
	if _chloe == null or _chloe_busy or chloe_ready:
		return
	var pose := "sit"
	var want := session.dog_wants()
	var wanted_type := ""
	if want != "":
		wanted_type = str(session.items.get(session.lock_item(want), {}).get("type", ""))
		pose = str(NEED_POSES.get(wanted_type, "sit"))
	_chloe_sprite.texture = UIKit.texture("props/chloe/chloe_%s.svg" % pose)
	_chloe_sprite.flip_h = false
	var show_bowl := wanted_type in ["kibble", "water_jug"]
	if show_bowl and _chloe_bowl == null:
		_chloe_bowl = Sprite2D.new()
		_chloe_bowl.texture = UIKit.texture("props/chloe/bowl_empty.svg")
		_chloe_bowl.position = _chloe_home + Vector2(-120, -20)
		_props_layer.add_child(_chloe_bowl)
		_props_layer.move_child(_chloe_bowl, _chloe.get_index())
	elif not show_bowl and _chloe_bowl != null:
		_chloe_bowl.queue_free()
		_chloe_bowl = null


## Tapping Chloé: with an item selected she's given it; otherwise she gets ready to go somewhere
## (tap her again to let her sit back down). With "Show helpers" on she barks at the next step.
func _tap_chloe() -> void:
	if not session.dog_present or _chloe_busy:
		return
	if inventory.selected != "":
		_give_to_chloe(inventory.selected)
		return
	if chloe_ready:
		_set_chloe_ready(false)
		return
	if helpers_on():
		var target := _goal_hotspot(session.next_goal())
		if target != "" and hotspots.has(target):
			var h: Control = hotspots[target]
			_walk_chloe_to(h.position + Vector2(h.size.x / 2.0, h.size.y), "walk", func() -> void:
				AudioManager.play_sfx("dog_bark")
				_sparkle_at(_hotspot_center(target), 2))
			return
	_set_chloe_ready(true)


func _exit_tree() -> void:
	if chloe_ready:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)


func _set_chloe_ready(on: bool) -> void:
	chloe_ready = on
	if on:
		AudioManager.play_sfx("dog_huff")
		_chloe_sprite.texture = UIKit.texture("props/chloe/chloe_ready.svg")
		_hop_chloe()
		var paw := UIKit.texture("ui/paw_badge.svg")
		if paw and not OS.has_feature("mobile"):
			var img := paw.get_image()
			if img:
				img.resize(48, 48)
				Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), Input.CURSOR_POINTING_HAND, Vector2(24, 24))
	else:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)
		_update_chloe_mood()


## Juliette tapped somewhere while Chloé was ready: she trots there and does what fits.
func send_chloe(key: String) -> Dictionary:
	_set_chloe_ready(false)
	var target := _chloe_target(key)
	var trip := session.send_dog_to(key)
	match str(trip.get("result", "")):
		"acted":
			pass # _on_dog_acted walks her there and back.
		"needs":
			_walk_chloe_to(target, "sniff", func() -> void: AudioManager.play_sfx("dog_whimper"))
		"silly":
			var find := str(trip.get("find", "sock"))
			_walk_chloe_to(target, "sniff", func() -> void: AudioManager.play_sfx("dog_sniff"), true, func() -> void: _drop_silly_find(find))
		"empty":
			_walk_chloe_to(target, "sniff", func() -> void: AudioManager.play_sfx("dog_sniff"))
	return trip


## Where Chloé goes for a tapped key: the bottom middle of its hotspot, or the tapped point.
func _chloe_target(key: String) -> Vector2:
	if key != "background" and hotspots.has(key):
		var h: Control = hotspots[key]
		return h.position + Vector2(h.size.x / 2.0, h.size.y)
	var at := room_view.stage.get_global_transform_with_canvas().affine_inverse() * get_viewport().get_mouse_position()
	return Vector2(clampf(at.x, 120.0, 2280.0), clampf(at.y, 700.0, 1380.0))


## She drops something silly at Juliette's feet: it lies there a moment, then she lies down on it.
func _drop_silly_find(find: String) -> void:
	if _chloe == null:
		return
	AudioManager.play_sfx("dog_drop")
	var s := Sprite2D.new()
	s.texture = UIKit.texture("props/chloe/find_%s.svg" % find)
	s.position = _chloe_home + Vector2(110, -30)
	_props_layer.add_child(s)
	host_sprites["silly_find"] = s
	UIKit.pop_in(s)
	_hop_chloe()
	var t := s.create_tween()
	t.tween_interval(3.0)
	t.tween_property(s, "modulate:a", 0.0, 0.6)
	t.tween_callback(func() -> void:
		host_sprites.erase("silly_find")
		s.queue_free())


func _give_to_chloe(item: String) -> void:
	var result := session.give_to_dog(item)
	inventory.deselect()
	if result == "wrong" or result == "unavailable":
		AudioManager.play_sfx("item_fail")
		toast(tr("DOG_WRONG") % text.item_name(item))


## Chloé did something: trot over, sniff or dig or fetch, come back. (The lock is already open.)
func _on_dog_acted(lock_id: String, action: String) -> void:
	if _chloe == null:
		return
	var key := "lock:" + lock_id
	if action == "care":
		AudioManager.play_sfx("dog_squeak" if str(session.items.get(session.lock_item(lock_id), {}).get("type", "")) == "gaston" else "dog_happy")
		_hop_chloe()
		_update_chloe_mood()
		# She drops what she was guarding at Juliette's feet.
		var inside := session.things_at(lock_id)
		if not inside.is_empty():
			toast(tr("DOG_HAPPY"))
			closeup.show_lock(lock_id)
		return
	var target := _chloe_home
	if hotspots.has(key):
		var h: Control = hotspots[key]
		target = h.position + Vector2(h.size.x / 2.0, h.size.y)
	var pose := "dig" if action == "dig" else "sniff"
	_walk_chloe_to(target, pose, func() -> void:
		AudioManager.play_sfx("dog_dig" if action == "dig" else "dog_sniff")
		if action == "sniff":
			AudioManager.play_sfx("dog_bark")
		toast(tr("DOG_FOUND_IT") % text.lock_name(lock_id)))


func _on_dog_found() -> void:
	var from := _chloe_home
	for id: String in session.locks.keys():
		if session.finds_dog(id) and hotspots.has("lock:" + id):
			var h: Control = hotspots["lock:" + id]
			from = h.position + Vector2(h.size.x / 2.0, h.size.y)
	if _hiding_tuft != null and is_instance_valid(_hiding_tuft):
		_hiding_tuft.queue_free()
	_hiding_tuft = null
	if mode == "main" or mode == "replay":
		GameState.set_chloe_found()
	AudioManager.play_sfx("dog_squeak")
	toast(tr("DOG_FOUND"), 4.0)
	_spawn_chloe(from)
	_walk_chloe_to(_chloe_home, "walk", func() -> void: AudioManager.play_sfx("dog_happy"), false)


## Walks Chloé to a stage point, plays a pose there, then (optionally) back to her spot.
## `on_home` runs once she's back.
func _walk_chloe_to(target: Vector2, pose: String, on_arrive: Callable, come_back: bool = true, on_home: Callable = Callable()) -> void:
	if _chloe == null:
		return
	if bool(SaveManager.settings.get("reduce_motion", false)):
		on_arrive.call()
		_chloe.position = _chloe_home
		if on_home.is_valid():
			on_home.call()
		_update_chloe_mood()
		return
	_chloe_busy = true
	var dist := _chloe.position.distance_to(target)
	var t := _chloe.create_tween()
	t.tween_callback(func() -> void:
		_chloe_sprite.texture = UIKit.texture("props/chloe/chloe_walk.svg")
		_chloe_sprite.flip_h = target.x > _chloe.position.x)
	t.tween_property(_chloe, "position", target, clampf(dist / 700.0, 0.3, 1.4)).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void:
		_chloe_sprite.texture = UIKit.texture("props/chloe/chloe_%s.svg" % pose)
		on_arrive.call())
	t.tween_interval(0.9)
	if come_back:
		t.tween_callback(func() -> void:
			_chloe_sprite.texture = UIKit.texture("props/chloe/chloe_walk.svg")
			_chloe_sprite.flip_h = _chloe_home.x > _chloe.position.x)
		t.tween_property(_chloe, "position", _chloe_home, clampf(dist / 700.0, 0.3, 1.4)).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void:
		_chloe_busy = false
		_update_chloe_mood()
		if on_home.is_valid():
			on_home.call())


func _hop_chloe() -> void:
	if _chloe == null or bool(SaveManager.settings.get("reduce_motion", false)):
		return
	var y := _chloe.position.y
	var t := _chloe.create_tween()
	t.tween_property(_chloe, "position:y", y - 40.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_chloe, "position:y", y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
