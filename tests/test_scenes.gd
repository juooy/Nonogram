extends "res://tests/test_case.gd"
## 씬 스모크: 로드·인스턴스화·_ready 가 에러 없이 도는지.

func test_editor_scene_instantiates() -> void:
	var packed: PackedScene = load("res://scenes/Editor.tscn")
	assert_true(packed != null, "load")
	var ed := add_node(packed.instantiate())
	var grid: NGrid = ed.get_node("MarginContainer/VBox/GridArea/NGrid")
	grid.solution[0][0] = true
	grid.solution_changed.emit()
	var label: Label = ed.get_node("MarginContainer/VBox/HintsLabel")
	assert_true(label.text.contains("[1]"), "hints label updated: " + label.text)

func test_editor_size_switch() -> void:
	var ed := add_node(load("res://scenes/Editor.tscn").instantiate())
	ed._on_size_option_item_selected(0)
	var grid: NGrid = ed.get_node("MarginContainer/VBox/GridArea/NGrid")
	assert_eq(grid.grid_size, Vector2i(5, 5), "size")
	assert_eq(grid.solution.size(), 5, "rows")
