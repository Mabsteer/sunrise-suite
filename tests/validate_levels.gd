extends Node
## Generates many levels for every room x tier and proves each one is valid and solvable.
## Also checks every campaign level and the next two weeks of Daily Sunrises.
##   bash tools/godot.sh --headless --path . res://tests/validate_levels.tscn -- --seeds=200

const DEFAULT_SEEDS := 200
const MAX_AVG_MS := 50.0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var seeds := DEFAULT_SEEDS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="):
			seeds = int(arg.trim_prefix("--seeds="))
	var rooms := available_rooms()
	var failures: PackedStringArray = []
	var total := 0
	var total_ms := 0.0
	var worst_ms := 0.0
	for room in rooms:
		for tier in range(1, 11):
			var cfg := LevelGenerator.tier_config(tier)
			var steps_sum := 0
			var tier_ms := 0.0
			for s in seeds:
				var seed_value := 1000 + s * 97 + tier
				var t0 := Time.get_ticks_usec()
				var level := LevelGenerator.generate(room, tier, seed_value)
				var ms := (Time.get_ticks_usec() - t0) / 1000.0
				total += 1
				total_ms += ms
				tier_ms += ms
				worst_ms = maxf(worst_ms, ms)
				if level.is_empty():
					failures.append("%s t%d seed %d: could not generate" % [room, tier, seed_value])
					continue
				var report := LevelValidator.validate(level, cfg)
				if not bool(report["ok"]):
					failures.append("%s t%d seed %d: %s" % [room, tier, seed_value, ", ".join(report["errors"])])
				steps_sum += int(report["steps"])
			print("  %-8s tier %2d: avg %.1f steps, %.1f ms/level" % [room, tier, float(steps_sum) / seeds, tier_ms / seeds])
	# Endless tiers and determinism.
	for tier in [11, 14, 20]:
		var a := LevelGenerator.generate(rooms[0], tier, 42)
		if a.is_empty():
			failures.append("endless tier %d failed" % tier)
	var x := LevelGenerator.generate(rooms[0], 5, 777)
	var y := LevelGenerator.generate(rooms[0], 5, 777)
	if JSON.stringify(x) != JSON.stringify(y):
		failures.append("generator is not deterministic")
	# Campaign + daily levels.
	for entry: Dictionary in Campaign.levels():
		if not Campaign.room_available(str(entry["room"])):
			continue
		if Campaign.build(str(entry["id"])).is_empty():
			failures.append("campaign level %s failed" % entry["id"])
	for d in 14:
		var key := Daily.date_key(Time.get_date_dict_from_unix_time(int(Time.get_unix_time_from_system()) + d * 86400))
		if Campaign.build_daily(key).is_empty():
			failures.append("daily %s failed" % key)
	for f in failures.slice(0, 30):
		printerr("FAIL ", f)
	var avg := total_ms / maxi(total, 1)
	print("VALIDATOR: %d levels, %d failed, avg %.1f ms, worst %.1f ms" % [total, failures.size(), avg, worst_ms])
	if avg > MAX_AVG_MS:
		printerr("FAIL generation too slow: %.1f ms average (limit %.0f)" % [avg, MAX_AVG_MS])
		get_tree().quit(1)
		return
	get_tree().quit(0 if failures.is_empty() else 1)


static func available_rooms() -> Array[String]:
	var rooms: Array[String] = []
	for r in ["lounge", "kitchen", "study"]:
		if ResourceLoader.exists("res://data/rooms/%s.json" % r) or FileAccess.file_exists("res://data/rooms/%s.json" % r):
			rooms.append(r)
	return rooms
