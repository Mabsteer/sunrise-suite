class_name NotebookPanel
extends PanelContainer
## Mamie's notebook (the top-right button in a room). Two tabs:
##  - Notes: every note Juliette has read on this walk, newest first, grouped by room
##  - Hints: ask Mamie for a hint (each ask on the same step says a little more)

signal hint_requested()

const NOTES := "notes"
const HINTS := "hints"

var tab := NOTES
var _text: LevelText
var _entries: Array = []
var _hint_bbcode := ""
var _notes_button: Button
var _hints_button: Button
var _body: VBoxContainer
var _scroll: ScrollContainer


func setup(level_text: LevelText) -> void:
	_text = level_text
	add_theme_stylebox_override("panel", UIKit.paper(24))
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -900
	offset_right = -28
	offset_top = 148
	offset_bottom = 900
	visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)
	_notes_button = _tab_button(tr("NOTEBOOK_NOTES"), NOTES)
	head.add_child(_notes_button)
	_hints_button = _tab_button(tr("NOTEBOOK_HINTS"), HINTS)
	head.add_child(_hints_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var close := UIKit.icon_button("ui/close.svg", 72, tr("CLOSE"))
	close.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_back")
		visible = false)
	head.add_child(close)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 16)
	_scroll.add_child(_body)


## Opens the notebook on a tab ("notes" or "hints").
func open(which: String) -> void:
	tab = which
	visible = true
	_rebuild()
	UIKit.pop_in(self)


## The notes to show: [{ "room": String, "title": String, "text": String }], oldest first.
func set_entries(entries: Array) -> void:
	_entries = entries
	if visible:
		_rebuild()


## Shows Mamie's hint on the Hints tab.
func show_hint_text(bbcode: String) -> void:
	_hint_bbcode = bbcode
	open(HINTS)


func _tab_button(caption: String, which: String) -> Button:
	var b := UIKit.text_button(caption, Vector2(220, 72))
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(func() -> void:
		AudioManager.play_sfx("page_turn")
		tab = which
		_rebuild())
	return b


func _rebuild() -> void:
	for c in _body.get_children():
		c.queue_free()
	for pair: Array in [[_notes_button, NOTES], [_hints_button, HINTS]]:
		var b: Button = pair[0]
		if pair[1] == tab:
			UIKit.primary(b)
		else:
			for state in ["normal", "hover", "pressed", "hover_pressed"]:
				b.remove_theme_stylebox_override(state)
			for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
				b.remove_theme_color_override(c)
	if tab == NOTES:
		_build_notes()
	else:
		_build_hints()
	_scroll.scroll_vertical = 0


func _build_notes() -> void:
	if _entries.is_empty():
		_body.add_child(_label(tr("NOTEBOOK_EMPTY"), 30, Palette.color("ink_soft")))
		return
	var room := ""
	for i in range(_entries.size() - 1, -1, -1):
		var e: Dictionary = _entries[i]
		if str(e.get("room", "")) != room:
			room = str(e.get("room", ""))
			_body.add_child(_label(room, 26, Palette.color("coral_dark")))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UIKit.box(Palette.color("white_warm"), 18, Palette.color("sand"), 2, 18))
		_body.add_child(card)
		var cv := VBoxContainer.new()
		card.add_child(cv)
		if str(e.get("title", "")) != "":
			cv.add_child(_label(str(e["title"]), 26, Palette.color("ink")))
		var r := UIKit.handwriting(_text.rich(str(e.get("text", "")), 38) if _text else str(e.get("text", "")), 38)
		r.custom_minimum_size.x = 780
		cv.add_child(r)


func _build_hints() -> void:
	if _hint_bbcode != "":
		var r := UIKit.handwriting(_hint_bbcode, 42)
		r.custom_minimum_size.x = 800
		_body.add_child(r)
	else:
		_body.add_child(_label(tr("NOTEBOOK_HINT_INTRO"), 30, Palette.color("ink_soft")))
	var ask := UIKit.primary(UIKit.text_button(tr("NOTEBOOK_ASK") if _hint_bbcode == "" else tr("NOTEBOOK_ASK_MORE"), Vector2(460, 90)))
	ask.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ask.pressed.connect(func() -> void: hint_requested.emit())
	_body.add_child(ask)


func _label(caption: String, size: int, color: Color) -> Label:
	var l := UIKit.label(caption, size, color, HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 800
	return l
