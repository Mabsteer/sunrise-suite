extends TestCase
## The puzzle maths behind the new locks: every generated puzzle must have exactly one answer.

const SYMBOLS: Array = ["sun", "shell", "wave", "star", "leaf", "heart"]


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func test_sudoku_is_valid_and_unique() -> void:
	for s in 60:
		var blanks := 6 + s % 6
		var p := PuzzleMath.sudoku_generate(_rng(s + 1), blanks)
		var sol := str(p["solution"])
		var giv := str(p["givens"])
		assert_true(PuzzleMath.sudoku_valid(sol, giv), "seed %d: the solution is a valid square" % s)
		var grid: Array[int] = []
		for ch in giv:
			grid.append(0 if ch == "." else int(ch))
		assert_eq(PuzzleMath.sudoku_count(grid, 3), 1, "seed %d: exactly one way to finish it" % s)
		assert_true(int(p["blanks"]) >= mini(blanks, 6), "seed %d: removed enough numbers (%d)" % [s, int(p["blanks"])])
	assert_false(PuzzleMath.sudoku_valid("1111222233334444", "................"), "a wrong square is rejected")


func test_sudoku_is_deterministic() -> void:
	var a := PuzzleMath.sudoku_generate(_rng(42), 9)
	var b := PuzzleMath.sudoku_generate(_rng(42), 9)
	assert_eq(str(a["givens"]), str(b["givens"]))


func test_order_statements_allow_one_order() -> void:
	for n in [3, 4, 5]:
		for depth in 5:
			for s in 12:
				var rng := _rng(1000 + n * 100 + depth * 10 + s)
				var items := SYMBOLS.duplicate()
				PuzzleMath._shuffle(rng, items)
				var order := items.slice(0, n)
				var st := PuzzleMath.order_statements(rng, order, depth)
				var sols := PuzzleMath.order_solutions(order, st)
				assert_eq(sols.size(), 1, "n %d depth %d seed %d: %s" % [n, depth, s, str(st)])
				if sols.size() == 1:
					assert_eq(sols[0], order)


func test_switch_statements_allow_one_pattern() -> void:
	for n in [3, 4, 5, 6]:
		for depth in 5:
			for s in 10:
				var rng := _rng(5000 + n * 100 + depth * 10 + s)
				var symbols := SYMBOLS.slice(0, n)
				var pattern := ""
				while pattern == "" or not pattern.contains("1") or not pattern.contains("0"):
					pattern = ""
					for i in n:
						pattern += "1" if rng.randf() < 0.5 else "0"
				var st := PuzzleMath.switch_statements(rng, symbols, pattern, depth)
				var sols := PuzzleMath.switch_solutions(symbols, st)
				assert_eq(sols.size(), 1, "n %d depth %d seed %d" % [n, depth, s])
				if sols.size() == 1:
					assert_eq(sols[0], pattern)


func test_patterns_hide_their_answer() -> void:
	for depth in 5:
		for s in 20:
			for kind in ["numbers", "symbols"]:
				var p := PuzzleMath.pattern_generate(_rng(9000 + depth * 50 + s), depth, kind, SYMBOLS)
				var terms: Array = p["terms"]
				var blanks: Array = p["blanks"]
				assert_true(terms.size() >= 6, "%s depth %d: long enough to see the rule" % [kind, depth])
				assert_eq(blanks.size(), 1 if depth <= 2 else 2)
				var answer: PackedStringArray = []
				for b: int in blanks:
					assert_true(b >= 3 and b < terms.size(), "blank position %d" % b)
					answer.append(str(terms[b]))
				assert_eq(",".join(answer), str(p["answer"]))


func test_digit_patterns_make_codes() -> void:
	for count in [3, 4, 5]:
		for s in 30:
			var p := PuzzleMath.digit_pattern(_rng(7000 + count * 100 + s), 2 + s % 3, count)
			var code := str(p["code"])
			assert_eq(code.length(), count)
			assert_true(code.is_valid_int(), "only digits: " + code)
			assert_true((p["shown"] as Array).size() >= 4, "enough numbers shown")
