extends Control
## The Daily Sunrise: today's puzzle, your streak, streak rewards and the Sunrise Calendar
## (every completed day becomes a tile painted in that day's sky colours).

var _month_offset := 0
var _grid: GridContainer
var _month_label: Label


func _ready() -> void:
	var bg := TextureRect.new()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Palette.color("lavender_light"), Palette.color("peach_light"), Palette.color("gold_light")])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var header := HBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 28
	header.offset_right = -28
	header.offset_top = 22
	header.add_theme_constant_override("separation", 20)
	add_child(header)
	var back := UIKit.icon_button("ui/back.svg", 96, tr("BACK"))
	back.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_back")
		Router.goto("main_menu"))
	header.add_child(back)
	var title := UIKit.label(tr("MENU_DAILY"), 56, Palette.color("ink"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UIKit.counters())

	var body := HBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 60
	body.offset_right = -60
	body.offset_top = 150
	body.offset_bottom = -40
	body.add_theme_constant_override("separation", 36)
	add_child(body)
	body.add_child(_today_panel())
	body.add_child(_calendar_panel())
	AudioManager.play_music("daily_sunrise")


func _today_panel() -> Control:
	var today := Daily.today_key()
	var info := Daily.level_for(today)
	var room := Data.get_dict("rooms/" + str(info["room"]))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.card(30))
	panel.custom_minimum_size = Vector2(760, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)
	var date := Daily.parse_key(today)
	var weekday := tr("WEEKDAY_%d" % int(date.get("weekday", 0)))
	v.add_child(UIKit.label(tr("DAILY_TODAY") % weekday, 40, Palette.color("ink")))
	var thumb := RoomThumb.new(str(info["room"]), 0.55)
	thumb.custom_minimum_size = Vector2(0, 280)
	v.add_child(thumb)
	v.add_child(UIKit.label("%s  ·  %s" % [tr(str(room.get("name", ""))), tr("TIER_TITLE") % int(info["tier"])], 34, Palette.color("ink_soft")))
	var done := GameState.daily_done(today)
	var play := UIKit.text_button(tr("DAILY_PLAY_AGAIN") if done else tr("DAILY_PLAY"), Vector2(520, 110))
	if not done:
		UIKit.primary(play)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.add_theme_font_size_override("font_size", 40)
	play.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		Launcher.play_daily())
	v.add_child(play)
	if done:
		v.add_child(UIKit.label(tr("DAILY_DONE_TEXT") % GameState.daily_stars(today), 30, Palette.color("sea_deep")))
	# Streak + sleep-in + next reward
	var streak := GameState.current_streak(today)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var sun := TextureRect.new()
	sun.texture = UIKit.texture("ui/symbols/sun.svg")
	sun.custom_minimum_size = Vector2(64, 64)
	sun.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sun.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sun.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sun)
	var streak_label := UIKit.label(tr("DAILY_STREAK_LABEL") % [streak, int(GameState.daily_data().get("best_streak", 0))], 34, Palette.color("ink"))
	streak_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(streak_label)
	var sleep := tr("DAILY_SLEEP_IN_FREE") if GameState.sleep_in_available(today) else tr("DAILY_SLEEP_IN_TAKEN")
	var sleep_label := UIKit.label(sleep, 26, Palette.color("ink_soft"))
	sleep_label.custom_minimum_size.x = 680
	v.add_child(sleep_label)
	var next := _next_streak_reward(streak)
	if next != "":
		var n := UIKit.label(next, 28, Palette.color("coral_dark"))
		n.custom_minimum_size.x = 680
		v.add_child(n)
	return panel


func _next_streak_reward(streak: int) -> String:
	var rewards: Dictionary = Data.get_dict("rewards").get("streak", {})
	var best_n := 0
	var best_id := ""
	for k: String in rewards.keys():
		var n := int(k)
		if n > streak and (best_n == 0 or n < best_n) and GameState.owned_count(str(rewards[k])) == 0:
			best_n = n
			best_id = str(rewards[k])
	if best_id == "":
		return ""
	return tr("DAILY_NEXT_REWARD") % [best_n - streak, str(GameState.decor(best_id).get("name", best_id))]


