#!/bin/bash
# ============================================================
# 공통 JSONL 로깅 유틸리티
# 모든 Hook에서 source하여 대시보드용 JSONL 로그를 기록한다.
# ============================================================

# LOG_DIR 결정: 환경변수 > ~/.claude/.env > 기본값
_resolve_log_dir() {
    if [ -n "$CLAUDE_LOG_DIR" ]; then
        echo "$CLAUDE_LOG_DIR"
        return
    fi

    # ~/.claude/.env에서 LOG_DIR 읽기
    local env_file="$HOME/.claude/.env"
    if [ -f "$env_file" ]; then
        local dir=$(grep "^CLAUDE_LOG_DIR=" "$env_file" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [ -n "$dir" ]; then
            echo "$dir"
            return
        fi
    fi

    echo "$HOME/.claude/logs"
}

# JSONL 한 줄 append (로컬 파일 + 원격 API 듀얼모드)
# 사용법: write_jsonl "hooks" '{"ts":"...","hook":"..."}'
#
# 환경변수:
#   AIOPS_REMOTE_URL  — 원격 대시보드 URL (예: https://dashboard.example.com)
#   AIOPS_API_KEY     — 원격 API 인증 키
#   AIOPS_TENANT_ID   — 테넌트 ID (미설정 시 레포명 사용)
write_jsonl() {
    local category="$1"  # hooks | prompts | workflow | misunderstandings
    local json_line="$2"

    # 1) 항상 로컬 파일에 먼저 쓴다 (기존 동작 100% 유지)
    local log_dir="$(_resolve_log_dir)"
    local date_str=$(date +%Y-%m-%d)
    local target_dir="${log_dir}/${category}"

    mkdir -p "$target_dir" 2>/dev/null
    echo "$json_line" >> "${target_dir}/${date_str}.jsonl"

    # 2) 원격 설정이 있으면 HTTP POST (fire-and-forget, 백그라운드)
    if [ -n "$AIOPS_REMOTE_URL" ] && [ -n "$AIOPS_API_KEY" ] && command -v curl &>/dev/null; then
        local tenant_id="${AIOPS_TENANT_ID:-$(get_repo_name)}"
        curl -s -X POST "${AIOPS_REMOTE_URL}/api/ingest" \
            -H "Content-Type: application/json" \
            -H "X-API-Key: ${AIOPS_API_KEY}" \
            -d "{\"tenant_id\":\"${tenant_id}\",\"category\":\"${category}\",\"payload\":${json_line}}" \
            --connect-timeout 2 --max-time 5 \
            > /dev/null 2>&1 &
    fi
}

# ISO 타임스탬프
get_ts() {
    date +%Y-%m-%dT%H:%M:%S
}

# 밀리초 타임스탬프 (경과 시간 측정용)
get_ms() {
    if date +%s%3N 2>/dev/null | grep -qE '^[0-9]+$'; then
        date +%s%3N
    else
        # %3N 미지원 시 초 단위 × 1000
        echo $(( $(date +%s) * 1000 ))
    fi
}

# 프로젝트 이름 추출 (git 루트 또는 디렉토리명)
get_repo_name() {
    local cwd="${1:-$(pwd)}"
    local root
    root=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || root="$cwd"
    basename "$root"
}

# 세션 ID
get_session_id() {
    echo "${CLAUDE_SESSION_ID:-unknown}"
}

# JSON 필드 추출 (jq > python3 > grep 폴백)
get_json_field() {
    local json="$1"
    local field="$2"

    if command -v jq &>/dev/null; then
        echo "$json" | jq -r ".$field // empty" 2>/dev/null
    elif command -v python3 &>/dev/null; then
        echo "$json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
keys = '${field}'.split('.')
for k in keys:
    if isinstance(d, dict):
        d = d.get(k, '')
    else:
        d = ''
        break
print(d if d else '')
" 2>/dev/null
    else
        echo "$json" | grep -oP "\"${field}\"\\s*:\\s*\"[^\"]*\"" | head -1 | sed 's/.*"\\([^"]*\\)"$/\\1/'
    fi
}

# Hook 실행 로그 JSONL 기록
# 사용법: log_hook_execution "스크립트명" "이벤트타입" exit_code start_ms "repo명" ["에러메시지"]
log_hook_execution() {
    local script_name="$1"
    local event_type="$2"
    local exit_code="$3"
    local start_ms="$4"
    local repo="$5"
    local error_msg="${6:-}"

    local end_ms=$(get_ms)
    local elapsed=$(( end_ms - start_ms ))
    # 음수 방지
    [ "$elapsed" -lt 0 ] && elapsed=0
    local ts=$(get_ts)
    local session=$(get_session_id)

    local json="{\"ts\":\"${ts}\",\"hook\":\"${event_type}\",\"script\":\"${script_name}\",\"exit\":${exit_code},\"ms\":${elapsed},\"repo\":\"${repo}\",\"session\":\"${session}\""

    if [ -n "$error_msg" ]; then
        # 에러 메시지의 따옴표/줄바꿈 이스케이프
        error_msg=$(echo "$error_msg" | tr '\n' ' ' | sed 's/"/\\"/g')
        json="${json},\"error\":\"${error_msg}\""
    fi
    json="${json}}"

    write_jsonl "hooks" "$json"
}
