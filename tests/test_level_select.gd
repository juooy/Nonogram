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
	assert_true(rows[0].text.contains("최신"), "newest first: " + rows[0].text)
	assert_true(rows[0].text.contains("2×2"), "size shown")
	assert_true(not s.get_node("MarginContainer/VBox/EmptyLabel").visible, "empty hidden")

func test_pick_level_opens_game_and_back_returns() -> void:
	var st := _storage()
	_save(st, "1000_0001", "고양이")
	var s := _select(st)
	_rows(s)[0].pressed.emit()
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
