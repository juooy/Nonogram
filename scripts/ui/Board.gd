class_name Board extends GridContainer
## 힌트바 2개 + NGrid 묶음. [Corner][ColHints] / [RowHints][NGrid]
## fit_to(area) 로 area 안에 들어가는 최대 칸 크기를 적용한다.

const MIN_CELL := 24.0
const MAX_CELL := 72.0

@onready var grid: NGrid = $NGrid
@onready var row_hints: HintBar = $RowHints
@onready var col_hints: HintBar = $ColHints

func set_hints(rows: Array, cols: Array) -> void:
	row_hints.set_hints(rows)
	col_hints.set_hints(cols)

func set_min_depth(row_depth: int, col_depth: int) -> void:
	row_hints.min_depth = row_depth
	col_hints.min_depth = col_depth

func fit_to(area: Vector2) -> float:
	var sep := float(get_theme_constant("h_separation"))
	var cell := calc_cell_px(area, grid.grid_size, row_hints.depth(), col_hints.depth(), sep)
	grid.cell_px = cell
	grid.custom_minimum_size = Vector2(grid.grid_size) * cell
	grid.size = grid.custom_minimum_size
	grid.queue_redraw()
	row_hints.cell_px = cell
	col_hints.cell_px = cell
	set_hints(row_hints.hints, col_hints.hints)  # 최소 크기 재계산
	return cell

static func calc_cell_px(area: Vector2, sz: Vector2i, row_depth: int, col_depth: int, sep: float) -> float:
	var cell := MAX_CELL
	while cell > MIN_CELL:
		var slot := HintBar.slot_px_for(cell)
		if sz.x * cell + row_depth * slot + sep <= area.x and sz.y * cell + col_depth * slot + sep <= area.y:
			return cell
		cell -= 1.0
	return MIN_CELL
