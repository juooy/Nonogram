extends Control
## 플레이 화면. 여는 쪽이 level 을 넣고 트리에 붙인 뒤, back_requested 를 받아 닫는다.

signal back_requested

@onready var grid: NGrid = $MarginContainer/VBox/GridArea/Board/NGrid
@onready var row_hints: HintBar = $MarginContainer/VBox/GridArea/Board/RowHints
@onready var col_hints: HintBar = $MarginContainer/VBox/GridArea/Board/ColHints
@onready var title_label: Label = $MarginContainer/VBox/TopBar/TitleLabel
@onready var pen_btn: Button = $MarginContainer/VBox/TopBar/PenBtn
@onready var clear_panel: Control = $ClearPanel
@onready var clear_label: Label = $ClearPanel/Center/Panel/VBox/ClearLabel

var level: LevelData

func _ready() -> void:
	grid.completed.connect(_on_completed)
	if level == null:
		title_label.text = "레벨 없음"
		return
	title_label.text = level.title
	grid.mode = NGrid.Mode.PLAY
	grid.cell_px = NGrid.cell_px_for(level.grid_size)
	grid.load_level(level)
	row_hints.cell_px = grid.cell_px
	col_hints.cell_px = grid.cell_px
	row_hints.set_hints(level.row_hints)
	col_hints.set_hints(level.col_hints)
	_update_pen_label()
	clear_panel.visible = false

func _on_completed() -> void:
	grid.interactive = false
	clear_label.text = "클리어!\n%s" % level.title
	clear_panel.visible = true

func _on_pen_pressed() -> void:
	grid.pen = 2 if grid.pen == 1 else 1
	_update_pen_label()

func _update_pen_label() -> void:
	pen_btn.text = "펜: ■ 채우기" if grid.pen == 1 else "펜: ✕ 표시"

func _on_retry_pressed() -> void:
	grid.reset_state()
	grid.interactive = true
	clear_panel.visible = false

func _on_back_pressed() -> void:
	back_requested.emit()
