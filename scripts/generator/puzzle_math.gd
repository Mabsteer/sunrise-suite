class_name PuzzleMath
extends RefCounted
## Pure puzzle maths for the generator (no nodes, no data files): 4x4 number squares, logic
## statements for orders and lamps, and number/symbol patterns. Everything takes a seeded
## RandomNumberGenerator and proves its puzzles have exactly one answer.


# ================================================================== 4x4 number square (sudoku)

## Returns { "solution": "1234341221434321", "givens": "1.3.....", "blanks": int }.
## Cells are read row by row; "." is an empty cell. The puzzle has exactly one solution.
static func sudoku_generate(rng: RandomNumberGenerator, blanks: int) -> Dictionary:
	var base := [[1, 2, 3, 4], [3, 4, 1, 2], [2, 1, 4, 3], [4, 3, 2, 1]]
	var digits: Array = [1, 2, 3, 4]
	_shuffle(rng, digits)
	var rows: Array = [0, 1, 2, 3]
	if rng.randf() < 0.5:
		rows = [rows[1], rows[0], rows[2], rows[3]]
	if rng.randf() < 0.5:
		rows = [rows[0], rows[1], rows[3], rows[2]]
	if rng.randf() < 0.5:
		rows = [rows[2], rows[3], rows[0], rows[1]]
	var cols: Array = [0, 1, 2, 3]
	if rng.randf() < 0.5:
		cols = [cols[1], cols[0], cols[2], cols[3]]
	if rng.randf() < 0.5:
		cols = [cols[0], cols[1], cols[3], cols[2]]
	if rng.randf() < 0.5:
		cols = [cols[2], cols[3], cols[0], cols[1]]
	var transpose := rng.randf() < 0.5
	var grid: Array[int] = []
	for r in 4:
		for c in 4:
			var rr: int = rows[r]
			var cc: int = cols[c]
			var v: int = base[cc][rr] if transpose else base[rr][cc]
			grid.append(int(digits[v - 1]))
	var puzzle: Array[int] = grid.duplicate()
	var order: Array = range(16)
	_shuffle(rng, order)
	var removed := 0
	for cell: int in order:
		if removed >= blanks:
			break
		var keep: int = puzzle[cell]
		puzzle[cell] = 0
		if sudoku_count(puzzle, 2) == 1:
			removed += 1
		else:
			puzzle[cell] = keep
	var sol := ""
	var giv := ""
	for i in 16:
		sol += str(grid[i])
		giv += "." if puzzle[i] == 0 else str(puzzle[i])
	return {"solution": sol, "givens": giv, "blanks": removed}


## Number of solutions of a 4x4 grid (0 = empty cell), counting up to `limit`.
static func sudoku_count(grid: Array[int], limit: int = 2) -> int:
	var g: Array[int] = grid.duplicate()
	return _sudoku_count(g, limit)


static func _sudoku_count(g: Array[int], limit: int) -> int:
	var cell := g.find(0)
	if cell < 0:
		return 1
	var count := 0
	for v in range(1, 5):
		if sudoku_fits(g, cell, v):
			g[cell] = v
			count += _sudoku_count(g, limit - count)
			g[cell] = 0
			if count >= limit:
				break
	return count


## True if value v can go in cell (row, column and 2x2 box don't have it yet).
static func sudoku_fits(g: Array[int], cell: int, v: int) -> bool:
	var r := cell / 4
	var c := cell % 4
	for i in 4:
		if g[r * 4 + i] == v or g[i * 4 + c] == v:
			return false
	var br := (r / 2) * 2
	var bc := (c / 2) * 2
	for dr in 2:
		for dc in 2:
			if g[(br + dr) * 4 + bc + dc] == v:
				return false
	return true


## True if a full 16-digit string is a valid 4x4 square that keeps all the givens.
static func sudoku_valid(answer: String, givens: String) -> bool:
	if answer.length() != 16:
		return false
	var g: Array[int] = []
	for i in 16:
		if givens.length() == 16 and givens[i] != "." and givens[i] != answer[i]:
			return false
		g.append(int(answer[i]))
	for i in 16:
		var v := g[i]
		if v < 1 or v > 4:
			return false
		g[i] = 0
		var ok := sudoku_fits(g, i, v)
		g[i] = v
		if not ok:
			return false
	return true


# ================================================================== logic statements: orders

