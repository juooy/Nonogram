extends "res://tests/test_case.gd"

var _dir := ""

func _storage() -> LevelStorage:
	_dir = "user://test_select_levels_%d" % randi()
	return LevelStorage.new(_dir)

func cleanup() -> void:
	super.cleanup()
	if _dir != "" and DirAccess.dir_exists_absolute(_dir):
		for f in DirAccess.get_files_at(_dir):
			DirAccess.remove_absolute(_dir + "/" + f)
		DirAccess.remove_absolute(_dir)

func _save(st: LevelStorage, id: String, title: String) -> void:
	var lv := LevelData.from_solution([[true, false], [false, true]], Vector2i(2, 2))
	lv.id = id
	lv.title = title
	st.save(lv)

func _select(st: LevelStorage) -> Node:
	var s: Node = load("res://scenes/LevelSelect.tscn").instantiate()
	s.storage = st
	return add_node(s)

func _rows(s: Node) -> Array:
	return s.get_node("MarginContainer/VBox/Scroll/List").get_children()

func _play(row: Node) -> Button:
	return row.get_node("PlayBtn")

func test_empty_state() -> void:
	var s := _select(_storage())
	assert_eq(_rows(s).size(), 0, "no rows")
	assert_true(s.get_node("MarginContainer/VBox/EmptyLabel").visible, "empty label")

func test_lists_levels_newest_first() -> void:
	var st := _storage()
	_save(st, "1000_0001", "옛날")
	_save(st, "2000_0001", "최신")
	var s := _select(st)
	var rows := _rows(s)
	assert_eq(rows.size(), 2, "count")
	var first: Button = _play(rows[0])
	assert_true(first.text.contains("최신"), "newest first: " + first.text)
	assert_true(first.text.contains("2×2"), "size shown")
	assert_true(not s.get_node("MarginContainer/VBox/EmptyLabel").visible, "empty hidden")

func test_pick_level_opens_game_and_back_returns() -> void:
	var st := _storage()
	_save(st, "1000_0001", "고양이")
	var s := _select(st)
	_play(_rows(s)[0]).pressed.emit()
	var game: Node = s.get_node_or_null("Game")
	assert_true(game != null, "game opened")
	assert_eq(game.level.title, "고양이", "level passed")
	assert_true(not s.get_node("MarginContainer").visible, "list hidden")
	game._on_back_pressed()
	assert_true(game.is_queued_for_deletion(), "game closed")
	assert_true(s.get_node("MarginContainer").visible, "list visible")

func test_new_level_opens_editor_and_back_refreshes() -> void:
	var st := _storage()
	var s := _select(st)
	s._on_new_pressed()
	var ed: Node = s.get_node_or_null("Editor")
	assert_true(ed != null, "editor opened")
	assert_true(ed.back_btn.visible, "back shown")
	ed.storage = st
	ed.grid.solution[0][0] = true
	ed._on_save_pressed()
	ed._on_back_pressed()
	assert_true(ed.is_queued_for_deletion(), "editor closed")
	assert_eq(_rows(s).size(), 1, "list refreshed")

# ── 안드로이드 뒤로가기 ───────────────────────────────────
func test_back_at_root_returns_false() -> void:
	var s := _select(_storage())
	assert_true(not s.go_back(), "root → 종료 신호")

func test_back_closes_top_screen_only() -> void:
	var st := _storage()
	var s := _select(st)
	s._on_new_pressed()
	var ed: Node = s.get_node("Editor")
	ed.storage = st
	ed.grid.solution[0][0] = true
	ed._on_play_pressed()
	var game: Node = ed.get_node("Game")
	assert_true(s.go_back(), "handled")
	assert_true(game.is_queued_for_deletion(), "game closed")
	assert_true(not ed.is_queued_for_deletion(), "editor stays")
	assert_true(s.go_back(), "handled again")
	assert_true(ed.is_queued_for_deletion(), "editor closed")
	assert_true(s.get_node("MarginContainer").visible, "list visible")

