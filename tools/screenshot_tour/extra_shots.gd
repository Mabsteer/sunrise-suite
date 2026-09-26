extends RefCounted
## Extra screenshot-tour shots. Add a Dictionary per shot:
##   { "name": ..., "screen": Router screen, "params": {...}, "action": Callable(scene) (optional, may await), "frames": int }

const TEST_LEVEL := {"level_id": "test_lounge"}


func shots() -> Array[Dictionary]:
	return [
		{"name": "art_props", "screen": "art_sheet", "params": {"dirs": ["props/common"], "scale": 1.0}},
		{"name": "art_items", "screen": "art_sheet", "params": {"dirs": ["items", "ui/symbols", "ui"], "scale": 0.9}},
		{"name": "art_puzzles", "screen": "art_sheet", "params": {"dirs": ["puzzles"], "scale": 0.5}},
		{"name": "level_start", "screen": "level", "params": TEST_LEVEL},
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
