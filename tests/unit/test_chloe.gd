extends TestCase
## Chloé's rules: fetching, caring for her, following a scent, and finding her.


func _level() -> Dictionary:
	return {
		"id": "chloe_test", "room": "bedroom", "tier": 3, "seed": 1, "par_time": 600, "companion": "chloe",
		"locks": [
			{"id": "door", "type": "key", "is_door": true, "host": {"kind": "door"}, "location": "room", "item": "i_key"},
			{"id": "under_bed", "type": "dog", "action": "fetch", "host": {"kind": "furniture", "furniture": "bed", "spot": "under_bed"}, "location": "room"},
			{"id": "breakfast", "type": "care", "host": {"kind": "dog"}, "location": "room", "item": "i_kibble"},
			{"id": "pillows", "type": "sniff", "host": {"kind": "furniture", "furniture": "bed", "spot": "pillows"}, "location": "room", "item": "i_glove"},
		],
		"items": [
			{"id": "i_glove", "type": "mamie_glove", "location": "under_bed"},
			{"id": "i_kibble", "type": "kibble", "location": "pillows"},
			{"id": "i_key", "type": "brass_key", "location": "breakfast"},
		],
		"recipes": [], "clues": [], "decoys": [],
	}


func test_the_chloe_level_is_valid_and_solvable() -> void:
	var report := LevelValidator.validate(_level())
	assert_true(bool(report["ok"]), str(report["errors"]))


func test_fetch_feed_sniff() -> void:
	var s := LevelSession.new(_level())
	assert_true(s.dog_present)
	assert_eq(s.give_to_dog("i_glove"), "unavailable", "nothing in the bag yet")
	assert_true(s.send_dog("under_bed"), "Chloé fetches from under the bed")
	assert_true(s.pick_up("i_glove"))
	assert_eq(s.give_to_dog("i_glove"), "pillows", "she follows the scent to the pillows")
	assert_true(s.pick_up("i_kibble"))
	assert_eq(s.use_item("i_kibble", "breakfast"), "unavailable", "breakfast is given to Chloé, not used on a spot")
	assert_eq(s.give_to_dog("i_kibble"), "breakfast")
	assert_true(s.pick_up("i_key"))
	assert_eq(s.use_item("i_key", "door"), "opened")
	assert_true(s.finished)


func test_no_dog_no_help() -> void:
	var lvl := _level()
	lvl["companion"] = ""
	var s := LevelSession.new(lvl)
	assert_false(s.send_dog("under_bed"))
	assert_false(bool(LevelValidator.validate(lvl)["ok"]), "Chloé's locks need Chloé")


func test_finding_chloe_in_the_hall() -> void:
	var level := LevelGenerator.generate("hall", 2, 77, {"find_dog": true})
	assert_false(level.is_empty(), "a hall level where Chloé hides")
	var s := LevelSession.new(level)
	assert_false(s.dog_present, "she's hiding at first")
	var found := [false]
	s.dog_found.connect(func() -> void: found[0] = true)
	for i in 80:
		if s.finished:
			break
		LevelSolver.apply_goal(s, s.next_goal())
	assert_true(s.finished)
	assert_true(found[0], "Chloé came out")
	assert_true(s.dog_present)


func test_companion_levels_use_chloe() -> void:
	var dog_locks := 0
	for seed_value in 20:
		var level := LevelGenerator.generate("garden", 6, 300 + seed_value, {"companion": true})
		for l: Dictionary in level["locks"]:
			if str(l["type"]) in LevelSession.DOG_TYPES:
				dog_locks += 1
		var plain := LevelGenerator.generate("garden", 6, 300 + seed_value)
		for l: Dictionary in plain["locks"]:
			assert_false(str(l["type"]) in LevelSession.DOG_TYPES, "no Chloé locks without Chloé")
	assert_true(dog_locks >= 10, "Chloé helps in most levels she's in (%d)" % dog_locks)


func test_hints_mention_chloe() -> void:
	var s := LevelSession.new(_level())
	s.send_dog("under_bed")
	s.pick_up("i_glove")
	var text := LevelText.new(s, Data.get_dict("rooms/bedroom"))
	var goal := s.next_goal()
	goal["level"] = 3
	assert_true(text.hint_text(goal).contains("Chloé"), text.hint_text(goal))
