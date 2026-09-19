extends SceneTree
## 씬 화면 캡처 (시각 확인용). --headless 없이 실행해야 렌더링된다.
## godot --path . -s res://tools/screenshot.gd -- <scene> <out.png>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := args[0] if args.size() > 0 else "res://scenes/Editor.tscn"
	var out := args[1] if args.size() > 1 else "user://screenshot.png"
	var node: Node = load(scene_path).instantiate()
	root.add_child(node)
	await process_frame
	var grid := node.find_child("NGrid", true, false) as NGrid
	if grid:  # 힌트가 보이도록 하트 모양을 채운다 (10×10)
		var heart := [
			"..........", ".##...##..", "####.####.", "#########.", "#########.",
			".#######..", "..#####...", "...###....", "....#.....", "..........",
		]
		for r in heart.size():
			for c in heart[r].length():
				grid.solution[r][c] = heart[r][c] == "#"
		grid.solution_changed.emit()
		grid.queue_redraw()
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("saved ", ProjectSettings.globalize_path(out))
	quit()
