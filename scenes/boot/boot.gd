extends Node
## Entry scene. Routes to the main menu, or runs a tool mode passed after `--` on the command line:
##   --screenshot-tour   capture screenshots of every screen into tests/screenshots/ and quit


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--screenshot-tour" in args and ResourceLoader.exists("res://tools/screenshot_tour/screenshot_tour.gd"):
		var tour: Node = (load("res://tools/screenshot_tour/screenshot_tour.gd") as GDScript).new()
		get_tree().root.add_child.call_deferred(tour)
		return
	Router.goto.call_deferred("main_menu", {}, false)
