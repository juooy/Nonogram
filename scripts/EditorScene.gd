extends Control

signal back_requested  # LevelSelect 에서 열었을 때 돌아가기

@onready var grid: NGrid = $MarginContainer/VBox/GridArea/Board/NGrid
@onready var row_hints: HintBar = $MarginContainer/VBox/GridArea/Board/RowHints
@onready var col_hints: HintBar = $MarginContainer/VBox/GridArea/Board/ColHints
@onready var size_option: OptionButton = $MarginContainer/VBox/TopBar/SizeOption
@onready var title_edit: LineEdit = $MarginContainer/VBox/TopBar/TitleEdit
@onready var status_label: Label = $MarginContainer/VBox/StatusLabel

const GameScene := preload("res://scenes/Game.tscn")

var storage := LevelStorage.new()
var show_back := false  # 여는 쪽이 트리에 붙이기 전에 설정
var current_id := ""  # 저장된 레벨을 편집 중이면 그 id — 재저장 시 덮어쓴다

func _ready() -> void:
	grid.solution_changed.connect(_refresh_hints)
	$MarginContainer/VBox/TopBar/BackBtn.visible = show_back
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
	# 한 줄 힌트 개수의 최대치 = ceil(길이/2) — 미리 예약해 격자가 밀리지 않게
	row_hints.min_depth = ceili(grid.grid_size.x / 2.0)
	col_hints.min_depth = ceili(grid.grid_size.y / 2.0)
	row_hints.set_hints(level.row_hints)
	col_hints.set_hints(level.col_hints)

func _on_clear_pressed() -> void:
	grid.clear()
	_start_new_level()

func _start_new_level() -> void:
	current_id = ""
	title_edit.text = ""
	status_label.text = ""

func _on_save_pressed() -> void:
	if not _has_filled_cell():
		status_label.text = "빈 격자는 저장할 수 없습니다."
		return
	var level := grid.get_level_data()
	level.id = current_id
	level.title = title_edit.text.strip_edges() if title_edit.text.strip_edges() != "" else "무제"
	var err := storage.save(level)
	if err != OK:
		status_label.text = "저장 실패 (%s)" % error_string(err)
		return
	current_id = level.id
	status_label.text = "저장됨: %s" % level.title

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
	var sizes := [Vector2i(5, 5), Vector2i(10, 10), Vector2i(15, 15)]
	grid.grid_size = sizes[index]
	grid.cell_px = NGrid.cell_px_for(grid.grid_size)
	grid._init_arrays()
	grid.custom_minimum_size = Vector2(grid.grid_size.x, grid.grid_size.y) * grid.cell_px
	grid.size = grid.custom_minimum_size
	grid.queue_redraw()
	_refresh_hints()
	_start_new_level()

func _on_back_pressed() -> void:
	back_requested.emit()

func _on_print_pressed() -> void:
	var level := grid.get_level_data()
	print("=== 힌트 확인 ===")
	print("행: ", level.row_hints)
	print("열: ", level.col_hints)
