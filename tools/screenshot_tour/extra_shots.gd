extends RefCounted
## Extra screenshot-tour shots. Add a Dictionary per shot:
##   { "name": ..., "screen": Router screen, "params": {...}, "action": Callable(scene) (optional, may await), "frames": int }

const TEST_LEVEL := {"level_id": "test_lounge"}


## Pretend the player finished the first few levels with some stars.
static func fake_progress(count: int) -> void:
	var levels: Dictionary = {}
	var list := Campaign.levels()
	for i in mini(count, list.size()):
		levels[str(list[i]["id"])] = {"stars": [3, 2, 3, 1, 3, 2, 2, 3, 1, 3, 2, 3][i % 12], "completions": 1, "best_time": 200.0}
	SaveManager.data["levels"] = levels
	SaveManager.data["seashells"] = 145


## Pretend the player owns and placed lots of decor.
static func fake_decor() -> void:
	GameState.ensure_starter_decor()
	var owned: Dictionary = SaveManager.data["decor_owned"]
	for id in ["rattan_chair", "hammock", "fiddle_leaf", "surfboard", "string_lanterns", "seascape_painting", "ceramic_vases", "candles", "jute_rug", "mango_cat", "shell_lamp", "record_crate"]:
		owned[id] = 1
	SaveManager.data["decor_placed"] = {
		"floor_center": {"id": "linen_sofa", "flipped": false}, "corner_right": {"id": "fiddle_leaf", "flipped": false},
		"corner_left": {"id": "surfboard", "flipped": false}, "floor_left": {"id": "rattan_chair", "flipped": false},
		"floor_right": {"id": "hammock", "flipped": true}, "wall_left": {"id": "seascape_painting", "flipped": false},
		"wall_right": {"id": "string_lanterns", "flipped": false}, "sill_left": {"id": "ceramic_vases", "flipped": false},
		"sill_right": {"id": "shell_lamp", "flipped": false}, "rug_center": {"id": "jute_rug", "flipped": false},
		"between_left": {"id": "mango_cat", "flipped": false}, "between_right": {"id": "record_crate", "flipped": false},
	}
	SaveManager.data["seashells"] = 320


## Pretend the player did the Daily Sunrise on most of the last two weeks.
static func fake_daily() -> void:
	var today := Daily.day_number(Daily.today_key())
	var completed := {}
	for back in range(14, 0, -1):
		if back in [9, 10]:
			continue
		var key := Daily.date_key(Time.get_date_dict_from_unix_time((today - back) * 86400 + 43200))
		completed[key] = {"stars": 1 + (back % 3), "time": 200.0}
	SaveManager.data["daily"] = {"completed": completed, "streak": 8, "best_streak": 8,
		"last_day": Daily.date_key(Time.get_date_dict_from_unix_time((today - 1) * 86400 + 43200)), "sleep_ins": {}}


static func fake_postcards(count: int) -> void:
	var ids: Array = []
	for p in GameState.postcard_list().slice(0, count):
		ids.append(str(p["id"]))
	SaveManager.data["postcards"] = ids


## A companion level with a lock of type `t` standing in the room from the start.
static func _level_with(room: String, tier: int, t: String) -> Dictionary:
	for seed_value in range(300, 400):
		var level := LevelGenerator.generate(room, tier, seed_value, {"companion": true})
		for l: Dictionary in level["locks"]:
			if str(l["type"]) == t and str(l["location"]) == "room":
				return level
	return LevelGenerator.generate(room, tier, 300, {"companion": true})


## Opens the close-up of the first lock of type `t` in the level (for the dog widget shots).
static func _open_first(scene: Node, t: String) -> void:
	var session: LevelSession = scene.get("session")
	for id: String in LevelSession._sorted_keys(session.locks):
		if session.lock_type(id) == t:
			scene.get("closeup").call("show_lock", id)
			return


