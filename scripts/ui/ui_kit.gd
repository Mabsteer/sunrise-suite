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
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## A RichTextLabel in Grandma's handwriting (for notes and clues).
static func handwriting(bbcode: String, size: int = 46) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_override("normal_font", HANDWRITING)
	r.add_theme_font_size_override("normal_font_size", size)
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


## A gentle "no" wiggle.
static func wiggle(node: Control) -> void:
	if bool(SaveManager.settings.get("reduce_motion", false)):
		return
	node.pivot_offset = node.size / 2.0
	var t := node.create_tween()
	for angle in [3.0, -3.0, 2.0, -1.5, 0.0]:
		t.tween_property(node, "rotation_degrees", angle, 0.06)
