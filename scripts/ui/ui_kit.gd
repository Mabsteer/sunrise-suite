class_name UIKit
extends RefCounted
## Small helpers for building cozy UI in code: styles, icon buttons, labels.

const SPRITES := "res://assets/sprites/"
const HANDWRITING := preload("res://assets/theme/handwriting.tres")


static func texture(path: String) -> Texture2D:
	var full := path if path.begins_with("res://") else SPRITES + path
	if not ResourceLoader.exists(full):
		push_warning("UIKit: missing texture %s" % full)
		return null
	return load(full) as Texture2D


static func box(bg: Color, radius: int = 24, border: Color = Color.TRANSPARENT, border_width: int = 0, margin: float = 16.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border_width > 0:
		sb.border_color = border
		sb.set_border_width_all(border_width)
	sb.set_content_margin_all(margin)
	return sb


static func card(margin: float = 28.0) -> StyleBoxFlat:
	var sb := box(Palette.color("white_warm"), 34, Palette.color("sand"), 3, margin)
	sb.shadow_color = Color(0.231, 0.18, 0.227, 0.25)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 8)
	return sb


static func paper(margin: float = 30.0) -> StyleBoxFlat:
	var sb := box(Palette.color("cream"), 10, Palette.color("peach_light"), 2, margin)
	sb.shadow_color = Color(0.231, 0.18, 0.227, 0.18)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(3, 6)
	return sb


## A square button showing an icon. Big enough for fingers (min 88px).
static func icon_button(icon_path: String, size: float = 96.0, tooltip: String = "") -> Button:
	var b := Button.new()
	b.icon = texture(icon_path)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(size, size)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.tooltip_text = tooltip
	b.focus_mode = Control.FOCUS_NONE
	var pad := size * 0.16
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var base := b.get_theme_stylebox(state, "Button") as StyleBoxFlat
		if base:
			var sb := base.duplicate() as StyleBoxFlat
			sb.set_content_margin_all(pad)
			b.add_theme_stylebox_override(state, sb)
	return b


static func label(text: String, size: int = 34, color: Color = Color(0.231, 0.18, 0.227), align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(size * text_scale()))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## A RichTextLabel in Mamie's handwriting (for notes and clues).
static func handwriting(bbcode: String, size: int = 46) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_override("normal_font", HANDWRITING)
	r.add_theme_font_size_override("normal_font_size", int(size * text_scale()))
	r.add_theme_color_override("default_color", Palette.color("ink"))
	r.text = bbcode
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Scales the text of every label/button under `node` with the player's text-size setting.
static func text_scale() -> float:
	return clampf(float(SaveManager.settings.get("text_scale", 1.0)), 0.8, 1.5)


static func pop_in(node: CanvasItem, seconds: float = 0.22) -> void:
	if bool(SaveManager.settings.get("reduce_motion", false)):
		node.modulate.a = 1.0
		return
	node.modulate.a = 0.0
	if node is Control:
		var c := node as Control
		c.pivot_offset = c.size / 2.0
		c.scale = Vector2(0.92, 0.92)
		var t := c.create_tween().set_parallel(true)
		t.tween_property(c, "modulate:a", 1.0, seconds)
		t.tween_property(c, "scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		node.create_tween().tween_property(node, "modulate:a", 1.0, seconds)


## Makes a button the coral "main action" button.
static func primary(b: Button) -> Button:
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var base := b.get_theme_stylebox(state, "Button") as StyleBoxFlat
		if base == null:
			continue
		var sb := base.duplicate() as StyleBoxFlat
		sb.bg_color = Palette.color("coral") if state == "normal" else (Palette.color("coral_dark") if state.contains("pressed") else Palette.color("terracotta_light"))
		sb.border_color = Palette.color("coral_dark")
		b.add_theme_stylebox_override(state, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Palette.color("white_warm"))
	return b


static func text_button(caption: String, min_size: Vector2 = Vector2(420, 96)) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", int(34 * text_scale()))
	return b


## A modal card with a title, optional text and buttons [[caption, callable, primary?], ...]. Returns the overlay.
## Any button closes the dialog before running its callable.
static func dialog(parent: Node, title: String, body: String, buttons: Array) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.169, 0.137, 0.314, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", card(44))
	panel.custom_minimum_size = Vector2(780, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	panel.add_child(v)
	v.add_child(label(title, 52, Palette.color("ink")))
	if body != "":
		var b := label(body, 34, Palette.color("ink_soft"))
		b.custom_minimum_size.x = 680
		v.add_child(b)
	for entry: Array in buttons:
		var button := text_button(str(entry[0]), Vector2(460, 96))
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if entry.size() > 2 and bool(entry[2]):
			primary(button)
		var cb: Callable = entry[1]
		button.pressed.connect(func() -> void:
			AudioManager.play_sfx("ui_click")
			overlay.queue_free()
			if cb.is_valid():
				cb.call())
		v.add_child(button)
	overlay.set_meta("body", v)
	parent.add_child(overlay)
	pop_in(panel)
	return overlay


## A handwritten letter on paper, scrolling if it's long, with a close button. `on_close` runs after.
static func letter(parent: Node, title: String, body: String, on_close: Callable = Callable()) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.169, 0.137, 0.314, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var paper_card := PanelContainer.new()
	paper_card.add_theme_stylebox_override("panel", paper(50))
	paper_card.custom_minimum_size = Vector2(1100, 0)
	center.add_child(paper_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	paper_card.add_child(v)
	v.add_child(label(title, 44, Palette.color("coral_dark")))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(1000, 640)
	v.add_child(scroll)
	var text := handwriting(body, 38)
	text.custom_minimum_size.x = 960
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(text)
	var close := text_button(TranslationServer.translate("CLOSE"), Vector2(260, 90))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_back")
		overlay.queue_free()
		if on_close.is_valid():
			on_close.call())
	v.add_child(close)
	parent.add_child(overlay)
	pop_in(paper_card)
	AudioManager.play_sfx("postcard_found")
	return overlay


## Seashell + star counters for screen headers.
static func counters() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	for pair in [["ui/star_full.svg", str(GameState.total_stars())], ["ui/seashell.svg", str(GameState.seashells())]]:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", box(Palette.color("white_warm", 0.92), 30, Palette.color("sand"), 3, 10))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		chip.add_child(h)
		var icon := TextureRect.new()
		icon.texture = texture(str(pair[0]))
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(icon)
		var l := label(str(pair[1]), 34, Palette.color("ink"))
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.custom_minimum_size.x = 56
		h.add_child(l)
		row.add_child(chip)
	return row


## A gentle "no" wiggle.
static func wiggle(node: Control) -> void:
	if bool(SaveManager.settings.get("reduce_motion", false)):
		return
	node.pivot_offset = node.size / 2.0
	var t := node.create_tween()
	for angle in [3.0, -3.0, 2.0, -1.5, 0.0]:
		t.tween_property(node, "rotation_degrees", angle, 0.06)
