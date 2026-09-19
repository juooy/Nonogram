#!/usr/bin/env bash
# 헤드리스 테스트 실행 (mac / Windows Git Bash 공용)
# Godot 경로: $GODOT 환경변수 > PATH 의 godot > OS별 기본 위치
set -uo pipefail
cd "$(dirname "$0")/.."

find_godot() {
	if [ -n "${GODOT:-}" ]; then echo "$GODOT"; return; fi
	for c in godot godot4; do
		if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return; fi
	done
	local mac="/Applications/Godot.app/Contents/MacOS/Godot"
	if [ -x "$mac" ]; then echo "$mac"; return; fi
	# Windows winget 설치 위치 (콘솔 빌드 우선 — stdout 이 보인다)
	local win
	win=$(ls "$LOCALAPPDATA"/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_*/Godot_*_console.exe 2>/dev/null | tail -1)
	if [ -n "$win" ]; then echo "$win"; return; fi
}

GODOT_BIN=$(find_godot)
if [ -z "$GODOT_BIN" ]; then
	echo "Godot 실행 파일을 찾지 못했습니다. GODOT 환경변수를 설정하세요." >&2
	exit 2
fi

# 신규 클론 시 전역 클래스 캐시(.godot/) 생성
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1

out=$("$GODOT_BIN" --headless --path . -s res://tests/run_tests.gd 2>&1)
code=$?
echo "$out"

# Godot 은 스크립트 런타임 에러가 나도 계속 진행하므로 출력으로 추가 판정
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error|Failed to load script"; then
	echo "스크립트 에러 감지 → 실패 처리" >&2
	exit 1
fi
exit $code