## All statement kinds for orders, and how much each depth (0..4) likes them.
const ORDER_WEIGHTS := {
	"pos": [3.0, 2.0, 0.8, 0.3, 0.0],
	"first": [2.0, 2.0, 1.0, 0.5, 0.2],
	"last": [2.0, 2.0, 1.0, 0.5, 0.2],
	"right_before": [1.0, 2.0, 2.0, 1.5, 1.2],
	"before": [0.5, 1.0, 2.5, 2.5, 2.5],
	"next_to": [0.0, 0.5, 1.0, 2.0, 2.0],
	"not_next_to": [0.0, 0.0, 0.5, 1.5, 2.0],
	"not_first": [0.0, 0.5, 1.0, 1.5, 1.5],
	"not_last": [0.0, 0.5, 1.0, 1.5, 1.5],
	"between": [0.0, 0.0, 0.5, 1.5, 2.0],
}


static var _perm_cache: Dictionary = {}


## Statements that together allow only `order` (the answer). Each statement is a Dictionary:
## { "type": ..., "a": item, "b": item?, "c": item?, "k": position? }.
static func order_statements(rng: RandomNumberGenerator, order: Array, depth: int) -> Array[Dictionary]:
	var n := order.size()
	var candidates := _true_order_statements(order)
	if not _perm_cache.has(n):
		_perm_cache[n] = permutations(range(n))
	var perms: Array = _perm_cache[n]
	# For every possible order ("world"), where each item stands.
	var positions: Array[PackedInt32Array] = []
	for p: Array in perms:
		var pos := PackedInt32Array()
		pos.resize(n)
		for k in n:
			pos[int(p[k])] = k
		positions.append(pos)
	# Which worlds a statement allows (only worked out for statements that get picked).
	var mask_of := func(c: Dictionary) -> PackedByteArray:
		var a := order.find(c.get("a", ""))
		var b := order.find(c.get("b", ""))
		var cc := order.find(c.get("c", ""))
		var t := str(c["type"])
		var k := int(c.get("k", 0))
		var m := PackedByteArray()
		m.resize(perms.size())
		for w in perms.size():
			m[w] = 1 if _order_holds_at(positions[w], n, t, a, b, cc, k) else 0
		return m
	return _select_statements(rng, candidates, mask_of, ORDER_WEIGHTS, clampi(depth, 0, 4), perms.size())


static func _order_holds_at(pos: PackedInt32Array, n: int, t: String, a: int, b: int, c: int, k: int) -> bool:
	var ia := pos[a] if a >= 0 else -1
	var ib := pos[b] if b >= 0 else -1
	var ic := pos[c] if c >= 0 else -1
	match t:
		"pos":
			return ia == k
		"first":
			return ia == 0
		"last":
			return ia == n - 1
		"right_before":
			return ib == ia + 1
		"before":
			return ia < ib
		"next_to":
			return absi(ia - ib) == 1
		"not_next_to":
			return absi(ia - ib) != 1
		"not_first":
			return ia != 0
		"not_last":
			return ia != n - 1
		"between":
			return (ib < ia and ia < ic) or (ic < ia and ia < ib)
	return false


## Picks statements (weighted by depth) until only one world is left, then drops the ones that
## aren't needed any more (keeps notes short). mask_of(statement)[w] = 1 if it allows world w.
static func _select_statements(rng: RandomNumberGenerator, candidates: Array[Dictionary], mask_of: Callable, weights: Dictionary, depth: int, worlds: int) -> Array[Dictionary]:
	var alive := PackedByteArray()
	alive.resize(worlds)
	alive.fill(1)
	var alive_count := worlds
	var pool: Array[int] = []
	var weight: Array[float] = []
	for i in candidates.size():
		pool.append(i)
		weight.append(float((weights.get(str(candidates[i]["type"]), [0.0, 0.0, 0.0, 0.0, 0.0]) as Array)[depth]))
	var masks: Array[PackedByteArray] = []
	masks.resize(candidates.size())
	var chosen: Array[int] = []
	var guard := 0
	while alive_count > 1 and not pool.is_empty() and guard < 120:
		guard += 1
		var idx := _weighted_index(rng, pool, weight)
		pool.erase(idx)
		var m: PackedByteArray = mask_of.call(candidates[idx])
		masks[idx] = m
		var left := 0
		for w in worlds:
			if alive[w] == 1 and m[w] == 1:
				left += 1
		if left == alive_count:
			continue # rules nothing out
		for w in worlds:
			if m[w] == 0:
				alive[w] = 0
		alive_count = left
		chosen.append(idx)
	var keep: Array[int] = chosen.duplicate()
	var tries: Array = chosen.duplicate()
	_shuffle(rng, tries)
	for i: int in tries:
		var without: Array[int] = keep.duplicate()
		without.erase(i)
		if _count_worlds(masks, without, worlds) == 1:
			keep = without
	var out: Array[Dictionary] = []
	for i in keep:
		out.append(candidates[i])
	_shuffle(rng, out)
	return out


