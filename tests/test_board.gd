extends "res://tests/test_case.gd"

# 1152×648 기본 / 1556×648 Pixel 비율에서 여백·패널·헤더를 뺀 보드 영역
const AREAS := [Vector2(884, 544), Vector2(1288, 544)]
const SEP := 4.0

func _fits(area: Vector2, sz: Vector2i, d: int, cell: float) -> bool:
	var slot := HintBar.slot_px_for(cell)
	return sz.x * cell + d * slot + SEP <= area.x and sz.y * cell + d * slot + SEP <= area.y

func test_calc_cell_fits_and_is_clamped() -> void:
	for sz in [Vector2i(5, 5), Vector2i(10, 10), Vector2i(15, 15)]:
		var d := ceili(sz.x / 2.0)
		for area in AREAS:
			var cell := Board.calc_cell_px(area, sz, d, d, SEP)
			assert_true(cell >= Board.MIN_CELL and cell <= Board.MAX_CELL, "range %s %s" % [sz, cell])
			assert_true(_fits(area, sz, d, cell), "fits %s %s %s" % [sz, area, cell])

func test_calc_cell_is_largest_fit() -> void:
	var sz := Vector2i(10, 10)
	var cell := Board.calc_cell_px(AREAS[0], sz, 5, 5, SEP)
	assert_true(cell == Board.MAX_CELL or not _fits(AREAS[0], sz, 5, cell + 1.0))

func test_tiny_area_falls_back_to_min() -> void:
	assert_eq(Board.calc_cell_px(Vector2.ZERO, Vector2i(10, 10), 5, 5, SEP), Board.MIN_CELL)

func test_fit_to_applies_cell_everywhere() -> void:
	var b: Board = add_node(load("res://scenes/ui/Board.tscn").instantiate())
	b.set_min_depth(5, 5)
	b.set_hints([[0]], [[0]])
	var cell := b.fit_to(Vector2(600, 400))
	assert_eq(b.grid.cell_px, cell, "grid")
	assert_eq(b.row_hints.cell_px, cell, "rows")
	assert_eq(b.col_hints.cell_px, cell, "cols")
	assert_eq(b.grid.custom_minimum_size, Vector2(b.grid.grid_size) * cell, "grid size")
