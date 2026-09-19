extends "res://tests/test_case.gd"

func _grid(rows: Array) -> Array:
	# "#.#" 형식 문자열 배열 → Array[Array[bool]]
	var sol := []
	for s in rows:
		var row := []
		for ch in s:
			row.append(ch == "#")
		sol.append(row)
	return sol

func test_run_basic() -> void:
	assert_eq(LevelData._run([true, true, false, true]), [2, 1])

func test_run_empty_line_is_zero() -> void:
	assert_eq(LevelData._run([false, false, false]), [0])

func test_run_full_line() -> void:
	assert_eq(LevelData._run([true, true, true]), [3])

func test_run_trailing_and_leading_gaps() -> void:
	assert_eq(LevelData._run([false, true, false, false, true, true, false]), [1, 2])

func test_hints_from_solution() -> void:
	var sol := _grid([
		"##.#.",
		".....",
		"#####",
	])
	var d := LevelData.from_solution(sol, Vector2i(5, 3))
	assert_eq(d.row_hints, [[2, 1], [0], [5]], "rows")
	assert_eq(d.col_hints, [[1, 1], [1, 1], [1], [1, 1], [1]], "cols")

func test_non_square_uses_x_as_width() -> void:
	var sol := _grid(["#.", "##", ".#"])  # 폭 2, 높이 3
	var d := LevelData.from_solution(sol, Vector2i(2, 3))
	assert_eq(d.row_hints.size(), 3, "row count")
	assert_eq(d.col_hints.size(), 2, "col count")
	assert_eq(d.col_hints, [[2], [2]], "cols")

func test_dict_roundtrip() -> void:
	var d := LevelData.from_solution(_grid(["#.", ".#"]), Vector2i(2, 2))
	d.id = "abc"
	d.title = "테스트"
	var r := LevelData.from_dict(d.to_dict())
	assert_eq(r.id, "abc", "id")
	assert_eq(r.title, "테스트", "title")
	assert_eq(r.grid_size, Vector2i(2, 2), "size")
	assert_eq(r.solution, d.solution, "solution")
	assert_eq(r.row_hints, d.row_hints, "row_hints")

## Step 3 (JSON 저장) 대비: 문자열 직렬화 왕복 후에도 타입이 유지되는가
func test_json_roundtrip_keeps_int_hints() -> void:
	var d := LevelData.from_solution(_grid(["##", ".#"]), Vector2i(2, 2))
	var parsed = JSON.parse_string(JSON.stringify(d.to_dict()))
	var r := LevelData.from_dict(parsed)
	assert_eq(r.row_hints, d.row_hints, "row_hints")
	assert_eq(r.play_count, 0, "play_count")