static func _count_worlds(masks: Array[PackedByteArray], picked: Array[int], worlds: int) -> int:
	var count := 0
	for w in worlds:
		var ok := true
		for i in picked:
			if masks[i][w] == 0:
				ok = false
				break
		if ok:
			count += 1
	return count


static func _weighted_index(rng: RandomNumberGenerator, pool: Array[int], weight: Array[float]) -> int:
	var total := 0.0
	for i in pool:
		total += weight[i]
	if total <= 0.0:
		return pool[rng.randi_range(0, pool.size() - 1)]
	var r := rng.randf() * total
	for i in pool:
		r -= weight[i]
		if r <= 0.0:
			return i
	return pool[pool.size() - 1]


## Every order (of the same items) that satisfies all statements.
static func order_solutions(items: Array, statements: Array[Dictionary]) -> Array:
	return _order_solutions(permutations(items), statements)


static func _order_solutions(perms: Array, statements: Array[Dictionary]) -> Array:
	var out: Array = []
	for p: Array in perms:
		var ok := true
		for s in statements:
			if not order_holds(p, s):
				ok = false
				break
		if ok:
			out.append(p)
	return out


static func order_holds(p: Array, s: Dictionary) -> bool:
	var ia := p.find(s.get("a", ""))
	var ib := p.find(s.get("b", ""))
	var ic := p.find(s.get("c", ""))
	var n := p.size()
	match str(s["type"]):
		"pos":
			return ia == int(s["k"])
		"first":
			return ia == 0
		"last":
			return ia == n - 1
		"right_before":
			return ib == ia + 1
		"before":
			return ia < ib
		"next_to":
			return absi(ia - ib) == 1
		"not_next_to":
			return absi(ia - ib) != 1
		"not_first":
			return ia != 0
		"not_last":
			return ia != n - 1
		"between":
			return (ib < ia and ia < ic) or (ic < ia and ia < ib)
	return false


