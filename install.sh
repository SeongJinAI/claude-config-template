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
    "skills"
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

    # 기존 commands 심볼릭 링크가 남아있으면 제거
    if [ -L "$CLAUDE_DIR/commands" ]; then
        rm "$CLAUDE_DIR/commands"
        echo "  정리: 기존 commands 심볼릭 링크 제거"
    fi

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

    # skills 확인
    echo "  skills/"
    for d in "$CLAUDE_DIR/skills/"*/; do
        [ -d "$d" ] && echo "    $(basename "$d")/"
    done

    # rules 확인
    echo "  rules/"
    for f in "$CLAUDE_DIR/rules/"*.md; do
        [ -f "$f" ] && echo "    $(basename "$f")"
    done

    # ─── .env 설정 (환경변수) ───
    ENV_FILE="$CLAUDE_DIR/.env"
    echo ""

    if [ -f "$ENV_FILE" ]; then
        echo "기존 ~/.claude/.env 발견:"
        cat "$ENV_FILE"
        echo ""
        read -rp ".env를 다시 설정하시겠습니까? (y/N): " RESET_ENV
        if [ "$RESET_ENV" != "y" ] && [ "$RESET_ENV" != "Y" ]; then
            echo "  .env 유지"
            echo ""
            echo "프로젝트 템플릿 적용은 별도로 실행:"
            echo "  ./scripts/init-project.sh spring-boot|fastapi|nextjs"
            exit 0
        fi
    fi

    echo "환경변수를 설정합니다. (빈 입력 시 기본값 사용)"
    echo ""

    # 로그 디렉토리
    DEFAULT_LOG_DIR="$HOME/.claude/logs"
    read -rp "CLAUDE_LOG_DIR (Hook 로그 저장 경로) [$DEFAULT_LOG_DIR]: " INPUT_LOG_DIR
    LOG_DIR="${INPUT_LOG_DIR:-$DEFAULT_LOG_DIR}"

    # 테스트 레포
    read -rp "CLAUDE_TEST_REPO (테스트 레포 절대경로) []: " INPUT_TEST_REPO
    TEST_REPO="${INPUT_TEST_REPO:-}"

    # 지식 레포
    read -rp "CLAUDE_KNOWLEDGE_REPO (지식 레포 절대경로) []: " INPUT_KNOWLEDGE_REPO
    KNOWLEDGE_REPO="${INPUT_KNOWLEDGE_REPO:-}"

    # .env 파일 생성
    cat > "$ENV_FILE" <<ENVEOF
CLAUDE_LOG_DIR=$LOG_DIR
CLAUDE_TEST_REPO=$TEST_REPO
CLAUDE_KNOWLEDGE_REPO=$KNOWLEDGE_REPO
ENVEOF

    echo ""
    echo "  생성: ~/.claude/.env"
    cat "$ENV_FILE" | sed 's/^/    /'

    # 로그 디렉토리 생성
    mkdir -p "$LOG_DIR"/{hooks,prompts,workflow} 2>/dev/null

    # 지식 레포 디렉토리 생성 (경로가 있고 디렉토리가 없으면)
    if [ -n "$KNOWLEDGE_REPO" ] && [ ! -d "$KNOWLEDGE_REPO" ]; then
        mkdir -p "$KNOWLEDGE_REPO"/{specs,architecture,manuals,errors,troubleshooting,insights}
        echo "  생성: 지식 레포 디렉토리 ($KNOWLEDGE_REPO)"
    fi

    echo ""
    echo "프로젝트 템플릿 적용은 별도로 실행:"
    echo "  ./scripts/init-project.sh spring-boot|fastapi|nextjs"

    exit 0
fi

# ─── 다운로드 모드 (원격 설치용) ───
echo "Claude 거버넌스 설치 시작..."

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/rules"
mkdir -p "$CLAUDE_DIR/hooks/lib"

# 기존 commands 디렉토리 정리
if [ -d "$CLAUDE_DIR/commands" ]; then
    mv "$CLAUDE_DIR/commands" "$CLAUDE_DIR/commands.backup"
    echo "기존 commands/ → commands.backup/ 으로 백업"
fi

# settings.json
echo "settings.json 다운로드..."
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup"
fi
curl -fsSL "$REPO_URL/global/settings.json" -o "$CLAUDE_DIR/settings.json"

