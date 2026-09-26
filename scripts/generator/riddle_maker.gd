class_name RiddleMaker
extends RefCounted
## Writes the notes for locks that need knowledge (combo, sequence, clock, switches, order).
##
## Riddle depth 0..4 comes from tiers.json ("riddle"). Depth 0-1 use the plain templates in
## data/clues.json. From depth 2 the answer is never written out: digits come from everyday facts,
## things to count in the room (counter props, placed through the generator), sums and number
## patterns; symbol tunes, lamps and orders get logic statements with exactly one answer
## (PuzzleMath proves it). A riddle may choose the lock's answer itself (e.g. a code that
## continues a pattern), so it must run before anything else reads that answer.

const TYPES: PackedStringArray = ["combo", "sequence", "clock", "switches", "order"]

const MAX_COUNTERS := 2

var gen: LevelGenerator
var rng: RandomNumberGenerator
var db: Dictionary
var _counters := 0


func _init(generator: LevelGenerator) -> void:
	gen = generator
	rng = generator.rng
	db = generator.clue_db


## The note texts for `lock` (one, or two halves). May change lock["answer"] and place counter props.
func notes_for(lock: Dictionary, depth: int) -> PackedStringArray:
	var t := str(lock["type"])
	var d := clampi(depth, 0, 4)
	match t:
		"order":
			if d == 0:
				return [_fill(_pick(t, "0"), lock)]
			return _statement_notes(lock, d, PuzzleMath.order_statements(rng, Array(str(lock["answer"]).split(",")), d))
		"sequence":
			if d <= 1:
				return _plain(lock, d)
			return _statement_notes(lock, d, PuzzleMath.order_statements(rng, Array(str(lock["answer"]).split(",")), d))
		"switches":
			if d <= 1:
				return _plain(lock, d)
			var symbols: Array = (lock.get("config", {}) as Dictionary).get("symbols", [])
			return _statement_notes(lock, d, PuzzleMath.switch_statements(rng, symbols, str(lock["answer"]), d))
		"combo":
			if d <= 1:
				return _plain(lock, d)
			return _combo(lock, d)
		"clock":
			if d <= 2:
				return _plain(lock, d)
			return _clock(lock, d)
	return [str(lock.get("answer", ""))]


# ================================================================== plain templates (depth 0-1)

## Depth 0 says the answer ("0", "1"); from depth 1 it always needs a twist: words, backwards,
## an hour earlier... ("2", "3"), or two halves on two notes.
func _plain(lock: Dictionary, level: int) -> PackedStringArray:
	var t := str(lock["type"])
	var templates: Dictionary = db.get(t, {})
	if level >= 1 and templates.has("first") and rng.randf() < 0.3:
		var parts := gen._split_answer(t, str(lock["answer"]), lock)
		return [gen._fill(_pick(t, "first"), lock, parts[0]), gen._fill(_pick(t, "last"), lock, parts[1])]
	var keys: Array[String] = ["0", "1"]
	if level >= 1:
		keys = ["2", "3"]
	var options: Array[String] = []
	for k in keys:
		if templates.has(k):
			options.append(k)
	var key: String = options[rng.randi_range(0, options.size() - 1)] if not options.is_empty() else "0"
	return [gen._fill(_pick(t, key), lock, "")]


# ================================================================== combination codes

func _combo(lock: Dictionary, depth: int) -> PackedStringArray:
	var n := str(lock["answer"]).length()
	if rng.randf() < 0.25:
		var p := PuzzleMath.digit_pattern(rng, depth, n)
		lock["answer"] = str(p["code"])
		var shown: PackedStringArray = []
		for v: int in p["shown"]:
			shown.append(str(v))
		return [_fill(_pick("combo", "pattern"), lock, {"{shown}": ", ".join(shown), "{count}": _number_word(n)})]
	var code := str(lock["answer"])
	var phrases: PackedStringArray = []
	for i in n:
		phrases.append(_digit_phrase(lock, int(code[i]), depth))
	if depth >= 3 and n >= 4 and rng.randf() < 0.5:
		var cut := n / 2
		var first := _join_parts(phrases.slice(0, cut), true, false)
		var last := _join_parts(phrases.slice(cut), false, true)
		return [
			_fill(_pick("combo", "riddle_first"), lock, {"{parts}": first, "{count}": _number_word(n)}),
			_fill(_pick("combo", "riddle_last"), lock, {"{parts}": last}),
		]
	return [_fill(_pick("combo", "riddle"), lock, {"{parts}": _join_parts(phrases, true, true), "{count}": _number_word(n)})]


