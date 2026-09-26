extends TestCase


func test_default_save_has_version() -> void:
	var save := SaveManager.default_save()
	assert_eq(int(save["version"]), SaveManager.SAVE_VERSION)


func test_migrate_fills_missing_keys() -> void:
	var old := {"version": 0, "seashells": 42, "daily": {"streak": 3}}
	var migrated := SaveManager.migrate_save(old)
	assert_eq(int(migrated["seashells"]), 42, "existing values are kept")
	assert_eq(int(migrated["version"]), SaveManager.SAVE_VERSION)
	assert_true(migrated.has("decor_owned"), "missing top-level keys are added")
	var daily: Dictionary = migrated["daily"]
	assert_eq(int(daily["streak"]), 3)
	assert_true(daily.has("sleep_ins"), "missing nested keys are added")


func test_json_round_trip() -> void:
	var save := SaveManager.default_save()
	save["seashells"] = 7
	(save["levels"] as Dictionary)["main_01"] = {"stars": 3, "best_time": 61.5, "completions": 1}
	var text := JSON.stringify(save)
	var back: Dictionary = SaveManager.migrate_save(JSON.parse_string(text))
	assert_eq(int(back["seashells"]), 7)
	assert_eq(int((back["levels"]["main_01"] as Dictionary)["stars"]), 3)


func test_v1_saves_start_the_walks_fresh() -> void:
	var old := {"version": 1, "seashells": 120, "levels": {"main_01": {"stars": 3, "completions": 1}}, "postcards": ["kyoto"], "decor_owned": {"hammock": 1}}
	var migrated := SaveManager.migrate_save(old)
	assert_eq((migrated["levels"] as Dictionary).size(), 0, "old main_XX levels are gone")
	assert_eq(int(migrated["seashells"]), 120, "seashells stay")
	assert_eq((migrated["postcards"] as Array).size(), 1, "postcards stay")
	assert_eq(int((migrated["decor_owned"] as Dictionary).get("hammock", 0)), 1, "decor stays")
