# UI 스킨 + 터치 영역 설계

- 작성: 2026-09-19
- 상태: 승인됨 (브레인스토밍 1·2부)
- 범위: LevelSelect / Editor / Game 세 화면의 시각 스타일과 배치

## 배경

MVP Step 1~5 완료 후 Pixel 5a 실기기 확인에서 UI가 작고(기본 테마) 버튼이 권장 터치 영역(48dp)에 못 미친다는 점이 드러났다. 화면은 가로 고정(sensor_landscape), stretch `canvas_items` + `expand`, 논리 높이 648px. Pixel 5a 기준 배율 약 1.455 → 48dp ≈ 87 논리 px.

## 결정 사항

| 항목 | 결정 |
|---|---|
| 스킨 방식 | 코드로 만든 Theme(StyleBoxFlat) + Kenney *Game Icons*(CC0) 아이콘 |
| 색 분위기 | 밝은 종이 톤 |
| 도구 배치 | 오른쪽 세로 패널 |
| 터치 영역 | 버튼 최소 64×64 논리 px(≈35dp) + 버튼 간 여백 8px. 648px 높이 안에 보드를 담기 위한 타협 |

## 1. 공통 스타일

### AppTheme (`scripts/ui/AppTheme.gd`)

- `static func get_theme() -> Theme` — 최초 호출 시 생성해 static 변수에 캐시.
- 세 화면 루트가 `_ready()` 에서 `theme = AppTheme.get_theme()` 적용. 오토로드 없음.
- 기본 글꼴 유지(한글 표시 확인됨), 기본 크기 18.

### 팔레트 (`AppTheme` 상수)

| 이름 | 값 | 용도 |
|---|---|---|
| `BG` | `#F4F1E8` | 화면 배경 |
| `PANEL` | `#FBFAF5` | 도구 패널·카드·클리어 패널 |
| `INK` | `#2B2B2B` | 글자, 채운 칸 |
| `ACCENT` | `#2A7F7A` | 주요 버튼, 선택된 펜, 클리어 강조 |
| `MARK` | `#B5483B` | X 표시 |
| `LINE` / `LINE_BOLD` | 회색 계열 | 격자 선(기존 값 유지) |

NGrid·HintBar 의 하드코딩 색을 이 상수로 교체한다.

### 버튼

- StyleBoxFlat: 모서리 10px, 테두리 없음. normal / hover / pressed / disabled / focus 상태별 명도 차이.
- 주요 버튼(ACCENT 배경 + 흰 글자)은 theme type variation `AccentButton`.
- 도구 패널 버튼 최소 크기 64×64, 패널 VBox separation 8.

### 아이콘

- Kenney *Game Icons*(CC0)에서 필요한 것만 `assets/icons/` 로 복사: 뒤로, 펜(채움), X, 다시 하기, 재생, 더하기, 저장(없으면 글자만).
- 팩에 없는 아이콘은 글자 버튼으로 둔다.
- 아이콘 색은 `icon_normal_color` 등 테마 색으로 틴트.
- 라이선스 기록: `assets/icons/LICENSE.txt` (CC0, 출처 URL).

## 2. 배치

### 공용 보드 (`scenes/ui/Board.tscn` + `scripts/ui/Board.gd`)

Editor·Game 이 복제하던 `Board`(Corner/ColHints/RowHints/NGrid) 를 하나로 추출.

- 공개 API: `grid: NGrid`, `set_hints(rows: Array, cols: Array)`, `set_min_depth(row_depth: int, col_depth: int)`, `fit_to(area: Vector2)`.
- `fit_to` — 힌트 깊이까지 포함해 `area` 안에 들어가는 최대 `cell_px` 계산, [24, 72] 로 클램프 후 NGrid·HintBar 에 반영.
  - 가로: `cols * cell + row_depth * slot(cell)`, 세로: `rows * cell + col_depth * slot(cell)` (slot = HintBar.slot_px 규칙).
- 호출자는 보드 영역 컨테이너의 `resized` 시그널에서 `fit_to` 를 다시 부른다.
- 제거: `GridArea` ScrollContainer, `NGrid.cell_px_for()`.

### 화면 공통 틀

```
Root (Control, theme=AppTheme)
└ Background (ColorRect BG)
└ HBox
  ├ Main (VBox, expand)
  │  ├ Header (HBox: ◀ BackBtn, TitleLabel)
  │  └ BoardArea (Control, expand) ─ Board (가운데 정렬)
  └ SidePanel (PanelContainer, 폭 200) ─ VBox (도구 버튼들)
```

### 화면별

- **Editor** — 헤더 제목 「레벨 만들기」. 패널: SizeOption(5/10/15), TitleEdit, SaveBtn(Accent), PlayBtn, ClearBtn, 맨 아래 StatusLabel. 「힌트 출력」 버튼 제거. BackBtn 은 기존대로 `show_back` 일 때만 표시.
- **Game** — 헤더 제목 = 레벨 제목. 패널: 펜 세그먼트(FillBtn `■ 채우기` / MarkBtn `✕ 표시`, toggle + ButtonGroup, 선택 쪽 Accent), RetryBtn. 클리어 패널: PANEL 배경, ACCENT 제목, 64px 버튼 2개.
- **LevelSelect** — 헤더 「네모로직」 + NewBtn(Accent, `＋ 새 레벨`). 목록 행은 64px 높이 카드(PANEL 배경, 제목·크기). 썸네일 없음(답 노출 방지).

## 3. 범위 밖

애니메이션, 효과음, 새 글꼴, 레벨 카드 그리드 목록, 다크 모드.

## 4. 검증

- `tools/test.sh` — 경로 변경분 수정 + 신규:
  - AppTheme 이 세 화면 루트에 적용됨
  - Editor·Game 도구 패널의 모든 Button 의 `get_combined_minimum_size()` 가 64×64 이상
  - `Board.fit_to`: 5×5·15×15 × (1152×648 기준 영역, 1556×648 기준 영역) 에서 보드 크기 ≤ 영역, cell_px ∈ [24, 72]
  - 펜 세그먼트: 누른 쪽만 `button_pressed`, `grid.pen` 반영
- `tools/screenshot.gd` — 창 크기 인자 추가, 세 화면을 1152×648 / 1556×648 로 캡처해 확인.
- Pixel 5a 실기기에서 전체 흐름 재확인.
