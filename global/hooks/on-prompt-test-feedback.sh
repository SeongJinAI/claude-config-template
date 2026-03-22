#!/bin/bash

# Claude Code UserPromptSubmit Hook — 테스트 결과 피드백 반영
# "테스트 결과 피드백 반영" 프롬프트 감지 시 최신 테스트 결과를 Claude 컨텍스트에 주입합니다.
#
# 이벤트: UserPromptSubmit
# 트리거: 프롬프트에 "테스트 결과 피드백 반영" 키워드 감지
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

PROMPT=$(get_prompt)
CWD=$(get_cwd)

# ─── 가드 조건 1: 키워드 매칭 ───
if ! echo "$PROMPT" | grep -q "테스트 결과 피드백 반영"; then
    exit 0
fi

# 키워드 매칭됨

# ─── 가드 조건 2: 프로젝트 확인 ───
cd "$CWD" 2>/dev/null || exit 0

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$PROJECT_ROOT" ]; then
    exit 0
fi

# ─── 테스트 결과 경로 결정 ───
# 우선순위: 1) CLAUDE_TEST_REPO 환경변수, 2) ~/.claude/.env, 3) {프로젝트}-test 폴백
_resolve_test_repo() {
    if [ -n "$CLAUDE_TEST_REPO" ]; then
        echo "$CLAUDE_TEST_REPO"
        return
    fi
    local env_file="$HOME/.claude/.env"
    if [ -f "$env_file" ]; then
        local dir=$(grep "^CLAUDE_TEST_REPO=" "$env_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [ -n "$dir" ]; then
            echo "$dir"
            return
        fi
    fi
    echo "${PROJECT_ROOT}-test"
}

TEST_REPO=$(_resolve_test_repo)
TEST_RESULTS_DIR="${TEST_REPO}/results/local"

if [ ! -d "$TEST_RESULTS_DIR" ]; then
    echo ""
    echo "<test-feedback-hook>"
    echo "ERROR: 테스트 결과 디렉토리를 찾을 수 없습니다."
    echo "경로: $TEST_RESULTS_DIR"
    echo "~/.claude/.env에 CLAUDE_TEST_REPO 경로를 설정하세요."
    echo "</test-feedback-hook>"
    echo ""
    exit 0
fi

# ─── 최신 날짜 디렉토리 찾기 ───
LATEST_DATE_DIR=$(find "$TEST_RESULTS_DIR" -maxdepth 1 -type d -name "2*" | sort -r | head -1)

if [ -z "$LATEST_DATE_DIR" ]; then
    echo ""
    echo "<test-feedback-hook>"
    echo "ERROR: 테스트 결과 파일이 없습니다."
    echo "경로: $TEST_RESULTS_DIR"
    echo "</test-feedback-hook>"
    echo ""
    exit 0
fi

DATE_NAME=$(basename "$LATEST_DATE_DIR")

# ─── 테스트 결과 파일 수집 ───
MD_FILES=$(find "$LATEST_DATE_DIR" -maxdepth 1 -name "*.md" -type f | sort)
FILE_COUNT=$(echo "$MD_FILES" | grep -c "." 2>/dev/null || echo 0)

if [ "$FILE_COUNT" -eq 0 ]; then
    echo ""
    echo "<test-feedback-hook>"
    echo "ERROR: $DATE_NAME 디렉토리에 .md 테스트 결과 파일이 없습니다."
    echo "</test-feedback-hook>"
    echo ""
    exit 0
fi

# 테스트 결과 로드됨

# ─── stdout 출력: Claude 컨텍스트에 주입 ───
echo ""
echo "<test-feedback-hook>"
echo "TEST_FEEDBACK_MODE: true"
echo "RESULTS_DATE: $DATE_NAME"
echo "FILE_COUNT: $FILE_COUNT"
echo ""
echo "== 테스트 결과 피드백 반영 모드 =="
echo ""
echo "아래 테스트 결과를 분석하여 다음 순서로 진행하세요:"
echo ""
echo "  1. 각 테스트 파일의 '발견된 이슈' 및 '실패' 항목을 식별"
echo "  2. '사용자 관점 피드백' 섹션의 개선 제안을 검토"
echo "  3. 수정이 필요한 항목을 우선순위별로 정리"
echo "  4. 수정 계획을 사용자에게 먼저 제시 (plan 모드 진입)"
echo "  5. 사용자 승인 후 코드 수정 진행"
echo ""
echo "중요: 코드 수정 전 반드시 계획을 먼저 보여주고 승인을 받으세요."
echo ""

# ─── 테스트 결과 파일 내용 주입 ───
echo "$MD_FILES" | while read -r file; do
    if [ -f "$file" ]; then
        FILENAME=$(basename "$file")
        echo "================================================================"
        echo "FILE: $FILENAME"
        echo "================================================================"
        cat "$file"
        echo ""
    fi
done

echo "</test-feedback-hook>"
echo ""

# JSONL 로그 기록
REPO=$(get_repo_name "$CWD")
log_hook_execution "on-prompt-test-feedback.sh" "UserPromptSubmit" 0 "$HOOK_START_MS" "$REPO"

# 항상 비차단
exit 0
