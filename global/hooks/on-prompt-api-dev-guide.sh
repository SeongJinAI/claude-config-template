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

# ─── 가드 조건 4: 프로젝트 확인 ───
cd "$CWD" 2>/dev/null || exit 0

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$PROJECT_ROOT" ]; then
    exit 0
fi

CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
if [ ! -f "$CLAUDE_MD" ]; then
    exit 0
fi

# ─── 지식 레포 경로 결정 ───
_resolve_knowledge_repo() {
    if [ -n "$CLAUDE_KNOWLEDGE_REPO" ]; then
        echo "$CLAUDE_KNOWLEDGE_REPO"
        return
    fi
    local env_file="$HOME/.claude/.env"
    if [ -f "$env_file" ]; then
        local dir=$(grep "^CLAUDE_KNOWLEDGE_REPO=" "$env_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [ -n "$dir" ]; then
            echo "$dir"
            return
        fi
    fi
    echo ""
}

KNOWLEDGE_REPO=$(_resolve_knowledge_repo)

# ─── 기획문서 탐색 (프로젝트별 위치 자동 감지) ───
STORYBOARD_DIR=""
PDF_LIST=""
for candidate in "$PROJECT_ROOT/src/docs/기획문서" "$PROJECT_ROOT/docs/기획문서" "$PROJECT_ROOT/docs/storyboard"; do
    if [ -d "$candidate" ]; then
        STORYBOARD_DIR="$candidate"
        break
    fi
done

if [ -n "$STORYBOARD_DIR" ]; then
    PDF_LIST=$(ls "$STORYBOARD_DIR"/*.pdf 2>/dev/null | while read -r f; do
        basename "$f"
    done)
fi

# ─── stdout 출력: Claude 컨텍스트에 주입 ───
PROJECT_NAME=$(basename "$PROJECT_ROOT")
echo ""
echo "<api-dev-guide-hook>"
echo "API_DEV_WORKFLOW_DETECTED: true"
echo "PROJECT: $PROJECT_NAME"
echo ""
echo "== 기능 개발 워크플로 =="
echo ""
echo "[사용 가능한 기획문서]"
if [ -n "$PDF_LIST" ]; then
    RELATIVE_DIR=$(echo "$STORYBOARD_DIR" | sed "s|$PROJECT_ROOT/||")
    echo "$PDF_LIST" | while read -r pdf; do
        echo "  - $RELATIVE_DIR/$pdf"
    done
else
    echo "  (기획문서 없음)"
fi
echo ""
echo "[개발 파이프라인]"
echo "  1. 기획문서 분석 → 요구사항 파악"
echo "  2. /feature-docs-plan → 기능명세서 + 아키텍처 초안 생성"
echo "  3. 코드 구현"
echo "  4. /feature-docs-complete → 7종 문서 일괄 생성"
echo "  5. 테스트 → PR"
echo ""
if [ -n "$KNOWLEDGE_REPO" ]; then
    echo "[문서 저장 위치] $KNOWLEDGE_REPO"
else
    echo "[주의] ~/.claude/.env에 CLAUDE_KNOWLEDGE_REPO가 설정되지 않았습니다."
fi
echo ""
echo "[참고] 유사 기능의 기존 코드를 먼저 분석한 후 개발을 시작하세요"
echo "</api-dev-guide-hook>"
echo ""

# 워크플로우 체크포인트 자동 기록
REPO=$(get_repo_name "$CWD")
"${SCRIPT_DIR}/lib/write-checkpoint.sh" "기능 개발 파이프라인" "기획문서 분석" 1 5 2>/dev/null

# JSONL 로그 기록
log_hook_execution "on-prompt-api-dev-guide.sh" "UserPromptSubmit" 0 "$HOOK_START_MS" "$REPO"

# 항상 비차단
exit 0
