class_name Solver extends RefCounted
## 네모로직 풀이기. 셀 값: -1 미정 / 0 빈칸 / 1 채움
## 줄 단위 추론(solve_line) → 전파(propagate) → 되돌아가기(analyze) 순으로 쓴다.

const UNKNOWN := -1
const EMPTY := 0
const FILL := 1

## 힌트와 기존 값에 맞는 모든 배치를 훑어, 배치마다 값이 같은 칸을 확정한다.
## 모순이면 빈 배열.
static func solve_line(clues: Array, line: Array) -> Array:
	var n := line.size()
	var cl: Array = [] if clues.size() == 1 and clues[0] == 0 else clues
	var k := cl.size()

	# f[i][j]: 칸 i 부터 힌트 j 부터를 배치할 수 있는가 (뒤에서부터 채운다)
	var f := []
	for i in n + 1:
		var row := []
		for j in k + 1:
			row.append(false)
		f.append(row)
	f[n][k] = true
	for i in range(n, -1, -1):
		for j in range(k, -1, -1):
			if i == n:
				f[i][j] = (j == k)
				continue
			var ok := false
			if line[i] != FILL and f[i + 1][j]:  # 이 칸을 비우기
				ok = true
			if not ok and j < k:  # 여기서 블록 j 시작
				var c: int = cl[j]
				if i + c <= n and _can_fill(line, i, c) and (i + c == n or line[i + c] != FILL):
					var next: int = mini(i + c + 1, n)
					if f[next][j + 1]:
						ok = true
			f[i][j] = ok
	if not f[0][0]:
		return []

	# 앞에서부터 도달 가능한 상태만 훑으며 각 칸이 가질 수 있는 값을 모은다
	var can_empty := []
	var can_fill := []
	for i in n:
		can_empty.append(false)
		can_fill.append(false)
	var seen := {}
	var stack := [[0, 0]]
	while not stack.is_empty():
		var st: Array = stack.pop_back()
		var i: int = st[0]
		var j: int = st[1]
		var key := i * (k + 1) + j
		if seen.has(key) or i >= n:
			continue
		seen[key] = true
		if line[i] != FILL and f[i + 1][j]:
			can_empty[i] = true
			stack.append([i + 1, j])
		if j < k:
			var c: int = cl[j]
			if i + c <= n and _can_fill(line, i, c) and (i + c == n or line[i + c] != FILL):
				var next: int = mini(i + c + 1, n)
				if f[next][j + 1]:
					for x in range(i, i + c):
						can_fill[x] = true
					if i + c < n:
						can_empty[i + c] = true
					stack.append([next, j + 1])

	var result := []
	for i in n:
		if can_empty[i] and can_fill[i]:
			result.append(UNKNOWN)
		elif can_fill[i]:
			result.append(FILL)
		elif can_empty[i]:
			result.append(EMPTY)
		else:
			return []
	return result

static func _can_fill(line: Array, start: int, count: int) -> bool:
	for x in range(start, start + count):
		if line[x] == EMPTY:
			return false
	return true

## 판정 결과
const LOGIC := "logic"        # 줄 추론만으로 풀림 (정답 1개)
const UNIQUE := "unique"      # 정답 1개지만 추측 필요
const MULTIPLE := "multiple"  # 다른 해가 있음
const UNVERIFIED := "unknown" # 탐색 상한 초과

const MAX_NODES := 5000

## 바뀐 줄을 다시 풀며 고정점까지 반복. 모순이면 false.
## state 는 Array[Array[int]] 로 제자리 갱신된다.
static func propagate(state: Array, rows: Array, cols: Array) -> bool:
	var h := state.size()
	var w: int = state[0].size()
	var dirty_rows := {}
	var dirty_cols := {}
	for r in h:
		dirty_rows[r] = true
	for c in w:
		dirty_cols[c] = true

	while not dirty_rows.is_empty() or not dirty_cols.is_empty():
		for r in dirty_rows.keys():
			dirty_rows.erase(r)
			var solved := solve_line(rows[r], state[r])
			if solved.is_empty():
				return false
			for c in w:
				if state[r][c] != solved[c]:
					state[r][c] = solved[c]
					dirty_cols[c] = true
		for c in dirty_cols.keys():
			dirty_cols.erase(c)
			var col := []
			for r in h:
				col.append(state[r][c])
			var solved := solve_line(cols[c], col)
			if solved.is_empty():
				return false
			for r in h:
				if state[r][c] != solved[r]:
					state[r][c] = solved[r]
					dirty_rows[r] = true
	return true

## 레벨의 해가 하나인지 판정한다.
## 반환: {quality: String, ambiguous_cells: Array[Vector2i]}
static func analyze(level: LevelData) -> Dictionary:
	var w := level.grid_size.x
	var h := level.grid_size.y
	var state := []
	for r in h:
		var row := []
		for c in w:
			row.append(UNKNOWN)
		state.append(row)

	if not propagate(state, level.row_hints, level.col_hints):
		# 힌트는 그림에서 만들었으므로 모순은 있을 수 없다
		return {"quality": UNVERIFIED, "ambiguous_cells": []}
	if _first_unknown(state) == Vector2i(-1, -1):
		return {"quality": LOGIC, "ambiguous_cells": []}

	var budget := [MAX_NODES]
	var other = _find_other_solution(state, level, budget)
	if other == null:
		return {"quality": UNVERIFIED if budget[0] <= 0 else UNIQUE, "ambiguous_cells": []}
	var cells: Array[Vector2i] = []
	for r in h:
		for c in w:
			if (other[r][c] == FILL) != bool(level.solution[r][c]):
				cells.append(Vector2i(c, r))
	return {"quality": MULTIPLE, "ambiguous_cells": cells}

## 크리에이터 그림과 다른 완전해를 찾는다. 없으면 null (상한 초과도 null — budget 으로 구분)
static func _find_other_solution(state: Array, level: LevelData, budget: Array):
	budget[0] -= 1
	if budget[0] <= 0:
		return null
	var cell := _first_unknown(state)
	if cell == Vector2i(-1, -1):
		return state if _differs(state, level) else null
	# 크리에이터 그림과 반대 값을 먼저 시도해 다른 해를 빨리 찾는다
	var intended: int = FILL if level.solution[cell.y][cell.x] else EMPTY
	for v in [EMPTY if intended == FILL else FILL, intended]:
		var next := _copy(state)
		next[cell.y][cell.x] = v
		if propagate(next, level.row_hints, level.col_hints):
			var found = _find_other_solution(next, level, budget)
			if found != null:
				return found
		if budget[0] <= 0:
			return null
	return null

static func _differs(state: Array, level: LevelData) -> bool:
	for r in state.size():
		for c in state[r].size():
			if (state[r][c] == FILL) != bool(level.solution[r][c]):
				return true
	return false

static func _first_unknown(state: Array) -> Vector2i:
	for r in state.size():
		for c in state[r].size():
			if state[r][c] == UNKNOWN:
				return Vector2i(c, r)
	return Vector2i(-1, -1)

static func _copy(state: Array) -> Array:
	var out := []
	for row in state:
		out.append(row.duplicate())
	return out
