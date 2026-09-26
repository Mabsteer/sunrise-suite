extends Control
## Céline's scrapbook: a look back on her life, one page per chapter (room) in route order, from her
## last years back to her childhood. Each page holds that period's postcard and the memories read
## there. After the last chapter comes her last letter, once the treasure hunt is finished.

const TILE := Vector2(410, 372)
const CARD := Vector2(300, 198)

var _overlay: Control


func _ready() -> void:
	var bg := TextureRect.new()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Palette.color("peach_light"), Palette.color("sand")])
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
	var title := UIKit.label(tr("SCRAPBOOK_TITLE"), 56, Palette.color("ink"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var count := UIKit.label(tr("SCRAPBOOK_COUNT") % [GameState.postcards_found_count(), GameState.postcard_list().size()], 32, Palette.color("ink_soft"), HORIZONTAL_ALIGNMENT_RIGHT)
	count.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(count)

	var page := PanelContainer.new()
	page.add_theme_stylebox_override("panel", UIKit.paper(26))
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 60
	page.offset_right = -60
	page.offset_top = 140
	page.offset_bottom = -30
	add_child(page)
	var center := CenterContainer.new()
	page.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 22)
	center.add_child(grid)
	var tilt := [-1.5, 1.2, -0.8, 1.6, -1.2, 0.9, -1.6, 1.0]
	var i := 0
	for c: Dictionary in Data.get_dict("story").get("chapters", []):
		grid.add_child(_chapter_tile(c, i, tilt[i % tilt.size()]))
		i += 1
	grid.add_child(_letter_tile())
	AudioManager.play_music("hub_penthouse")


## One chapter of Céline's life: years, title, its postcard (or the room), and how many memories were found.
func _chapter_tile(c: Dictionary, index: int, tilt: float) -> Control:
	var room := str(c.get("room", ""))
	var b := Button.new()
	b.custom_minimum_size = TILE
	b.focus_mode = Control.FOCUS_NONE
	var sb := UIKit.box(Palette.color("white_warm", 0.7), 18, Palette.color("sand"), 3, 12)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(show_chapter.bind(room))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 10
	v.offset_bottom = -10
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	v.add_child(UIKit.label("%d  ·  %s" % [index + 1, str(c.get("years", ""))], 22, Palette.color("coral_dark")))
	var t := UIKit.label(tr(str(c.get("title", ""))), 28, Palette.color("ink"))
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.clip_text = true
	v.add_child(t)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 222)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(holder)
	var pc := _postcard_for(room)
	if not pc.is_empty() and GameState.has_postcard(str(pc["id"])):
		var front := TextureRect.new()
		front.texture = UIKit.texture(str(pc["front"]))
		front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		front.custom_minimum_size = CARD
		front.pivot_offset = CARD / 2.0
		front.rotation_degrees = tilt
		front.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(front)
	elif not pc.is_empty():
		var slot := Control.new()
		slot.custom_minimum_size = CARD
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(slot)
		var empty := EmptySlot.new()
		empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(empty)
		var hint := UIKit.label(tr("SCRAPBOOK_HINT") % tr(str(Data.get_dict("rooms/" + room).get("name", room))).to_lower(), 24, Palette.color("ink_soft"))
		hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hint.offset_left = 20
		hint.offset_right = -20
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(hint)
	else:
		var thumb := RoomThumb.new(room, 0.2 + 0.8 * index / 6.0)
		thumb.custom_minimum_size = CARD
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(thumb)
	var mem := _memories(c)
	var found := 0
	for m: Dictionary in mem:
		if GameState.has_memory(str(m.get("id", ""))):
			found += 1
	var line := tr("SCRAPBOOK_MEMORIES") % [found, mem.size()] if not mem.is_empty() else tr("SCRAPBOOK_NO_MEMORIES")
	v.add_child(UIKit.label(line, 22, Palette.color("ink_soft")))
	return b


