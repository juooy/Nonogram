# 해 유일성 검증 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 크리에이터가 그린 레벨의 정답이 하나인지 판정하고, 여러 개면 갈리는 칸을 짚어 준다.

**Architecture:** `Solver`(줄 DP + 전파 + 되돌아가기)가 판정하고, 결과를 `LevelData.quality` 로 저장한다. 에디터는 저장 시 판정·경고·모호 칸 표시, 목록은 배지 표시.

**Tech Stack:** Godot 4.7 GDScript, `tools/test.sh`.

**Spec:** `docs/superpowers/specs/2026-09-20-solver-uniqueness-design.md`

## Global Constraints

- 셀 값 규약: `-1` 미정 / `0` 빈칸 / `1` 채움
- `quality` 값은 `logic` | `unique` | `multiple` | `unknown` 네 가지뿐, 옛 파일 기본값 `unknown`
- 탐색 노드 상한 `Solver.MAX_NODES = 5000`
- 검증 게이트: 매 태스크 끝 `tools/test.sh` exit 0

---

### Task 1: Solver — 줄 풀이

**Files:** Create `scripts/Solver.gd`, `tests/test_solver.gd`

**Interfaces:**
- Produces: `class_name Solver extends RefCounted`, `static func solve_line(clues: Array, line: Array) -> Array` (모순이면 `[]`)

- [ ] **Step 1:** `[3]`/5칸, `[1,1]`/3칸, `[5]`/5칸, `[0]`, 모순 입력, 부분 확정 입력에 대한 실패 테스트 작성
- [ ] **Step 2:** `tools/test.sh` 로 실패 확인 (Parse Error: Solver 없음)
- [ ] **Step 3:** 뒤에서부터 `f(i, j)` 메모 + 앞에서부터 도달 상태 훑기로 구현
- [ ] **Step 4:** 통과 확인
- [ ] **Step 5:** 커밋 `feat(solver): 줄 단위 힌트 풀이`

---

### Task 2: Solver — 전파와 판정

**Files:** Modify `scripts/Solver.gd`, `tests/test_solver.gd`; Modify `scripts/LevelData.gd`(quality)

**Interfaces:**
- Produces: `Solver.propagate(state, rows, cols) -> bool`, `Solver.analyze(level: LevelData) -> Dictionary` (`quality`, `ambiguous_cells`), `LevelData.quality: String`

- [ ] **Step 1:** 실패 테스트 — 2×2 대각선 → `multiple` + 모호 칸 4개, 하트 10×10 → `logic`, 무작위 4×4 150개를 완전 열거와 대조, 15×15 3개 1초 이내, `LevelData` dict 왕복에 quality 포함
- [ ] **Step 2:** 실패 확인
- [ ] **Step 3:** 구현 (전파 고정점 + 반대값 우선 되돌아가기, 노드 상한 초과 시 `unknown`)
- [ ] **Step 4:** 통과 확인 (성능 테스트 포함)
- [ ] **Step 5:** 커밋 `feat(solver): 전파·되돌아가기로 해 유일성 판정`

---

### Task 3: 에디터 경고 + 모호 칸 표시 + 목록 배지

**Files:** Modify `scripts/NGrid.gd`(highlight_cells), `scripts/EditorScene.gd`, `scripts/LevelSelectScene.gd`, `tests/test_scenes.gd`, `tests/test_ngrid.gd`, `tests/test_level_select.gd`

**Interfaces:**
- Consumes: `Solver.analyze`, `LevelData.quality`
- Produces: `NGrid.highlight_cells: Array[Vector2i]` (편집 시 자동 초기화), 에디터 상태 메시지 4종, 목록 배지 3종

- [ ] **Step 1:** 실패 테스트 — 저장 시 quality 가 파일에 기록됨, `multiple` 이면 `grid.highlight_cells` 채워지고 편집하면 비워짐, 목록 배지 문자열
- [ ] **Step 2:** 실패 확인
- [ ] **Step 3:** 구현
- [ ] **Step 4:** 통과 확인
- [ ] **Step 5:** 캡처(`multiple` 상태 에디터) + Pixel 5a 실기기 확인, 기기 설정 원복
- [ ] **Step 6:** 문서(CLAUDE.md 구조, 위키 완료 표기) + 커밋 `feat: 저장 시 해 유일성 검증 경고·배지`
