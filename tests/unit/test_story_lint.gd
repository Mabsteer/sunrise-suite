extends TestCase
## The notes rules (docs/STORY.md, "Voice and rules") for the hand-made story rooms: a note is a
## memory, not an instruction. It never names its lock, never says how to read the code, never
## shows symbol icons and never writes the answer out. Every lock has its reasoning (`_why`) and
## three hints: a nudge, which object, how to read it.

## Hand-made levels the rules don't apply to (yet):
## the tutorial (the Day 1 kitchen may be explicit, and its guide does the hinting).
const EXCLUDED: PackedStringArray = ["tutorial"]

## Words that turn a memory into an instruction.
const FORBIDDEN: PackedStringArray = ["opens with", "open with", "read from", "read it from", "in that order", "the code", "set it to", "set the", "the drawer", "the lock", "padlock", "combination"]


func _story_levels() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in Campaign.levels():
		if e.has("level_file") and not EXCLUDED.has(str(e["level_file"])):
			out.append(Campaign.build(str(e["id"])))
	return out


func test_the_rules_cover_the_rewritten_rooms() -> void:
	assert_true(_story_levels().size() >= 1, "at least one hand-made room follows the new rules")


func test_notes_are_memories_not_instructions() -> void:
	for level in _story_levels():
		var session := LevelSession.new(level)
		var text := LevelText.new(session, Data.get_dict("rooms/" + str(level["room"])))
		for key in ["clues", "decoys"]:
			for c: Dictionary in level.get(key, []):
				if not c.has("memory"):
					continue
				var note := str(c.get("text", "")).to_lower()
				var where := "%s %s" % [level["id"], c["id"]]
				assert_false(note.contains("{"), "%s shows a symbol icon" % where)
				for phrase in FORBIDDEN:
					assert_false(note.contains(phrase), "%s says \"%s\"" % [where, phrase])
				var lock_id := str(c.get("for", ""))
				if lock_id == "" or not session.locks.has(lock_id):
					continue
				var name := text.lock_name(lock_id).to_lower().trim_prefix("the ")
				assert_false(note.contains(name), "%s names its own lock (%s)" % [where, name])
				var answer := str(session.locks[lock_id].get("answer", ""))
				if answer.length() >= 2 and not answer.contains(","):
					assert_false(note.contains(answer.to_lower()), "%s writes the answer out (%s)" % [where, answer])
					assert_false(note.contains(answer.replace(":", "")), "%s writes the answer out (%s)" % [where, answer])


func test_every_lock_has_a_reason_and_three_hints() -> void:
	for level in _story_levels():
		for l: Dictionary in level.get("locks", []):
			var where := "%s %s" % [level["id"], l["id"]]
			assert_false(str(l.get("_why", "")).is_empty(), "%s has a _why" % where)
			var hints: Array = l.get("hints", [])
			assert_eq(hints.size(), 3, "%s has three hints" % where)


func test_the_first_hint_is_only_a_nudge() -> void:
	for level in _story_levels():
		var session := LevelSession.new(level)
		var text := LevelText.new(session, Data.get_dict("rooms/" + str(level["room"])))
		for l: Dictionary in level.get("locks", []):
			var hints: Array = l.get("hints", [])
			# Chloé's needs are about her (she's not a lock), so her name may come up.
			if hints.size() != 3 or session.given_to_dog(str(l["id"])):
				continue
			var first := str(hints[0]).to_lower()
			var answer := str(l.get("answer", ""))
			if answer.length() >= 2 and not answer.contains(","):
				assert_false(first.contains(answer.to_lower()), "%s %s: the first hint gives the answer" % [level["id"], l["id"]])
			var name := text.lock_name(str(l["id"])).to_lower().trim_prefix("the ")
			assert_false(first.contains(name), "%s %s: the first hint names the lock" % [level["id"], l["id"]])
