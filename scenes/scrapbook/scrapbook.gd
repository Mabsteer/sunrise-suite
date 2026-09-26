extends Control
## Céline's scrapbook: the postcards you found (tap to read, turn over for the back) and, once all
## are found, her final letter.

const CARD := Vector2(470, 310)

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
	page.add_theme_stylebox_override("panel", UIKit.paper(34))
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 70
	page.offset_right = -70
	page.offset_top = 150
	page.offset_bottom = -40
	add_child(page)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_child(v)
	var list := GameState.postcard_list()
	var rows := [list.slice(0, 3), list.slice(3)]
	var tilt := [-2.5, 1.5, -1.0, 2.0, -1.8]
	var i := 0
	for row_items: Array in rows:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 40)
		v.add_child(row)
		for p: Dictionary in row_items:
			row.add_child(_slot(p, tilt[i % tilt.size()]))
			i += 1
	var letter := UIKit.text_button(tr("SCRAPBOOK_LETTER") if GameState.all_postcards_found() else tr("SCRAPBOOK_LETTER_LOCKED"), Vector2(560, 96))
	letter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	letter.disabled = not GameState.all_postcards_found()
	if GameState.all_postcards_found():
		UIKit.primary(letter)
	letter.pressed.connect(show_letter)
	v.add_child(letter)
	AudioManager.play_music("hub_penthouse")


func _slot(p: Dictionary, tilt: float) -> Control:
	var id := str(p["id"])
	var holder := Control.new()
	holder.custom_minimum_size = CARD
	if GameState.has_postcard(id):
		var b := TextureButton.new()
		b.texture_normal = UIKit.texture(str(p["front"]))
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.size = CARD
		b.pivot_offset = CARD / 2.0
		b.rotation_degrees = tilt
		b.pressed.connect(show_postcard.bind(id))
		holder.add_child(b)
		for corner in [Vector2(-10, -8), Vector2(CARD.x - 70, -8)]:
			var tape := ColorRect.new()
			tape.color = Color(0.984, 0.890, 0.627, 0.75)
			tape.size = Vector2(80, 26)
			tape.position = corner
			tape.rotation_degrees = -12.0 if corner.x < 0 else 12.0
			tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(tape)
		var caption := str(p.get("place", ""))
		if p.has("year"):
			caption += "  ·  %d" % int(p["year"])
		var name_label := UIKit.label(caption, 24, Palette.color("ink_soft"))
		name_label.position = Vector2(0, CARD.y - 4)
		name_label.size = Vector2(CARD.x, 30)
		holder.add_child(name_label)
	else:
		var empty := EmptySlot.new()
		empty.size = CARD
		holder.add_child(empty)
		var level_id := GameState.postcard_level(id)
		var hint := tr("SCRAPBOOK_MISSING")
		if level_id != "":
			hint = tr("SCRAPBOOK_HINT") % (Campaign.index_of(level_id) + 1)
		var l := UIKit.label(hint, 26, Palette.color("ink_soft"))
		l.position = Vector2(30, CARD.y / 2.0 - 10)
		l.size = Vector2(CARD.x - 60, 60)
		holder.add_child(l)
	return holder


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
	AudioManager.play_sfx("postcard_found")
	_open_overlay()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", UIKit.paper(50))
	paper.custom_minimum_size = Vector2(1100, 0)
	center.add_child(paper)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	paper.add_child(v)
	v.add_child(UIKit.label(str(letter.get("title", "")), 44, Palette.color("coral_dark")))
	# Long letters scroll inside the paper, so the close button always stays on screen.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(1000, 640)
	v.add_child(scroll)
	var text := UIKit.handwriting(str(letter.get("text", "")), 38)
	text.custom_minimum_size.x = 960
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(text)
	var close := UIKit.text_button(tr("CLOSE"), Vector2(260, 90))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_overlay)
	v.add_child(close)
	UIKit.pop_in(paper)
	SaveManager.data["final_letter_read"] = true
	SaveManager.save_game()


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _overlay:
			_close_overlay()
		else:
			Router.goto("main_menu")
