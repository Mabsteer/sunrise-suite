extends Control
## Céline's house: the walks through the house, one row per walk with the seven rooms in route order
## (kitchen → hall → bedroom → living room → garden → shed → front garden), plus Endless Sunrise.

const CARD_SIZE := Vector2(236, 228)

var _scroll: ScrollContainer
var _current_row: Control


func _ready() -> void:
	var bg := TextureRect.new()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	grad.colors = PackedColorArray([Palette.color("lavender_light"), Palette.color("peach_light"), Palette.color("cream")])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = 150
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(center)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 26)
	center.add_child(list)

	var current := GameState.current_level_id()
	for w in Campaign.walks():
		list.add_child(_walk_row(w, current))
	list.add_child(_endless_row())
	var pad := Control.new()
	pad.custom_minimum_size.y = 60
	list.add_child(pad)

	_build_header()
	AudioManager.play_music("menu_theme")
	if _current_row:
		_scroll_to_current.call_deferred()


func _build_header() -> void:
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UIKit.box(Palette.color("white_warm", 0.85), 0, Color.TRANSPARENT, 0, 18))
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 140
	add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	header.add_child(row)
	var back := UIKit.icon_button("ui/back.svg", 96, tr("BACK"))
	back.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_back")
		Router.goto("main_menu"))
	row.add_child(back)
	var title := UIKit.label(tr("BOOK_TITLE"), 54, Palette.color("ink"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	row.add_child(UIKit.counters())


func _walk_row(w: Dictionary, current: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.card(22))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	head.add_child(titles)
	titles.add_child(UIKit.label(tr(str(w.get("title", ""))), 38, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT))
	titles.add_child(UIKit.label(tr(str(w.get("subtitle", ""))), 26, Palette.color("ink_soft"), HORIZONTAL_ALIGNMENT_LEFT))
	var gate := int(w.get("star_gate", 0))
	if gate > 0 and GameState.total_stars() < gate:
		var gl := UIKit.label(tr("GATE_NEEDS") % gate, 28, Palette.color("coral_dark"), HORIZONTAL_ALIGNMENT_RIGHT)
		gl.autowrap_mode = TextServer.AUTOWRAP_OFF
		head.add_child(gl)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	v.add_child(cards)
	for e in Campaign.levels():
		if int(e["walk"]) != int(w.get("id", 0)):
			continue
		cards.add_child(_level_card(e, current))
		if str(e["id"]) == current:
			_current_row = panel
	return panel


func _level_card(e: Dictionary, current: String) -> Control:
	var id := str(e["id"])
	var room := str(e["room"])
	var available := Campaign.room_available(room)
	var unlocked := available and GameState.is_level_unlocked(id)
	var done := GameState.is_level_completed(id)
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	if id == current and unlocked:
		var sb := UIKit.box(Palette.color("peach_light"), 24, Palette.color("coral"), 6, 10)
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			button.add_theme_stylebox_override(state, sb)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 10
	v.offset_top = 10
	v.offset_right = -10
	v.offset_bottom = -8
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(v)
	var thumb := RoomThumb.new(room, 0.25 + 0.7 * float(GameState.level_stars(id)) / 3.0 if done else 0.15)
	thumb.custom_minimum_size = Vector2(0, 132)
	v.add_child(thumb)
	var room_name := tr(str(Data.get_dict("rooms/" + room).get("name", room))) if available else room
	var name_label := UIKit.label("%d · %s" % [int(e.get("step", 0)) + 1, room_name], 22, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	v.add_child(name_label)
	var stars := HBoxContainer.new()
	stars.add_theme_constant_override("separation", 2)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(stars)
	for i in 3:
		var s := TextureRect.new()
		s.texture = UIKit.texture("ui/star_full.svg" if i < GameState.level_stars(id) else "ui/star_empty.svg")
		s.custom_minimum_size = Vector2(30, 30)
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars.add_child(s)
	if done and _best_time(id) > 0.0:
		var best := UIKit.label(tr("BEST_TIME") % LevelScene._format_time(_best_time(id)), 20, Palette.color("ink_soft"), HORIZONTAL_ALIGNMENT_RIGHT)
		best.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		best.autowrap_mode = TextServer.AUTOWRAP_OFF
		stars.add_child(best)
	if e.has("postcard") and not GameState.has_postcard(str(e["postcard"])):
		var stamp := TextureRect.new()
		stamp.texture = UIKit.texture("props/common/postcard_small.svg")
		stamp.size = Vector2(52, 38)
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.position = Vector2(CARD_SIZE.x - 66, 16)
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamp.tooltip_text = tr("POSTCARD_HERE")
		button.add_child(stamp)
	if not unlocked:
		var veil := ColorRect.new()
		veil.color = Color(0.231, 0.18, 0.227, 0.45)
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(veil)
		var lock := TextureRect.new()
		lock.texture = UIKit.texture("ui/padlock.svg")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.size = Vector2(80, 80)
		lock.position = CARD_SIZE / 2.0 - Vector2(40, 60)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(lock)
	button.pressed.connect(_on_card.bind(id, unlocked, done))
	return button


func _best_time(id: String) -> float:
	return float(GameState.level_record(id).get("best_time", 0.0))


func _endless_row() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.card(22))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	panel.add_child(h)
	var thumb := RoomThumb.new("front_garden" if Campaign.room_available("front_garden") else "lounge", 1.0)
	thumb.custom_minimum_size = Vector2(300, 170)
	h.add_child(thumb)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	v.add_child(UIKit.label(tr("ENDLESS_TITLE"), 42, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT))
	var unlocked := GameState.campaign_finished()
	var best := int((SaveManager.data.get("endless", {}) as Dictionary).get("best_tier", 0))
	var sub := tr("ENDLESS_LOCKED") if not unlocked else (tr("ENDLESS_BEST") % best if best > 0 else tr("ENDLESS_READY"))
	var sub_label := UIKit.label(sub, 30, Palette.color("ink_soft"), HORIZONTAL_ALIGNMENT_LEFT)
	sub_label.custom_minimum_size.x = 900
	v.add_child(sub_label)
	var play := UIKit.primary(UIKit.text_button(tr("ENDLESS_PLAY"), Vector2(320, 96)))
	play.disabled = not unlocked
	play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		Launcher.play_endless())
	h.add_child(play)
	return panel


func _on_card(id: String, unlocked: bool, done: bool) -> void:
	if not unlocked:
		AudioManager.play_sfx("item_fail")
		var reason := GameState.lock_reason(id)
		var text := tr("LOCKED_PREVIOUS")
		if reason.begins_with("stars:"):
			text = tr("LOCKED_STARS") % int(reason.trim_prefix("stars:"))
		elif not Campaign.room_available(str(Campaign.entry(id).get("room", ""))):
			text = tr("LOCKED_SOON")
		UIKit.dialog(self, tr("LOCKED_TITLE"), text, [[tr("OK"), Callable(), true]])
		return
	AudioManager.play_sfx("ui_click")
	if not done:
		Launcher.play_main(id)
		return
	var room_name := tr(str(Data.get_dict("rooms/" + str(Campaign.entry(id).get("room", ""))).get("name", "")))
	UIKit.dialog(self, tr("LEVEL_POPUP_TITLE") % room_name, tr("LEVEL_POPUP_TEXT"), [
		[tr("PLAY_AGAIN_SAME"), func() -> void: Launcher.play_main(id), true],
		[tr("PLAY_FRESH"), func() -> void: Launcher.play_replay(id)],
		[tr("CANCEL"), Callable()],
	])


func _scroll_to_current() -> void:
	await get_tree().process_frame
	if _current_row:
		_scroll.scroll_vertical = maxi(0, int(_current_row.position.y) - 40)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Router.goto("main_menu")
