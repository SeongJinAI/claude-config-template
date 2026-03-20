#!/bin/bash

# Claude Code PreCompact Hook
# compact 실행 전 HANDOFF.md 작성을 알립니다.
#
# 이벤트: PreCompact
# 트리거: 수동(/compact) 또는 자동 compact 발생 전
# JSON 입력: session_id, transcript_path, trigger(manual|auto), custom_instructions

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/log-utils.sh"
HOOK_START_MS=$(get_ms)

# stdin에서 JSON 읽기
INPUT=$(cat)

# trigger 추출 (manual 또는 auto)
get_trigger() {
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r '.trigger // "unknown"'
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('trigger','unknown'))" 2>/dev/null
    else
        echo "unknown"
    fi
}

get_cwd() {
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r '.cwd // "."'
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd','.'))" 2>/dev/null
    else
        pwd
    fi
}

TRIGGER=$(get_trigger)
CWD=$(get_cwd)

echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

if [ "$TRIGGER" = "auto" ]; then
    echo "🔄 자동 Compact 감지! (컨텍스트 한계 도달)" >&2
else
    echo "📋 수동 Compact 감지!" >&2
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "" >&2

# 작업 디렉토리로 이동
cd "$CWD" 2>/dev/null || cd ~

# HANDOFF.md 존재 여부 및 최근 수정 여부 확인
check_handoff() {
    # 프로젝트 루트 찾기 (git root 또는 현재 디렉토리)
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$CWD")

    if [ -f "$PROJECT_ROOT/HANDOFF.md" ]; then
        # 마지막 수정 시간 확인
        LAST_MODIFIED=$(stat -c %Y "$PROJECT_ROOT/HANDOFF.md" 2>/dev/null || stat -f %m "$PROJECT_ROOT/HANDOFF.md" 2>/dev/null || echo 0)
        CURRENT_TIME=$(date +%s)
        DIFF=$((CURRENT_TIME - LAST_MODIFIED))

        # 10분(600초) 이내에 수정되었는지 확인
        if [ "$DIFF" -lt 600 ]; then
            echo "✅ HANDOFF.md 최근 업데이트됨 (${DIFF}초 전)" >&2
            echo "   위치: $PROJECT_ROOT/HANDOFF.md" >&2
        else
            MINUTES=$((DIFF / 60))
            echo "⚠️  HANDOFF.md가 ${MINUTES}분 전에 수정되었습니다!" >&2
            echo "" >&2
            echo "💡 Compact 전에 다음 내용을 HANDOFF.md에 업데이트하세요:" >&2
            echo "   - 완료된 작업" >&2
            echo "   - 다음 작업 (남은 할일)" >&2
            echo "   - 주의사항" >&2
            echo "   - 관련 파일 경로" >&2
            echo "" >&2
            echo "   위치: $PROJECT_ROOT/HANDOFF.md" >&2
        fi
    else
        echo "⚠️  HANDOFF.md가 존재하지 않습니다!" >&2
        echo "" >&2
        echo "💡 프로젝트 루트에 HANDOFF.md를 생성하세요:" >&2
        echo "   $PROJECT_ROOT/HANDOFF.md" >&2
    fi
}

check_handoff

echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "" >&2

# JSONL 로그 기록
REPO=$(get_repo_name "$CWD")
log_hook_execution "on-compact-handoff-save.sh" "PreCompact" 0 "$HOOK_START_MS" "$REPO"

# 항상 통과 (알림만, 차단하지 않음)
exit 0
