extends Control
## 레벨 선택 (앱 시작 화면). 저장된 레벨 목록 → Game, 새 레벨 만들기 → Editor.
## 하위 화면은 자식으로 띄우고 back_requested 를 받아 닫는다.

const GameScene := preload("res://scenes/Game.tscn")
const EditorScene := preload("res://scenes/Editor.tscn")

@onready var list_box: VBoxContainer = $MarginContainer/VBox/Scroll/List
@onready var empty_label: Label = $MarginContainer/VBox/EmptyLabel

var storage := LevelStorage.new()

func _ready() -> void:
	refresh()

func refresh() -> void:
	for child in list_box.get_children():
		list_box.remove_child(child)
		child.queue_free()
	var levels := storage.list()
	empty_label.visible = levels.is_empty()
	for level in levels:
		var btn := Button.new()
		btn.name = "Level_" + level.id
		btn.text = "%s  ·  %d×%d" % [level.title, level.grid_size.x, level.grid_size.y]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 48)
		btn.pressed.connect(_open_game.bind(level))
		list_box.add_child(btn)

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
