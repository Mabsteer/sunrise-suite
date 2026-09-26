class_name SettingsPanel
extends Control
## Settings overlay: volumes, fullscreen, timer, reduce motion, text size, credits and reset.
## Add it to any screen: add_child(SettingsPanel.new())

signal closed()

const SLIDERS := [
	["SETTINGS_MASTER", "volume_master"],
	["SETTINGS_MUSIC", "volume_music"],
	["SETTINGS_SFX", "volume_sfx"],
	["SETTINGS_AMBIENCE", "volume_ambience"],
]
const TEXT_SIZES := [1.0, 1.15, 1.3]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.169, 0.137, 0.314, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.card(40))
	card.custom_minimum_size = Vector2(1080, 0)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	card.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var title := UIKit.label(tr("MENU_SETTINGS"), 52, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := UIKit.icon_button("ui/close.svg", 88, tr("CLOSE"))
	close.pressed.connect(close_panel)
	head.add_child(close)

	var s := SaveManager.settings
	for entry: Array in SLIDERS:
		v.add_child(_slider_row(tr(str(entry[0])), str(entry[1]), float(s.get(str(entry[1]), 0.8))))
	if not OS.has_feature("mobile"):
		v.add_child(_toggle_row(tr("SETTINGS_FULLSCREEN"), "fullscreen", func() -> void: SaveManager.apply_display()))
	v.add_child(_toggle_row(tr("SETTINGS_TIMER"), "show_timer"))
	v.add_child(_toggle_row(tr("SETTINGS_REDUCE_MOTION"), "reduce_motion"))
	v.add_child(_text_size_row())

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	v.add_child(buttons)
	var credits := UIKit.text_button(tr("SETTINGS_CREDITS"), Vector2(260, 90))
	credits.pressed.connect(func() -> void:
		AudioManager.play_sfx("page_turn")
		UIKit.dialog(self, tr("SETTINGS_CREDITS"), tr("CREDITS_TEXT"), [[tr("CLOSE"), Callable(), true]]))
	buttons.add_child(credits)
	var reset := UIKit.text_button(tr("SETTINGS_RESET"), Vector2(300, 90))
	reset.pressed.connect(_confirm_reset)
	buttons.add_child(reset)
	var done := UIKit.primary(UIKit.text_button(tr("SETTINGS_DONE"), Vector2(260, 90)))
	done.pressed.connect(close_panel)
	buttons.add_child(done)
	UIKit.pop_in(card)


func close_panel() -> void:
	AudioManager.play_sfx("ui_back")
	SaveManager.save_settings()
	closed.emit()
	queue_free()


func _slider_row(caption: String, key: String, value: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var l := UIKit.label(caption, 32, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 300
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(520, 64)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	var grab := UIKit.texture("ui/grabber.svg")
	slider.add_theme_icon_override("grabber", grab)
	slider.add_theme_icon_override("grabber_highlight", grab)
	row.add_child(slider)
	var pct := UIKit.label("%d%%" % int(round(value * 100)), 30, Palette.color("ink_soft"))
	pct.custom_minimum_size.x = 100
	pct.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(pct)
	slider.value_changed.connect(func(v: float) -> void:
		SaveManager.settings[key] = v
		pct.text = "%d%%" % int(round(v * 100))
		AudioManager.apply_volumes())
	slider.drag_ended.connect(func(_changed: bool) -> void:
		AudioManager.play_sfx("ui_click" if key != "volume_music" else "hint"))
	return row


func _toggle_row(caption: String, key: String, after: Callable = Callable()) -> Control:
	var t := CheckButton.new()
	t.text = caption
	t.button_pressed = bool(SaveManager.settings.get(key, false))
	t.focus_mode = Control.FOCUS_NONE
	t.custom_minimum_size = Vector2(0, 72)
	t.add_theme_font_size_override("font_size", int(32 * UIKit.text_scale()))
	t.add_theme_icon_override("checked", UIKit.texture("ui/toggle_on.svg"))
	t.add_theme_icon_override("unchecked", UIKit.texture("ui/toggle_off.svg"))
	t.toggled.connect(func(on: bool) -> void:
		SaveManager.settings[key] = on
		AudioManager.play_sfx("ui_click")
		SaveManager.save_settings()
		if after.is_valid():
			after.call())
	return t


func _text_size_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := UIKit.label(tr("SETTINGS_TEXT_SIZE"), 32, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 300
	row.add_child(l)
	var current := float(SaveManager.settings.get("text_scale", 1.0))
	var group := ButtonGroup.new()
	for i in TEXT_SIZES.size():
		var b := Button.new()
		b.text = ["A", "A+", "A++"][i]
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = absf(current - float(TEXT_SIZES[i])) < 0.01
		b.custom_minimum_size = Vector2(120, 80)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", int(28 + i * 6))
		var size_value: float = TEXT_SIZES[i]
		b.pressed.connect(func() -> void:
			SaveManager.settings["text_scale"] = size_value
			SaveManager.save_settings()
			AudioManager.play_sfx("ui_click"))
		row.add_child(b)
	var note := UIKit.label(tr("SETTINGS_TEXT_NOTE"), 22, Palette.color("ink_soft"), HORIZONTAL_ALIGNMENT_LEFT)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(note)
	return row


func _confirm_reset() -> void:
	AudioManager.play_sfx("item_fail")
	UIKit.dialog(self, tr("RESET_TITLE"), tr("RESET_TEXT"), [
		[tr("RESET_YES"), func() -> void:
			SaveManager.reset_progress()
			queue_free()
			Router.goto("main_menu")],
		[tr("RESET_NO"), Callable(), true],
	])