func _letter_tile() -> Control:
	var open := GameState.story_finished()
	var b := Button.new()
	b.custom_minimum_size = TILE
	b.focus_mode = Control.FOCUS_NONE
	var sb := UIKit.box(Palette.color("peach_light", 0.9) if open else Palette.color("white_warm", 0.5), 18, Palette.color("coral") if open else Palette.color("sand"), 4, 12)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(state, sb)
	b.disabled = not open
	b.pressed.connect(show_letter)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_right = -18
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var env := Envelope.new()
	env.custom_minimum_size = Vector2(0, 150)
	env.sealed = not open
	v.add_child(env)
	var l := UIKit.label(tr("SCRAPBOOK_LETTER") if open else tr("SCRAPBOOK_LETTER_LOCKED"), 26, Palette.color("ink") if open else Palette.color("ink_soft"))
	l.custom_minimum_size.x = TILE.x - 40
	v.add_child(l)
	return b


## A chapter page: the period, its intro, the postcard and every memory (read or still waiting).
func show_chapter(room: String) -> void:
	var c := Campaign.chapter(room)
	if c.is_empty():
		return
	AudioManager.play_sfx("page_turn")
	_open_overlay()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", UIKit.paper(40))
	paper.custom_minimum_size = Vector2(1300, 0)
	center.add_child(paper)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	paper.add_child(v)
	v.add_child(UIKit.label(str(c.get("years", "")), 28, Palette.color("coral_dark")))
	v.add_child(UIKit.label(tr(str(c.get("title", ""))), 48, Palette.color("ink")))
	var intro := UIKit.handwriting(tr(str(c.get("intro", ""))), 38)
	intro.custom_minimum_size.x = 1200
	v.add_child(intro)
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 22)
	row.add_theme_constant_override("v_separation", 18)
	v.add_child(row)
	var pc := _postcard_for(room)
	if not pc.is_empty():
		var found := GameState.has_postcard(str(pc["id"]))
		var pb := _memory_card(str(pc.get("place", "")) if found else tr("SCRAPBOOK_MISSING"), UIKit.texture(str(pc["front"])) if found else null, found)
		if found:
			pb.pressed.connect(func() -> void: show_postcard(str(pc["id"])))
		row.add_child(pb)
	for m: Dictionary in _memories(c):
		var id := str(m.get("id", ""))
		var found_m := GameState.has_memory(id)
		var mb := _memory_card(tr(str(m.get("title", ""))) if found_m else tr("SCRAPBOOK_MEMORY_WAITING"), UIKit.texture("props/common/note.svg") if found_m else null, found_m)
		if found_m:
			mb.pressed.connect(func() -> void: UIKit.letter(self, tr(str(m.get("title", ""))), UIKit.symbol_icons(tr(str(m.get("text", ""))), 40)))
		row.add_child(mb)
	var close := UIKit.text_button(tr("CLOSE"), Vector2(260, 90))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_overlay)
	v.add_child(close)
	UIKit.pop_in(paper)


func _memory_card(caption: String, icon: Texture2D, found: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(250, 210)
	b.focus_mode = Control.FOCUS_NONE
	b.expand_icon = true
	b.icon = icon
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.text = caption
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 22)
	b.disabled = not found
	if not found:
		var sb := UIKit.box(Palette.color("white_warm", 0.4), 16, Palette.color("ink_soft", 0.4), 3, 12)
		for state in ["normal", "disabled"]:
			b.add_theme_stylebox_override(state, sb)
	return b


