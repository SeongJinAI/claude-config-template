#!/bin/bash

# Claude Code UserPromptSubmit Hook — 요구사항 오해 감지
# 사용자의 교정/거부/재시도 패턴을 감지하여 JSONL에 기록합니다.
#
# 이벤트: UserPromptSubmit
# 트리거: 교정 키워드 감지 시
# 출력: 없음 (로깅만)
# 차단: 비차단 (항상 exit 0)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/log-utils.sh"

HOOK_START_MS=$(get_ms)

# stdin에서 JSON 읽기
INPUT=$(cat)

PROMPT=$(get_json_field "$INPUT" "prompt")
CWD=$(get_json_field "$INPUT" "cwd")
export _HOOK_CWD="$CWD"
SESSION=$(get_session_id)

# 빈 프롬프트 무시
[ -z "$PROMPT" ] && exit 0

# 시스템 명령 무시
echo "$PROMPT" | grep -qE "^/" && exit 0

# ─── 캐시 파일 (이전 프롬프트 저장) ───
CACHE_FILE="/tmp/.claude-last-prompt-${SESSION:-default}"
PREV_PROMPT=""
if [ -f "$CACHE_FILE" ]; then
    PREV_PROMPT=$(cat "$CACHE_FILE" 2>/dev/null)
fi

# ─── 패턴 매칭 ───
# 패턴은 환경변수로 커스텀 가능 (파이프 구분)
# 기본값은 한국어 + 영어 혼합
PATTERN=""
MATCHED_KEYWORDS=""

# rejection 패턴 (명확한 거부)
REJECTION_PATTERN="${CLAUDE_REJECT_PATTERN:-아니야|아니 그게|그게 아니라|아닌데|그거 아니고|아니요|그건 아닌데|no not that|that's not what|wrong}"
if echo "$PROMPT" | grep -qiE "$REJECTION_PATTERN"; then
    PATTERN="rejection"
    MATCHED_KEYWORDS=$(echo "$PROMPT" | grep -oiE "$REJECTION_PATTERN" | tr '\n' ',' | sed 's/,$//')
fi

# correction 패턴 (수정 요청)
if [ -z "$PATTERN" ]; then
    CORRECTION_PATTERN="${CLAUDE_CORRECT_PATTERN:-다시 해봐|다시 해줘|수정해줘|고쳐줘|잘못했어|틀렸어|잘못됐|틀린|제대로|건드리지마|건드리지 마|fix that|redo|try again|that's wrong}"
    if echo "$PROMPT" | grep -qiE "$CORRECTION_PATTERN"; then
        PATTERN="correction"
        MATCHED_KEYWORDS=$(echo "$PROMPT" | grep -oiE "$CORRECTION_PATTERN" | tr '\n' ',' | sed 's/,$//')
    fi
fi

# retry 패턴 (재시도 요청)
if [ -z "$PATTERN" ]; then
    RETRY_PATTERN="${CLAUDE_RETRY_PATTERN:-처음부터|원래대로|되돌려|롤백|취소해|되돌려줘|원복|start over|revert|rollback|undo}"
    if echo "$PROMPT" | grep -qiE "$RETRY_PATTERN"; then
        PATTERN="retry"
        MATCHED_KEYWORDS=$(echo "$PROMPT" | grep -oiE "$RETRY_PATTERN" | tr '\n' ',' | sed 's/,$//')
    fi
fi

# ─── 매칭 시 JSONL 기록 ───
if [ -n "$PATTERN" ]; then
    REPO=$(get_repo_name "$CWD")
    TS=$(get_ts)

    # JSON 이스케이프
    PROMPT_ESC=$(echo "$PROMPT" | tr '\n' ' ' | sed 's/"/\\"/g')
    PREV_ESC=$(echo "$PREV_PROMPT" | tr '\n' ' ' | sed 's/"/\\"/g')
    KEYWORDS_JSON=$(echo "$MATCHED_KEYWORDS" | sed 's/,/","/g')

    JSON="{\"ts\":\"${TS}\",\"prompt\":\"${PROMPT_ESC}\",\"prev_prompt\":\"${PREV_ESC}\",\"pattern\":\"${PATTERN}\",\"keywords\":[\"${KEYWORDS_JSON}\"],\"repo\":\"${REPO}\",\"session\":\"${SESSION}\"}"

    write_jsonl "misunderstandings" "$JSON"

    # Hook 실행 로그
    log_hook_execution "on-prompt-misunderstanding-detect.sh" "UserPromptSubmit" 0 "$HOOK_START_MS" "$REPO"
fi

# ─── 항상 현재 프롬프트를 캐시에 저장 ───
echo "$PROMPT" > "$CACHE_FILE"

# 오래된 캐시 정리 (7일 이상)
find /tmp -name ".claude-last-prompt-*" -mtime +7 -delete 2>/dev/null

exit 0
