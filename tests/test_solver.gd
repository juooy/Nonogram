extends "res://tests/test_case.gd"

func _unknown(n: int) -> Array:
	var line := []
	for i in n:
		line.append(-1)
	return line

func test_center_cell_is_forced() -> void:
	# 5칸에 3연속 → 어디에 놓아도 가운데 칸은 채워진다
	assert_eq(Solver.solve_line([3], _unknown(5)), [-1, -1, 1, -1, -1])

func test_exact_fit() -> void:
	assert_eq(Solver.solve_line([1, 1], _unknown(3)), [1, 0, 1])

func test_full_line() -> void:
	assert_eq(Solver.solve_line([5], _unknown(5)), [1, 1, 1, 1, 1])

func test_empty_line_clue_zero() -> void:
	assert_eq(Solver.solve_line([0], _unknown(4)), [0, 0, 0, 0])

func test_uses_known_cells() -> void:
	# 5칸에 2연속, 0번 칸이 비어 있음 → 2번 칸이 확정
	assert_eq(Solver.solve_line([2], [0, -1, -1, -1, -1]), [0, -1, -1, -1, -1])
	# 5칸에 4연속, 0번 칸이 비어 있음 → 1~4 전부 채움
	assert_eq(Solver.solve_line([4], [0, -1, -1, -1, -1]), [0, 1, 1, 1, 1])

func test_contradiction_returns_empty() -> void:
	assert_eq(Solver.solve_line([3], [0, -1, 0, -1, -1]), [])
	assert_eq(Solver.solve_line([0], [-1, 1, -1]), [])

func test_keeps_already_solved_line() -> void:
	assert_eq(Solver.solve_line([1, 1], [1, 0, 1]), [1, 0, 1])

# ── 전파·판정 ─────────────────────────────────────────────
func _level(rows: Array) -> LevelData:
	var sol := []
	for s in rows:
		var row := []
		for ch in s:
			row.append(ch == "#")
		sol.append(row)
	return LevelData.from_solution(sol, Vector2i(rows[0].length(), rows.size()))

const HEART := [
	"..........", ".##...##..", "####.####.", "#########.", "#########.",
	".#######..", "..#####...", "...###....", "....#.....", "..........",
]

func test_diagonal_2x2_has_multiple_solutions() -> void:
	var r := Solver.analyze(_level(["#.", ".#"]))
	assert_eq(r.quality, "multiple", "quality")
	assert_eq(r.ambiguous_cells.size(), 4, "모든 칸이 갈린다")

func test_heart_is_logic_solvable() -> void:
	assert_eq(Solver.analyze(_level(HEART)).quality, "logic")

func test_single_cell_is_logic() -> void:
	assert_eq(Solver.analyze(_level(["#"])).quality, "logic")

func test_empty_grid_is_logic() -> void:
	assert_eq(Solver.analyze(_level(["..", ".."])).quality, "logic")

## 완전 열거로 해 개수를 센다 (작은 격자 전용 — 테스트 검증용)
func _count_solutions(level: LevelData, limit := 3) -> int:
	var w := level.grid_size.x
	var candidates := []
	for r in level.grid_size.y:
		candidates.append(_row_candidates(level.row_hints[r], w))
	return _count_rec(candidates, level.col_hints, [], limit)

func _row_candidates(clues: Array, w: int) -> Array:
	var out := []
	for mask in 1 << w:
		var row := []
		for c in w:
			row.append(1 if mask & (1 << c) else 0)
		if _runs(row) == _norm(clues):
			out.append(row)
	return out

func _runs(row: Array) -> Array:
	var out := []
	var n := 0
	for v in row:
		if v == 1:
			n += 1
		elif n > 0:
			out.append(n)
			n = 0
	if n > 0:
		out.append(n)
	return out

func _norm(clues: Array) -> Array:
	return [] if clues.size() == 1 and clues[0] == 0 else clues

func _count_rec(candidates: Array, col_hints: Array, chosen: Array, limit: int) -> int:
	if chosen.size() == candidates.size():
		for c in col_hints.size():
			var col := []
			for row in chosen:
				col.append(row[c])
			if _runs(col) != _norm(col_hints[c]):
				return 0
		return 1
	var total := 0
	for cand in candidates[chosen.size()]:
		chosen.append(cand)
		total += _count_rec(candidates, col_hints, chosen, limit)
		chosen.pop_back()
		if total >= limit:
			return total
	return total

func test_matches_brute_force_on_random_4x4() -> void:
	seed(42)
	var mismatches := []
	for t in 150:
		var rows := []
		for r in 4:
			var s := ""
			for c in 4:
				s += "#" if randi() % 2 == 0 else "."
			rows.append(s)
		var level := _level(rows)
		var quality: String = Solver.analyze(level).quality
		var count := _count_solutions(level)
		var expected_multiple := count >= 2
		if (quality == "multiple") != expected_multiple:
			mismatches.append("%s → %s (해 %d개)" % [rows, quality, count])
	assert_eq(mismatches.size(), 0, "불일치: " + str(mismatches.slice(0, 3)))

func test_15x15_analyzed_within_a_second() -> void:
	seed(7)
	for t in 3:
		var rows := []
		for r in 15:
			var s := ""
			for c in 15:
				s += "#" if randi() % 2 == 0 else "."
			rows.append(s)
		var started := Time.get_ticks_msec()
		var quality: String = Solver.analyze(_level(rows)).quality
		var elapsed := Time.get_ticks_msec() - started
		assert_true(elapsed < 1000, "%dms (%s)" % [elapsed, quality])
