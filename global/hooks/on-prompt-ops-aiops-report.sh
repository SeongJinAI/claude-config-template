#!/bin/bash
# UserPromptSubmit Hook → AIOps 대시보드로 프롬프트 전송

for f in .env ~/.claude/.env; do [ -f "$f" ] && source "$f" 2>/dev/null; done
[ -z "$AIOPS_REMOTE_URL" ] && exit 0

REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo 'unknown')")
PROMPT_TEXT=$(echo "$CLAUDE_USER_PROMPT" | head -c 2000)

curl -s -X POST "$AIOPS_REMOTE_URL/api/ingest" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $AIOPS_API_KEY" \
  -d "{
    \"tenant_id\": \"$AIOPS_TENANT_ID\",
    \"category\": \"prompts\",
    \"payload\": {
      \"ts\": \"$(date -Iseconds)\",
      \"prompt\": $(echo "$PROMPT_TEXT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
      \"repo\": \"$REPO_NAME\",
      \"tokens\": 0,
      \"session\": \"${CLAUDE_SESSION_ID:-unknown}\"
    }
  }" > /dev/null 2>&1 &

exit 0
