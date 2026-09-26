class_name SkyBackdrop
extends ColorRect
## The sunrise sky + sea shader on a large rect. Set `sunrise_t` (0..1, >1 keeps rising).
## `horizon_y` and `sun_x` are in the parent's (stage) coordinates.

const SHADER := preload("res://assets/shaders/sunrise_sky.gdshader")

@export var sunrise_t: float = 0.5:
	set(value):
		sunrise_t = value
		_update()
@export var horizon_y: float = 450.0:
	set(value):
		horizon_y = value
		_update()
@export var sun_x: float = 960.0:
	set(value):
		sun_x = value
		_update()
## Stage y where the sky gradient begins (so windows show the whole gradient, not just its bottom).
@export var gradient_top_y: float = 60.0:
	set(value):
		gradient_top_y = value
		_update()
@export var sun_radius_px: float = 64.0:
	set(value):
		sun_radius_px = value
		_update()

var _material: ShaderMaterial


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material = _material


func _ready() -> void:
	resized.connect(_update)
	Events.settings_changed.connect(_update)
	_update()


func _update() -> void:
	if _material == null or size.y <= 0.0:
		return
	_material.set_shader_parameter("sunrise_t", sunrise_t)
	_material.set_shader_parameter("aspect", size.x / size.y)
	_material.set_shader_parameter("horizon", (horizon_y - position.y) / size.y)
	_material.set_shader_parameter("sun_x", (sun_x - position.x) / size.x)
	_material.set_shader_parameter("gradient_top", (gradient_top_y - position.y) / size.y)
	_material.set_shader_parameter("sun_radius", sun_radius_px / size.y)
	var reduce_motion := bool(SaveManager.settings.get("reduce_motion", false))
	_material.set_shader_parameter("motion", 0.25 if reduce_motion else 1.0)
