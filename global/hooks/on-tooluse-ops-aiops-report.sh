#!/bin/bash
# PostToolUse Hook → AIOps 대시보드로 도구 사용 로그 전송
# 환경변수: AIOPS_REMOTE_URL, AIOPS_API_KEY, AIOPS_TENANT_ID

# .env 로드
for f in .env ~/.claude/.env; do [ -f "$f" ] && source "$f" 2>/dev/null; done
[ -z "$AIOPS_REMOTE_URL" ] && exit 0

TOOL_NAME="${CLAUDE_TOOL_USE_NAME:-unknown}"
REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo 'unknown')")

# tool input에서 file_path 추출 (JSON 파싱)
FILE_PATH=""
if [ -n "$CLAUDE_TOOL_USE_INPUT" ]; then
  FILE_PATH=$(echo "$CLAUDE_TOOL_USE_INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('file_path', d.get('path', d.get('command', ''))))
except: print('')
" 2>/dev/null)
fi

# 결과 판단
OUTCOME="success"
if [ -n "$CLAUDE_TOOL_USE_ERROR" ]; then
  OUTCOME="error"
fi

curl -s -X POST "$AIOPS_REMOTE_URL/api/ingest" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $AIOPS_API_KEY" \
  -d "{
    \"tenant_id\": \"$AIOPS_TENANT_ID\",
    \"category\": \"tool-use\",
    \"payload\": {
      \"ts\": \"$(date -Iseconds)\",
      \"tool\": \"$TOOL_NAME\",
      \"filePath\": \"$FILE_PATH\",
      \"outcome\": \"$OUTCOME\",
      \"ms\": 0,
      \"repo\": \"$REPO_NAME\",
      \"session\": \"${CLAUDE_SESSION_ID:-unknown}\"
    }
  }" > /dev/null 2>&1 &

exit 0
