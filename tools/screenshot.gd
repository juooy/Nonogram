extends SceneTree
## 씬 화면 캡처 (시각 확인용). --headless 없이 실행해야 렌더링된다.
## godot --path . -s res://tools/screenshot.gd -- <scene> <out.png> [WxH] [solve]
##   WxH: 창 크기 (예: 1556x648 = Pixel 5a 비율). 생략 시 프로젝트 기본 1152x648
##   Editor 씬: 하트 샘플을 그린다
##   LevelSelect 씬: 임시 폴더에 샘플 레벨 3개를 넣어 목록을 찍는다 (끝나면 삭제). confirm 플래그로 삭제 확인 패널
##   Game 씬: 하트 샘플 레벨로 시작해 일부를 칠한다. solve 를 주면 끝까지 풀어 클리어 화면을 찍는다

const HEART := [
	"..........", ".##...##..", "####.####.", "#########.", "#########.",
	".#######..", "..#####...", "...###....", "....#.....", "..........",
]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := args[0] if args.size() > 0 else "res://scenes/Editor.tscn"
	var out := args[1] if args.size() > 1 else "user://screenshot.png"
	var solve := "solve" in args
	for a in args.slice(2):
		if RegEx.create_from_string("^[0-9]+x[0-9]+$").search(a):
			var wh := a.split("x")
			DisplayServer.window_set_size(Vector2i(int(wh[0]), int(wh[1])))
			for i in 3:
				await process_frame

	var node: Node = load(scene_path).instantiate()
	if "level" in node:
		var lv := LevelData.from_solution(_heart(), Vector2i(10, 10))
		lv.title = "하트"
		node.level = lv
	var tmp_dir := "user://screenshot_levels"
	if "storage" in node:
		var st := LevelStorage.new(tmp_dir)
		var titles := ["하트", "고양이", "별"]
		for i in titles.size():
			var lv := LevelData.from_solution(_heart(), Vector2i(10, 10))
			lv.id = "%d_0000" % (1000 + i)
			lv.title = titles[i]
			st.save(lv)
		node.storage = st
	root.add_child(node)
	await process_frame
	if "confirm" in args and node.has_method("_ask_delete"):
		node._ask_delete(node.storage.list()[0])

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
	if DirAccess.dir_exists_absolute(tmp_dir):
		for f in DirAccess.get_files_at(tmp_dir):
			DirAccess.remove_absolute(tmp_dir + "/" + f)
		DirAccess.remove_absolute(tmp_dir)
	quit()

func _heart() -> Array:
	var sol := []
	for s in HEART:
		var row := []
		for ch in s:
			row.append(ch == "#")
		sol.append(row)
	return sol
