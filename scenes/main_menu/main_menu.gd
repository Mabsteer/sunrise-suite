extends Control
## Title screen.


func _ready() -> void:
	var version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	($Version as Label).text = "v" + version
