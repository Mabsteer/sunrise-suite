extends Node
## Player progress on top of SaveManager.data: levels, stars, seashells, decor, postcards, daily streak.

## Seashell rewards.
const SHELLS_FIRST_CLEAR := 10
const SHELLS_PER_NEW_STAR := 5
const SHELLS_REPLAY := 3
const SHELLS_DAILY := 15
const SHELLS_ENDLESS_BASE := 5


func seashells() -> int:
	return int(SaveManager.data.get("seashells", 0))


func add_seashells(amount: int) -> void:
	if amount == 0:
		return
	SaveManager.data["seashells"] = maxi(0, seashells() + amount)
	if amount > 0:
		SaveManager.data["seashells_earned"] = int(SaveManager.data.get("seashells_earned", 0)) + amount
	Events.seashells_changed.emit(seashells())


func level_record(level_id: String) -> Dictionary:
	var levels: Dictionary = SaveManager.data.get("levels", {})
	return levels.get(level_id, {})


func level_stars(level_id: String) -> int:
	return int(level_record(level_id).get("stars", 0))


func is_level_completed(level_id: String) -> bool:
	return int(level_record(level_id).get("completions", 0)) > 0


func total_stars() -> int:
	var total := 0
	var levels: Dictionary = SaveManager.data.get("levels", {})
	for id: String in levels.keys():
		total += int((levels[id] as Dictionary).get("stars", 0))
	return total


## Is a main level playable? Level 1 always; later ones once the previous level is done and the tier's star gate is met.
func is_level_unlocked(level_id: String) -> bool:
	var idx := Campaign.index_of(level_id)
	if idx <= 0:
		return idx == 0
	var list := Campaign.levels()
	if not is_level_completed(str(list[idx - 1]["id"])):
		return false
	return total_stars() >= Campaign.star_gate(int(list[idx]["tier"]))


## Why a level is locked ("" if it isn't): "previous" or "stars:<needed>".
func lock_reason(level_id: String) -> String:
	var idx := Campaign.index_of(level_id)
	if idx <= 0:
		return ""
	var list := Campaign.levels()
	if not is_level_completed(str(list[idx - 1]["id"])):
		return "previous"
	var need := Campaign.star_gate(int(list[idx]["tier"]))
	if total_stars() < need:
		return "stars:%d" % need
	return ""


## The next main level after `level_id` ("" if it was the last).
func next_level_id(level_id: String) -> String:
	var idx := Campaign.index_of(level_id)
	var list := Campaign.levels()
	if idx < 0 or idx + 1 >= list.size():
		return ""
	return str(list[idx + 1]["id"])


## The first level that isn't completed yet (or the last one if all are done).
func current_level_id() -> String:
	var list := Campaign.levels()
	for e in list:
		if not is_level_completed(str(e["id"])):
			return str(e["id"])
	return str(list[list.size() - 1]["id"]) if not list.is_empty() else ""


func campaign_finished() -> bool:
	var list := Campaign.levels()
	return not list.is_empty() and is_level_completed(str(list[list.size() - 1]["id"]))


func completed_count() -> int:
	var n := 0
	for e in Campaign.levels():
		if is_level_completed(str(e["id"])):
			n += 1
	return n


## Next Endless Sunrise number (1, 2, 3...).
func endless_next() -> int:
	return int((SaveManager.data.get("endless", {}) as Dictionary).get("cleared", 0)) + 1


# ================================================================== daily sunrise

func daily_data() -> Dictionary:
	var d: Dictionary = SaveManager.data.get("daily", {})
	SaveManager.data["daily"] = d
	return d


func daily_done(day: String) -> bool:
	return (daily_data().get("completed", {}) as Dictionary).has(day)


func daily_stars(day: String) -> int:
	return int(((daily_data().get("completed", {}) as Dictionary).get(day, {}) as Dictionary).get("stars", 0))


## The streak as the player should see it today (0 if it's already broken).
func current_streak(today: String = "") -> int:
	if today == "":
		today = Daily.today_key()
	var d := daily_data()
	var last := str(d.get("last_day", ""))
	if last == "":
		return 0
	var gap := Daily.day_number(today) - Daily.day_number(last)
	if gap <= 1:
		return int(d.get("streak", 0))
	# Missed days can still be covered by unused weekly sleep-ins until today is played.
	var missed := _missed_days(last, today)
	return int(d.get("streak", 0)) if _sleep_ins_cover(missed, d) else 0


