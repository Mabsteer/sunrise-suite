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
	var play := Button.new()
	play.text = tr("MENU_TRY_ROOM")
	play.custom_minimum_size = Vector2(460, 104)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.focus_mode = Control.FOCUS_NONE
	play.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		Router.goto("level", {"level_id": "test_lounge", "exit_to": "main_menu"}))
	$Center.add_child(play)
	AudioManager.play_music("menu_theme")
