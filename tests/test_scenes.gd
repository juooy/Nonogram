extends "res://tests/test_case.gd"
## 씬 스모크: 로드·인스턴스화·_ready 가 에러 없이 도는지 + 에디터 ↔ 힌트바 연동.

func _editor() -> Node:
	var packed: PackedScene = load("res://scenes/Editor.tscn")
	assert_true(packed != null, "load")
	return add_node(packed.instantiate())

func test_editor_initial_hints_are_zero() -> void:
	var ed := _editor()
	var rows: HintBar = ed.board.row_hints
	var cols: HintBar = ed.board.col_hints
	assert_eq(rows.hints.size(), 10, "row count")
	assert_eq(cols.hints.size(), 10, "col count")
	assert_eq(rows.hints[0], [0], "empty line")

func test_editor_hints_follow_solution() -> void:
	var ed := _editor()
	var grid: NGrid = ed.grid
	grid.solution[0][0] = true
	grid.solution[0][1] = true
	grid.solution[0][3] = true
	grid.solution_changed.emit()
	var rows: HintBar = ed.board.row_hints
	var cols: HintBar = ed.board.col_hints
	assert_eq(rows.hints[0], [2, 1], "row0")
	assert_eq(cols.hints[3], [1], "col3")

func test_editor_size_switch_resizes_hints() -> void:
	var ed := _editor()
	ed._on_size_option_item_selected(0)
	var grid: NGrid = ed.grid
	var rows: HintBar = ed.board.row_hints
	var cols: HintBar = ed.board.col_hints
	assert_eq(grid.grid_size, Vector2i(5, 5), "size")
	assert_eq(grid.solution.size(), 5, "rows")
	assert_eq(rows.hints.size(), 5, "row hints")
	assert_eq(rows.cell_px, grid.cell_px, "row bar cell")
	assert_eq(cols.cell_px, grid.cell_px, "col bar cell")

func test_editor_clear_resets_hints() -> void:
	var ed := _editor()
	var grid: NGrid = ed.grid
	grid.solution[2][2] = true
	grid.solution_changed.emit()
	ed._on_clear_pressed()
	var rows: HintBar = ed.board.row_hints
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
	var grid: NGrid = ed.grid
	grid.solution[0][0] = true
	ed.title_edit.text = "점 하나"
	ed._on_save_pressed()
	var levels: Array = ed.storage.list()
	assert_eq(levels.size(), 1, "saved")
	assert_eq(levels[0].title, "점 하나", "title")

func test_editor_resave_keeps_id_and_clear_starts_new() -> void:
	var ed := _editor_with_storage()
	var grid: NGrid = ed.grid
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
	var status: Label = ed.status_label
	assert_true(status.text != "", "status message")

# ── 테스트 플레이 (Step 4) ────────────────────────────────
func test_editor_play_opens_game_and_back_returns() -> void:
	var ed := _editor_with_storage()
	var grid: NGrid = ed.grid
	grid.solution[0][0] = true
	ed._on_play_pressed()
	var game: Node = ed.get_node_or_null("Game")
	assert_true(game != null, "game opened")
	assert_eq(game.grid.grid_size, grid.grid_size, "same level")
	game._on_back_pressed()
	assert_true(game.is_queued_for_deletion(), "game closed")
	assert_true(ed.get_node("MarginContainer").visible, "editor visible")

func test_editor_play_refuses_empty_grid() -> void:
	var ed := _editor_with_storage()
	ed._on_play_pressed()
	assert_true(ed.get_node_or_null("Game") == null)

# ── 돌아가기 (Step 5) ─────────────────────────────────────
func test_editor_back_hidden_when_standalone() -> void:
	var ed := _editor()
	assert_true(not ed.back_btn.visible)

func test_editor_back_emits_signal() -> void:
	var ed := _editor()
	var hits := [0]
	ed.back_requested.connect(func(): hits[0] += 1)
	ed._on_back_pressed()
	assert_eq(hits[0], 1)

# ── 실기기 피드백 (격자 밀림) ─────────────────────────────
func test_editor_board_does_not_shift_while_drawing() -> void:
	var ed := _editor()
	var grid: NGrid = ed.grid
	var cols: HintBar = ed.board.col_hints
	var rows: HintBar = ed.board.row_hints
	var col_h := cols.custom_minimum_size.y
	var row_w := rows.custom_minimum_size.x
	for r in [0, 2, 4, 6, 8]:
		grid.solution[r][0] = true  # 0열 힌트 5개, 0행은 그대로
	for c in [0, 2, 4, 6, 8]:
		grid.solution[0][c] = true  # 0행 힌트 5개
	grid.solution_changed.emit()
	assert_eq(cols.custom_minimum_size.y, col_h, "col bar height fixed")
	assert_eq(rows.custom_minimum_size.x, row_w, "row bar width fixed")

func test_editor_touch_targets_and_theme() -> void:
	var ed := _editor()
	assert_true(ed.theme == AppTheme.get_theme(), "theme")
	for b in ed.find_children("*", "BaseButton", true, false):
		var s: Vector2 = b.get_combined_minimum_size()
		assert_true(s.x >= AppTheme.BUTTON_MIN and s.y >= AppTheme.BUTTON_MIN, "%s %s" % [b.name, s])

# ── 레벨 편집 ─────────────────────────────────────────────
func test_editor_load_level_sets_size_and_header() -> void:
	var ed := _editor()
	var lv := LevelData.from_solution([[true, false, false, false, false], [false, false, false, false, false],
		[false, false, false, false, false], [false, false, false, false, false], [false, false, false, false, true]], Vector2i(5, 5))
	lv.id = "1000_0001"
	lv.title = "점 두 개"
	ed.load_level(lv)
	assert_eq(ed.size_option.selected, 0, "5x5 option")
	assert_eq(ed.grid.grid_size, Vector2i(5, 5), "grid size")
	assert_eq(ed.board.row_hints.hints[0], [1], "hints refreshed")
	assert_eq(ed.header_label.text, "레벨 편집", "header edit")
	ed._on_clear_pressed()
	assert_eq(ed.current_id, "", "new level after clear")
	assert_eq(ed.header_label.text, "레벨 만들기", "header new")

# ── 해 유일성 검증 (저장 시) ──────────────────────────────
func test_save_records_quality_and_highlights_ambiguous() -> void:
	var ed := _editor_with_storage()
	var grid: NGrid = ed.grid
	# 2칸 대각선 → 반대 대각선도 정답이라 multiple
	grid.solution[0][0] = true
	grid.solution[1][1] = true
	ed._on_save_pressed()
	var level: LevelData = ed.storage.list()[0]
	assert_eq(level.quality, "multiple", "quality saved")
	assert_eq(grid.highlight_cells.size(), 4, "모호한 칸 표시")
	assert_true(ed.status_label.text.contains("여러 개"), ed.status_label.text)

func test_save_logic_level_has_no_highlight() -> void:
	var ed := _editor_with_storage()
	var grid: NGrid = ed.grid
	for c in 10:
		grid.solution[0][c] = true  # 한 줄 가득 → 논리로 풀림
	ed._on_save_pressed()
	assert_eq(ed.storage.list()[0].quality, "logic", "quality")
	assert_eq(grid.highlight_cells.size(), 0, "표시 없음")
	assert_true(ed.status_label.text.contains("정답 1개"), ed.status_label.text)
