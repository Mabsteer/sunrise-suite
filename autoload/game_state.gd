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
	if mode == "daily":
		shells = SHELLS_DAILY
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
	SaveManager.save_game()
	return {"stars": stars, "seashells": shells, "first_clear": first_clear, "new_stars": new_stars, "unlocks": unlocks, "record_id": id}