func _calendar_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.card(30))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var nav := HBoxContainer.new()
	v.add_child(nav)
	var prev := UIKit.icon_button("ui/back.svg", 80)
	prev.pressed.connect(func() -> void:
		_month_offset -= 1
		_fill_month())
	nav.add_child(prev)
	_month_label = UIKit.label("", 40, Palette.color("ink"))
	_month_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(_month_label)
	var next := UIKit.icon_button("ui/forward.svg", 80)
	next.pressed.connect(func() -> void:
		if _month_offset < 0:
			_month_offset += 1
			_fill_month())
	nav.add_child(next)
	var heads := GridContainer.new()
	heads.columns = 7
	heads.add_theme_constant_override("h_separation", 10)
	v.add_child(heads)
	for wd in [1, 2, 3, 4, 5, 6, 0]:
		var l := UIKit.label(tr("WEEKDAY_SHORT_%d" % wd), 24, Palette.color("ink_soft"))
		l.custom_minimum_size.x = 118
		heads.add_child(l)
	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	v.add_child(_grid)
	v.add_child(UIKit.label(tr("CALENDAR_HELP"), 24, Palette.color("ink_soft")))
	_fill_month()
	return panel


func _fill_month() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var today := Daily.today_key()
	var t := Daily.parse_key(today)
	var year := int(t["year"])
	var month := int(t["month"]) + _month_offset
	while month < 1:
		month += 12
		year -= 1
	_month_label.text = "%s %d" % [tr("MONTH_%d" % month), year]
	var first_key := "%04d-%02d-01" % [year, month]
	var first_weekday := int(Daily.parse_key(first_key).get("weekday", 0))
	var lead := (first_weekday + 6) % 7   # Monday first
	for i in lead:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(118, 96)
		_grid.add_child(spacer)
	for day in range(1, Daily.days_in_month(year, month) + 1):
		var key := "%04d-%02d-%02d" % [year, month, day]
		var tile := DayTile.new()
		tile.day = day
		tile.key = key
		tile.done = GameState.daily_done(key)
		tile.stars = GameState.daily_stars(key)
		tile.is_today = key == today
		tile.future = Daily.day_number(key) > Daily.day_number(today)
		tile.custom_minimum_size = Vector2(118, 96)
		_grid.add_child(tile)


## One calendar day. Completed days are painted with that day's sunrise colours.
class DayTile extends Control:
	var day := 1
	var key := ""
	var done := false
	var stars := 0
	var is_today := false
	var future := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if done:
			var c := Daily.sky_colors_for(key)
			var h := size.y
			draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, h * 0.55), Vector2(0, h * 0.55)]), PackedColorArray([c[0], c[0], c[1], c[1]]))
			draw_polygon(PackedVector2Array([Vector2(0, h * 0.55), Vector2(size.x, h * 0.55), Vector2(size.x, h * 0.7), Vector2(0, h * 0.7)]), PackedColorArray([c[1], c[1], c[2], c[2]]))
			draw_rect(Rect2(0, h * 0.7, size.x, h * 0.3), Color("2e8c8c"))
			draw_circle(Vector2(size.x * 0.5, h * 0.66), h * 0.16, Color("f6c453"))
			for i in stars:
				draw_circle(Vector2(size.x - 16 - i * 16, h - 14), 6, Color("fbe3a0"))
		else:
			draw_rect(r, Color(1, 0.984, 0.961, 0.35 if future else 0.8))
		if is_today:
			draw_rect(r, Palette.color("coral"), false, 5.0)
		var font := get_theme_default_font()
		var col := Color.WHITE if done else (Palette.color("ink_soft") if not future else Color(0.42, 0.35, 0.4, 0.4))
		draw_string(font, Vector2(10, 30), str(day), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, col)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Router.goto("main_menu")