## "first A, then B, and last C" (the pieces of a split riddle leave out the start or the end).
func _join_parts(phrases: PackedStringArray, has_start: bool, has_end: bool) -> String:
	var out: PackedStringArray = []
	for i in phrases.size():
		var p := phrases[i]
		if i == 0 and has_start:
			out.append("first " + p)
		elif i == phrases.size() - 1 and has_end and phrases.size() > 1:
			out.append("and last " + p)
		else:
			out.append("then " + p)
	return ", ".join(out)


## A phrase that works out to the digit d: a fact, something to count, or a little sum.
func _digit_phrase(lock: Dictionary, d: int, depth: int) -> String:
	var weights := {
		"fact": [0.0, 0.0, 3.0, 1.5, 0.6][depth],
		"counter": [0.0, 0.0, 2.0, 1.5, 1.0][depth],
		"sum": [0.0, 0.0, 0.0, 2.0, 3.0][depth],
		"counter_sum": [0.0, 0.0, 0.0, 0.6, 1.5][depth],
	}
	for _attempt in 6:
		var kind := _weighted_key(weights)
		var phrase := ""
		match kind:
			"fact":
				phrase = _fact_text(d)
			"counter":
				if d >= 1 and d <= 9 and _counters < MAX_COUNTERS:
					phrase = gen.place_counter(lock, d)
					if phrase != "":
						_counters += 1
			"sum":
				phrase = _sum_phrase(d)
			"counter_sum":
				phrase = _counter_sum_phrase(lock, d)
		if phrase != "":
			return phrase
		weights[kind] = 0.0
	return _fact_text(d)


func _fact_text(n: int) -> String:
	var options: Array[String] = []
	for f: Dictionary in db.get("facts", []):
		if int(f["n"]) == n:
			options.append(str(f["text"]))
	return options[rng.randi_range(0, options.size() - 1)] if not options.is_empty() else _number_word(n)


## "the legs on a spider minus the wheels on a bicycle", "half of the months in a year"...
func _sum_phrase(d: int) -> String:
	var facts: Array = db.get("facts", [])
	var options: Array[String] = []
	var arith: Dictionary = db.get("arithmetic", {})
	for a: Dictionary in facts:
		var av := int(a["n"])
		if av == 2 * d and d >= 1:
			options.append(_arith("half", str(a["text"]), ""))
		if av * 2 == d and av >= 1:
			options.append(_arith("double", str(a["text"]), ""))
		for b: Dictionary in facts:
			var bv := int(b["n"])
			if a == b or bv < 1:
				continue
			if av - bv == d:
				options.append(_arith("minus", str(a["text"]), str(b["text"])))
			if av + bv == d and av >= 1 and str(a["text"]) < str(b["text"]):
				options.append(_arith("plus", str(a["text"]), str(b["text"])))
	if arith.is_empty() or options.is_empty():
		return ""
	return options[rng.randi_range(0, options.size() - 1)]


## "the shells in the jar plus two"
func _counter_sum_phrase(lock: Dictionary, d: int) -> String:
	if _counters >= MAX_COUNTERS:
		return ""
	var k := rng.randi_range(1, 3)
	var up := rng.randf() < 0.5
	var shown := d - k if up else d + k
	if shown < 1 or shown > 9:
		up = not up
		shown = d - k if up else d + k
	if shown < 1 or shown > 9:
		return ""
	var counter := gen.place_counter(lock, shown)
	if counter == "":
		return ""
	_counters += 1
	return "%s %s %s" % [counter, "plus" if up else "minus", _number_word(k)]


