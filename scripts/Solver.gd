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