## Is this week's free sleep-in still unused?
func sleep_in_available(today: String = "") -> bool:
	if today == "":
		today = Daily.today_key()
	return not (daily_data().get("sleep_ins", {}) as Dictionary).has(Daily.week_key(today))


## Records a finished Daily Sunrise. Returns { "streak", "first_time", "sleep_in_used", "rewards": Array[String], "shells" }.
func record_daily(day: String, stars: int, time: float) -> Dictionary:
	var d := daily_data()
	var completed: Dictionary = d.get("completed", {})
	var first_time := not completed.has(day)
	var result := {"streak": int(d.get("streak", 0)), "first_time": first_time, "sleep_in_used": false, "rewards": [], "shells": 0}
	if not first_time:
		var rec: Dictionary = completed[day]
		rec["stars"] = maxi(int(rec.get("stars", 0)), stars)
		rec["time"] = minf(float(rec.get("time", time)), time)
		return result
	completed[day] = {"stars": stars, "time": time}
	d["completed"] = completed
	var last := str(d.get("last_day", ""))
	var streak := 1
	if last != "":
		var gap := Daily.day_number(day) - Daily.day_number(last)
		if gap == 1:
			streak = int(d.get("streak", 0)) + 1
		elif gap > 1:
			var missed := _missed_days(last, day)
			if _sleep_ins_cover(missed, d):
				var sleep_ins: Dictionary = d.get("sleep_ins", {})
				for m in missed:
					sleep_ins[Daily.week_key(m)] = true
				d["sleep_ins"] = sleep_ins
				streak = int(d.get("streak", 0)) + 1
				result["sleep_in_used"] = true
		elif gap <= 0:
			streak = int(d.get("streak", 1))
	if last == "" or Daily.day_number(day) > Daily.day_number(last):
		d["last_day"] = day
	d["streak"] = streak
	d["best_streak"] = maxi(int(d.get("best_streak", 0)), streak)
	result["streak"] = streak
	var shells := SHELLS_DAILY + mini(streak, 7) * 2
	result["shells"] = shells
	result["rewards"] = grant_rewards("streak", str(streak))
	return result


func _missed_days(last: String, today: String) -> Array[String]:
	var out: Array[String] = []
	var start := Daily.day_number(last) + 1
	var end := Daily.day_number(today)
	for n in range(start, end):
		out.append(Daily.date_key(Time.get_date_dict_from_unix_time(n * 86400 + 43200)))
	return out


## Every missed day needs its own week's unused sleep-in.
func _sleep_ins_cover(missed: Array[String], d: Dictionary) -> bool:
	var used: Dictionary = (d.get("sleep_ins", {}) as Dictionary).duplicate()
	for m in missed:
		var wk := Daily.week_key(m)
		if used.has(wk):
			return false
		used[wk] = true
	return true


# ================================================================== postcards

func postcard_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Dictionary in Data.get_dict("postcards").get("postcards", []):
		out.append(p)
	return out


func postcard(id: String) -> Dictionary:
	for p in postcard_list():
		if str(p["id"]) == id:
			return p
	return {}


func has_postcard(id: String) -> bool:
	return (SaveManager.data.get("postcards", []) as Array).has(id)


func postcards_found_count() -> int:
	var n := 0
	for p in postcard_list():
		if has_postcard(str(p["id"])):
			n += 1
	return n


func all_postcards_found() -> bool:
	return postcards_found_count() >= postcard_list().size() and not postcard_list().is_empty()


## The main level that hides a postcard ("" if none).
func postcard_level(id: String) -> String:
	for e in Campaign.levels():
		if str(e.get("postcard", "")) == id:
			return str(e["id"])
	return ""


## Adds a postcard to the scrapbook. Returns { "new": bool, "all": bool, "rewards": Array[String] }.
func collect_postcard(id: String) -> Dictionary:
	var result := {"new": false, "all": false, "rewards": []}
	if postcard(id).is_empty() or has_postcard(id):
		return result
	var list: Array = SaveManager.data.get("postcards", [])
	list.append(id)
	SaveManager.data["postcards"] = list
	result["new"] = true
	if all_postcards_found():
		result["all"] = true
		result["rewards"] = grant_rewards("postcards_all")
	SaveManager.save_game()
	Events.postcard_found.emit(id)
	return result


# ================================================================== decor

func decor_items() -> Dictionary:
	return Data.get_dict("decor").get("items", {})


func decor(id: String) -> Dictionary:
	return decor_items().get(id, {})