func show_postcard(id: String) -> void:
	var p := GameState.postcard(id)
	AudioManager.play_sfx("page_turn")
	_open_overlay()
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.offset_bottom = -130
	_overlay.add_child(holder)
	var card := Control.new()
	card.custom_minimum_size = Vector2(900, 590)
	holder.add_child(card)
	var front := TextureRect.new()
	front.texture = UIKit.texture(str(p["front"]))
	front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(front)
	var back := PanelContainer.new()
	back.add_theme_stylebox_override("panel", UIKit.paper(40))
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.visible = false
	card.add_child(back)
	var bv := VBoxContainer.new()
	back.add_child(bv)
	var place_text := str(p.get("place", ""))
	if p.has("year"):
		place_text += ", %d" % int(p["year"])
	var place := UIKit.label(place_text, 30, Palette.color("coral_dark"), HORIZONTAL_ALIGNMENT_LEFT)
	bv.add_child(place)
	var text := UIKit.handwriting(str(p.get("text", "")), 42)
	text.custom_minimum_size.x = 800
	bv.add_child(text)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	buttons.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	buttons.offset_top = -120
	buttons.offset_bottom = -24
	buttons.offset_left = -400
	buttons.offset_right = 400
	_overlay.add_child(buttons)
	var turn := UIKit.primary(UIKit.text_button(tr("POSTCARD_TURN"), Vector2(360, 96)))
	turn.pressed.connect(func() -> void:
		AudioManager.play_sfx("page_turn")
		card.pivot_offset = card.size / 2.0
		var t := card.create_tween()
		t.tween_property(card, "scale:x", 0.0, 0.15)
		t.tween_callback(func() -> void:
			front.visible = not front.visible
			back.visible = not back.visible)
		t.tween_property(card, "scale:x", 1.0, 0.15))
	buttons.add_child(turn)
	var close := UIKit.text_button(tr("CLOSE"), Vector2(260, 96))
	close.pressed.connect(_close_overlay)
	buttons.add_child(close)


func show_letter() -> void:
	var letter: Dictionary = Data.get_dict("postcards").get("final_letter", {})
	_close_overlay()
	_overlay = UIKit.letter(self, str(letter.get("title", "")), str(letter.get("text", "")), func() -> void: _overlay = null)
	GameState.mark_final_letter_read()


func _postcard_for(room: String) -> Dictionary:
	for e in Campaign.levels():
		if str(e.get("room", "")) == room and e.has("postcard"):
			return GameState.postcard(str(e["postcard"]))
	return {}


func _memories(c: Dictionary) -> Array:
	return c.get("memories", [])


func _open_overlay() -> void:
	_close_overlay()
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.169, 0.137, 0.314, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	add_child(_overlay)


func _close_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null


## An empty, dashed postcard spot.
class EmptySlot extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2(6, 6), size - Vector2(12, 12))
		draw_rect(r, Color(1, 1, 1, 0.3))
		var dash := 18.0
		var col := Palette.color("ink_soft", 0.5)
		for edge in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end], [r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
			var a: Vector2 = edge[0]
			var b: Vector2 = edge[1]
			var length := a.distance_to(b)
			var dir := (b - a).normalized()
			var d := 0.0
			while d < length:
				draw_line(a + dir * d, a + dir * minf(d + dash, length), col, 4.0)
				d += dash * 2.0


## A little envelope drawing for the last letter (sealed with a heart until the hunt is done).
class Envelope extends Control:
	var sealed := true

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := minf(size.x * 0.7, 220.0)
		var h := w * 0.62
		var o := Vector2((size.x - w) / 2.0, (size.y - h) / 2.0)
		draw_rect(Rect2(o + Vector2(6, 8), Vector2(w, h)), Color(0.231, 0.18, 0.227, 0.15))
		draw_rect(Rect2(o, Vector2(w, h)), Palette.color("cream"))
		draw_colored_polygon(PackedVector2Array([o, o + Vector2(w, 0), o + Vector2(w / 2.0, h * 0.58)]), Palette.color("sand"))
		draw_polyline(PackedVector2Array([o, o + Vector2(w / 2.0, h * 0.58), o + Vector2(w, 0)]), Palette.color("wood_light"), 3.0)
		var c := o + Vector2(w / 2.0, h * 0.58)
		draw_circle(c, 18.0, Palette.color("coral") if sealed else Palette.color("gold"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _overlay:
			_close_overlay()
		else:
			Router.goto("main_menu")
