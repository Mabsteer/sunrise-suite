extends Node
## Opens every screen (with and without progress) and lets it run for a moment, so runtime script
## errors fail tools/check.sh (which greps the log for ERROR lines).

var _screens: Array[Dictionary] = []


func _ready() -> void:
	# Changing screens frees the current scene, so do the work from a copy attached to the root.
	if not has_meta("runner"):
		var runner: Node = (get_script() as GDScript).new()
		runner.set_meta("runner", true)
		get_tree().root.add_child.call_deferred(runner)
		return
	SaveManager.persist = false
	AudioManager.enabled = false
	get_tree().create_timer(180.0).timeout.connect(func() -> void:
		printerr("FAIL smoke test timed out")
		get_tree().quit(1))
	_screens = [
		{"screen": "main_menu"},
		{"screen": "main_menu", "overlay": "settings"},
		{"screen": "level_select"},
		{"screen": "hub"},
		{"screen": "calendar"},
		{"screen": "scrapbook"},
		{"screen": "level", "params": {"level_id": "test_lounge"}},
		{"screen": "room_preview", "params": {"room": "kitchen", "t": 0.5}},
	]
	_run.call_deferred()


func _run() -> void:
	var opened := 0
	for pass_index in 2:
		if pass_index == 1:
			_fake_progress()
		for s in _screens:
			if not Router.has_screen(str(s["screen"])):
				continue
			var ok: bool = await Router.goto(str(s["screen"]), s.get("params", {}), false)
			if not ok:
				printerr("FAIL could not open ", s["screen"])
				continue
			if str(s.get("overlay", "")) == "settings":
				get_tree().current_scene.add_child(SettingsPanel.new())
			for i in 12:
				await get_tree().process_frame
			opened += 1
	print("SCREENS: %d screens opened" % opened)
	get_tree().unload_current_scene()
	await get_tree().process_frame
	get_tree().quit(0)


func _fake_progress() -> void:
	var levels := {}
	var list := Campaign.levels()
	for i in 12:
		levels[str(list[i]["id"])] = {"stars": 2, "completions": 1, "best_time": 100.0}
	SaveManager.data["levels"] = levels
	SaveManager.data["seashells"] = 500
	SaveManager.data["postcards"] = ["lisbon", "kyoto"]
	GameState.ensure_starter_decor()
	(SaveManager.data["decor_owned"] as Dictionary)["candles"] = 1
	var today := Daily.today_key()
	SaveManager.data["daily"] = {"completed": {today: {"stars": 3, "time": 99.0}}, "streak": 4, "best_streak": 6, "last_day": today, "sleep_ins": {}}
