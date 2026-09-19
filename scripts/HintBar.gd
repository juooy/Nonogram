class_name HintBar extends Control
## 행(ROW, 격자 왼쪽) 또는 열(COL, 격자 위) 힌트 숫자 표시.
## 숫자는 격자 쪽으로 붙는다 — ROW 는 오른쪽 정렬, COL 은 아래쪽 정렬.

enum Axis { ROW, COL }

const MIN_SLOT_PX := 16.0

@export var axis: Axis = Axis.ROW
@export var cell_px: float = 40.0

var hints: Array = []  # Array[Array[int]] — 줄마다 힌트 숫자 목록
## 최소 숫자 칸 수. 에디터는 격자 크기로 나올 수 있는 최대치를 예약해
## 그리는 도중 바가 커져 격자가 밀리는 것(=드래그 중 엉뚱한 칸 입력)을 막는다.
var min_depth: int = 0

func set_hints(h: Array) -> void:
	hints = h
	custom_minimum_size = _calc_min_size()
	size = custom_minimum_size
	queue_redraw()

## 숫자 한 개가 차지하는 칸 폭(ROW) / 높이(COL)
func slot_px() -> float:
	return maxf(cell_px * 0.6, MIN_SLOT_PX)

func font_size() -> int:
	return int(clampf(cell_px * 0.5, 11.0, 24.0))

## line 번째 줄의 j 번째 숫자가 그려질 영역
func slot_rect(line: int, j: int) -> Rect2:
	var offset: int = _depth() - hints[line].size() + j
	var s := slot_px()
	if axis == Axis.ROW:
		return Rect2(offset * s, line * cell_px, s, cell_px)
	return Rect2(line * cell_px, offset * s, cell_px, s)

func _max_len() -> int:
	var m := 0
	for line in hints:
		m = maxi(m, line.size())
	return m

func _depth() -> int:
	return maxi(_max_len(), min_depth)

func _calc_min_size() -> Vector2:
	if hints.is_empty():
		return Vector2.ZERO
	var depth := _depth() * slot_px()
	var length := hints.size() * cell_px
	return Vector2(depth, length) if axis == Axis.ROW else Vector2(length, depth)

func _draw() -> void:
	var font := get_theme_default_font()
	var fs := font_size()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.94, 0.94, 0.92))
	for i in hints.size():
		# 5줄 단위로 음영을 번갈아 격자의 굵은 선과 맞춰 읽기 쉽게
		if (i / 5) % 2 == 1:
			var band := Rect2(0, i * cell_px, size.x, cell_px) if axis == Axis.ROW \
				else Rect2(i * cell_px, 0, cell_px, size.y)
			draw_rect(band, Color(0, 0, 0, 0.07))
		for j in hints[i].size():
			var r := slot_rect(i, j)
			var text := str(hints[i][j])
			var baseline := r.position.y + (r.size.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5
			draw_string(font, Vector2(r.position.x, baseline), text,
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, Color(0.15, 0.15, 0.15))