func owned_decor() -> Dictionary:
	ensure_starter_decor()
	return SaveManager.data.get("decor_owned", {})


func placed_decor() -> Dictionary:
	ensure_starter_decor()
	return SaveManager.data.get("decor_placed", {})


func owned_count(id: String) -> int:
	return int(owned_decor().get(id, 0))


func placed_count(id: String) -> int:
	var n := 0
	for slot: String in placed_decor().keys():
		if str((placed_decor()[slot] as Dictionary).get("id", "")) == id:
			n += 1
	return n


## How many of this item are owned but not placed.
func available_count(id: String) -> int:
	return owned_count(id) - placed_count(id)


func decor_price(id: String) -> int:
	var p: Variant = decor(id).get("price", null)
	return -1 if p == null else int(p)


func can_buy_decor(id: String) -> bool:
	var price := decor_price(id)
	return price >= 0 and seashells() >= price


func buy_decor(id: String) -> bool:
	if not can_buy_decor(id):
		return false
	add_seashells(-decor_price(id))
	_add_owned(id)
	SaveManager.save_game()
	Events.decor_changed.emit()
	return true


## Gives an earned (reward) item. Returns false if it was already owned.
func grant_decor(id: String) -> bool:
	if decor(id).is_empty() or owned_count(id) > 0:
		return false
	_add_owned(id)
	SaveManager.save_game()
	Events.decor_changed.emit()
	return true


## Puts an owned item on a hub slot (replacing what was there, which goes back to storage).
func place_decor(slot_id: String, id: String) -> bool:
	if available_count(id) <= 0 and str((placed_decor().get(slot_id, {}) as Dictionary).get("id", "")) != id:
		return false
	if hub_slot(slot_id).get("type", "") != decor(id).get("slot", "?"):
		return false
	placed_decor()[slot_id] = {"id": id, "flipped": false}
	SaveManager.save_game()
	Events.decor_changed.emit()
	return true


func move_decor(from_slot: String, to_slot: String) -> bool:
	var placed := placed_decor()
	if not placed.has(from_slot) or placed.has(to_slot):
		return false
	var entry: Dictionary = placed[from_slot]
	if hub_slot(to_slot).get("type", "") != decor(str(entry["id"])).get("slot", "?"):
		return false
	placed.erase(from_slot)
	placed[to_slot] = entry
	SaveManager.save_game()
	Events.decor_changed.emit()
	return true


func flip_decor(slot_id: String) -> void:
	var placed := placed_decor()
	if placed.has(slot_id):
		(placed[slot_id] as Dictionary)["flipped"] = not bool((placed[slot_id] as Dictionary).get("flipped", false))
		SaveManager.save_game()
		Events.decor_changed.emit()


func store_decor(slot_id: String) -> void:
	placed_decor().erase(slot_id)
	SaveManager.save_game()
	Events.decor_changed.emit()


func hub_slot(slot_id: String) -> Dictionary:
	for s: Dictionary in Data.get_dict("rooms/hub").get("decor_slots", []):
		if str(s["id"]) == slot_id:
			return s
	return {}


## First visit: own and place the starter decor from decor.json.
func ensure_starter_decor() -> void:
	if bool(SaveManager.data.get("starter_decor_given", false)):
		return
	SaveManager.data["starter_decor_given"] = true
	var starter: Dictionary = Data.get_dict("decor").get("starter", {})
	var owned: Dictionary = SaveManager.data.get("decor_owned", {})
	var placed: Dictionary = SaveManager.data.get("decor_placed", {})
	for slot: String in starter.keys():
		if slot.begins_with("_"):
			continue
		var id := str(starter[slot])
		owned[id] = int(owned.get(id, 0)) + 1
		if not placed.has(slot):
			placed[slot] = {"id": id, "flipped": false}
	SaveManager.data["decor_owned"] = owned
	SaveManager.data["decor_placed"] = placed


func _add_owned(id: String) -> void:
	var owned := owned_decor()
	owned[id] = int(owned.get(id, 0)) + 1
	SaveManager.data["decor_owned"] = owned


