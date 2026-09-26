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
		if arg.begins_with("--print="):
			# Show one generated level in words:  -- --print=kitchen:6:123
			var p := arg.trim_prefix("--print=").split(":")
			_print_level(LevelGenerator.generate(p[0], int(p[1]), int(p[2])))
			get_tree().quit(0)
			return
	var rooms := available_rooms()
	var failures: PackedStringArray = []
	var total := 0
	var total_ms := 0.0
	var worst_ms := 0.0
	var type_counts := {}
	for room in rooms:
		for tier in range(1, 11):
			var cfg := LevelGenerator.tier_config(tier)
			var steps_sum := 0
			var tier_ms := 0.0
			var estimates: Array[float] = []
			for s in seeds:
				var seed_value := 1000 + s * 97 + tier
				var t0 := Time.get_ticks_usec()
				# Every other level has Chloé along; some hall levels are the one where she's found.
				var options := {"companion": s % 2 == 1}
				if room == "hall" and s % 6 == 0:
					options = {"find_dog": true}
				var level := LevelGenerator.generate(room, tier, seed_value, options)
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
				for l: Dictionary in level.get("locks", []):
					var lt := str(l.get("type", ""))
					type_counts[lt] = int(type_counts.get(lt, 0)) + 1
				estimates.append(float(report.get("estimate", 0.0)))
			estimates.sort()
			var median := estimates[estimates.size() / 2] if not estimates.is_empty() else 0.0
			var p90 := estimates[int(estimates.size() * 0.9)] if not estimates.is_empty() else 0.0
			var par := float(cfg.get("par_time", 600))
			print("  %-8s tier %2d: avg %.1f steps, %.1f ms/level, time estimate median %ds / p90 %ds, par %ds" % [room, tier, float(steps_sum) / seeds, tier_ms / seeds, median, p90, par])
			# Par-time sanity: a careful player without hints should usually beat par.
			if par < p90:
				failures.append("%s tier %d: par_time %ds is below the p90 time estimate %ds (raise it in tiers.json)" % [room, tier, par, p90])
	# Endless tiers and determinism.
	for tier in [11, 14, 20]:
		var a := LevelGenerator.generate(rooms[0], tier, 42)
		if a.is_empty():
			failures.append("endless tier %d failed" % tier)
	var x := LevelGenerator.generate(rooms[0], 7, 777)
	var y := LevelGenerator.generate(rooms[0], 7, 777)
	if JSON.stringify(x) != JSON.stringify(y):
		failures.append("generator is not deterministic")
	# Campaign + daily levels.
	for entry: Dictionary in Campaign.levels():
		if not Campaign.room_available(str(entry["room"])):
			continue
		var built := Campaign.build(str(entry["id"]))
		if built.is_empty():
			failures.append("campaign level %s failed" % entry["id"])
		elif entry.has("level_file"):
			var r := LevelValidator.validate(built)
			if not bool(r["ok"]):
				failures.append("hand-made level %s: %s" % [entry["id"], ", ".join(r["errors"])])
	for d in 14:
		var key := Daily.date_key(Time.get_date_dict_from_unix_time(int(Time.get_unix_time_from_system()) + d * 86400))
		if Campaign.build_daily(key).is_empty():
			failures.append("daily %s failed" % key)
	# Every lock type must actually turn up in generated levels.
	for t in LevelSession.ALL_TYPES:
		if int(type_counts.get(t, 0)) == 0:
			failures.append("no generated level uses a %s lock" % t)
	print("LOCK TYPES: %s" % str(type_counts))
	for f in failures.slice(0, 30):
		printerr("FAIL ", f)
	var avg := total_ms / maxi(total, 1)
	print("VALIDATOR: %d levels, %d failed, avg %.1f ms, worst %.1f ms" % [total, failures.size(), avg, worst_ms])
	if avg > MAX_AVG_MS:
		printerr("FAIL generation too slow: %.1f ms average (limit %.0f)" % [avg, MAX_AVG_MS])
		get_tree().quit(1)
		return
	get_tree().quit(0 if failures.is_empty() else 1)


func _print_level(level: Dictionary) -> void:
	print("LEVEL %s (tier %d, par %ds, attempt %d)" % [level.get("id", "?"), int(level.get("tier", 0)), int(level.get("par_time", 0)), int(level.get("attempt", 0))])
	for l: Dictionary in level.get("locks", []):
		print("  lock %s: %s in %s, answer %s%s" % [l["id"], l["type"], l.get("location", "room"), l.get("answer", "-"), "  (door)" if l.get("is_door", false) else ""])
	for i: Dictionary in level.get("items", []):
		print("  item %s: %s in %s" % [i["id"], i["type"], i.get("location", "room")])
	for c: Dictionary in level.get("clues", []):
		print("  clue %s for %s in %s: %s" % [c["id"], c.get("for", "?"), c.get("location", "room"), c.get("text", "")])
	for d: Dictionary in level.get("decoys", []):
		print("  decoy: %s" % d.get("text", ""))


static func available_rooms() -> Array[String]:
	var rooms: Array[String] = []
	for r in Campaign.ROUTE:
		if ResourceLoader.exists("res://data/rooms/%s.json" % r) or FileAccess.file_exists("res://data/rooms/%s.json" % r):
			rooms.append(r)
	return rooms
