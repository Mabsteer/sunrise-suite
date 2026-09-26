extends TestCase


func test_same_seed_same_level() -> void:
	var a := LevelGenerator.generate("lounge", 6, 4242)
	var b := LevelGenerator.generate("lounge", 6, 4242)
	assert_eq(JSON.stringify(a), JSON.stringify(b))


func test_different_seeds_differ() -> void:
	var a := LevelGenerator.generate("lounge", 6, 1)
	var b := LevelGenerator.generate("lounge", 6, 2)
	assert_ne(JSON.stringify(a["locks"]), JSON.stringify(b["locks"]))


func test_tier_one_is_gentle() -> void:
	var cfg := LevelGenerator.tier_config(1)
	for s in 20:
		var level := LevelGenerator.generate("lounge", 1, 300 + s)
		var session := LevelSession.new(level)
		assert_between(float(session.total_steps), 3.0, 4.0)
		for l: Dictionary in level["locks"]:
			assert_true((cfg["types"] as Array).has(str(l["type"])), "tier 1 only uses its lock types, got %s" % l["type"])
		assert_eq((level["recipes"] as Array).size(), 0, "no combining in tier 1")


func test_tier_ten_is_big() -> void:
	var level := LevelGenerator.generate("lounge", 10, 99)
	var session := LevelSession.new(level)
	assert_true(session.total_steps >= 11, "tier 10 has at least 11 steps")
	assert_true((level["decoys"] as Array).size() >= 2, "tier 10 has red herrings")


func test_endless_tiers_grow() -> void:
	var t10 := LevelGenerator.tier_config(10)
	var t16 := LevelGenerator.tier_config(16)
	assert_true(int(t16["steps"][1]) > int(t10["steps"][1]))
	assert_true(int(t16["par_time"]) > int(t10["par_time"]))


func test_direct_clues_contain_the_answer() -> void:
	var found := false
	for s in 40:
		var level := LevelGenerator.generate("lounge", 1, 700 + s)
		for l: Dictionary in level["locks"]:
			if str(l["type"]) == "combo" and (l["clues"] as Array).size() == 1:
				var clue_id := str(l["clues"][0])
				for c: Dictionary in level["clues"]:
					if str(c["id"]) == clue_id:
						assert_true(str(c["text"]).contains(" ".join(str(l["answer"]).split(""))), "clue '%s' shows code %s" % [c["text"], l["answer"]])
						found = true
	assert_true(found, "found at least one direct combo clue")


func test_campaign_has_thirty_levels_and_postcards() -> void:
	var list := Campaign.levels()
	assert_eq(list.size(), 30)
	var postcards := 0
	for e in list:
		if e.has("postcard"):
			postcards += 1
	assert_eq(postcards, 5)
	var first := Campaign.build("main_01")
	assert_false(first.is_empty(), "main_01 builds")
	assert_eq(str(first["room"]), "lounge")