## Grants earned decor for an event. Returns the names of new items (for "you got..." messages).
func grant_rewards(event: String, key: String = "") -> Array[String]:
	var rewards := Data.get_dict("rewards")
	var ids: Array[String] = []
	match event:
		"level":
			var levels: Dictionary = rewards.get("levels", {})
			if levels.has(key):
				ids.append(str(levels[key]))
		"streak":
			var streak: Dictionary = rewards.get("streak", {})
			for k: String in streak.keys():
				if not k.begins_with("_") and int(key) >= int(k):
					ids.append(str(streak[k]))
		"postcards_all":
			if rewards.has("postcards_all"):
				ids.append(str(rewards["postcards_all"]))
	var names: Array[String] = []
	for id in ids:
		if grant_decor(id):
			names.append(str(decor(id).get("name", id)))
	return names


## Stars for a finished session: 1 for finishing, +1 for using at most one hint, +1 for beating par time.
static func stars_for(session: LevelSession, par_time: float) -> int:
	var stars := 1
	if session.hints_used <= 1:
		stars += 1
	if session.elapsed <= par_time:
		stars += 1
	return stars


## Saves the result of a finished level and hands out seashells.
## Returns { "stars", "seashells", "first_clear", "new_stars", "unlocks": Array[String] }.
func record_level_result(level: Dictionary, record_id: String, mode: String, session: LevelSession) -> Dictionary:
	var id := record_id if record_id != "" else str(level.get("id", "level"))
	var stars_before := total_stars()
	var par := float(level.get("par_time", 600))
	var stars := stars_for(session, par)
	var shells := 0
	var first_clear := false
	var new_stars := 0
	var new_best_time := false
	var daily_result := {}
	if mode == "daily":
		var day := id.trim_prefix("daily_")
		daily_result = record_daily(day, stars, session.elapsed)
		shells = int(daily_result.get("shells", 0))
	elif mode == "endless":
		shells = SHELLS_ENDLESS_BASE + int(level.get("tier", 1))
		var endless: Dictionary = SaveManager.data.get("endless", {})
		endless["cleared"] = int(endless.get("cleared", 0)) + 1
		endless["best_tier"] = maxi(int(endless.get("best_tier", 0)), int(level.get("tier", 1)))
		SaveManager.data["endless"] = endless
	else:
		var levels: Dictionary = SaveManager.data.get("levels", {})
		var rec: Dictionary = levels.get(id, {})
		var old_stars := int(rec.get("stars", 0))
		first_clear = int(rec.get("completions", 0)) == 0
		new_stars = maxi(0, stars - old_stars)
		shells = (SHELLS_FIRST_CLEAR if first_clear else SHELLS_REPLAY) + new_stars * SHELLS_PER_NEW_STAR
		rec["stars"] = maxi(old_stars, stars)
		rec["completions"] = int(rec.get("completions", 0)) + 1
		new_best_time = rec.has("best_time") and session.elapsed < float(rec["best_time"])
		rec["best_time"] = minf(float(rec.get("best_time", INF)), session.elapsed) if rec.has("best_time") else session.elapsed
		rec["fewest_hints"] = mini(int(rec.get("fewest_hints", 999)), session.hints_used)
		levels[id] = rec
		SaveManager.data["levels"] = levels
		if mode == "replay":
			SaveManager.data["replays"] = int(SaveManager.data.get("replays", 0)) + 1
	add_seashells(shells)
	var unlocks: Array[String] = []
	if mode == "main" or mode == "replay":
		var nxt := next_level_id(id)
		if first_clear and nxt != "" and is_level_unlocked(nxt):
			unlocks.append(tr("UNLOCK_NEXT"))
		for tier in [4, 7, 10]:
			var need := Campaign.star_gate(tier)
			if need > 0 and stars_before < need and total_stars() >= need:
				unlocks.append(tr("UNLOCK_GATE") % tier)
		if first_clear and nxt == "" and Campaign.index_of(id) >= 0:
			unlocks.append(tr("UNLOCK_ENDLESS"))
		if first_clear:
			for decor_name in grant_rewards("level", id):
				unlocks.append(tr("UNLOCK_DECOR") % decor_name)
	if mode == "daily" and not daily_result.is_empty():
		if bool(daily_result.get("first_time", false)):
			unlocks.append(tr("DAILY_STREAK") % int(daily_result["streak"]))
		if bool(daily_result.get("sleep_in_used", false)):
			unlocks.append(tr("DAILY_SLEEP_IN_USED"))
		for decor_name: String in daily_result.get("rewards", []):
			unlocks.append(tr("UNLOCK_DECOR") % decor_name)
	SaveManager.save_game()
	return {"stars": stars, "seashells": shells, "first_clear": first_clear, "new_stars": new_stars, "unlocks": unlocks, "record_id": id, "new_best_time": new_best_time}
