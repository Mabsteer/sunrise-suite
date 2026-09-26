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


func shots() -> Array[Dictionary]:
	return [
		{"name": "settings", "screen": "main_menu", "action": func(s: Node) -> void: s.add_child(SettingsPanel.new()), "frames": 30},
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
		{"name": "level_postcard", "screen": "level", "params": func() -> Dictionary: return {"level": Campaign.build("main_09"), "mode": "main", "record_id": "main_09"}, "action": func(s: Node) -> void:
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
		{"name": "select_start", "screen": "level_select", "frames": 30},
		{"name": "select_progress", "screen": "level_select", "setup": func() -> void: fake_progress(11), "frames": 40},
		{"name": "select_popup", "screen": "level_select", "setup": func() -> void: fake_progress(11), "action": func(s: Node) -> void: s.call("_on_card", "main_02", true, true), "frames": 30},
		{"name": "art_props", "screen": "art_sheet", "params": {"dirs": ["props/common"], "scale": 1.0}},
		{"name": "art_items", "screen": "art_sheet", "params": {"dirs": ["items", "ui/symbols", "ui"], "scale": 0.9}},
		{"name": "art_puzzles", "screen": "art_sheet", "params": {"dirs": ["puzzles"], "scale": 0.5}},
		{"name": "level_start", "screen": "level", "params": TEST_LEVEL},
		{"name": "gen_lounge_t1", "screen": "level", "params": {"level": LevelGenerator.generate("lounge", 1, 11)}},
		{"name": "gen_lounge_t5", "screen": "level", "params": {"level": LevelGenerator.generate("lounge", 5, 55)}},
		{"name": "gen_lounge_t10", "screen": "level", "params": {"level": LevelGenerator.generate("lounge", 10, 1010)}},
		{"name": "gen_kitchen_t8", "screen": "level", "params": {"level": LevelGenerator.generate("kitchen", 8, 808)}},
		{"name": "gen_study_t9", "screen": "level", "params": {"level": LevelGenerator.generate("study", 9, 909)}},
		{"name": "gen_study_t2", "screen": "level", "params": {"level": LevelGenerator.generate("study", 2, 202)}},
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
