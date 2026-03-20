#!/bin/bash

# Claude Code UserPromptSubmit Hook — API 개발 워크플로 가이드
# 신규 API 개발 관련 프롬프트 감지 시 워크플로 가이드를 Claude 컨텍스트에 주입합니다.
#
# 이벤트: UserPromptSubmit
# 트리거: 프롬프트에 API 개발 관련 키워드 감지
# 출력: stdout → Claude 컨텍스트에 주입됨
# 차단: 비차단 (항상 exit 0)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/log-utils.sh"
HOOK_START_MS=$(get_ms)

# stdin에서 JSON 읽기
INPUT=$(cat)

# prompt 추출 (jq → python3 → grep 폴백)
get_prompt() {
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r '.prompt // ""'
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null
    else
        echo "$INPUT" | grep -oP '"prompt":\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
    fi
}

# cwd 추출 (jq → python3 → grep 폴백)
get_cwd() {
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r '.cwd // "."'
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd','.'))" 2>/dev/null
    else
        echo "$INPUT" | grep -oP '"cwd":\s*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/'
    fi
}

# permission_mode 추출 (jq → python3 → grep 폴백)
get_permission_mode() {
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r '.permission_mode // ""'
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('permission_mode',''))" 2>/dev/null
    else
        echo "$INPUT" | grep -oP '"permission_mode":\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
    fi
}

PROMPT=$(get_prompt)
CWD=$(get_cwd)
PERMISSION_MODE=$(get_permission_mode)

# ─── 가드 조건 1: 시스템 명령 무시 (/clear, /compact, /help 등) ───
if echo "$PROMPT" | grep -qE "^/"; then
    exit 0
fi

# ─── 가드 조건 2: 플랜모드에서만 동작 ───
if [ "$PERMISSION_MODE" != "plan" ]; then
    exit 0
fi

# ─── 가드 조건 3: 키워드 매칭 (복합 조건으로 오탐 방지) ───
KEYWORD_PATTERN="신규.*개발|신규.*구현|API.*개발|기능.*개발|기능개발|스토리보드|착수|개발.*시작|implement|develop.*new|new.*feature"

if ! echo "$PROMPT" | grep -qiE "$KEYWORD_PATTERN"; then
    exit 0
fi

# 키워드 매칭됨 — 로그 기록은 하단에서 처리

# ─── 가드 조건 4: 프로젝트 확인 (Inconus ERP인지) ───
cd "$CWD" 2>/dev/null || exit 0

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$PROJECT_ROOT" ]; then
    exit 0
fi

CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
if [ ! -f "$CLAUDE_MD" ]; then
    exit 0
fi

if ! grep -q "Inconus ERP" "$CLAUDE_MD" 2>/dev/null; then
    exit 0
fi

# ─── PDF 목록 수집 ───
STORYBOARD_DIR="$PROJECT_ROOT/src/docs/기획문서"
PDF_LIST=""
if [ -d "$STORYBOARD_DIR" ]; then
    PDF_LIST=$(ls "$STORYBOARD_DIR"/*.pdf 2>/dev/null | while read -r f; do
        basename "$f"
    done)
fi

# ─── stdout 출력: Claude 컨텍스트에 주입 ───
echo ""
echo "<api-dev-guide-hook>"
echo "API_DEV_WORKFLOW_DETECTED: true"
echo ""
echo "== 스토리보드 기반 API 개발 워크플로 =="
echo ""
echo "[사용 가능한 기획문서]"
if [ -n "$PDF_LIST" ]; then
    echo "$PDF_LIST" | while read -r pdf; do
        echo "  - src/docs/기획문서/$pdf"
    done
else
    echo "  (기획문서 없음 - src/docs/기획문서/ 디렉토리를 확인하세요)"
fi
echo ""
echo "[6단계 개발 파이프라인]"
echo "  1. 스토리보드 PDF 분석 → UI 요소를 API 엔드포인트로 매핑"
echo "  2. 기능명세서 작성 (src/docs/{기능명}_기능명세서.md)"
echo "  3. 아키텍처 설명서 작성 (src/docs/architecture/)"
echo "  4. 코드 구현: Entity → Repository → DTO → Service → Controller → Test"
echo "  5. 사용자매뉴얼 작성 (src/docs/user-guide/)"
echo "  6. 부수 문서: ERROR_MESSAGES.md, 아키텍처 특이사항 업데이트"
echo ""
echo "[참고] CLAUDE.md 섹션 9 '스토리보드 기반 API 개발 워크플로' 참조"
echo "[참고] 유사 기능의 기존 코드를 먼저 분석한 후 개발을 시작하세요"
echo "</api-dev-guide-hook>"
echo ""

# 워크플로우 체크포인트 자동 기록 (API 개발 파이프라인 시작)
REPO=$(get_repo_name "$CWD")
"${SCRIPT_DIR}/lib/write-checkpoint.sh" "API 개발 파이프라인" "기획문서 분석" 1 6 2>/dev/null

# JSONL 로그 기록
log_hook_execution "on-prompt-api-dev-guide.sh" "UserPromptSubmit" 0 "$HOOK_START_MS" "$REPO"

# 항상 비차단
exit 0
