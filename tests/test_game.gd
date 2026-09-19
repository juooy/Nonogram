extends "res://tests/test_case.gd"

const CELL := 40.0

func _level(rows: Array, title := "테스트") -> LevelData:
	var sol := []
	for s in rows:
		var row := []
		for ch in s:
			row.append(ch == "#")
		sol.append(row)
	var d := LevelData.from_solution(sol, Vector2i(rows[0].length(), rows.size()))
	d.title = title
	return d

func _game(level: LevelData) -> Node:
	var g: Node = load("res://scenes/Game.tscn").instantiate()
	g.level = level
	return add_node(g)

func _grid(g: Node) -> NGrid:
	return g.grid

func _click(grid: NGrid, c: int, r: int, button := MOUSE_BUTTON_LEFT) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.position = Vector2((c + 0.5) * grid.cell_px, (r + 0.5) * grid.cell_px)
	grid._gui_input(e)
	var up := InputEventMouseButton.new()
	up.button_index = button
	up.pressed = false
	grid._gui_input(up)

func _clear_panel(g: Node) -> Control:
	return g.get_node("ClearPanel")

func test_start_sets_play_mode_and_hints() -> void:
	var g := _game(_level(["#.", "##", ".#"], "계단"))
	var grid := _grid(g)
	assert_eq(grid.mode, NGrid.Mode.PLAY, "mode")
	assert_eq(grid.grid_size, Vector2i(2, 3), "size")
	var rows: HintBar = g.board.row_hints
	var cols: HintBar = g.board.col_hints
	assert_eq(rows.hints, [[1], [2], [1]], "row hints")
	assert_eq(cols.hints, [[2], [2]], "col hints")
	assert_true(g.title_label.text.contains("계단"), "title")
	assert_true(not _clear_panel(g).visible, "panel hidden")

func test_solving_shows_clear_panel_and_locks_grid() -> void:
	var g := _game(_level(["#.", ".#"]))
	var grid := _grid(g)
	_click(grid, 0, 0)
	assert_true(not _clear_panel(g).visible, "not yet")
	_click(grid, 1, 1)
	assert_true(_clear_panel(g).visible, "cleared")
	assert_true(not grid.interactive, "locked")
	_click(grid, 0, 1)
	assert_eq(grid.state[1][0], 0, "input ignored after clear")

func test_alternative_solution_matching_hints_is_accepted() -> void:
	# 대각선 2×2 는 힌트가 전부 [1] → 반대 대각선도 정답
	var g := _game(_level(["#.", ".#"]))
	var grid := _grid(g)
	_click(grid, 1, 0)
	_click(grid, 0, 1)
	assert_true(_clear_panel(g).visible)

func test_x_marks_do_not_block_clear() -> void:
	var g := _game(_level(["#.", ".#"]))
	var grid := _grid(g)
	_click(grid, 1, 0, MOUSE_BUTTON_RIGHT)
	_click(grid, 0, 0)
	_click(grid, 1, 1)
	assert_true(_clear_panel(g).visible)

func test_pen_segment() -> void:
	var g := _game(_level(["#.", ".#"]))
	var grid := _grid(g)
	assert_true(g.fill_btn.button_pressed, "fill default")
	g.mark_btn.button_pressed = true
	assert_true(not g.fill_btn.button_pressed, "exclusive")
	assert_eq(grid.pen, 2, "pen x")
	_click(grid, 0, 0)
	assert_eq(grid.state[0][0], 2, "x mark")
	g.fill_btn.button_pressed = true
	_click(grid, 1, 0)
	assert_eq(grid.state[0][1], 1, "fill again")

func test_touch_targets_min_64() -> void:
	var g := _game(_level(["#"]))
	for b in g.find_children("*", "BaseButton", true, false):
		var s: Vector2 = b.get_combined_minimum_size()
		assert_true(s.x >= AppTheme.BUTTON_MIN and s.y >= AppTheme.BUTTON_MIN, "%s %s" % [b.name, s])

func test_theme_applied() -> void:
	var g := _game(_level(["#"]))
	assert_true(g.theme == AppTheme.get_theme())

func test_retry_resets_board() -> void:
	var g := _game(_level(["#.", ".#"]))
	var grid := _grid(g)
	_click(grid, 0, 0)
	_click(grid, 1, 1)
	g._on_retry_pressed()
	assert_true(not _clear_panel(g).visible, "panel hidden")
	assert_true(grid.interactive, "unlocked")
	assert_eq(grid.state, [[0, 0], [0, 0]], "state reset")

func test_back_emits_signal() -> void:
	var g := _game(_level(["#"]))
	var hits := [0]
	g.back_requested.connect(func(): hits[0] += 1)
	g._on_back_pressed()
	assert_eq(hits[0], 1)
