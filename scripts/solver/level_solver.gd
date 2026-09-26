class_name LevelSolver
extends RefCounted
## Plays a level to the end by always doing what the hint system suggests, with the correct answers.
## Used by the validator (is every generated level solvable?) and by the autoplay bot.


## Returns { "solvable": bool, "all_steps": bool, "actions": Array[Dictionary], "rounds": int, "error": String }.
static func solve(level: Dictionary) -> Dictionary:
	var s := LevelSession.new(level)
	var actions: Array[Dictionary] = []
	var error := ""
	var guard := 0
	while not s.finished and guard < 400:
		guard += 1
		var goal := s.next_goal()
		var ok := apply_goal(s, goal)
		actions.append(goal)
		if not ok:
			error = "stuck at %s" % str(goal.get("target", "?"))
			break
	if not s.finished and error == "":
		error = "gave up after %d actions" % guard
	return {
		"solvable": s.finished,
		"all_steps": s.solved_steps == s.total_steps,
		"solved_steps": s.solved_steps,
		"total_steps": s.total_steps,
		"actions": actions,
		"error": error,
	}


## Rough time (seconds) a thoughtful player who uses no hints needs: looking around, reading,
## working out answers and entering them. Used to check that par times are fair (the validator
## prints it per tier). `actions` comes from solve().
static func estimate_seconds(level: Dictionary, actions: Array, indirection: int) -> float:
	var t := 0.0
	var things: int = level.get("locks", []).size() + level.get("items", []).size() + level.get("clues", []).size() + level.get("decoys", []).size()
	t += 5.0 * things  # finding each thing in the room
	t += 6.0 * level.get("decoys", []).size()  # reading notes that lead nowhere
	var locks := {}
	for l: Dictionary in level.get("locks", []):
		locks[str(l["id"])] = l
	for a: Dictionary in actions:
		match str(a.get("action", "")):
			"pick_up":
				t += 4.0
			"see_clue":
				t += 8.0 + 7.0 * indirection
			"combine":
				t += 12.0
			"open":
				var l: Dictionary = locks.get(str(a.get("id", "")), {})
				match str(l.get("type", "")):
					"combo":
						t += 10.0 + 2.0 * str(l.get("answer", "")).length()
					"sequence", "switches":
						t += 14.0
					"clock":
						t += 12.0
					"slider":
						var n := int((l.get("config", {}) as Dictionary).get("size", 3))
						t += 40.0 if n <= 3 else 110.0
					_:
						t += 5.0
	return t


## Performs one goal from LevelSession.next_goal(). Returns false if it could not be done.
static func apply_goal(s: LevelSession, goal: Dictionary) -> bool:
	match str(goal.get("action", "")):
		"pick_up":
			return s.pick_up(str(goal["id"]))
		"combine":
			return s.combine(str(goal["a"]), str(goal["b"])) != ""
		"see_clue":
			var before := s.seen.size()
			s.see_clue(str(goal["id"]))
			return s.seen.size() > before
		"open":
			return open_lock(s, str(goal["id"]))
	return false


static func open_lock(s: LevelSession, lock_id: String) -> bool:
	var t := s.lock_type(lock_id)
	if t in LevelSession.KNOWLEDGE_TYPES or t == "slider":
		return s.submit_answer(lock_id, str(s.locks[lock_id].get("answer", "")))
	if t == "key" or (t == "hidden" and s.lock_item(lock_id) != ""):
		var held := s._inventory_match(s.lock_item(lock_id))
		return held != "" and s.use_item(held, lock_id) == "opened"
	if t == "hidden":
		return s.search(lock_id)
	return false
