extends Node
## The Daily Sunrise: one level per UTC day, identical for every player.
## Rooms and weekday difficulty come from res://data/daily.json.


## Today's key in UTC, e.g. "2026-09-26".
func today_key() -> String:
	return date_key(Time.get_date_dict_from_system(true))


static func date_key(date: Dictionary) -> String:
	return "%04d-%02d-%02d" % [int(date["year"]), int(date["month"]), int(date["day"])]


## Parses "YYYY-MM-DD" into a date dictionary (year, month, day, weekday).
static func parse_key(key: String) -> Dictionary:
	var unix := Time.get_unix_time_from_datetime_string(key + "T12:00:00")
	return Time.get_datetime_dict_from_unix_time(unix)


## Deterministic seed for a day. Same key -> same seed on every device.
static func seed_for(key: String) -> int:
	return absi(("sunrise-suite-daily-" + key).hash()) + 1


## Unix day number (days since 1970-01-01) for a key.
static func day_number(key: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(key + "T12:00:00") / 86400.0)


## Week key used for the weekly sleep-in, e.g. "W2912" (weeks since 1970, starting on Monday).
static func week_key(key: String) -> String:
	var day := day_number(key)
	# 1970-01-01 was a Thursday; shift so weeks start on Monday.
	var week := int(floor((day + 3) / 7.0))
	return "W%d" % week


## Returns { "day": key, "room": room_id, "tier": int, "seed": int } for the given day.
func level_for(key: String) -> Dictionary:
	var cfg := Data.get_dict("daily")
	var rooms: Array = cfg.get("rooms", ["lounge", "kitchen", "study"])
	var weekday_tiers: Array = cfg.get("weekday_tiers", [4, 2, 3, 4, 5, 6, 7])
	var date := parse_key(key)
	var weekday := int(date.get("weekday", 0))
	var room: String = rooms[posmod(day_number(key), rooms.size())]
	return {
		"day": key,
		"room": room,
		"tier": int(weekday_tiers[weekday % weekday_tiers.size()]),
		"seed": seed_for(key),
	}


func today_level() -> Dictionary:
	return level_for(today_key())


## Sky colours for a day's calendar tile: small, deterministic variations of the sunrise palette.
static func sky_colors_for(key: String) -> Array[Color]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_for(key)
	var top := Color.from_hsv(0.72 + rng.randf_range(-0.05, 0.05), 0.45 + rng.randf_range(-0.1, 0.1), 0.45 + rng.randf_range(-0.08, 0.08))
	var mid := Color.from_hsv(0.03 + rng.randf_range(-0.03, 0.05), 0.45 + rng.randf_range(-0.1, 0.1), 0.97)
	var low := Color.from_hsv(0.11 + rng.randf_range(-0.02, 0.03), 0.6 + rng.randf_range(-0.1, 0.1), 0.98)
	return [top, mid, low]
