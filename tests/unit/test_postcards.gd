extends TestCase

var _saved: Dictionary


func before_each() -> void:
	_saved = SaveManager.data
	SaveManager.data = SaveManager.default_save()


func after_each() -> void:
	SaveManager.data = _saved


func test_five_postcards_with_levels() -> void:
	var list := GameState.postcard_list()
	assert_eq(list.size(), 5)
	for p in list:
		assert_true(ResourceLoader.exists("res://assets/sprites/" + str(p["front"])), "front for %s" % p["id"])
		assert_true(str(p["text"]).length() > 80, "%s has a real message" % p["id"])
		assert_ne(GameState.postcard_level(str(p["id"])), "", "%s is hidden in a level" % p["id"])


func test_campaign_levels_hide_their_postcard() -> void:
	var level := Campaign.build("w1_hall")
	assert_eq(str((level.get("postcard", {}) as Dictionary).get("id", "")), "reykjavik", "the hall hides the Reykjavik postcard")
	var session := LevelSession.new(level)
	var reachable := false
	for step in 80:
		if session.accessible(str(level["postcard"]["location"])):
			reachable = true
			break
		if session.finished:
			break
		LevelSolver.apply_goal(session, session.next_goal())
	assert_true(reachable, "the postcard can be reached before the door opens")


func test_collecting() -> void:
	var r := GameState.collect_postcard("kyoto")
	assert_true(bool(r["new"]))
	assert_false(bool(r["all"]))
	assert_true(GameState.has_postcard("kyoto"))
	assert_false(bool(GameState.collect_postcard("kyoto")["new"]), "no duplicates")
	assert_eq(GameState.postcards_found_count(), 1)


func test_all_postcards_give_portrait() -> void:
	var last := {}
	for p in GameState.postcard_list():
		last = GameState.collect_postcard(str(p["id"]))
	assert_true(bool(last["all"]))
	assert_eq(GameState.owned_count("grandma_portrait"), 1)
	assert_true(GameState.all_postcards_found())
