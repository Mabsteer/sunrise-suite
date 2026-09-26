class_name Launcher
extends RefCounted
## Starts levels in each mode with the right Router params.


static func play_main(level_id: String) -> void:
	var level := Campaign.build(level_id)
	if level.is_empty():
		push_error("Launcher: could not build %s" % level_id)
		return
	Router.goto("level", {"level": level, "mode": "main", "record_id": level_id, "exit_to": "level_select"})


## A fresh puzzle for the same room and tier (counts toward the level's stars).
static func play_replay(level_id: String) -> void:
	var level := Campaign.build_replay(level_id, _fresh_seed())
	if level.is_empty():
		return
	Router.goto("level", {"level": level, "mode": "replay", "record_id": level_id, "exit_to": "level_select"})


static func play_endless() -> void:
	var n := GameState.endless_next()
	var level := Campaign.build_endless(n, _fresh_seed())
	if level.is_empty():
		return
	Router.goto("level", {"level": level, "mode": "endless", "endless_n": n, "exit_to": "level_select"})


static func play_daily() -> void:
	var key := Daily.today_key()
	var level := Campaign.build_daily(key)
	if level.is_empty():
		return
	Router.goto("level", {"level": level, "mode": "daily", "day": key, "record_id": "daily_" + key, "exit_to": "main_menu"})


static func _fresh_seed() -> int:
	return absi(hash(Time.get_ticks_usec() + int(Time.get_unix_time_from_system()))) % 1000000 + 1
