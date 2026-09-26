extends TestCase
## Dates used: 2026-09-21 is a Monday, 2026-09-28 the next Monday.

var _saved: Dictionary


func before_each() -> void:
	_saved = SaveManager.data
	SaveManager.data = SaveManager.default_save()


func after_each() -> void:
	SaveManager.data = _saved


func test_first_and_consecutive_days() -> void:
	assert_eq(int(GameState.record_daily("2026-09-21", 3, 100.0)["streak"]), 1)
	assert_eq(int(GameState.record_daily("2026-09-22", 2, 100.0)["streak"]), 2)
	assert_eq(GameState.current_streak("2026-09-23"), 2, "still alive the next day")


func test_sleep_in_covers_one_missed_day_per_week() -> void:
	GameState.record_daily("2026-09-21", 3, 100.0)
	var r := GameState.record_daily("2026-09-23", 3, 100.0)   # missed Tuesday
	assert_eq(int(r["streak"]), 2)
	assert_true(bool(r["sleep_in_used"]))
	assert_false(GameState.sleep_in_available("2026-09-24"))
	var r2 := GameState.record_daily("2026-09-25", 3, 100.0)  # missed Thursday, same week
	assert_eq(int(r2["streak"]), 1, "second miss in the same week breaks the streak")


func test_sleep_ins_from_two_weeks() -> void:
	GameState.record_daily("2026-09-26", 3, 100.0)   # Saturday
	var r := GameState.record_daily("2026-09-29", 3, 100.0)  # missed Sun (week 1) + Mon (week 2)
	assert_eq(int(r["streak"]), 2, "one sleep-in from each week")


func test_broken_streak_shows_zero() -> void:
	GameState.record_daily("2026-09-21", 3, 100.0)
	GameState.record_daily("2026-09-22", 3, 100.0)
	assert_eq(GameState.current_streak("2026-09-26"), 0, "three missed days in one week")


func test_replaying_a_day_keeps_streak() -> void:
	GameState.record_daily("2026-09-21", 1, 300.0)
	var again := GameState.record_daily("2026-09-21", 3, 120.0)
	assert_false(bool(again["first_time"]))
	assert_eq(GameState.daily_stars("2026-09-21"), 3)
	assert_eq(int(GameState.daily_data()["streak"]), 1)


func test_streak_rewards() -> void:
	GameState.record_daily("2026-09-21", 3, 100.0)
	GameState.record_daily("2026-09-22", 3, 100.0)
	var r := GameState.record_daily("2026-09-23", 3, 100.0)
	assert_eq(int(r["streak"]), 3)
	assert_eq((r["rewards"] as Array).size(), 1)
	assert_eq(GameState.owned_count("shell_lamp"), 1)
