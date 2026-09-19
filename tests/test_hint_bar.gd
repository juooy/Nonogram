extends "res://tests/test_case.gd"

func _make(axis: HintBar.Axis, hints: Array, cell := 40.0) -> HintBar:
	var b := HintBar.new()
	b.axis = axis
	b.cell_px = cell
	add_node(b)
	b.set_hints(hints)
	return b

func test_row_min_size() -> void:
	var b := _make(HintBar.Axis.ROW, [[1, 2], [0], [3]])
	var s := b.slot_px()
	assert_eq(b.custom_minimum_size, Vector2(2 * s, 3 * 40.0))

func test_col_min_size() -> void:
	var b := _make(HintBar.Axis.COL, [[1], [1, 1, 1], [2], [0]])
	var s := b.slot_px()
	assert_eq(b.custom_minimum_size, Vector2(4 * 40.0, 3 * s))

func test_row_numbers_right_aligned() -> void:
	# 가장 긴 줄 길이 2 → 한 개짜리 줄은 오른쪽(격자 쪽) 슬롯에 붙는다
	var b := _make(HintBar.Axis.ROW, [[1, 2], [5]])
	var s := b.slot_px()
	assert_eq(b.slot_rect(0, 0), Rect2(0, 0, s, 40.0), "row0 first")
	assert_eq(b.slot_rect(1, 0), Rect2(s, 40.0, s, 40.0), "row1 single")

func test_col_numbers_bottom_aligned() -> void:
	var b := _make(HintBar.Axis.COL, [[1, 2, 3], [4]])
	var s := b.slot_px()
	assert_eq(b.slot_rect(1, 0), Rect2(40.0, 2 * s, 40.0, s))

func test_empty_hints_zero_size() -> void:
	var b := _make(HintBar.Axis.ROW, [])
	assert_eq(b.custom_minimum_size, Vector2.ZERO)

func test_slot_scales_with_cell_but_has_floor() -> void:
	var small := _make(HintBar.Axis.ROW, [[1]], 10.0)
	var big := _make(HintBar.Axis.ROW, [[1]], 60.0)
	assert_true(small.slot_px() >= HintBar.MIN_SLOT_PX, "floor")
	assert_true(big.slot_px() > small.slot_px(), "scales")

func test_min_depth_reserves_space() -> void:
	# 에디터에서 그리는 중 힌트 개수가 늘어도 바 크기가 변하지 않아야 격자가 밀리지 않는다
	var b := _make(HintBar.Axis.COL, [[0], [0]])
	b.min_depth = 3
	b.set_hints([[0], [0]])
	var before := b.custom_minimum_size
	b.set_hints([[1, 1, 1], [0]])
	assert_eq(b.custom_minimum_size, before, "size fixed")
	assert_eq(b.custom_minimum_size.y, 3 * b.slot_px(), "depth 3")

func test_min_depth_keeps_numbers_grid_aligned() -> void:
	var b := _make(HintBar.Axis.ROW, [[5]])
	b.min_depth = 3
	b.set_hints([[5]])
	var s := b.slot_px()
	assert_eq(b.slot_rect(0, 0).position.x, 2 * s, "rightmost slot")
