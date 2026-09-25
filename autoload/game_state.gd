extends Node
## Player progress on top of SaveManager.data: levels, stars, seashells, decor, postcards, daily streak.


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
