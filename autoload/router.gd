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
	if fade and not reduce_motion:
		await get_tree().process_frame
		var t_in := create_tween()
		t_in.tween_property(_fade_rect, "color:a", 0.0, FADE_SECONDS)
		await t_in.finished
	_fade_rect.color.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	return true
