extends Control

signal back_requested  # LevelSelect 에서 열었을 때 돌아가기

const GameScene := preload("res://scenes/Game.tscn")
const SIZES := [Vector2i(5, 5), Vector2i(10, 10), Vector2i(15, 15)]
## 저장 후 상태 메시지에 붙는 검증 결과
const QUALITY_NOTE := {
	"logic": " · 정답 1개",
	"unique": " · 정답 1개(추측 필요)",
	"multiple": " · ⚠ 정답이 여러 개입니다 (표시된 칸)",
	"unknown": " · 검증 상한 초과(미검증)",
}

@onready var board: Board = %Board
@onready var grid: NGrid = board.grid
@onready var board_area: Control = %BoardArea
@onready var size_option: OptionButton = %SizeOption
@onready var title_edit: LineEdit = %TitleEdit
@onready var status_label: Label = %StatusLabel
@onready var back_btn: Button = %BackBtn
@onready var header_label: Label = %HeaderLabel

var storage := LevelStorage.new()
var show_back := false  # 여는 쪽이 트리에 붙이기 전에 설정
var current_id := ""  # 저장된 레벨을 편집 중이면 그 id — 재저장 시 덮어쓴다
var edit_level: LevelData  # 여는 쪽이 트리에 붙이기 전에 설정하면 그 레벨을 편집

func _ready() -> void:
	theme = AppTheme.get_theme()
	back_btn.visible = show_back
	grid.solution_changed.connect(_refresh_hints)
	grid.solution_changed.connect(func(): status_label.text = "")  # 편집하면 지난 검증 결과를 지운다
	board_area.resized.connect(_fit_board)
	_setup_size_options()
	_refresh_hints()
	_fit_board()
	if edit_level:
		load_level(edit_level)

## 저장된 레벨을 불러와 편집한다. 저장하면 같은 id 로 덮어쓴다.
func load_level(level: LevelData) -> void:
	grid.grid_size = level.grid_size
	grid._init_arrays()
	grid.solution = level.solution.duplicate(true)
	grid.queue_redraw()
	size_option.selected = SIZES.find(level.grid_size)
	title_edit.text = level.title
	current_id = level.id
	header_label.text = "레벨 편집"
	status_label.text = ""
	_refresh_hints()
	_fit_board()

func _setup_size_options() -> void:
	size_option.clear()
	for sz in SIZES:
		size_option.add_item("%d × %d" % [sz.x, sz.y])
	size_option.selected = 1  # 10×10 기본

func _refresh_hints() -> void:
	var level := grid.get_level_data()
	# 한 줄 힌트 개수의 최대치 = ceil(길이/2) — 미리 예약해 그리는 중 격자가 밀리지 않게
	board.set_min_depth(ceili(grid.grid_size.x / 2.0), ceili(grid.grid_size.y / 2.0))
	board.set_hints(level.row_hints, level.col_hints)

func _fit_board() -> void:
	board.fit_to(board_area.size)

func _on_clear_pressed() -> void:
	grid.clear()
	_start_new_level()

func _start_new_level() -> void:
	current_id = ""
	header_label.text = "레벨 만들기"
	title_edit.text = ""
	status_label.text = ""

func _on_save_pressed() -> void:
	if not _has_filled_cell():
		status_label.text = "빈 격자는 저장할 수 없습니다."
		return
	var level := grid.get_level_data()
	level.id = current_id
	level.title = title_edit.text.strip_edges() if title_edit.text.strip_edges() != "" else "무제"
	var result := Solver.analyze(level)
	level.quality = result.quality
	var err := storage.save(level)
	if err != OK:
		status_label.text = "저장 실패 (%s)" % error_string(err)
		return
	current_id = level.id
	grid.highlight_cells.assign(result.ambiguous_cells)
	grid.queue_redraw()
	status_label.text = "저장됨: %s%s" % [level.title, QUALITY_NOTE[level.quality]]

## 현재 그림으로 테스트 플레이 — 에디터 상태는 그대로 두고 위에 Game 을 띄운다
func _on_play_pressed() -> void:
	if not _has_filled_cell():
		status_label.text = "빈 격자는 플레이할 수 없습니다."
		return
	var level := grid.get_level_data()
	level.title = title_edit.text.strip_edges() if title_edit.text.strip_edges() != "" else "테스트 플레이"
	var game := GameScene.instantiate()
	game.name = "Game"
	game.level = level
	game.back_requested.connect(_close_game.bind(game))
	$MarginContainer.visible = false
	add_child(game)

func _close_game(game: Node) -> void:
	game.queue_free()
	$MarginContainer.visible = true

func _has_filled_cell() -> bool:
	for row in grid.solution:
		if row.has(true):
			return true
	return false

func _on_size_option_item_selected(index: int) -> void:
	grid.grid_size = SIZES[index]
	grid._init_arrays()
	_refresh_hints()
	_fit_board()
	_start_new_level()

func _on_back_pressed() -> void:
	back_requested.emit()
