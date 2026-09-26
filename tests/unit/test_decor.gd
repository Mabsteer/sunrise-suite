extends TestCase

var _saved: Dictionary


func before_each() -> void:
	_saved = SaveManager.data
	SaveManager.data = SaveManager.default_save()


func after_each() -> void:
	SaveManager.data = _saved


func test_starter_decor_is_placed() -> void:
	GameState.ensure_starter_decor()
	assert_eq(GameState.owned_count("linen_sofa"), 1)
	assert_eq(str(GameState.placed_decor()["floor_center"]["id"]), "linen_sofa")
	assert_eq(GameState.available_count("linen_sofa"), 0)


func test_buy_needs_seashells() -> void:
	assert_false(GameState.buy_decor("candles"), "can't buy without seashells")
	GameState.add_seashells(100)
	assert_true(GameState.buy_decor("candles"))
	assert_eq(GameState.seashells(), 100 - GameState.decor_price("candles"))
	assert_eq(GameState.available_count("candles"), 1)


func test_reward_items_cannot_be_bought() -> void:
	GameState.add_seashells(9999)
	assert_eq(GameState.decor_price("mango_cat"), -1)
	assert_false(GameState.buy_decor("mango_cat"))


func test_place_move_flip_store() -> void:
	GameState.add_seashells(500)
	GameState.buy_decor("seascape_painting")
	assert_false(GameState.place_decor("sill_left", "seascape_painting"), "a wall item doesn't fit a table slot")
	assert_true(GameState.place_decor("wall_left", "seascape_painting"))
	assert_eq(GameState.available_count("seascape_painting"), 0)
	assert_true(GameState.move_decor("wall_left", "wall_right"))
	assert_false(GameState.placed_decor().has("wall_left"))
	GameState.flip_decor("wall_right")
	assert_true(bool(GameState.placed_decor()["wall_right"]["flipped"]))
	GameState.store_decor("wall_right")
	assert_eq(GameState.available_count("seascape_painting"), 1)


func test_level_reward_granted_once() -> void:
	var names := GameState.grant_rewards("level", "main_03")
	assert_eq(names.size(), 1)
	assert_eq(GameState.owned_count("mango_cat"), 1)
	assert_eq(GameState.grant_rewards("level", "main_03").size(), 0, "not granted twice")


func test_streak_rewards_accumulate() -> void:
	var names := GameState.grant_rewards("streak", "7")
	assert_eq(names.size(), 2, "3-day and 7-day rewards")
	assert_eq(GameState.owned_count("hanging_egg_chair"), 1)


func test_catalog_has_enough_items() -> void:
	assert_true(GameState.decor_items().size() >= 15)
	for id: String in GameState.decor_items().keys():
		var item := GameState.decor(id)
		assert_true(ResourceLoader.exists("res://assets/sprites/" + str(item["sprite"])), "sprite for %s exists" % id)
		assert_true(["floor_large", "floor_small", "wall", "table", "rug"].has(str(item["slot"])), "%s has a valid slot type" % id)
