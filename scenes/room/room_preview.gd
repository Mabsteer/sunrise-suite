extends Node2D
## Developer preview of a room at a fixed sunrise (used by the screenshot tour).
## Router params: { "room": "lounge", "t": 0.5 }


func _ready() -> void:
	var view := RoomView.new()
	add_child(view)
	view.setup(str(Router.params.get("room", "lounge")))
	view.sunrise_t = float(Router.params.get("t", 0.5))
