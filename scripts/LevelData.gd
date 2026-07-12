class_name LevelData

var id: String = ""
var title: String = "무제"
var grid_size: Vector2i = Vector2i(10, 10)
var solution: Array = []   # Array[Array[bool]]
var row_hints: Array = []  # Array[Array[int]]
var col_hints: Array = []  # Array[Array[int]]
var play_count: int = 0

static func from_solution(sol: Array, sz: Vector2i) -> LevelData:
	var d = LevelData.new()
	d.solution = sol
	d.grid_size = sz
	d.row_hints = _calc_rows(sol, sz)
	d.col_hints = _calc_cols(sol, sz)
	return d

static func _run(line: Array) -> Array:
	var hints := []
	var n := 0
	for v in line:
		if v:
			n += 1
		elif n > 0:
			hints.append(n)
			n = 0
	if n > 0:
		hints.append(n)
	return hints if not hints.is_empty() else [0]

static func _calc_rows(sol: Array, sz: Vector2i) -> Array:
	var result := []
	for r in sz.y:
		result.append(_run(sol[r]))
	return result

static func _calc_cols(sol: Array, sz: Vector2i) -> Array:
	var result := []
	for c in sz.x:
		var col := []
		for r in sz.y:
			col.append(sol[r][c])
		result.append(_run(col))
	return result

func to_dict() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"grid_size": {"x": grid_size.x, "y": grid_size.y},
		"solution": solution,
		"row_hints": row_hints,
		"col_hints": col_hints,
		"play_count": play_count,
	}

static func from_dict(d: Dictionary) -> LevelData:
	var level = LevelData.new()
	level.id = d.get("id", "")
	level.title = d.get("title", "무제")
	var sz = d.get("grid_size", {"x": 10, "y": 10})
	level.grid_size = Vector2i(sz["x"], sz["y"])
	level.solution = d.get("solution", [])
	level.row_hints = d.get("row_hints", [])
	level.col_hints = d.get("col_hints", [])
	level.play_count = d.get("play_count", 0)
	return level
