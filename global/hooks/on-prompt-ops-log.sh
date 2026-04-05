#!/bin/bash
# ============================================================
# 프롬프트 로깅 전용 Hook
# 모든 사용자 프롬프트를 JSONL로 기록한다.
#
# 이벤트: UserPromptSubmit
# 출력: 없음 (로깅만, Claude 컨텍스트 주입 없음)
# 차단: 비차단 (항상 exit 0)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/log-utils.sh"

HOOK_START_MS=$(get_ms)

# stdin에서 JSON 읽기
INPUT=$(cat)

PROMPT=$(get_json_field "$INPUT" "prompt")
CWD=$(get_json_field "$INPUT" "cwd")

# 빈 프롬프트 무시
[ -z "$PROMPT" ] && exit 0

REPO=$(get_repo_name "$CWD")
TS=$(get_ts)
SESSION=$(get_session_id)

# 프롬프트 JSON 이스케이프 (python3 사용, 없으면 간단한 치환)
if command -v python3 &>/dev/null; then
    PROMPT_ESCAPED=$(echo "$PROMPT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip(), ensure_ascii=False))" 2>/dev/null)
else
    # 기본 이스케이프: 따옴표, 백슬래시, 줄바꿈
    PROMPT_ESCAPED=$(echo "$PROMPT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
    PROMPT_ESCAPED="\"${PROMPT_ESCAPED}\""
fi

# 토큰 수 근사치 (공백 기준 단어 수 × 1.3)
WORD_COUNT=$(echo "$PROMPT" | wc -w | tr -d ' ')
TOKENS=$(( WORD_COUNT * 13 / 10 ))
[ "$TOKENS" -lt 1 ] && TOKENS=1

write_jsonl "prompts" "{\"ts\":\"${TS}\",\"prompt\":${PROMPT_ESCAPED},\"repo\":\"${REPO}\",\"tokens\":${TOKENS},\"session\":\"${SESSION}\"}"

# Hook 실행 자체도 hooks 로그에 기록
log_hook_execution "on-prompt-log.sh" "UserPromptSubmit" 0 "$HOOK_START_MS" "$REPO"

exit 0