# ── UI 스킨 ───────────────────────────────────────────────
func test_theme_and_card_rows() -> void:
	var st := _storage()
	_save(st, "1000_0001", "a")
	var s := _select(st)
	assert_true(s.theme == AppTheme.get_theme(), "theme")
	var row: Button = _play(_rows(s)[0])
	assert_eq(row.theme_type_variation, &"CardButton", "card")
	assert_true(row.get_combined_minimum_size().y >= AppTheme.BUTTON_MIN, "row height")
	var new_btn: Button = s.get_node("MarginContainer/VBox/TopBar/NewBtn")
	assert_true(new_btn.get_combined_minimum_size().y >= AppTheme.BUTTON_MIN, "new btn")

# ── 편집·삭제 ─────────────────────────────────────────────
func test_row_has_edit_and_delete_buttons() -> void:
	var st := _storage()
	_save(st, "1000_0001", "a")
	var row: Node = _rows(_select(st))[0]
	for n in ["PlayBtn", "EditBtn", "DeleteBtn"]:
		var b: Button = row.get_node(n)
		var sz := b.get_combined_minimum_size()
		assert_true(sz.x >= AppTheme.BUTTON_MIN and sz.y >= AppTheme.BUTTON_MIN, "%s %s" % [n, sz])

func test_delete_asks_confirmation() -> void:
	var st := _storage()
	_save(st, "1000_0001", "고양이")
	var s := _select(st)
	var confirm: Control = s.get_node("ConfirmPanel")
	assert_true(not confirm.visible, "hidden at start")
	_rows(s)[0].get_node("DeleteBtn").pressed.emit()
	assert_true(confirm.visible, "confirm shown")
	assert_true(s.confirm_label.text.contains("고양이"), "names level: " + s.confirm_label.text)
	s._on_cancel_delete()
	assert_true(not confirm.visible, "cancel hides")
	assert_true(st.load_level("1000_0001") != null, "still exists")
	_rows(s)[0].get_node("DeleteBtn").pressed.emit()
	s._on_confirm_delete()
	assert_true(not confirm.visible, "confirm hides")
	assert_true(st.load_level("1000_0001") == null, "deleted")
	assert_eq(_rows(s).size(), 0, "list refreshed")
	assert_true(s.get_node("MarginContainer/VBox/EmptyLabel").visible, "empty label")

func test_back_closes_confirm_first() -> void:
	var st := _storage()
	_save(st, "1000_0001", "a")
	var s := _select(st)
	_rows(s)[0].get_node("DeleteBtn").pressed.emit()
	assert_true(s.go_back(), "handled")
	assert_true(not s.get_node("ConfirmPanel").visible, "confirm closed")
	assert_true(st.load_level("1000_0001") != null, "not deleted")

func test_edit_opens_editor_with_level_and_overwrites() -> void:
	var st := _storage()
	_save(st, "1000_0001", "원래 제목")
	var s := _select(st)
	_rows(s)[0].get_node("EditBtn").pressed.emit()
	var ed: Node = s.get_node_or_null("Editor")
	assert_true(ed != null, "editor opened")
	assert_eq(ed.current_id, "1000_0001", "id")
	assert_eq(ed.title_edit.text, "원래 제목", "title")
	assert_eq(ed.grid.grid_size, Vector2i(2, 2), "size")
	assert_eq(ed.grid.solution, [[true, false], [false, true]], "solution")
	ed.grid.solution[0][1] = true
	ed.title_edit.text = "고친 제목"
	ed._on_save_pressed()
	assert_eq(st.list().size(), 1, "overwritten, not duplicated")
	assert_eq(st.load_level("1000_0001").title, "고친 제목", "saved")
	ed._on_back_pressed()
	assert_true(_play(_rows(s)[0]).text.contains("고친 제목"), "list refreshed")

func test_quality_badge_in_row() -> void:
	var st := _storage()
	var lv := LevelData.from_solution([[true, false], [false, true]], Vector2i(2, 2))
	lv.id = "1000_0001"
	lv.title = "대각선"
	lv.quality = "multiple"
	st.save(lv)
	var s := _select(st)
	assert_true(_play(_rows(s)[0]).text.contains("정답 여러 개"), _play(_rows(s)[0]).text)
