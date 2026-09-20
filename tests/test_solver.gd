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
