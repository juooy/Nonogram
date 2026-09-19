extends Control
## 레벨 선택 (앱 시작 화면). 목록 행: [플레이 → Game][편집 → Editor][삭제 → 확인 패널]. 새 레벨 → Editor.
## 하위 화면은 자식으로 띄우고 back_requested 를 받아 닫는다.

const GameScene := preload("res://scenes/Game.tscn")
const EditorScene := preload("res://scenes/Editor.tscn")
const EDIT_ICON := preload("res://assets/icons/edit.svg")
const TRASH_ICON := preload("res://assets/icons/trash.png")

@onready var list_box: VBoxContainer = $MarginContainer/VBox/Scroll/List
@onready var empty_label: Label = $MarginContainer/VBox/EmptyLabel
@onready var confirm_panel: Control = $ConfirmPanel
@onready var confirm_label: Label = %ConfirmLabel

var storage := LevelStorage.new()
var _pending_delete_id := ""

func _ready() -> void:
	theme = AppTheme.get_theme()
	confirm_panel.visible = false
	refresh()

# 안드로이드 뒤로가기 (project.godot 의 quit_on_go_back=false 전제).
# 알림은 모든 노드에 전파되므로 루트인 이 화면에서만 처리한다.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not go_back():
		get_tree().quit()

## 가장 위에 열린 화면을 닫는다. 닫을 게 없으면(목록 화면) false.
func go_back() -> bool:
	if confirm_panel.visible:
		_on_cancel_delete()
		return true
	var top := _top_screen(self)
	if top == self:
		return false
	top.back_requested.emit()
	return true

func _top_screen(node: Node) -> Node:
	for child in node.get_children():
		if child.has_signal("back_requested") and not child.is_queued_for_deletion():
			return _top_screen(child)
	return node

func refresh() -> void:
	for child in list_box.get_children():
		list_box.remove_child(child)
		child.queue_free()
	var levels := storage.list()
	empty_label.visible = levels.is_empty()
	for level in levels:
		list_box.add_child(_make_row(level))

func _make_row(level: LevelData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Level_" + level.id
	row.add_theme_constant_override("separation", 8)
	var play := _row_button("PlayBtn", "%s  ·  %d×%d" % [level.title, level.grid_size.x, level.grid_size.y], null)
	play.alignment = HORIZONTAL_ALIGNMENT_LEFT
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.pressed.connect(_open_game.bind(level))
	var edit := _row_button("EditBtn", "", EDIT_ICON)
	edit.pressed.connect(_open_editor.bind(level))
	var del := _row_button("DeleteBtn", "", TRASH_ICON)
	del.pressed.connect(_ask_delete.bind(level))
	for b in [play, edit, del]:
		row.add_child(b)
	return row

func _row_button(node_name: String, text: String, icon: Texture2D) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.icon = icon
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.theme_type_variation = &"CardButton"
	b.custom_minimum_size = Vector2(AppTheme.BUTTON_MIN, AppTheme.BUTTON_MIN)
	return b

func _ask_delete(level: LevelData) -> void:
	_pending_delete_id = level.id
	confirm_label.text = "「%s」 레벨을 삭제할까요?
되돌릴 수 없습니다." % level.title
	confirm_panel.visible = true

func _on_cancel_delete() -> void:
	_pending_delete_id = ""
	confirm_panel.visible = false

func _on_confirm_delete() -> void:
	var err := storage.delete(_pending_delete_id)
	if err != OK:
		push_warning("레벨 삭제 실패: %s (%s)" % [_pending_delete_id, error_string(err)])
	_on_cancel_delete()
	refresh()

func _open_editor(level: LevelData) -> void:
	var ed := EditorScene.instantiate()
	ed.name = "Editor"
	ed.show_back = true
	ed.storage = storage
	ed.edit_level = level
	_push(ed)

func _open_game(level: LevelData) -> void:
	var game := GameScene.instantiate()
	game.name = "Game"
	game.level = level
	_push(game)

func _on_new_pressed() -> void:
	var ed := EditorScene.instantiate()
	ed.name = "Editor"
	ed.show_back = true
	ed.storage = storage
	_push(ed)

func _push(screen: Node) -> void:
	screen.back_requested.connect(_pop.bind(screen))
	$MarginContainer.visible = false
	add_child(screen)

func _pop(screen: Node) -> void:
	screen.queue_free()
	$MarginContainer.visible = true
	refresh()
