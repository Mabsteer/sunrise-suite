class_name Hotspot
extends Control
## An invisible tappable area over something in the room. Brightens its sprite on hover (desktop),
## and accepts inventory items dropped on it.

signal tapped(key: String)
signal item_dropped(key: String, item_id: String)

var key := ""
var sprite: CanvasItem
var _pressed_at := Vector2.INF


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void:
		if sprite:
			sprite.self_modulate = Color(1.12, 1.1, 1.06))
	mouse_exited.connect(func() -> void:
		if sprite:
			sprite.self_modulate = Color.WHITE)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_pressed_at = mb.position
		elif _pressed_at != Vector2.INF and mb.position.distance_to(_pressed_at) < 40.0:
			_pressed_at = Vector2.INF
			accept_event()
			tapped.emit(key)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("item") and not key.begins_with("background")


func _drop_data(_at: Vector2, data: Variant) -> void:
	item_dropped.emit(key, str(data["item"]))
