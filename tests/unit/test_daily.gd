extends TestCase


func test_seed_is_deterministic() -> void:
	assert_eq(Daily.seed_for("2026-09-26"), Daily.seed_for("2026-09-26"))
	assert_ne(Daily.seed_for("2026-09-26"), Daily.seed_for("2026-09-27"))


func test_level_for_day() -> void:
	var a := Daily.level_for("2026-09-26")
	var b := Daily.level_for("2026-09-26")
	assert_eq(a, b, "same day gives the same level")
	assert_true(Campaign.ROUTE.has(str(a["room"])))
	assert_between(float(a["tier"]), 1.0, 10.0)


func test_rooms_rotate() -> void:
	var rooms := {}
	for day in ["2026-09-26", "2026-09-27", "2026-09-28"]:
		rooms[Daily.level_for(day)["room"]] = true
	assert_eq(rooms.size(), 3, "three consecutive days visit all three rooms")


func test_week_key_changes_on_monday() -> void:
	# 2026-09-27 is a Sunday, 2026-09-28 a Monday.
	assert_eq(Daily.week_key("2026-09-26"), Daily.week_key("2026-09-27"))
	assert_ne(Daily.week_key("2026-09-27"), Daily.week_key("2026-09-28"))
