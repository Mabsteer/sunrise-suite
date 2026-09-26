class_name RoomThumb
extends Control
## A small picture of a room: a sunrise gradient behind the room's background art (its window holes show the sky).

var room_id := ""
var sunrise := 0.6:
	set(value):
		sunrise = value
		queue_redraw()


func _init(id: String = "", t: float = 0.6) -> void:
	room_id = id
	sunrise = t
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _ready() -> void:
	var room := Data.get_dict("rooms/" + room_id)
	var bg := UIKit.texture(str(room.get("background", "")))
	if bg:
		# The stage area of a room background is (240, 180, 1920, 1080) inside the 2400x1440 texture.
		var atlas := AtlasTexture.new()
		atlas.atlas = bg
		atlas.region = Rect2(240, 180, 1920, 1080)
		var art := TextureRect.new()
		art.texture = atlas
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
	queue_redraw()


func _draw() -> void:
	var top := Color("3e3570").lerp(Color("8fafdc"), sunrise)
	var mid := Color("9c8ac4").lerp(Color("fbcdb8"), sunrise)
	var low := Color("f9b98a").lerp(Color("fbe3a0"), sunrise)
	var h := size.y
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x, h * 0.4), Vector2(0, h * 0.4)]),
		PackedColorArray([top, top, mid, mid]))
	draw_rect(Rect2(0, h * 0.38, size.x, h * 0.05), low)
	draw_rect(Rect2(0, h * 0.42, size.x, h * 0.58), Color("2e8c8c").lerp(Color("6cc2be"), sunrise * 0.6))
