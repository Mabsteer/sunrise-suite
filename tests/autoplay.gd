extends Node
## Plays levels through the real level scene, the way a player would: tapping hotspots, opening
## close-ups, entering answers on the lock widgets, selecting and using items, combining.
## Fails if a level can't be finished or the results screen doesn't appear.
##   bash tools/godot.sh --headless --path . res://tests/autoplay.tscn -- --seeds=2

const LEVEL_SCENE := preload("res://scenes/level/level.tscn")

var _failures: PackedStringArray = []


func _ready() -> void:
	SaveManager.persist = false
	AudioManager.enabled = false
	SaveManager.settings["reduce_motion"] = true
	get_tree().create_timer(800.0).timeout.connect(func() -> void:
		printerr("FAIL autoplay timed out")
		get_tree().quit(1))
	_run.call_deferred()


func _run() -> void:
	var seeds := 2
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="):
			seeds = int(arg.trim_prefix("--seeds="))
	var played := 0
	var levels: Array[Dictionary] = [Data.get_dict("levels/test_lounge"), Campaign.build("w1_kitchen")]
	for room in Campaign.rooms():
		if not Campaign.room_available(room):
			continue
		for tier in range(1, 11):
			for s in seeds:
				levels.append(LevelGenerator.generate(room, tier, 5000 + tier * 13 + s * 101))
	levels.append(Campaign.build_endless(2, 99))
	for e in Campaign.levels():
		if e.has("postcard"):
			levels.append(Campaign.build(str(e["id"])))
	for level in levels:
		if level.is_empty():
			_failures.append("a level could not be generated")
			continue
		await _play(level)
		played += 1
	for f in _failures:
		printerr("FAIL ", f)
	print("AUTOPLAY: %d levels played, %d failed" % [played, _failures.size()])
	AudioManager.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if _failures.is_empty() else 1)


func _play(level: Dictionary) -> void:
	var name := str(level.get("id", "?"))
	Router.params = {"level": level, "mode": "test"}
	var scene := LEVEL_SCENE.instantiate() as LevelScene
	add_child(scene)
	await get_tree().process_frame
	var s := scene.session
	var guard := 0
	while not s.finished and guard < 300:
		guard += 1
		_try_postcard(scene)
		var goal := s.next_goal()
		var ok := await _do(scene, goal)
		if not ok:
			_failures.append("%s: could not %s (%s)" % [name, goal.get("action", "?"), goal.get("target", "?")])
			break
		await get_tree().process_frame
	if bool(level.get("tutorial", false)):
		var guides := scene.find_children("*", "TutorialGuide", true, false)
		if guides.is_empty():
			_failures.append("%s: tutorial guide missing" % name)
		elif (guides[0] as TutorialGuide).current_step() < (Data.get_dict("tutorial").get("steps", []) as Array).size():
			_failures.append("%s: tutorial stopped at step %d" % [name, (guides[0] as TutorialGuide).current_step()])
	if not s.finished:
		_failures.append("%s: level not finished" % name)
	else:
		var waited := 0.0
		while scene.get("_results") == null and waited < 4.0:
			await get_tree().create_timer(0.1).timeout
			waited += 0.1
		if scene.get("_results") == null:
			_failures.append("%s: results screen never appeared" % name)
	scene.queue_free()
	await get_tree().process_frame


## Performs one goal through the UI. Returns false if the UI didn't allow it.
func _do(scene: LevelScene, goal: Dictionary) -> bool:
	var s := scene.session
	match str(goal.get("action", "")):
		"pick_up":
			var id := str(goal["id"])
			if scene.hotspots.has("item:" + id):
				scene.tap("item:" + id)
			else:
				_open_container(scene, str(s.items[id]["location"]))
				scene.take("item", id)
			return s.picked.has(id)
		"combine":
			scene.select_item(str(goal["a"]))
			scene.combine_items(str(goal["a"]), str(goal["b"]))
			return s.inventory.size() > 0
		"see_clue":
			var cid := str(goal["id"])
			if scene.hotspots.has("clue:" + cid):
				scene.tap("clue:" + cid)
			else:
				_open_container(scene, str(s.clues[cid]["location"]))
				scene.take("clue", cid)
			scene.closeup.close()
			return s.seen.has(cid)
		"open":
			return _open_lock(scene, str(goal["id"]))
	return false


## Picks up the level's postcard through the UI as soon as it can be reached.
func _try_postcard(scene: LevelScene) -> void:
	var s := scene.session
	var pc: Dictionary = s.level.get("postcard", {})
	if pc.is_empty() or s.postcard_taken or not s.accessible(str(pc.get("location", "room"))):
		return
	var id := str(pc["id"])
	if scene.hotspots.has("postcard:" + id):
		scene.tap("postcard:" + id)
	else:
		_open_container(scene, str(pc["location"]))
		scene.take("postcard", id)
	scene.closeup.close()
	if not s.postcard_taken:
		_failures.append("%s: could not pick up postcard %s" % [s.level.get("id", "?"), id])
	elif not GameState.has_postcard(id):
		_failures.append("%s: postcard %s not added to the scrapbook" % [s.level.get("id", "?"), id])


func _open_container(scene: LevelScene, lock_id: String) -> void:
	scene.inventory.deselect()
	if scene.hotspots.has("lock:" + lock_id):
		scene.tap("lock:" + lock_id)
	else:
		scene.closeup.show_lock(lock_id)


func _open_lock(scene: LevelScene, lock_id: String) -> bool:
	var s := scene.session
	var lock: Dictionary = s.locks[lock_id]
	var t := str(lock["type"])
	var answer := str(lock.get("answer", ""))
	_open_container(scene, lock_id)
	var w := scene.closeup.widget
	if w == null:
		return false
	match t:
		"combo":
			w.call("set_answer", answer)
			w.submitted.emit(str(w.call("answer")))
		"sequence":
			for sym in answer.split(","):
				w.call("_add", sym)
		"clock":
			w.call("set_answer", answer)
			w.submitted.emit(str(w.call("answer")))
		"switches":
			w.call("set_answer", answer)
			w.submitted.emit(str(w.call("answer")))
		"slider", "sudoku", "rotate":
			w.call("solve_instantly")
		"order", "pattern":
			w.call("set_answer", answer)
			w.submitted.emit(answer)
		"key", "tool":
			scene.select_item(s._inventory_match(s.lock_item(lock_id)))
			w.use_requested.emit()
		"hidden":
			if s.lock_item(lock_id) != "":
				scene.select_item(s._inventory_match(s.lock_item(lock_id)))
				w.use_requested.emit()
			else:
				w.submitted.emit("search")
	scene.inventory.deselect()
	if not s.finished:
		scene.closeup.close()
	return s.is_open(lock_id)
