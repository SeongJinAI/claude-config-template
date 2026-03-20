#!/bin/bash

# Claude 거버넌스 설치 스크립트
# global/ 디렉토리의 내용을 ~/.claude/에 설치한다.
#
# 사용법:
#   로컬 (심볼릭 링크): ./install.sh --link [레포경로]
#   원격 (다운로드):     curl -fsSL https://raw.githubusercontent.com/[YOUR_ID]/claude-config-template/main/install.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/[YOUR_ID]/claude-config-template/main"
CLAUDE_DIR="$HOME/.claude"

# global/ 안에서 ~/.claude/로 심볼릭 링크할 대상 목록
LINK_TARGETS=(
    "settings.json"
    "CLAUDE.md"
    "commands"
    "rules"
    "hooks"
)

# ─── 심볼릭 링크 모드 (로컬 개발용) ───
if [ "$1" = "--link" ]; then
    DOTFILES_DIR="${2:-.}"
    DOTFILES_DIR=$(cd "$DOTFILES_DIR" && pwd)
    GLOBAL_DIR="$DOTFILES_DIR/global"

    if [ ! -d "$GLOBAL_DIR" ]; then
        echo "오류: $GLOBAL_DIR 디렉토리가 없습니다."
        exit 1
    fi

    echo "심볼릭 링크 모드: $GLOBAL_DIR → $CLAUDE_DIR"
    echo ""

    mkdir -p "$CLAUDE_DIR"

    for target in "${LINK_TARGETS[@]}"; do
        SOURCE="$GLOBAL_DIR/$target"
        DEST="$CLAUDE_DIR/$target"

        # 소스 존재 확인
        if [ ! -e "$SOURCE" ]; then
            echo "  건너뜀: $target (소스 없음)"
            continue
        fi

        # 기존 대상 처리
        if [ -L "$DEST" ]; then
            rm "$DEST"
        elif [ -e "$DEST" ]; then
            mv "$DEST" "${DEST}.backup"
            echo "  백업: $target → ${target}.backup"
        fi

        ln -s "$SOURCE" "$DEST"
        echo "  연결: ~/.claude/$target → global/$target"
    done

    echo ""
    echo "설치 완료. 연결 상태:"
    echo ""

    # hooks 확인
    echo "  hooks/"
    for f in "$CLAUDE_DIR/hooks/"on-*.sh; do
        [ -f "$f" ] && echo "    $(basename "$f")"
    done

    # commands 확인
    echo "  commands/"
    for f in "$CLAUDE_DIR/commands/"*.md; do
        [ -f "$f" ] && echo "    $(basename "$f")"
    done

    # rules 확인
    echo "  rules/"
    for f in "$CLAUDE_DIR/rules/"*.md; do
        [ -f "$f" ] && echo "    $(basename "$f")"
    done

    echo ""
    echo "프로젝트 템플릿 적용은 별도로 실행:"
    echo "  ./scripts/init-project.sh spring-boot|fastapi|nextjs"

    exit 0
fi

# ─── 다운로드 모드 (원격 설치용) ───
echo "Claude 거버넌스 설치 시작..."

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/rules"
mkdir -p "$CLAUDE_DIR/hooks/lib"

# settings.json
echo "settings.json 다운로드..."
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup"
fi
curl -fsSL "$REPO_URL/global/settings.json" -o "$CLAUDE_DIR/settings.json"

# CLAUDE.md
echo "CLAUDE.md 다운로드..."
curl -fsSL "$REPO_URL/global/CLAUDE.md" -o "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || true

# commands
echo "commands/ 다운로드..."
for f in clear gen-spec verify-docs feedback-to-pr project-chat; do
    curl -fsSL "$REPO_URL/global/commands/${f}.md" -o "$CLAUDE_DIR/commands/${f}.md" 2>/dev/null || true
done

# rules
echo "rules/ 다운로드..."
for f in 예외처리_원칙 코드리뷰_원칙 개발워크플로_원칙; do
    curl -fsSL "$REPO_URL/global/rules/${f}.md" -o "$CLAUDE_DIR/rules/${f}.md" 2>/dev/null || true
done

# hooks
echo "hooks/ 다운로드..."
for f in on-commit-quality-check on-commit-doc-sync-check on-push-signature-check \
         on-compact-handoff-save on-prompt-handoff-remind on-prompt-api-dev-guide \
         on-prompt-test-feedback on-prompt-log; do
    curl -fsSL "$REPO_URL/global/hooks/${f}.sh" -o "$CLAUDE_DIR/hooks/${f}.sh" 2>/dev/null || true
done
for f in log-utils write-checkpoint; do
    curl -fsSL "$REPO_URL/global/hooks/lib/${f}.sh" -o "$CLAUDE_DIR/hooks/lib/${f}.sh" 2>/dev/null || true
done
chmod +x "$CLAUDE_DIR/hooks/"*.sh "$CLAUDE_DIR/hooks/lib/"*.sh 2>/dev/null || true

echo ""
echo "설치 완료!"
echo ""
echo "설치된 항목:"
echo "  ~/.claude/settings.json"
echo "  ~/.claude/CLAUDE.md"
echo "  ~/.claude/commands/ (5개)"
echo "  ~/.claude/rules/ (3개)"
echo "  ~/.claude/hooks/ (8개 + lib 2개)"
echo ""
echo "프로젝트 템플릿 적용:"
echo "  curl -fsSL $REPO_URL/scripts/init-project.sh | bash -s spring-boot"
