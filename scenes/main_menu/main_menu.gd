extends Control
## Title screen: the lounge at dawn slowly brightening behind the title, and the main buttons.

var _room: RoomView


func _ready() -> void:
	_room = RoomView.new()
	add_child(_room)
	_room.setup("lounge")
	_room.sunrise_t = 0.12
	_room.animate_sunrise_to(0.62, 24.0)

	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color(0.169, 0.137, 0.314, 0.72), Color(0.169, 0.137, 0.314, 0.3), Color(0.169, 0.137, 0.314, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.anchor_bottom = 0.75
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	column.offset_left = -560
	column.offset_right = 560
	column.offset_top = 90
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	var title := UIKit.label(tr("TITLE"), 148, Palette.color("white_warm"))
	title.add_theme_color_override("font_shadow_color", Color(0.169, 0.137, 0.314, 0.45))
	title.add_theme_constant_override("shadow_offset_y", 6)
	column.add_child(title)
	column.add_child(UIKit.label(tr("SUBTITLE"), 46, Palette.color("cream")))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 36
	column.add_child(spacer)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(buttons)
	var play_caption := tr("MENU_PLAY") if GameState.completed_count() == 0 else tr("MENU_CONTINUE")
	var play := UIKit.primary(UIKit.text_button(play_caption, Vector2(520, 110)))
	play.add_theme_font_size_override("font_size", 42)
	play.pressed.connect(_on_play)
	buttons.add_child(play)
	if Campaign.room_available("lounge"):
		var daily := UIKit.text_button(_daily_caption(), Vector2(520, 96))
		daily.pressed.connect(_on_daily)
		buttons.add_child(daily)
	for entry in [["hub", "MENU_PENTHOUSE"], ["scrapbook", "MENU_SCRAPBOOK"]]:
		if Router.has_screen(str(entry[0])):
			var b := UIKit.text_button(tr(str(entry[1])), Vector2(520, 96))
			var screen := str(entry[0])
			b.pressed.connect(func() -> void:
				AudioManager.play_sfx("ui_click")
				Router.goto(screen))
			buttons.add_child(b)
	if ResourceLoader.exists("res://scenes/settings/settings_panel.gd"):
		var s := UIKit.text_button(tr("MENU_SETTINGS"), Vector2(520, 96))
		s.pressed.connect(_on_settings)
		buttons.add_child(s)

	var counters := UIKit.counters()
	counters.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	counters.offset_left = -330
	counters.offset_right = -28
	counters.offset_top = 24
	counters.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(counters)

	var version := UIKit.label("v" + str(ProjectSettings.get_setting("application/config/version", "0.1.0")), 26, Color(1, 0.984, 0.961, 0.7), HORIZONTAL_ALIGNMENT_RIGHT)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -260
	version.offset_top = -64
	version.offset_right = -24
	version.offset_bottom = -16
	add_child(version)
	AudioManager.play_music("menu_theme")
	AudioManager.play_ambience("ambience_ocean")


func _daily_caption() -> String:
	var done := (SaveManager.data.get("daily", {}) as Dictionary).get("completed", {}) as Dictionary
	return tr("MENU_DAILY_DONE") if done.has(Daily.today_key()) else tr("MENU_DAILY")


func _on_play() -> void:
	AudioManager.play_sfx("ui_click")
	if GameState.completed_count() == 0:
		Launcher.play_main(GameState.current_level_id())
	else:
		Router.goto("level_select")


func _on_daily() -> void:
	AudioManager.play_sfx("ui_click")
	if Router.has_screen("calendar"):
		Router.goto("calendar")
	else:
		Launcher.play_daily()


func _on_settings() -> void:
	AudioManager.play_sfx("ui_click")
	var panel: Control = (load("res://scenes/settings/settings_panel.gd") as GDScript).new()
	add_child(panel)
