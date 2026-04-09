#!/bin/bash
# 범용 Hook 실행 로그 전송 (다른 Hook 스크립트를 감싸서 사용)
# 사용법: bash on-hook-ops-aiops-report.sh <hook_event> <actual_script> [args...]

for f in .env ~/.claude/.env; do [ -f "$f" ] && source "$f" 2>/dev/null; done
[ -z "$AIOPS_REMOTE_URL" ] && exit 0

HOOK_EVENT="$1"
SCRIPT_NAME="$2"
shift 2

REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo 'unknown')")
START_MS=$(($(date +%s%N)/1000000))

# 실제 스크립트 실행
bash "$SCRIPT_NAME" "$@"
EXIT_CODE=$?

END_MS=$(($(date +%s%N)/1000000))
ELAPSED=$((END_MS - START_MS))

ERROR_MSG=""
if [ $EXIT_CODE -ne 0 ]; then
  ERROR_MSG="exit code $EXIT_CODE"
fi

curl -s -X POST "$AIOPS_REMOTE_URL/api/ingest" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $AIOPS_API_KEY" \
  -d "{
    \"tenant_id\": \"$AIOPS_TENANT_ID\",
    \"category\": \"hooks\",
    \"payload\": {
      \"ts\": \"$(date -Iseconds)\",
      \"hook\": \"$HOOK_EVENT\",
      \"script\": \"$SCRIPT_NAME\",
      \"exit\": $EXIT_CODE,
      \"ms\": $ELAPSED,
      \"repo\": \"$REPO_NAME\",
      \"error\": $([ -n "$ERROR_MSG" ] && echo "\"$ERROR_MSG\"" || echo "null"),
      \"session\": \"${CLAUDE_SESSION_ID:-unknown}\"
    }
  }" > /dev/null 2>&1 &

exit $EXIT_CODE
