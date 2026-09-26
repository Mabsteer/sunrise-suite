extends Control
## Title screen: the lounge at dawn slowly brightening behind the title.

var _room: RoomView


func _ready() -> void:
	var version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	($Version as Label).text = "v" + version
	_room = RoomView.new()
	add_child(_room)
	move_child(_room, 0)
	_room.setup("lounge")
	_room.sunrise_t = 0.12
	_room.animate_sunrise_to(0.62, 24.0)
