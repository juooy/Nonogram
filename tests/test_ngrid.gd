extends "res://tests/test_case.gd"

const CELL := 40.0

func _make(mode: NGrid.Mode, sz := Vector2i(5, 5)) -> NGrid:
	var g := NGrid.new()
	g.grid_size = sz
	g.cell_px = CELL
	g.mode = mode
	add_node(g)
	return g

func _center(c: int, r: int) -> Vector2:
	return Vector2((c + 0.5) * CELL, (r + 0.5) * CELL)

func _press(g: NGrid, c: int, r: int, button := MOUSE_BUTTON_LEFT) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.position = _center(c, r)
	g._gui_input(e)

func _release(g: NGrid) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	g._gui_input(e)

func _move(g: NGrid, c: int, r: int) -> void:
	var e := InputEventMouseMotion.new()
	e.position = _center(c, r)
	g._gui_input(e)

func test_ready_sizes_arrays() -> void:
	var g := _make(NGrid.Mode.EDIT, Vector2i(4, 3))
	assert_eq(g.solution.size(), 3, "rows")
	assert_eq(g.solution[0].size(), 4, "cols")
	assert_eq(g.custom_minimum_size, Vector2(4, 3) * CELL, "min size")

func test_edit_click_toggles_and_emits() -> void:
	var g := _make(NGrid.Mode.EDIT)
	var hits := [0]
	g.solution_changed.connect(func(): hits[0] += 1)
	_press(g, 2, 1)
	assert_true(g.solution[1][2], "filled")
	_release(g)
	_press(g, 2, 1)
	assert_true(not g.solution[1][2], "toggled back")
	assert_eq(hits[0], 2, "emit count")

func test_edit_drag_fills_row() -> void:
	var g := _make(NGrid.Mode.EDIT)
	_press(g, 0, 0)
	_move(g, 1, 0)
	_move(g, 2, 0)
	_release(g)
	_move(g, 3, 0)  # 릴리스 후 이동은 무시
	assert_eq(g.solution[0], [true, true, true, false, false])

func test_edit_drag_erases_when_started_on_filled() -> void:
	var g := _make(NGrid.Mode.EDIT)
	g.solution[0] = [true, true, true, false, false]
	_press(g, 0, 0)  # 채워진 칸에서 시작 → 지우기 드래그
	_move(g, 1, 0)
	_release(g)
	assert_eq(g.solution[0], [false, false, true, false, false])

func test_out_of_bounds_ignored() -> void:
	var g := _make(NGrid.Mode.EDIT)
	var hits := [0]
	g.solution_changed.connect(func(): hits[0] += 1)
	_press(g, 7, 7)
	assert_eq(hits[0], 0)

func test_play_right_click_marks_x() -> void:
	var g := _make(NGrid.Mode.PLAY)
	_press(g, 1, 1, MOUSE_BUTTON_RIGHT)
	assert_eq(g.state[1][1], 2)

func test_play_completion_emits() -> void:
	var g := _make(NGrid.Mode.PLAY, Vector2i(2, 2))
	var level := LevelData.from_solution([[true, false], [false, true]], Vector2i(2, 2))
	g.load_level(level)
	var done := [0]
	g.completed.connect(func(): done[0] += 1)
	_press(g, 0, 0)
	_release(g)
	assert_eq(done[0], 0, "not yet")
	_press(g, 1, 1, MOUSE_BUTTON_RIGHT)  # X표시는 정답 판정에 영향 없음
	_release(g)
	_press(g, 1, 1)  # X → 채움으로 덮어씀
	_release(g)
	assert_eq(done[0], 1, "completed")

func test_clear_resets_and_emits() -> void:
	var g := _make(NGrid.Mode.EDIT)
	g.solution[0][0] = true
	var hits := [0]
	g.solution_changed.connect(func(): hits[0] += 1)
	g.clear()
	assert_true(not g.solution[0][0], "cleared")
	assert_eq(hits[0], 1, "emit")

func test_get_level_data_hints() -> void:
	var g := _make(NGrid.Mode.EDIT, Vector2i(3, 1))
	g.solution[0] = [true, false, true]
	assert_eq(g.get_level_data().row_hints, [[1, 1]])

func test_screen_touch_not_double_handled() -> void:
	# 터치는 마우스 에뮬레이션으로 처리한다 — ScreenTouch 를 따로 받으면 한 번 탭에 두 번 토글된다
	var g := _make(NGrid.Mode.EDIT)
	var e := InputEventScreenTouch.new()
	e.pressed = true
	e.position = _center(0, 0)
	g._gui_input(e)
	assert_true(not g.solution[0][0])

func test_non_interactive_ignores_input() -> void:
	var g := _make(NGrid.Mode.PLAY)
	g.interactive = false
	_press(g, 0, 0)
	assert_eq(g.state[0][0], 0)

func test_reset_state_clears_play_marks() -> void:
	var g := _make(NGrid.Mode.PLAY, Vector2i(2, 2))
	g.load_level(LevelData.from_solution([[true, false], [false, true]], Vector2i(2, 2)))
	_press(g, 0, 0)
	_release(g)
	g.reset_state()
	assert_eq(g.state, [[0, 0], [0, 0]])
