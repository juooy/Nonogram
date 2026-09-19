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

# ── 저장 (Step 3) ─────────────────────────────────────────
var _save_dir := ""

func _editor_with_storage() -> Node:
	var ed := _editor()
	_save_dir = "user://test_editor_levels_%d" % randi()
	ed.storage = LevelStorage.new(_save_dir)
	return ed

func cleanup() -> void:
	super.cleanup()
	if _save_dir != "" and DirAccess.dir_exists_absolute(_save_dir):
		for f in DirAccess.get_files_at(_save_dir):
			DirAccess.remove_absolute(_save_dir + "/" + f)
		DirAccess.remove_absolute(_save_dir)

func test_editor_save_writes_level() -> void:
	var ed := _editor_with_storage()
	var grid: NGrid = ed.get_node(BOARD + "NGrid")
	grid.solution[0][0] = true
	ed.get_node("MarginContainer/VBox/TopBar/TitleEdit").text = "점 하나"
	ed._on_save_pressed()
	var levels: Array = ed.storage.list()
	assert_eq(levels.size(), 1, "saved")
	assert_eq(levels[0].title, "점 하나", "title")

func test_editor_resave_keeps_id_and_clear_starts_new() -> void:
	var ed := _editor_with_storage()
	var grid: NGrid = ed.get_node(BOARD + "NGrid")
	grid.solution[0][0] = true
	ed._on_save_pressed()
	grid.solution[1][1] = true
	ed._on_save_pressed()
	assert_eq(ed.storage.list().size(), 1, "overwrite")
	ed._on_clear_pressed()
	grid.solution[2][2] = true
	ed._on_save_pressed()
	assert_eq(ed.storage.list().size(), 2, "new level after clear")

func test_editor_refuses_empty_grid() -> void:
	var ed := _editor_with_storage()
	ed._on_save_pressed()
	assert_eq(ed.storage.list().size(), 0, "not saved")
	var status: Label = ed.get_node("MarginContainer/VBox/StatusLabel")
	assert_true(status.text != "", "status message")

# ── 테스트 플레이 (Step 4) ────────────────────────────────
func test_editor_play_opens_game_and_back_returns() -> void:
	var ed := _editor_with_storage()
	var grid: NGrid = ed.get_node(BOARD + "NGrid")
	grid.solution[0][0] = true
	ed._on_play_pressed()
	var game: Node = ed.get_node_or_null("Game")
	assert_true(game != null, "game opened")
	assert_eq(game.get_node(BOARD + "NGrid").grid_size, grid.grid_size, "same level")
	game._on_back_pressed()
	assert_true(game.is_queued_for_deletion(), "game closed")
	assert_true(ed.get_node("MarginContainer").visible, "editor visible")

func test_editor_play_refuses_empty_grid() -> void:
	var ed := _editor_with_storage()
	ed._on_play_pressed()
	assert_true(ed.get_node_or_null("Game") == null)
