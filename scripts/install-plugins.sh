#!/bin/bash

# Claude Code 플러그인 & 외부 스킬 설치 스크립트
# 사용법: ./scripts/install-plugins.sh [--global|--project]
#
# --global:  전역 설치 (모든 프로젝트에 적용)
# --project: 현재 프로젝트에만 설치
# 기본값: --global

set -e

SCOPE="${1:---global}"

echo "Claude Code 플러그인 & 외부 스킬 설치"
echo "스코프: $SCOPE"
echo ""

# ─── 1. Claude Code 내장 플러그인 (settings.json으로 관리) ───
echo "=== 내장 플러그인 ==="
echo "  code-review@claude-plugins-official  → settings.json의 enabledPlugins로 자동 활성화"
echo "  feature-dev@claude-plugins-official   → 프로젝트별 .claude/settings.local.json에서 활성화"
echo ""

# ─── 2. 외부 스킬 (npx skills) ───
echo "=== 외부 스킬 설치 ==="

# npx 존재 확인
if ! command -v npx &> /dev/null; then
    echo "오류: npx를 찾을 수 없습니다. Node.js를 먼저 설치하세요."
    exit 1
fi

# 설치할 외부 스킬 목록
# 형식: "레포URL|스킬명|설명"
SKILLS=(
    "https://github.com/vercel-labs/skills|find-skills|스킬 검색/설치 도우미"
    "https://github.com/forrestchang/andrej-karpathy-skills|karpathy-guidelines|LLM 코딩 가이드라인"
)

GLOBAL_FLAG=""
if [ "$SCOPE" = "--global" ]; then
    GLOBAL_FLAG="-g"
fi

for skill_entry in "${SKILLS[@]}"; do
    IFS='|' read -r repo name desc <<< "$skill_entry"
    echo "  설치: $name ($desc)"
    echo "    npx skills add $repo --skill $name $GLOBAL_FLAG -y"
    npx skills add "$repo" --skill "$name" $GLOBAL_FLAG -y 2>/dev/null || {
        echo "    경고: $name 설치 실패 (수동 설치 필요)"
    }
done

echo ""
echo "=== 설치 완료 ==="
echo ""
echo "내장 플러그인 상태 확인:"
echo "  Claude Code에서 /plugins 명령어 실행"
echo ""
echo "외부 스킬 상태 확인:"
echo "  npx skills check"
echo ""

# ─── 3. 프로젝트별 플러그인 (feature-dev) 안내 ───
if [ "$SCOPE" = "--project" ]; then
    echo "=== 프로젝트별 추가 설정 ==="
    echo ""
    echo "feature-dev 플러그인을 이 프로젝트에 활성화하려면:"
    echo "  .claude/settings.local.json에 다음을 추가하세요:"
    echo '  {'
    echo '    "enabledPlugins": {'
    echo '      "feature-dev@claude-plugins-official": true'
    echo '    }'
    echo '  }'
fi
