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
	SaveManager.save_game()
	return {"stars": stars, "seashells": shells, "first_clear": first_clear, "new_stars": new_stars, "unlocks": []}
