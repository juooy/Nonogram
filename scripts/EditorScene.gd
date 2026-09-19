extends Control

@onready var grid: NGrid = $MarginContainer/VBox/GridArea/Board/NGrid
@onready var row_hints: HintBar = $MarginContainer/VBox/GridArea/Board/RowHints
@onready var col_hints: HintBar = $MarginContainer/VBox/GridArea/Board/ColHints
@onready var size_option: OptionButton = $MarginContainer/VBox/TopBar/SizeOption

func _ready() -> void:
	grid.solution_changed.connect(_refresh_hints)
	_setup_size_options()
	_refresh_hints()

func _setup_size_options() -> void:
	size_option.clear()
	size_option.add_item("5 × 5",  0)
	size_option.add_item("10 × 10", 1)
	size_option.add_item("15 × 15", 2)
	size_option.selected = 1  # 10×10 기본

func _refresh_hints() -> void:
	var level := grid.get_level_data()
	row_hints.cell_px = grid.cell_px
	col_hints.cell_px = grid.cell_px
	row_hints.set_hints(level.row_hints)
	col_hints.set_hints(level.col_hints)

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
	_refresh_hints()

func _on_print_pressed() -> void:
	var level := grid.get_level_data()
	print("=== 힌트 확인 ===")
	print("행: ", level.row_hints)
	print("열: ", level.col_hints)
