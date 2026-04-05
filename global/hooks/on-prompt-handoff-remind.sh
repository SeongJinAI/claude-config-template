#!/bin/bash

# Claude Code UserPromptSubmit Hook
# /clear 또는 /compact 명령 감지 시 HANDOFF 작성을 Claude에게 지시합니다.
# 멀티 세션(handoff/ 디렉토리) 및 레거시(HANDOFF.md) 모두 지원
#
# 이벤트: UserPromptSubmit
# 트리거: 사용자 프롬프트 제출 시
# 출력: stdout → Claude 컨텍스트에 주입됨

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/log-utils.sh"
HOOK_START_MS=$(get_ms)

# stdin에서 JSON 읽기
INPUT=$(cat)

# prompt 추출
get_prompt() {
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r '.prompt // ""'
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null
    else
        echo "$INPUT" | grep -oP '"prompt":\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
    fi
}

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

# /clear 또는 /compact 명령인지 확인
if echo "$PROMPT" | grep -qE "^/(clear|compact)"; then
    # 작업 디렉토리로 이동
    cd "$CWD" 2>/dev/null || cd ~

    # 프로젝트 루트 찾기
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$CWD")
    HANDOFF_THRESHOLD="${CLAUDE_HANDOFF_THRESHOLD:-600}"

    # 명령어 종류 확인
    if echo "$PROMPT" | grep -qE "^/compact"; then
        COMMAND_TYPE="compact"
    else
        COMMAND_TYPE="clear"
    fi

    # handoff 디렉토리 vs 레거시 HANDOFF.md 분기
    HANDOFF_DIR="$PROJECT_ROOT/handoff"
    HANDOFF_FILENAME="${CLAUDE_HANDOFF_FILE:-HANDOFF.md}"
    HANDOFF_PATH="$PROJECT_ROOT/$HANDOFF_FILENAME"

    NEEDS_UPDATE="false"

    if [ -d "$HANDOFF_DIR" ]; then
        # 멀티 세션 모드: handoff/ 디렉토리 내 최신 mtime 체크
        LATEST_MTIME=0
        for f in "$HANDOFF_DIR"/*.md; do
            [ -f "$f" ] || continue
            FMTIME=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || echo 0)
            [ "$FMTIME" -gt "$LATEST_MTIME" ] && LATEST_MTIME=$FMTIME
        done

        CURRENT_TIME=$(date +%s)
        DIFF=$((CURRENT_TIME - LATEST_MTIME))

        if [ "$DIFF" -ge "$HANDOFF_THRESHOLD" ]; then
            NEEDS_UPDATE="true"
            MINUTES=$((DIFF / 60))
        fi

        if [ "$NEEDS_UPDATE" = "true" ]; then
            echo ""
            echo "<user-prompt-submit-hook>"
            echo "HANDOFF_UPDATE_REQUIRED: true"
            echo "COMMAND: /$COMMAND_TYPE"
            echo "HANDOFF_DIR: $HANDOFF_DIR"
            echo "LAST_MODIFIED: ${MINUTES}분 전"
            echo ""
            echo "지시사항: /$COMMAND_TYPE 명령 실행 전에 해당 세션의 handoff 파일을 업데이트하세요."
            echo "세션 목록: handoff/INDEX.md 참조"
            echo "포함할 내용:"
            echo "  - 완료된 작업"
            echo "  - 다음 작업 (남은 할일)"
            echo "  - 주의사항"
            echo "  - 관련 파일 경로"
            echo "</user-prompt-submit-hook>"
            echo ""
        fi
    elif [ -f "$HANDOFF_PATH" ]; then
        # 레거시 모드: 단일 HANDOFF.md
        LAST_MODIFIED=$(stat -c %Y "$HANDOFF_PATH" 2>/dev/null || stat -f %m "$HANDOFF_PATH" 2>/dev/null || echo 0)
        CURRENT_TIME=$(date +%s)
        DIFF=$((CURRENT_TIME - LAST_MODIFIED))

        if [ "$DIFF" -ge "$HANDOFF_THRESHOLD" ]; then
            NEEDS_UPDATE="true"
            MINUTES=$((DIFF / 60))
        fi

        if [ "$NEEDS_UPDATE" = "true" ]; then
            echo ""
            echo "<user-prompt-submit-hook>"
            echo "HANDOFF_UPDATE_REQUIRED: true"
            echo "COMMAND: /$COMMAND_TYPE"
            echo "HANDOFF_PATH: $HANDOFF_PATH"
            echo "LAST_MODIFIED: ${MINUTES}분 전"
            echo ""
            echo "지시사항: /$COMMAND_TYPE 명령 실행 전에 $HANDOFF_FILENAME 를 업데이트하세요."
            echo "포함할 내용:"
            echo "  - 완료된 작업"
            echo "  - 다음 작업 (남은 할일)"
            echo "  - 주의사항"
            echo "  - 관련 파일 경로"
            echo "</user-prompt-submit-hook>"
            echo ""
        fi
    fi
fi

# JSONL 로그 기록
CWD_FOR_LOG=$(get_json_field "$INPUT" "cwd")
REPO=$(get_repo_name "$CWD_FOR_LOG")
log_hook_execution "on-prompt-handoff-remind.sh" "UserPromptSubmit" 0 "$HOOK_START_MS" "$REPO"

# 항상 통과
exit 0
