extends Control

@onready var grid: NGrid = $MarginContainer/VBox/GridArea/NGrid
@onready var hints_label: Label = $MarginContainer/VBox/HintsLabel
@onready var size_option: OptionButton = $MarginContainer/VBox/TopBar/SizeOption

func _ready() -> void:
	grid.solution_changed.connect(_on_solution_changed)
	_setup_size_options()

func _setup_size_options() -> void:
	size_option.clear()
	size_option.add_item("5 × 5",  0)
	size_option.add_item("10 × 10", 1)
	size_option.add_item("15 × 15", 2)
	size_option.selected = 1  # 10×10 기본

func _on_solution_changed() -> void:
	var level := grid.get_level_data()
	var lines: Array[String] = []
	lines.append("행 힌트: " + str(level.row_hints))
	lines.append("열 힌트: " + str(level.col_hints))
	hints_label.text = "\n".join(lines)

func _on_clear_pressed() -> void:
	grid.clear()

func _on_size_option_item_selected(index: int) -> void:
	var sizes := [Vector2i(5, 5), Vector2i(10, 10), Vector2i(15, 15)]
	grid.grid_size = sizes[index]
	grid.cell_px = 60.0 if index == 0 else (40.0 if index == 1 else 28.0)
	grid._init_arrays()
	grid.custom_minimum_size = Vector2(grid.grid_size.x, grid.grid_size.y) * grid.cell_px
	grid.size = grid.custom_minimum_size
	grid.queue_redraw()
	hints_label.text = ""

func _on_print_pressed() -> void:
	var level := grid.get_level_data()
	print("=== 힌트 확인 ===")
	print("행: ", level.row_hints)
	print("열: ", level.col_hints)
