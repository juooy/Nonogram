extends Control
## 플레이 화면. 여는 쪽이 level 을 넣고 트리에 붙인 뒤, back_requested 를 받아 닫는다.

signal back_requested

@onready var board: Board = %Board
@onready var grid: NGrid = board.grid
@onready var board_area: Control = %BoardArea
@onready var title_label: Label = %TitleLabel
@onready var fill_btn: Button = %FillBtn
@onready var mark_btn: Button = %MarkBtn
@onready var clear_panel: Control = $ClearPanel
@onready var clear_label: Label = %ClearLabel

var level: LevelData

func _ready() -> void:
	theme = AppTheme.get_theme()
	grid.completed.connect(_on_completed)
	fill_btn.toggled.connect(func(on: bool): if on: grid.pen = 1)
	mark_btn.toggled.connect(func(on: bool): if on: grid.pen = 2)
	board_area.resized.connect(_fit_board)
	clear_panel.visible = false
	if level == null:
		title_label.text = "레벨 없음"
		return
	title_label.text = level.title
	grid.mode = NGrid.Mode.PLAY
	grid.load_level(level)
	board.set_hints(level.row_hints, level.col_hints)
	fill_btn.button_pressed = true
	_fit_board()

func _fit_board() -> void:
	board.fit_to(board_area.size)

func _on_completed() -> void:
	grid.interactive = false
	clear_label.text = "클리어!\n%s" % level.title
	clear_panel.visible = true

func _on_retry_pressed() -> void:
	grid.reset_state()
	grid.interactive = true
	clear_panel.visible = false

func _on_back_pressed() -> void:
	back_requested.emit()
