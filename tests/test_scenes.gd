extends "res://tests/test_case.gd"
## 씬 스모크: 로드·인스턴스화·_ready 가 에러 없이 도는지 + 에디터 ↔ 힌트바 연동.

const BOARD := "MarginContainer/VBox/GridArea/Board/"

func _editor() -> Node:
	var packed: PackedScene = load("res://scenes/Editor.tscn")
	assert_true(packed != null, "load")
	return add_node(packed.instantiate())

func test_editor_initial_hints_are_zero() -> void:
	var ed := _editor()
	var rows: HintBar = ed.get_node(BOARD + "RowHints")
	var cols: HintBar = ed.get_node(BOARD + "ColHints")
	assert_eq(rows.hints.size(), 10, "row count")
	assert_eq(cols.hints.size(), 10, "col count")
	assert_eq(rows.hints[0], [0], "empty line")

func test_editor_hints_follow_solution() -> void:
	var ed := _editor()
	var grid: NGrid = ed.get_node(BOARD + "NGrid")
	grid.solution[0][0] = true
	grid.solution[0][1] = true
	grid.solution[0][3] = true
	grid.solution_changed.emit()
	var rows: HintBar = ed.get_node(BOARD + "RowHints")
	var cols: HintBar = ed.get_node(BOARD + "ColHints")
	assert_eq(rows.hints[0], [2, 1], "row0")
	assert_eq(cols.hints[3], [1], "col3")

func test_editor_size_switch_resizes_hints() -> void:
	var ed := _editor()
	ed._on_size_option_item_selected(0)
	var grid: NGrid = ed.get_node(BOARD + "NGrid")
	var rows: HintBar = ed.get_node(BOARD + "RowHints")
	var cols: HintBar = ed.get_node(BOARD + "ColHints")
	assert_eq(grid.grid_size, Vector2i(5, 5), "size")
	assert_eq(grid.solution.size(), 5, "rows")
	assert_eq(rows.hints.size(), 5, "row hints")
	assert_eq(rows.cell_px, grid.cell_px, "row bar cell")
	assert_eq(cols.cell_px, grid.cell_px, "col bar cell")

func test_editor_clear_resets_hints() -> void:
	var ed := _editor()
	var grid: NGrid = ed.get_node(BOARD + "NGrid")
	grid.solution[2][2] = true
	grid.solution_changed.emit()
	ed._on_clear_pressed()
	var rows: HintBar = ed.get_node(BOARD + "RowHints")
	assert_eq(rows.hints[2], [0])
