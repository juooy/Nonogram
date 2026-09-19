extends SceneTree
## 씬 화면 캡처 (시각 확인용). --headless 없이 실행해야 렌더링된다.
## godot --path . -s res://tools/screenshot.gd -- <scene> <out.png> [solve]
##   Editor 씬: 하트 샘플을 그린다
##   Game 씬: 하트 샘플 레벨로 시작해 일부를 칠한다. solve 를 주면 끝까지 풀어 클리어 화면을 찍는다

const HEART := [
	"..........", ".##...##..", "####.####.", "#########.", "#########.",
	".#######..", "..#####...", "...###....", "....#.....", "..........",
]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := args[0] if args.size() > 0 else "res://scenes/Editor.tscn"
	var out := args[1] if args.size() > 1 else "user://screenshot.png"
	var solve := args.size() > 2 and args[2] == "solve"

	var node: Node = load(scene_path).instantiate()
	if "level" in node:
		var lv := LevelData.from_solution(_heart(), Vector2i(10, 10))
		lv.title = "하트"
		node.level = lv
	root.add_child(node)
	await process_frame

	var grid := node.find_child("NGrid", true, false) as NGrid
	if grid and grid.mode == NGrid.Mode.EDIT:
		grid.solution = _heart()
		grid.solution_changed.emit()
	elif grid:
		var rows := HEART.size() if solve else 4
		for r in rows:
			for c in HEART[r].length():
				grid.state[r][c] = 1 if HEART[r][c] == "#" else (2 if r == 0 else 0)
		grid._check_complete()
	if grid:
		grid.queue_redraw()

	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("saved ", ProjectSettings.globalize_path(out))
	quit()

func _heart() -> Array:
	var sol := []
	for s in HEART:
		var row := []
		for ch in s:
			row.append(ch == "#")
		sol.append(row)
	return sol
