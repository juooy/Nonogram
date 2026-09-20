# 해 유일성 검증 설계

- 작성: 2026-09-20
- 상태: 승인됨 (브레인스토밍)
- 범위: 풀이기(Solver), 레벨 품질 값, 에디터·목록 표시

## 배경

UGC 레벨은 크리에이터가 그린 그림과 다른 해가 존재할 수 있다. 플레이 판정은 이미 「힌트 일치」라 플레이어가 억울할 일은 없지만(Step 4), **정답이 여러 개인 레벨은 퍼즐로서 품질이 낮다.** 업로드(Step 6) 전 품질 관문이 필요하다.

## 판정 기준

| 값 | 뜻 | 처리 |
|---|---|---|
| `logic` | 줄 단위 추론만으로 끝까지 풀림 (정답 1개) | 통과, 배지 없음 |
| `unique` | 정답은 1개지만 추측(되돌아가기)이 필요 | 통과, 「추측 필요」 배지 |
| `multiple` | 힌트를 만족하는 다른 해가 존재 | 저장은 허용, ⚠ 경고 + 모호한 칸 표시 |
| `unknown` | 탐색 상한 초과로 판정 못 함 | 「미검증」 배지 |

업로드(Step 6)는 `logic`·`unique` 만 허용한다 (이 문서 범위 밖, 값만 준비).

## Solver (`scripts/Solver.gd`, RefCounted, static)

셀 값: `-1` 미정 / `0` 빈칸 / `1` 채움.

- `solve_line(clues: Array, line: Array) -> Array` — 힌트와 기존 값에 모순 없는 모든 배치를 DP로 훑어, 모든 배치에서 같은 값인 칸을 확정한 새 줄을 돌려준다. 모순이면 빈 배열.
  - 상태 `(i, j)` = 칸 i 부터 힌트 j 부터. 뒤에서부터 `f(i, j)` 가능 여부를 메모하고, 앞에서부터 도달 가능한 상태만 훑으며 각 칸의 가능 값(0/1)을 모은다. 방문 집합으로 지수 폭발을 막는다.
  - 힌트 `[0]` 은 빈 줄로 취급한다.
- `propagate(state: Array, rows: Array, cols: Array) -> bool` — 바뀐 줄만 다시 풀며 고정점까지 반복. 모순이면 false.
- `analyze(level: LevelData) -> Dictionary` — `{quality: String, ambiguous_cells: Array[Vector2i]}`
  1. 빈 격자에서 `propagate`. 전부 확정되면 `logic`.
  2. 미정 칸이 남으면 되돌아가기 탐색. 분기 시 **크리에이터 그림과 반대 값을 먼저** 시도해 다른 해를 빨리 찾는다.
     - 크리에이터 그림과 다른 완전해를 찾으면 `multiple`, 두 그림이 다른 칸이 `ambiguous_cells`.
     - 다 훑어도 없으면 `unique`.
  3. 탐색 노드가 `MAX_NODES`(5000) 를 넘으면 `unknown`.

## 데이터

`LevelData.quality: String = "unknown"` 추가, `to_dict`/`from_dict` 에 포함(옛 파일은 `unknown`).

## UI

- **에디터**: 저장 시 `analyze` 실행 → `level.quality` 설정 후 저장. 상태 메시지:
  - `logic` → `저장됨: {제목} · 정답 1개`
  - `unique` → `저장됨: {제목} · 정답 1개(추측 필요)`
  - `multiple` → `저장됨: {제목} · ⚠ 정답이 여러 개입니다 (표시된 칸)`
  - `unknown` → `저장됨: {제목} · 검증 상한 초과(미검증)`
  - `multiple` 이면 `grid.highlight_cells` 에 모호한 칸을 넣어 빨간 테두리로 표시. 다음 편집(`solution_changed`)에 지워진다.
- **NGrid**: `highlight_cells: Array[Vector2i]` 추가, `_draw` 에서 해당 칸 테두리를 `AppTheme.MARK` 로 그린다.
- **목록**: 제목 뒤 배지 — `multiple` → `⚠ 정답 여러 개`, `unique` → `추측 필요`, `unknown` → `미검증`, `logic` → 없음.

## 범위 밖

업로드 차단, 난이도 산정, 자동 수정 제안, 백그라운드 스레드.

## 검증

- 줄 풀이: `[3]`/5 → 가운데 확정, `[1,1]`/3 → `1,0,1`, `[5]`/5 → 전부 채움, `[0]` → 전부 빈칸, 모순 입력 → 빈 배열
- `analyze`: 2×2 대각선 → `multiple` + 모호한 칸 4개, 하트(10×10) → `logic`
- **무작위 4×4 150개**: 풀이기 판정과 완전 열거(행 후보 조합 + 열 검사)로 센 해 개수 비교 — `multiple` ⟺ 해 2개 이상
- 성능: 무작위 15×15 3개, 각각 1초 이내
- 캡처 + Pixel 5a 실기기 확인