func _arith(kind: String, x: String, y: String) -> String:
	var list: Array = (db.get("arithmetic", {}) as Dictionary).get(kind, ["{x}"])
	return str(list[rng.randi_range(0, list.size() - 1)]).replace("{x}", x).replace("{y}", y)


# ================================================================== logic statements

func _statement_notes(lock: Dictionary, depth: int, statements: Array[Dictionary]) -> PackedStringArray:
	var t := str(lock["type"])
	var sentences: PackedStringArray = []
	for s in statements:
		sentences.append(_sentence(s))
	if depth >= 3 and sentences.size() >= 4 and rng.randf() < 0.5:
		var cut := sentences.size() / 2
		return [
			_fill(_pick(t, "riddle_first"), lock, {"{statements}": " ".join(sentences.slice(0, cut))}),
			_fill(_pick(t, "riddle_last"), lock, {"{statements}": " ".join(sentences.slice(cut))}),
		]
	return [_fill(_pick(t, "riddle"), lock, {"{statements}": " ".join(sentences)})]


func _sentence(s: Dictionary) -> String:
	var list: Array = (db.get("statements", {}) as Dictionary).get(str(s["type"]), ["{a}"])
	var out := str(list[rng.randi_range(0, list.size() - 1)])
	for key in ["a", "b", "c"]:
		if s.has(key):
			out = out.replace("{%s}" % key, "{%s}" % str(s[key]))
	if s.has("k"):
		var ordinals: Array = db.get("ordinals", [])
		var k := int(s["k"])
		out = out.replace("{ord}", str(ordinals[k]) if k < ordinals.size() else str(k + 1))
		out = out.replace("{k}", _number_word(k))
	return _cap(out)


# ================================================================== times

func _clock(lock: Dictionary, depth: int) -> PackedStringArray:
	var base_h := rng.randi_range(5, 10)
	var base_m := rng.randi_range(0, 3) * 15
	var offsets: Array[int] = [10, 15, 20, 25, 30, 40, 45, 60, 90]
	var o1: int = offsets[rng.randi_range(0, offsets.size() - 1)]
	var key := "offset"
	var total := o1
	var o2 := 0
	if depth >= 4:
		key = "two_steps"
		o2 = [5, 10, 15, 20][rng.randi_range(0, 3)]
		total += o2
	elif rng.randf() < 0.35:
		key = "offset_before"
		total = -o1
	var minutes := posmod(base_h * 60 + base_m + total, 12 * 60)
	var h := minutes / 60
	if h == 0:
		h = 12
	lock["answer"] = "%d:%02d" % [h, minutes % 60]
	var words: Dictionary = db.get("offset_words", {})
	return [_fill(_pick("clock", key), lock, {
		"{base}": gen._time_words(base_h, base_m),
		"{offset}": str(words.get(str(o1), "%d minutes" % o1)),
		"{offset2}": str(words.get(str(o2), "%d minutes" % o2)),
	})]


# ================================================================== helpers

func _pick(type: String, key: String) -> String:
	var list: Array = (db.get(type, {}) as Dictionary).get(key, [])
	if list.is_empty():
		return "{lock}: {code}"
	return str(list[rng.randi_range(0, list.size() - 1)])


func _fill(template: String, lock: Dictionary, extra: Dictionary = {}) -> String:
	var out := template
	for k: String in extra.keys():
		out = out.replace(k, str(extra[k]))
	return gen._fill(out, lock, "")


func _number_word(n: int) -> String:
	var words: Array = db.get("number_words", [])
	return str(words[n]) if n >= 0 and n < words.size() else str(n)


func _weighted_key(weights: Dictionary) -> String:
	var total := 0.0
	for k: String in weights.keys():
		total += float(weights[k])
	if total <= 0.0:
		return "fact"
	var r := rng.randf() * total
	for k: String in weights.keys():
		r -= float(weights[k])
		if r <= 0.0:
			return k
	return "fact"


static func _cap(s: String) -> String:
	if s.begins_with("{"):
		return s
	return s if s.is_empty() else s[0].to_upper() + s.substr(1)
