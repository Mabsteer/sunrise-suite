extends Node
## Switches between screens with a soft fade. Screens read their parameters from Router.params.
##   Router.goto("level", {"level_id": "main_03"})

const SCREENS := {
	"main_menu": "res://scenes/main_menu/main_menu.tscn",
	"hub": "res://scenes/hub/hub.tscn",
	"level_select": "res://scenes/level_select/level_select.tscn",
	"level": "res://scenes/level/level.tscn",
	"scrapbook": "res://scenes/scrapbook/scrapbook.tscn",
	"calendar": "res://scenes/calendar/calendar.tscn",
	"room_preview": "res://scenes/room/room_preview.tscn",
	"art_sheet": "res://scenes/dev/art_sheet.tscn",
}
const FADE_SECONDS := 0.35

var params: Dictionary = {}
var current: String = ""
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _busy := false
var _rotate_hint: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.169, 0.137, 0.314, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)
	_build_rotate_hint()
	get_viewport().size_changed.connect(_update_rotate_hint)
	_update_rotate_hint()


## On a phone held upright the rooms get tiny, so gently suggest turning it sideways.
func _build_rotate_hint() -> void:
	_rotate_hint = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.169, 0.137, 0.314, 0.9)
	sb.set_corner_radius_all(40)
	sb.set_content_margin_all(40)
	_rotate_hint.add_theme_stylebox_override("panel", sb)
	_rotate_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_rotate_hint.offset_left = -700
	_rotate_hint.offset_right = 700
	_rotate_hint.offset_top = -260
	_rotate_hint.offset_bottom = 260
	_rotate_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 30)
	_rotate_hint.add_child(v)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/sprites/ui/icon.svg") as Texture2D
	icon.custom_minimum_size = Vector2(220, 220)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.rotation_degrees = 90.0
	icon.pivot_offset = Vector2(110, 110)
	v.add_child(icon)
	var l := Label.new()
	l.text = tr("ROTATE_HINT")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 72)
	l.add_theme_color_override("font_color", Color(1, 0.984, 0.961))
	v.add_child(l)
	var ok := Button.new()
	ok.text = tr("ROTATE_OK")
	ok.custom_minimum_size = Vector2(520, 130)
	ok.add_theme_font_size_override("font_size", 56)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func() -> void:
		_rotate_hint_dismissed = true
		_update_rotate_hint())
	v.add_child(ok)
	_fade_layer.add_child(_rotate_hint)


var _rotate_hint_dismissed := false


func _update_rotate_hint() -> void:
	if _rotate_hint == null:
		return
	var s := get_viewport().get_visible_rect().size
	_rotate_hint.visible = s.x < s.y * 1.05 and not _rotate_hint_dismissed


func has_screen(screen: String) -> bool:
	return SCREENS.has(screen) and ResourceLoader.exists(SCREENS[screen])


## Changes to another screen. Returns false if the screen doesn't exist.
func goto(screen: String, screen_params: Dictionary = {}, fade: bool = true) -> bool:
	if not has_screen(screen):
		push_error("Router: unknown screen '%s'" % screen)
		return false
	if _busy:
		return false
	_busy = true
	params = screen_params
	var reduce_motion := bool(SaveManager.settings.get("reduce_motion", false))
	if fade and not reduce_motion:
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		var t_out := create_tween()
		t_out.tween_property(_fade_rect, "color:a", 1.0, FADE_SECONDS)
		await t_out.finished
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(SCREENS[screen])
	if err != OK:
		push_error("Router: could not open %s (error %d)" % [screen, err])
	current = screen
	# The scene change happens at the end of the frame; wait so current_scene is ready for callers.
	await get_tree().process_frame
	if fade and not reduce_motion:
		var t_in := create_tween()
		t_in.tween_property(_fade_rect, "color:a", 0.0, FADE_SECONDS)
		await t_in.finished
	_fade_rect.color.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	return true