# CLAUDE.md
echo "CLAUDE.md 다운로드..."
curl -fsSL "$REPO_URL/global/CLAUDE.md" -o "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || true

# skills
echo "skills/ 다운로드..."
SKILLS=(clear feedback-to-pr notion project-chat feature-docs-plan feature-docs-complete)
for skill in "${SKILLS[@]}"; do
    mkdir -p "$CLAUDE_DIR/skills/$skill"
    curl -fsSL "$REPO_URL/global/skills/${skill}/SKILL.md" -o "$CLAUDE_DIR/skills/${skill}/SKILL.md" 2>/dev/null || true
done

# feature-docs-plan 템플릿
mkdir -p "$CLAUDE_DIR/skills/feature-docs-plan/references/templates"
for f in feature-spec-template architecture-template; do
    curl -fsSL "$REPO_URL/global/skills/feature-docs-plan/references/templates/${f}.md" \
        -o "$CLAUDE_DIR/skills/feature-docs-plan/references/templates/${f}.md" 2>/dev/null || true
done

# feature-docs-complete 템플릿
mkdir -p "$CLAUDE_DIR/skills/feature-docs-complete/references/templates"
for f in feature-spec-update-guide architecture-update-guide user-manual-template \
         error-messages-template troubleshooting-template insights-template architecture-notes-template; do
    curl -fsSL "$REPO_URL/global/skills/feature-docs-complete/references/templates/${f}.md" \
        -o "$CLAUDE_DIR/skills/feature-docs-complete/references/templates/${f}.md" 2>/dev/null || true
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
echo "파일 설치 완료. 환경변수를 설정합니다."
echo ""

ENV_FILE="$CLAUDE_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    echo "기존 ~/.claude/.env 발견:"
    cat "$ENV_FILE"
    echo ""
    read -rp ".env를 다시 설정하시겠습니까? (y/N): " RESET_ENV
    if [ "$RESET_ENV" != "y" ] && [ "$RESET_ENV" != "Y" ]; then
        echo "  .env 유지"
        echo ""
        echo "설치 완료!"
        exit 0
    fi
fi

echo "환경변수를 설정합니다. (빈 입력 시 기본값 사용)"
echo ""

DEFAULT_LOG_DIR="$HOME/.claude/logs"
read -rp "CLAUDE_LOG_DIR (Hook 로그 저장 경로) [$DEFAULT_LOG_DIR]: " INPUT_LOG_DIR
LOG_DIR="${INPUT_LOG_DIR:-$DEFAULT_LOG_DIR}"

read -rp "CLAUDE_TEST_REPO (테스트 레포 절대경로) []: " INPUT_TEST_REPO
TEST_REPO="${INPUT_TEST_REPO:-}"

read -rp "CLAUDE_KNOWLEDGE_REPO (지식 레포 절대경로) []: " INPUT_KNOWLEDGE_REPO
KNOWLEDGE_REPO="${INPUT_KNOWLEDGE_REPO:-}"

cat > "$ENV_FILE" <<ENVEOF
CLAUDE_LOG_DIR=$LOG_DIR
CLAUDE_TEST_REPO=$TEST_REPO
CLAUDE_KNOWLEDGE_REPO=$KNOWLEDGE_REPO
ENVEOF

mkdir -p "$LOG_DIR"/{hooks,prompts,workflow} 2>/dev/null

if [ -n "$KNOWLEDGE_REPO" ] && [ ! -d "$KNOWLEDGE_REPO" ]; then
    mkdir -p "$KNOWLEDGE_REPO"/{specs,architecture,manuals,errors,troubleshooting,insights}
    echo "  생성: 지식 레포 디렉토리 ($KNOWLEDGE_REPO)"
fi

echo ""
echo "설치 완료!"
echo ""
echo "설치된 항목:"
echo "  ~/.claude/settings.json"
echo "  ~/.claude/CLAUDE.md"
echo "  ~/.claude/skills/ (${#SKILLS[@]}개)"
echo "  ~/.claude/rules/ (3개)"
echo "  ~/.claude/hooks/ (8개 + lib 2개)"
echo "  ~/.claude/.env (환경변수)"
echo ""
echo "프로젝트 템플릿 적용:"
echo "  curl -fsSL $REPO_URL/scripts/init-project.sh | bash -s spring-boot"
