extends TestCase
## Chloé is commanded, not offered: tap her, then a spot. She does the job if there is one, shows
## what she needs first if she can't yet, and otherwise comes back empty (or with something silly).


func _shed() -> LevelSession:
	var s := LevelSession.new(Campaign.build("w1_shed"))
	s.dog_present = true
	return s


func test_she_shows_her_need_before_the_job() -> void:
	var s := _shed()
	var trip := s.send_dog_to("lock:under")
	assert_eq(trip["result"], "needs", "her fringe is in her eyes, so she can't fetch yet")
	assert_eq(trip["need"], "fringe", "the care lock she's waiting on")
	assert_false(s.is_open("under"))
	assert_eq(s.dog_wants(), "fringe", "she wants her brush")


func test_she_does_the_job_once_she_is_happy() -> void:
	var s := _shed()
	s.opened["fringe"] = true
	var trip := s.send_dog_to("lock:under")
	assert_eq(trip["result"], "acted")
	assert_true(s.is_open("under"), "she fetched it from under the workbench")


func test_empty_trips_are_seeded_and_sometimes_silly() -> void:
	var a := _shed()
	var b := _shed()
	var silly := 0
	for i in 40:
		var ta := a.send_dog_to("background")
		var tb := b.send_dog_to("background")
		assert_eq(ta, tb, "the same level gives the same trips")
		assert_true(str(ta["result"]) in ["empty", "silly"])
		if ta["result"] == "silly":
			silly += 1
			assert_true(str(ta["find"]) in LevelSession.SILLY_FINDS)
	assert_between(silly, 3, 20, "about a quarter of the empty trips bring something silly")
	assert_eq(a.opened.size(), 0, "sending her around never opens anything by itself")


func test_she_is_not_there_before_she_is_found() -> void:
	var s := LevelSession.new(Campaign.build("w1_shed"))
	s.dog_present = false
	assert_eq(s.send_dog_to("lock:under")["result"], "unavailable")


func test_tap_chloe_then_a_spot_in_the_room() -> void:
	var settings := SaveManager.settings.duplicate(true)
	SaveManager.settings["show_helpers"] = false
	SaveManager.settings["reduce_motion"] = true
	Router.params = {"level": Campaign.build("w1_shed"), "mode": "test"}
	var scene := (load("res://scenes/level/level.tscn") as PackedScene).instantiate() as LevelScene
	tree.root.add_child(scene)
	await tree.process_frame
	scene.session.opened["fringe"] = true
	scene.tap("dog:chloe")
	assert_true(scene.chloe_ready, "tapping Chloé makes her ready")
	scene.tap("lock:under")
	assert_false(scene.chloe_ready, "the next tap sends her")
	assert_true(scene.session.is_open("under"), "she fetched it")
	scene.tap("lock:under")
	assert_false(scene.closeup.widget != null, "Juliette tapping her spot gets no Chloé button")
	scene.queue_free()
	await tree.process_frame
	SaveManager.settings = settings


func test_no_text_says_what_she_needs() -> void:
	var csv := FileAccess.get_file_as_string("res://i18n/strings.csv")
	for key in ["DOG_NEEDS_FOOD", "DOG_NEEDS_WATER", "DOG_FETCH", "DOG_DIG", "DOG_BARKS_AT"]:
		assert_false(csv.contains("\n" + key + ","), "%s is gone" % key)
