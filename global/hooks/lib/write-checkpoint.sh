#!/bin/bash
# ============================================================
# 워크플로우 체크포인트 기록
# 사용법: write-checkpoint.sh "워크플로우명" "단계명" 단계번호 전체단계수
# 예시: write-checkpoint.sh "API 개발 파이프라인" "기획문서 분석" 1 6
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/log-utils.sh"

WORKFLOW="${1:?워크플로우명 필수}"
STEP="${2:?단계명 필수}"
STEP_NUM="${3:?단계번호 필수}"
TOTAL="${4:?전체단계수 필수}"

REPO=$(get_repo_name)
TS=$(get_ts)
SESSION=$(get_session_id)

write_jsonl "workflow" "{\"ts\":\"${TS}\",\"workflow\":\"${WORKFLOW}\",\"step\":\"${STEP}\",\"stepNum\":${STEP_NUM},\"total\":${TOTAL},\"repo\":\"${REPO}\",\"session\":\"${SESSION}\"}"