static func _true_order_statements(order: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n := order.size()
	for i in n:
		var a: String = order[i]
		out.append({"type": "pos", "a": a, "k": i})
		if i == 0:
			out.append({"type": "first", "a": a})
		else:
			out.append({"type": "not_first", "a": a})
		if i == n - 1:
			out.append({"type": "last", "a": a})
		else:
			out.append({"type": "not_last", "a": a})
		for j in n:
			if i == j:
				continue
			var b: String = order[j]
			if j == i + 1:
				out.append({"type": "right_before", "a": a, "b": b})
			if i < j:
				out.append({"type": "before", "a": a, "b": b})
			if j == i + 1:
				out.append({"type": "next_to", "a": a, "b": b})
			if absi(i - j) > 1 and i < j:
				out.append({"type": "not_next_to", "a": a, "b": b})
			for k in range(j + 1, n):
				if k != i and ((j < i and i < k) or (k < i and i < j)):
					out.append({"type": "between", "a": a, "b": b, "c": order[k]})
	return out


# ================================================================== logic statements: lamps (switches)

const SWITCH_WEIGHTS := {
	"on": [3.0, 2.0, 1.0, 0.4, 0.2],
	"off": [3.0, 2.0, 1.0, 0.4, 0.2],
	"same": [0.0, 0.5, 1.5, 2.0, 2.0],
	"different": [0.0, 0.5, 1.5, 2.0, 2.0],
	"if_on_then_on": [0.0, 0.0, 0.8, 1.5, 2.0],
	"not_both": [0.0, 0.0, 0.8, 1.5, 2.0],
	"count": [0.0, 0.5, 1.0, 1.2, 1.2],
}


## Statements that together allow only `pattern` ("1" = on) for the lamps `symbols`.
static func switch_statements(rng: RandomNumberGenerator, symbols: Array, pattern: String, depth: int) -> Array[Dictionary]:
	var d := clampi(depth, 0, 4)
	var n := symbols.size()
	var candidates: Array[Dictionary] = []
	var lit := 0
	for i in n:
		var on := pattern[i] == "1"
		if on:
			lit += 1
		candidates.append({"type": "on" if on else "off", "a": symbols[i]})
		for j in n:
			if i == j:
				continue
			var on_j := pattern[j] == "1"
			if i < j:
				candidates.append({"type": "same" if on == on_j else "different", "a": symbols[i], "b": symbols[j]})
			if (not on) or on_j:
				candidates.append({"type": "if_on_then_on", "a": symbols[i], "b": symbols[j]})
			if i < j and not (on and on_j):
				candidates.append({"type": "not_both", "a": symbols[i], "b": symbols[j]})
	candidates.append({"type": "count", "k": lit})
	var worlds := 1 << n
	var patterns: PackedStringArray = []
	for mask in worlds:
		var p := ""
		for i in n:
			p += "1" if mask & (1 << i) else "0"
		patterns.append(p)
	var mask_of := func(c: Dictionary) -> PackedByteArray:
		var m := PackedByteArray()
		m.resize(worlds)
		for w in worlds:
			m[w] = 1 if switch_holds(symbols, patterns[w], c) else 0
		return m
	var chosen := _select_statements(rng, candidates, mask_of, SWITCH_WEIGHTS, d, worlds)
	_shuffle(rng, chosen)
	return chosen


## Every on/off pattern (strings of 0/1) that satisfies all statements.
static func _switch_solutions(symbols: Array, statements: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	var n := symbols.size()
	for mask in 1 << n:
		var p := ""
		for i in n:
			p += "1" if mask & (1 << i) else "0"
		var ok := true
		for s in statements:
			if not switch_holds(symbols, p, s):
				ok = false
				break
		if ok:
			out.append(p)
	return out


static func switch_solutions(symbols: Array, statements: Array[Dictionary]) -> Array[String]:
	return _switch_solutions(symbols, statements)


static func switch_holds(symbols: Array, p: String, s: Dictionary) -> bool:
	var ia := symbols.find(s.get("a", ""))
	var ib := symbols.find(s.get("b", ""))
	var a_on := ia >= 0 and p[ia] == "1"
	var b_on := ib >= 0 and p[ib] == "1"
	match str(s["type"]):
		"on":
			return a_on
		"off":
			return not a_on
		"same":
			return a_on == b_on
		"different":
			return a_on != b_on
		"if_on_then_on":
			return (not a_on) or b_on
		"not_both":
			return not (a_on and b_on)
		"count":
			return p.count("1") == int(s["k"])
	return false


# ================================================================== patterns

## A "what comes next?" pattern. kind "numbers" or "symbols".
## Returns { "terms": Array[String] (all terms), "blanks": Array[int] (hidden positions), "answer": "a,b", "rule": String }.
static func pattern_generate(rng: RandomNumberGenerator, depth: int, kind: String, symbols: Array = []) -> Dictionary:
	var d := clampi(depth, 0, 4)
	var terms: Array[String] = []
	var rule := ""
	if kind == "symbols" and symbols.size() >= 3:
		var pool := symbols.duplicate()
		_shuffle(rng, pool)
		var options: Array[String] = ["cycle2", "cycle3"]
		if d >= 2:
			options.append_array(["mirror", "grow"])
		if d >= 3:
			options.append("cycle4")
		rule = options[rng.randi_range(0, options.size() - 1)]
		match rule:
			"cycle2", "cycle3", "cycle4":
				var clen := int(rule.substr(5))
				var cyc := pool.slice(0, mini(clen, pool.size()))
				for i in (8 if clen < 4 else 10):
					terms.append(str(cyc[i % cyc.size()]))
			"mirror":
				var a: String = pool[0]
				var b: String = pool[1]
				var c: String = pool[2]
				for s in [a, b, c, b, a, b, c, b, a]:
					terms.append(s)
			"grow":
				var a: String = pool[0]
				var b: String = pool[1]
				for k in range(1, 4):
					terms.append(a)
					for _i in k:
						terms.append(b)
				terms.append(a)
	else:
		var nums: Array[int] = []
		var options: Array[String] = ["add"]
		if d >= 1:
			options.append_array(["sub", "cycle"])
		if d >= 2:
			options.append_array(["double", "alternate"])
		if d >= 3:
			options.append_array(["triangle", "interleave", "squares"])
		if d >= 4:
			options.append("fibonacci")
		rule = options[rng.randi_range(0, options.size() - 1)]
		match rule:
			"add":
				var start := rng.randi_range(1, 6)
				var step := rng.randi_range(1, 3 + d)
				for i in 6:
					nums.append(start + i * step)
			"sub":
				var step2 := rng.randi_range(2, 5)
				var start2 := step2 * 6 + rng.randi_range(0, 4)
				for i in 6:
					nums.append(start2 - i * step2)
			"cycle":
				var a := rng.randi_range(1, 9)
				var b := rng.randi_range(1, 9)
				while b == a:
					b = rng.randi_range(1, 9)
				var c := rng.randi_range(1, 9)
				for i in 7:
					nums.append([a, b, c][i % 3])
			"double":
				var s := rng.randi_range(1, 3)
				for i in 6:
					nums.append(s * (1 << i))
			"alternate":
				var s3 := rng.randi_range(1, 5)
				var x := rng.randi_range(1, 3)
				var y := rng.randi_range(x + 1, 5)
				var v := s3
				for i in 7:
					nums.append(v)
					v += x if i % 2 == 0 else y
			"triangle":
				var s4 := rng.randi_range(1, 4)
				var v4 := s4
				for i in 6:
					nums.append(v4)
					v4 += i + 1
			"interleave":
				var a5 := rng.randi_range(1, 4)
				var b5 := rng.randi_range(10, 20)
				var da := rng.randi_range(1, 3)
				var db := -rng.randi_range(1, 2)
				for i in 8:
					nums.append(a5 + (i / 2) * da if i % 2 == 0 else b5 + (i / 2) * db)
			"squares":
				var s6 := rng.randi_range(1, 2)
				for i in 6:
					nums.append((s6 + i) * (s6 + i))
			"fibonacci":
				var f1 := rng.randi_range(1, 3)
				var f2 := rng.randi_range(1, 4)
				nums.append_array([f1, f2])
				for i in 5:
					nums.append(nums[nums.size() - 1] + nums[nums.size() - 2])
		for n in nums:
			terms.append(str(n))
	var blank_count := 1 if d <= 2 else 2
	var blanks: Array[int] = []
	if blank_count == 1:
		blanks.append(terms.size() - 1)
	elif rng.randf() < 0.5 or terms.size() < 7:
		blanks.append_array([terms.size() - 2, terms.size() - 1])
	else:
		# One gap in the middle and one at the end (at least four terms show the rule first).
		blanks.append_array([terms.size() - 3, terms.size() - 1])
	var answer: PackedStringArray = []
	for b in blanks:
		answer.append(terms[b])
	return {"terms": terms, "blanks": blanks, "answer": ",".join(answer), "rule": rule}


## A digit pattern for a code: shows some single digits, the code is the next `count` digits (all 0-9).
## Returns { "shown": Array[int], "code": String, "rule": String }.
static func digit_pattern(rng: RandomNumberGenerator, depth: int, count: int) -> Dictionary:
	for _attempt in 40:
		var options: Array[String] = ["step", "cycle"]
		if depth >= 3:
			options.append("alternate")
		var rule: String = options[rng.randi_range(0, options.size() - 1)]
		var seq: Array[int] = []
		var total := 4 + count
		match rule:
			"step":
				var step := rng.randi_range(1, 2) * (1 if rng.randf() < 0.5 else -1)
				var start := rng.randi_range(0, 9)
				for i in total:
					seq.append(start + i * step)
			"cycle":
				var clen2 := rng.randi_range(2, 3)
				var cyc: Array[int] = []
				while cyc.size() < clen2:
					var v := rng.randi_range(0, 9)
					if not cyc.has(v):
						cyc.append(v)
				for i in total + 1:
					seq.append(cyc[i % clen2])
			"alternate":
				var a := rng.randi_range(0, 4)
				var b := rng.randi_range(5, 9)
				for i in total + 1:
					seq.append(a + i / 2 if i % 2 == 0 else b - i / 2)
		var ok := true
		for v in seq:
			if v < 0 or v > 9:
				ok = false
		if not ok:
			continue
		var shown_count := seq.size() - count
		var code := ""
		for i in count:
			code += str(seq[shown_count + i])
		if _all_same(code):
			continue
		return {"shown": seq.slice(0, shown_count), "code": code, "rule": rule}
	return {"shown": [1, 2, 3, 4], "code": "567".substr(0, count), "rule": "step"}


# ================================================================== helpers

static func permutations(items: Array) -> Array:
	if items.size() <= 1:
		return [items.duplicate()]
	var out: Array = []
	for i in items.size():
		var rest := items.duplicate()
		var first: Variant = rest.pop_at(i)
		for p: Array in permutations(rest):
			p.push_front(first)
			out.append(p)
	return out


static func _shuffle(rng: RandomNumberGenerator, arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _all_same(s: String) -> bool:
	for ch in s:
		if ch != s[0]:
			return false
	return true