func shots() -> Array[Dictionary]:
	return [
		{"name": "tutorial_start", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_kitchen"), "mode": "main", "record_id": "w1_kitchen"}, "frames": 60},
		{"name": "tutorial_combine", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_kitchen"), "mode": "main", "record_id": "w1_kitchen"}, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			session.see_clue("c_welcome")
			session.submit_answer("drawers", "714")
			s.call("take", "item", "i_batteries")
			s.call("tap", "item:i_flashlight_empty")
			(s.get("closeup") as CloseupPanel).close(), "frames": 90},
		{"name": "level_door_opening", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			for i in 80:
				if session.finished:
					break
				LevelSolver.apply_goal(session, session.next_goal()), "frames": 110},
		{"name": "settings", "screen": "main_menu", "action": func(s: Node) -> void: s.add_child(SettingsPanel.new()), "frames": 30},
		{"name": "notebook_notes", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_hall"), "mode": "test"}, "action": func(s: Node) -> void:
			s.call("tap", "clue:c_marks")
			s.get("closeup").call("close")
			s.call("toggle_notebook"), "frames": 30},
		{"name": "bag_folded", "screen": "level", "setup": func() -> void: SaveManager.settings["bag_collapsed"] = true, "params": func() -> Dictionary: return {"level": Campaign.build("w1_hall"), "mode": "test"}, "frames": 30},
		{"name": "dev_panel", "screen": "level", "setup": func() -> void: SaveManager.settings["dev_mode"] = true, "params": func() -> Dictionary: return {"level": Campaign.build("w1_hall"), "mode": "test"}, "action": func(s: Node) -> void: s.get("ui").add_child(DevPanel.new()), "frames": 30},
		{"name": "chapter_card", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_hall"), "mode": "main", "record_id": "w1_hall"}, "frames": 40},
		{"name": "room_hall_start", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_hall"), "mode": "test"}, "frames": 40},
		{"name": "finale_letter", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_front_garden"), "mode": "main", "record_id": "w1_front_garden"}, "action": func(s: Node) -> void:
			for c in s.get("ui").find_children("*", "Button", true, false):
				if (c as Button).text == TranslationServer.translate("CHAPTER_START"):
					(c as Button).pressed.emit()
			var session: LevelSession = s.get("session")
			for i in 120:
				if session.finished:
					break
				LevelSolver.apply_goal(session, session.next_goal()), "frames": 300},
		{"name": "story_bedroom", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_bedroom"), "mode": "test"}, "frames": 40},
		{"name": "story_lounge", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_lounge"), "mode": "test"}, "frames": 40},
		{"name": "story_garden", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_garden"), "mode": "test"}, "frames": 40},
		{"name": "story_shed", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_shed"), "mode": "test"}, "frames": 40},
		{"name": "story_front_garden", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_front_garden"), "mode": "test"}, "frames": 40},
		{"name": "story_memory_note", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_hall"), "mode": "test"}, "action": func(s: Node) -> void: s.call("tap", "clue:c_marks"), "frames": 30},
		{"name": "scrapbook_memories", "screen": "scrapbook", "setup": func() -> void:
			fake_postcards(3)
			for m in ["hall_marks", "hall_bus", "kitchen_welcome", "kitchen_chloe"]:
				GameState.collect_memory(m), "action": func(s: Node) -> void: s.call("show_chapter", "hall"), "frames": 30},
		{"name": "tutorial_memory", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_kitchen"), "mode": "main", "record_id": "w1_kitchen"}, "action": func(s: Node) -> void: s.call("tap", "clue:c_welcome"), "frames": 60},
		{"name": "scrapbook_memory_open", "screen": "scrapbook", "setup": func() -> void: GameState.collect_memory("hall_photos"), "action": func(s: Node) -> void:
			s.call("show_chapter", "hall")
			for b: Button in s.find_children("*", "Button", true, false):
				if b.text == "Our summers":
					b.pressed.emit(), "frames": 30},
		{"name": "scrapbook_chapter", "screen": "scrapbook", "setup": func() -> void: fake_postcards(3), "action": func(s: Node) -> void: s.call("show_chapter", "hall"), "frames": 30},
		{"name": "scrapbook_empty", "screen": "scrapbook", "frames": 30},
		{"name": "scrapbook_some", "screen": "scrapbook", "setup": func() -> void: fake_postcards(3), "frames": 30},
		{"name": "scrapbook_card", "screen": "scrapbook", "setup": func() -> void: fake_postcards(3), "action": func(s: Node) -> void: s.call("show_postcard", "kyoto"), "frames": 30},
		{"name": "scrapbook_back", "screen": "scrapbook", "setup": func() -> void: fake_postcards(3), "action": func(s: Node) -> void:
			s.call("show_postcard", "lisbon")
			var ov: Control = s.get("_overlay")
			for b in ov.find_children("*", "Button", true, false):
				if (b as Button).text == TranslationServer.translate("POSTCARD_TURN"):
					(b as Button).pressed.emit()
					break, "frames": 40},
		{"name": "scrapbook_letter", "screen": "scrapbook", "setup": func() -> void: fake_postcards(5), "action": func(s: Node) -> void: s.call("show_letter"), "frames": 30},
		{"name": "level_postcard", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("w1_hall"), "mode": "main", "record_id": "w1_hall"}, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			var pc: Dictionary = session.level["postcard"]
			while not session.accessible(str(pc["location"])):
				LevelSolver.apply_goal(session, session.next_goal())
			s.call("take", "postcard", str(pc["id"])), "frames": 40},
		{"name": "calendar_new", "screen": "calendar", "frames": 30},
		{"name": "calendar_streak", "screen": "calendar", "setup": fake_daily, "frames": 30},
		{"name": "hub_start", "screen": "hub", "frames": 40},
		{"name": "hub_decorated", "screen": "hub", "setup": fake_decor, "frames": 40},
		{"name": "hub_decorate_mode", "screen": "hub", "action": func(s: Node) -> void: s.call("toggle_decorate"), "frames": 30},
		{"name": "hub_catalog", "screen": "hub", "setup": func() -> void: SaveManager.data["seashells"] = 130, "action": func(s: Node) -> void: s.call("_open_catalog", "Grandma's Catalog", s.call("_all_ids")), "frames": 30},
		{"name": "hub_picker", "screen": "hub", "setup": func() -> void: SaveManager.data["seashells"] = 130, "action": func(s: Node) -> void:
			s.call("toggle_decorate")
			s.call("_open_picker", "wall_left"), "frames": 30},
		{"name": "menu_new", "screen": "main_menu", "frames": 30},
		{"name": "menu_returning", "screen": "main_menu", "setup": func() -> void: fake_progress(8), "frames": 30},
		{"name": "menu_gated", "screen": "main_menu", "setup": func() -> void:
			fake_progress(9)
			for id: String in SaveManager.data["levels"]:
				SaveManager.data["levels"][id]["stars"] = 1, "frames": 30},
		{"name": "level_timer", "screen": "level", "setup": func() -> void: SaveManager.settings["show_timer"] = true, "params": TEST_LEVEL, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			session.elapsed = 83.0
			LevelSolver.apply_goal(session, session.next_goal()), "frames": 30},
		{"name": "results_best", "screen": "level", "setup": func() -> void:
			SaveManager.data["levels"] = {"main_02": {"stars": 1, "completions": 1, "best_time": 9000.0}}
			SaveManager.data["levels"]["main_01"] = {"stars": 3, "completions": 1, "best_time": 100.0}, "params": func() -> Dictionary: return {"level": Campaign.build("main_02"), "mode": "main", "record_id": "main_02"}, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			for i in 80:
				if session.finished:
					break
				LevelSolver.apply_goal(session, session.next_goal()), "frames": 260},
		{"name": "select_start", "screen": "level_select", "frames": 30},
		{"name": "select_progress", "screen": "level_select", "setup": func() -> void: fake_progress(11), "frames": 40},
		{"name": "select_popup", "screen": "level_select", "setup": func() -> void: fake_progress(11), "action": func(s: Node) -> void: s.call("_on_card", "main_02", true, true), "frames": 30},
		{"name": "art_props", "screen": "art_sheet", "params": {"dirs": ["props/common"], "scale": 1.0}},
		{"name": "art_items", "screen": "art_sheet", "params": {"dirs": ["items", "ui/symbols", "ui"], "scale": 0.9}},
		{"name": "art_puzzles", "screen": "art_sheet", "params": {"dirs": ["puzzles"], "scale": 0.5}},
		{"name": "art_counters", "screen": "art_sheet", "params": {"dirs": ["props/counters"], "scale": 1.0}},
		{"name": "chloe_hall_hiding", "screen": "level", "params": func() -> Dictionary: return {"level": LevelGenerator.generate("hall", 2, 77, {"find_dog": true}), "mode": "test"}, "frames": 40},
		{"name": "chloe_garden", "screen": "level", "params": func() -> Dictionary: return {"level": LevelGenerator.generate("garden", 6, 301, {"companion": true}), "mode": "test"}, "frames": 40},
		{"name": "chloe_w_dog", "screen": "level", "params": func() -> Dictionary: return {"level": _level_with("garden", 6, "dog"), "mode": "test"}, "action": func(s: Node) -> void: _open_first(s, "dog"), "frames": 30},
		{"name": "chloe_w_care", "screen": "level", "params": func() -> Dictionary: return {"level": _level_with("bedroom", 5, "care"), "mode": "test"}, "action": func(s: Node) -> void: _open_first(s, "care"), "frames": 30},
		{"name": "chloe_w_sniff", "screen": "level", "params": func() -> Dictionary: return {"level": _level_with("lounge", 7, "sniff"), "mode": "test"}, "action": func(s: Node) -> void: _open_first(s, "sniff"), "frames": 30},
		{"name": "hub_chloe", "screen": "hub", "setup": func() -> void: SaveManager.data["chloe_found"] = true, "frames": 40},
		{"name": "art_chloe", "screen": "art_sheet", "params": {"dirs": ["props/chloe"], "scale": 1.6}},
		{"name": "art_puzzle_props", "screen": "art_sheet", "params": {"dirs": ["props/puzzles"], "scale": 1.3}},
		{"name": "level_start", "screen": "level", "params": TEST_LEVEL},
		{"name": "level_zoomed", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: (s.get("room_zoom") as RoomZoom).animate_to(2.0, Vector2(560, 560), 0.0), "frames": 30},
		{"name": "gen_lounge_t1", "screen": "level", "params": {"level": LevelGenerator.generate("lounge", 1, 11)}},
		{"name": "gen_lounge_t5", "screen": "level", "params": {"level": LevelGenerator.generate("lounge", 5, 55)}},
		{"name": "gen_lounge_t10", "screen": "level", "params": {"level": LevelGenerator.generate("lounge", 10, 1010)}},
		{"name": "gen_kitchen_t8", "screen": "level", "params": {"level": LevelGenerator.generate("kitchen", 8, 808)}},
		{"name": "gen_shed_t9", "screen": "level", "params": {"level": LevelGenerator.generate("shed", 9, 909)}},
		{"name": "gen_garden_t4", "screen": "level", "params": {"level": LevelGenerator.generate("garden", 4, 404)}},
		{"name": "gen_hall_t6", "screen": "level", "params": {"level": LevelGenerator.generate("hall", 6, 606)}},
		{"name": "gen_bedroom_t8", "screen": "level", "params": {"level": LevelGenerator.generate("bedroom", 8, 808)}},
		{"name": "gen_front_garden_t10", "screen": "level", "params": {"level": LevelGenerator.generate("front_garden", 10, 1001)}},
		{"name": "level_inventory", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void:
			s.call("tap", "item:i_flashlight_empty")
			s.call("select_item", "i_flashlight_empty"), "frames": 60},
		{"name": "level_hint", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void:
			s.call("show_hint")
			s.call("show_hint"), "frames": 30},
		{"name": "level_clue", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "clue:c_clock")},
		{"name": "level_w_combo", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "lock:door")},
		{"name": "level_w_sequence", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "lock:music_box")},
		{"name": "level_w_clock", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "lock:clock")},
		{"name": "level_w_switches", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "lock:switches")},
		{"name": "level_w_key", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "lock:lockbox")},
		{"name": "level_w_tool", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "lock:armchair")},
		{"name": "level_w_slider", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			session.opened["credenza"] = true
			(s.get("closeup") as CloseupPanel).show_lock("puzzle_box")},
		{"name": "level_w_order", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "lock:records")},
		{"name": "level_w_pattern", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "lock:drawers")},
		{"name": "level_w_pattern_symbols", "screen": "level", "params": func() -> Dictionary:
			var lvl: Dictionary = Data.get_dict("levels/test_lounge").duplicate(true)
			for l: Dictionary in lvl["locks"]:
				if str(l["id"]) == "drawers":
					l["answer"] = "shell,sun"
					l["config"] = {"kind": "symbols", "terms": ["sun", "shell", "shell", "sun", "shell", "shell", "sun", "shell", "sun"], "blanks": [7, 8]}
			return {"level": lvl}, "action": func(s: Node) -> void: s.call("tap", "lock:drawers")},
		{"name": "level_w_sudoku", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			session.opened["drawers"] = true
			(s.get("closeup") as CloseupPanel).show_lock("paper")},
		{"name": "level_w_sudoku_solved", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			session.submit_answer("drawers", "10,12")
			session.submit_answer("paper", "1234341221434321")
			(s.get("closeup") as CloseupPanel).show_lock("paper"), "frames": 40},
		{"name": "level_w_rotate", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "lock:picture_box")},
		{"name": "level_counter", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void: s.call("tap", "clue:c_jar")},
		{"name": "level_riddle_note", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			session.submit_answer("clock", "7:30")
			(s.get("closeup") as CloseupPanel).show_thing("clue", "c_order")},
		{"name": "level_contents", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void:
			s.call("submit", "clock", "7:30")
			s.call("tap", "lock:clock"), "frames": 90},
		{"name": "level_results", "screen": "level", "params": TEST_LEVEL, "action": func(s: Node) -> void:
			var session: LevelSession = s.get("session")
			for i in 80:
				if session.finished:
					break
				LevelSolver.apply_goal(session, session.next_goal()), "frames": 260},
	]
