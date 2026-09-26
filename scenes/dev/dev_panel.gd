class_name DevPanel
extends Control
## The owner's dev menu (Settings: tap the version number 5 times). Jump to any room, unlock
## everything, see the answers of the room you're in, solve a step or the whole room, turn the
## helpers on or off, and check what the audio is doing. Normal players never see it.

signal closed()

var _body: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.169, 0.137, 0.314, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.card(36))
	card.custom_minimum_size = Vector2(1500, 1100)
	center.add_child(card)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	card.add_child(outer)
	var head := HBoxContainer.new()
	outer.add_child(head)
	var title := UIKit.label(tr("DEV_TITLE"), 48, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := UIKit.icon_button("ui/close.svg", 80, tr("CLOSE"))
	close.pressed.connect(close_panel)
	head.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 14)
	scroll.add_child(_body)
	_build()
	UIKit.pop_in(card)


func close_panel() -> void:
	AudioManager.play_sfx("ui_back")
	closed.emit()
	queue_free()


## The level screen that's open right now, or null.
func current_level() -> Node:
	return get_tree().get_first_node_in_group("level_screen") if is_inside_tree() else null


func _build() -> void:
	var level := current_level()
	if level != null and level.get("session") != null:
		_section(tr("DEV_THIS_ROOM"))
		var row := _row()
		row.add_child(_button(tr("DEV_NEXT_STEP"), func() -> void:
			level.call("dev_step")
			close_panel()))
		row.add_child(_button(tr("DEV_FINISH_ROOM"), func() -> void:
			close_panel()
			level.call("dev_finish")))
		for line in solution_lines(level.get("session"), level.get("text")):
			_body.add_child(_small(line))

	_section(tr("DEV_JUMP"))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_body.add_child(grid)
	for e: Dictionary in Campaign.levels():
		var id := str(e["id"])
		var caption := "%s\n%s" % [id.get_slice("_", 0).to_upper(), Campaign.room_name(id)]
		var b := UIKit.text_button(caption, Vector2(196, 110))
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(func() -> void:
			queue_free()
			GameState.dev_prepare_jump(id)
			Launcher.play_main(id))
		grid.add_child(b)

	_section(tr("DEV_PROGRESS"))
	var prog := _row()
	prog.add_child(_toggle(tr("DEV_UNLOCK_ALL"), "dev_unlock_all"))
	prog.add_child(_toggle(tr("SETTINGS_HELPERS"), "show_helpers"))
	var reset := _button(tr("DEV_RESET"), func() -> void:
		UIKit.dialog(self, tr("RESET_TITLE"), tr("RESET_TEXT"), [
			[tr("RESET_YES"), func() -> void:
				SaveManager.reset_progress()
				queue_free()
				Router.goto("main_menu")],
			[tr("RESET_NO"), Callable(), true],
		]))
	prog.add_child(reset)
	prog.add_child(_button(tr("DEV_OFF"), func() -> void:
		SaveManager.settings["dev_mode"] = false
		SaveManager.save_settings()
		close_panel()))

	_section(tr("DEV_AUDIO"))
	var audio_label := _small(_audio_text())
	var arow := _row()
	arow.add_child(_button(tr("SETTINGS_TEST_SOUND"), func() -> void:
		AudioManager.play_test_sound()
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			if is_instance_valid(audio_label):
				audio_label.text = _audio_text())))
	arow.add_child(_button(tr("DEV_RESUME_AUDIO"), func() -> void:
		AudioManager.resume_web_audio()
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			if is_instance_valid(audio_label):
				audio_label.text = _audio_text())))
	_body.add_child(audio_label)


## One line per lock: its name, type, answer, and where its clue is.
static func solution_lines(session: LevelSession, text: LevelText) -> PackedStringArray:
	var out := PackedStringArray()
	if session == null or text == null:
		return out
	for id: String in LevelSession._sorted_keys(session.locks):
		var lock: Dictionary = session.locks[id]
		var what := ""
		if lock.has("answer"):
			what = text.answer_text(id)
		elif session.lock_item(id) != "":
			what = "use " + text.item_name(session.lock_item(id))
		var clue_places := PackedStringArray()
		for c in session.lock_clues(id):
			clue_places.append(text.clue_place(c))
		var line := "%s %s (%s): %s" % ["✓" if session.is_open(id) else "•", text.lock_name(id), str(lock.get("type", "")), what]
		if not clue_places.is_empty():
			line += "   ← " + ", ".join(clue_places)
		if lock.has("_why"):
			line += "   (" + str(lock["_why"]) + ")"
		out.append(line)
	return out


func _audio_text() -> String:
	var st := AudioManager.audio_status()
	var parts := PackedStringArray()
	for bus: String in (st["buses"] as Dictionary).keys():
		var b: Dictionary = st["buses"][bus]
		parts.append("%s %s dB%s" % [bus, str(b["volume_db"]), " (muted)" if bool(b["mute"]) else ""])
	return "Browser audio: %s\nBuses: %s\nLast sounds: %s" % [str(st["web_audio"]), ", ".join(parts), ", ".join(PackedStringArray(st["recent"]))]


func _section(caption: String) -> void:
	var l := UIKit.label(caption, 34, Palette.color("coral"), HORIZONTAL_ALIGNMENT_LEFT)
	_body.add_child(l)


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_body.add_child(row)
	return row


func _small(text: String) -> Label:
	var l := UIKit.label(text, 24, Palette.color("ink_soft"), HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 1400
	return l


func _button(caption: String, cb: Callable) -> Button:
	var b := UIKit.text_button(caption, Vector2(300, 84))
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		cb.call())
	return b


func _toggle(caption: String, key: String) -> CheckButton:
	var t := CheckButton.new()
	t.text = caption
	t.button_pressed = bool(SaveManager.settings.get(key, false))
	t.focus_mode = Control.FOCUS_NONE
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_icon_override("checked", UIKit.texture("ui/toggle_on.svg"))
	t.add_theme_icon_override("unchecked", UIKit.texture("ui/toggle_off.svg"))
	t.toggled.connect(func(on: bool) -> void:
		SaveManager.settings[key] = on
		SaveManager.save_settings())
	return t
