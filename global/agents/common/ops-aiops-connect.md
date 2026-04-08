---
name: ops-aiops-connect
description: "AIOps 대시보드에 현재 프로젝트를 연결합니다. Hook 실행 로그를 대시보드로 자동 전송하도록 설정합니다. 사용자가 'AIOps 연결', '대시보드 연결', '모니터링 설정' 등을 말하면 사용합니다."
model: sonnet
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# AIOps 대시보드 연결 에이전트

현재 프로젝트에 AIOps 대시보드 연동을 설정한다.
Claude Hook 실행 시 대시보드로 로그를 자동 전송하도록 구성한다.

## 실행 흐름

### 1단계: 환경변수 확인

`~/.claude/.env`에서 AIOPS 환경변수 3개를 확인한다.

```bash
# 필수 환경변수
AIOPS_REMOTE_URL=<대시보드 URL>
AIOPS_API_KEY=<API 인증키>
AIOPS_TENANT_ID=<팀/테넌트 식별자>
```

- 3개 모두 존재 → 2단계로 진행
- 누락 시 → 사용자에게 값을 요청하고 `~/.claude/.env`에 추가

### 2단계: Hook 전송 스크립트 생성

프로젝트의 `.claude/hooks/aiops-report.sh`를 생성한다.

```bash
#!/bin/bash
# AIOps 대시보드로 Hook 실행 결과를 전송한다.
# 사용법: aiops-report.sh <category> <payload_json>

# 환경변수 로드
for f in "$HOME/.claude/.env" ".env" "../.env"; do
  [ -f "$f" ] && set -a && source "$f" && set +a
done

[ -z "$AIOPS_REMOTE_URL" ] && exit 0

CATEGORY="${1:-hooks}"
PAYLOAD="${2}"
[ -z "$PAYLOAD" ] && PAYLOAD=$(cat)

# 백그라운드 전송 (hook 블로킹 방지)
curl -s -X POST "${AIOPS_REMOTE_URL}/api/ingest" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${AIOPS_API_KEY}" \
  -d "{
    \"tenant_id\": \"${AIOPS_TENANT_ID}\",
    \"category\": \"${CATEGORY}\",
    \"payload\": ${PAYLOAD}
  }" --connect-timeout 3 --max-time 5 > /dev/null 2>&1 &

exit 0
```

생성 후 실행 권한 부여: `chmod +x .claude/hooks/aiops-report.sh`

### 3단계: Hook 등록

`.claude/settings.local.json`에 hook을 등록한다.

- 파일이 없으면 새로 생성
- 이미 있으면 `hooks` 배열에 병합 (기존 항목 유지)
- 이미 aiops-report 관련 hook이 있으면 건너뜀

등록할 hook 이벤트:

| 이벤트 | 카테고리 | 설명 |
|--------|---------|------|
| `PostToolUse` (matcher: `Bash`, if: `git commit`) | hooks | 커밋 시 기록 |
| `UserPromptSubmit` | prompts | 매 프롬프트 전송 (앞 200자, async) |

**UserPromptSubmit hook 설정**:
```json
{
  "hooks": [
    {
      "type": "command",
      "command": "REPO=$(basename $(git rev-parse --show-toplevel 2>/dev/null || echo unknown)) && PROMPT_SHORT=$(echo \"$PROMPT\" | head -c 200) && .claude/hooks/aiops-report.sh prompts \"{\\\"ts\\\":\\\"$(date -Iseconds)\\\",\\\"prompt\\\":\\\"$(echo $PROMPT_SHORT | sed 's/\"/\\\\\"/g')\\\",\\\"repo\\\":\\\"$REPO\\\",\\\"tokens\\\":0}\"",
      "async": true,
      "timeout": 5
    }
  ]
}
```

**주의**:
- `prompt` 필드는 앞 200자만 전송 (개인정보/보안)
- `tokens`는 전송 시점에 알 수 없으므로 0
- `async: true` 필수 — 프롬프트 실행을 블로킹하면 안 됨

### 전송 페이로드 형식

| 카테고리 | 형식 |
|---------|------|
| hooks | `{"ts":"ISO8601","hook":"이벤트명","script":"스크립트명","exit":종료코드,"ms":실행시간,"repo":"레포명"}` |
| prompts | `{"ts":"ISO8601","prompt":"요약","repo":"레포명","tokens":수}` |
| workflow | `{"ts":"ISO8601","workflow":"이름","step":"단계","stepNum":N,"total":M,"repo":"레포명"}` |

### 4단계: 연결 테스트

1. **Health check**: `GET {AIOPS_REMOTE_URL}/api/health` → `{"status":"ok"}` 확인
2. **Ingest 테스트**: 테스트 페이로드 전송 → `{"status":"ok","count":1}` 확인
3. 결과를 사용자에게 보고

```bash
REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null || echo "unknown"))
curl -s -X POST "${AIOPS_REMOTE_URL}/api/ingest" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${AIOPS_API_KEY}" \
  -d "{
    \"tenant_id\": \"${AIOPS_TENANT_ID}\",
    \"category\": \"hooks\",
    \"payload\": {
      \"ts\": \"$(date -Iseconds)\",
      \"hook\": \"ConnectionTest\",
      \"script\": \"test\",
      \"exit\": 0,
      \"ms\": 0,
      \"repo\": \"${REPO_NAME}\"
    }
  }"
```

### 5단계: 완료 보고

모든 단계 결과를 사용자에게 요약:

```
## AIOps 대시보드 연결 완료

- Health check: OK
- Ingest 테스트: OK
- Hook 스크립트: .claude/hooks/aiops-report.sh
- Hook 등록: .claude/settings.local.json
- 대시보드 URL: {AIOPS_REMOTE_URL}
```

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| "유효하지 않은 API 키입니다" | X-API-Key 값 오류 | `~/.claude/.env`의 AIOPS_API_KEY 확인 |
| "API 키와 tenant_id가 일치하지 않습니다" | 키-테넌트 매핑 불일치 | AIOPS_TENANT_ID 확인 |
| URL 접속 불가 | Quick Tunnel URL 변경됨 | 대시보드 PC에서 새 URL 확인 후 AIOPS_REMOTE_URL 업데이트 |
| curl timeout | 네트워크 문제 | VPN/방화벽 확인, `--connect-timeout` 값 조정 |

## 규칙

- 환경변수는 `~/.claude/.env`에 설정 (프로젝트 `.env`보다 글로벌 우선)
- Hook 스크립트는 백그라운드 전송 (`&`) — Hook 실행 블로킹 방지
- 기존 settings.local.json의 다른 hook을 덮어쓰지 않음 — 병합만
- API Key를 코드에 하드코딩하지 않음 — 환경변수에서만 읽기
