class_name NGrid extends Control

enum Mode { PLAY, EDIT }

@export var grid_size: Vector2i = Vector2i(10, 10)
@export var cell_px: float = 40.0
@export var mode: Mode = Mode.EDIT

var solution: Array = []  # Array[Array[bool]]  — 정답 (EDIT에서 작성)
var state: Array = []     # Array[Array[int]]   — 0 빈칸 1 채움 2 X표시 (PLAY)

var interactive: bool = true  # false 면 입력 무시 (클리어 후 잠금)
var pen: int = 1  # PLAY 모드 주 입력(좌클릭·터치)이 놓는 값: 1 채움 / 2 X표시. 우클릭은 항상 X

var _drag_value: int = -1  # 드래그 중 덮어쓸 값
var _target_rows: Array = []  # PLAY 판정용 힌트 — 정답 그림이 아니라 힌트 일치로 판정
var _target_cols: Array = []

signal completed
signal solution_changed  # EDIT 모드에서 셀 변경 시

func _ready() -> void:
	_init_arrays()
	custom_minimum_size = Vector2(grid_size.x, grid_size.y) * cell_px
	size = custom_minimum_size

func _init_arrays() -> void:
	solution = []
	state = []
	for r in grid_size.y:
		var sol_row: Array = []
		var state_row: Array = []
		for c in grid_size.x:
			sol_row.append(false)
			state_row.append(0)
		solution.append(sol_row)
		state.append(state_row)

func load_level(level: LevelData) -> void:
	grid_size = level.grid_size
	solution = level.solution.duplicate(true)
	_target_rows = LevelData._calc_rows(solution, grid_size)
	_target_cols = LevelData._calc_cols(solution, grid_size)
	_init_state()
	custom_minimum_size = Vector2(grid_size.x, grid_size.y) * cell_px
	size = custom_minimum_size
	queue_redraw()

func _init_state() -> void:
	state = []
	for r in grid_size.y:
		var row: Array = []
		for c in grid_size.x:
			row.append(0)
		state.append(row)

# ── 렌더링 ────────────────────────────────────────────────
func _draw() -> void:
	for r in grid_size.y:
		for c in grid_size.x:
			_draw_cell(r, c)
	_draw_grid_lines()

func _draw_cell(r: int, c: int) -> void:
	var rect := Rect2(c * cell_px, r * cell_px, cell_px, cell_px)
	var filled: bool = false
	if mode == Mode.EDIT:
		filled = solution[r][c]
	else:
		filled = (state[r][c] == 1)

	draw_rect(rect, AppTheme.INK if filled else Color.WHITE)

	if mode == Mode.PLAY and state[r][c] == 2:
		var m := rect.get_center()
		var half := cell_px * 0.3
		draw_line(m + Vector2(-half, -half), m + Vector2(half, half), AppTheme.MARK, 2.0)
		draw_line(m + Vector2(half, -half), m + Vector2(-half, half), AppTheme.MARK, 2.0)

func _draw_grid_lines() -> void:
	var w := grid_size.x * cell_px
	var h := grid_size.y * cell_px
	var thin := Color(0.55, 0.55, 0.55)
	var thick := Color(0.2, 0.2, 0.2)

	for c in grid_size.x + 1:
		var x := c * cell_px
		var lw := 2.0 if c % 5 == 0 else 1.0
		var col := thick if c % 5 == 0 else thin
		draw_line(Vector2(x, 0), Vector2(x, h), col, lw)

	for r in grid_size.y + 1:
		var y := r * cell_px
		var lw := 2.0 if r % 5 == 0 else 1.0
		var col := thick if r % 5 == 0 else thin
		draw_line(Vector2(0, y), Vector2(w, y), col, lw)

# ── 입력 ─────────────────────────────────────────────────
# 터치는 Godot 기본 마우스 에뮬레이션(emulate_mouse_from_touch)으로 들어온다.
# InputEventScreenTouch 를 따로 처리하면 한 번 탭에 두 번 토글되므로 받지 않는다.
func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton:
		if event.pressed:
			var cell := _cell_at(event.position)
			if not _in_bounds(cell):
				return
			if mode == Mode.EDIT:
				solution[cell.y][cell.x] = not solution[cell.y][cell.x]
				_drag_value = 1 if solution[cell.y][cell.x] else 0
				solution_changed.emit()
			else:
				var next := pen if event.button_index == MOUSE_BUTTON_LEFT else 2
				state[cell.y][cell.x] = 0 if state[cell.y][cell.x] == next else next
				_drag_value = state[cell.y][cell.x]
				_check_complete()
			queue_redraw()
		else:
			_drag_value = -1

	elif event is InputEventMouseMotion and _drag_value >= 0:
		var cell := _cell_at(event.position)
		if not _in_bounds(cell):
			return
		if mode == Mode.EDIT:
			solution[cell.y][cell.x] = (_drag_value == 1)
			solution_changed.emit()
		else:
			state[cell.y][cell.x] = _drag_value
			_check_complete()
		queue_redraw()

# ── 유틸 ──────────────────────────────────────────────────
func _cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / cell_px), int(pos.y / cell_px))

func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < grid_size.x and c.y >= 0 and c.y < grid_size.y

func _check_complete() -> void:
	if _target_rows.is_empty():
		_target_rows = LevelData._calc_rows(solution, grid_size)
		_target_cols = LevelData._calc_cols(solution, grid_size)
	var filled := []
	for row in state:
		filled.append(row.map(func(v): return v == 1))
	var rows_ok := LevelData._calc_rows(filled, grid_size) == _target_rows
	if rows_ok and LevelData._calc_cols(filled, grid_size) == _target_cols:
		completed.emit()

func reset_state() -> void:
	_init_state()
	_drag_value = -1
	queue_redraw()

func get_level_data() -> LevelData:
	return LevelData.from_solution(solution, grid_size)

func clear() -> void:
	_init_arrays()
	queue_redraw()
	solution_changed.emit()
