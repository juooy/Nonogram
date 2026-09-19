extends "res://tests/test_case.gd"

var _dirs: Array[String] = []

func _storage() -> LevelStorage:
	var dir := "user://test_levels_%d" % randi()
	_dirs.append(dir)
	return LevelStorage.new(dir)

func _level(title := "무제") -> LevelData:
	var d := LevelData.from_solution([[true, false], [true, true]], Vector2i(2, 2))
	d.title = title
	return d

func cleanup() -> void:
	super.cleanup()
	for dir in _dirs:
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for f in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir + "/" + f)
		DirAccess.remove_absolute(dir)

func test_save_assigns_id_and_loads_back() -> void:
	var st := _storage()
	var lv := _level("고양이")
	assert_eq(st.save(lv), OK, "save")
	assert_true(lv.id != "", "id assigned")
	var back := st.load_level(lv.id)
	assert_true(back != null, "loaded")
	assert_eq(back.title, "고양이", "title")
	assert_eq(back.solution, lv.solution, "solution")
	assert_eq(back.row_hints, lv.row_hints, "row_hints int")

func test_save_existing_id_overwrites() -> void:
	var st := _storage()
	var lv := _level("v1")
	st.save(lv)
	var id := lv.id
	lv.title = "v2"
	st.save(lv)
	assert_eq(lv.id, id, "id kept")
	assert_eq(st.list().size(), 1, "single file")
	assert_eq(st.load_level(id).title, "v2", "overwritten")

func test_list_newest_first() -> void:
	var st := _storage()
	var a := _level("a")
	a.id = "1000_0001"
	var b := _level("b")
	b.id = "2000_0001"
	st.save(a)
	st.save(b)
	var titles := st.list().map(func(l): return l.title)
	assert_eq(titles, ["b", "a"])

func test_list_empty_when_dir_missing() -> void:
	var st := _storage()
	assert_eq(st.list().size(), 0)

func test_load_missing_returns_null() -> void:
	var st := _storage()
	assert_true(st.load_level("nope") == null)

func test_list_skips_corrupt_file() -> void:
	var st := _storage()
	st.save(_level("ok"))
	var f := FileAccess.open(st.dir + "/broken.json", FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	assert_eq(st.list().size(), 1)

func test_delete() -> void:
	var st := _storage()
	var lv := _level()
	st.save(lv)
	assert_eq(st.delete(lv.id), OK, "delete")
	assert_true(st.load_level(lv.id) == null, "gone")

func test_rejects_path_traversal_id() -> void:
	var st := _storage()
	var lv := _level()
	lv.id = "../evil"
	assert_eq(st.save(lv), ERR_INVALID_PARAMETER, "save")
	assert_true(st.load_level("../evil") == null, "load")
	assert_eq(st.delete("../evil"), ERR_INVALID_PARAMETER, "delete")

func test_generated_ids_are_valid_and_unique() -> void:
	var a := LevelStorage.new_id()
	var b := LevelStorage.new_id()
	assert_true(LevelStorage.is_valid_id(a), "valid: " + a)
	assert_true(a != b, "unique")
