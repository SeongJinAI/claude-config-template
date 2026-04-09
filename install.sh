#!/bin/bash

# Claude 거버넌스 설치 스크립트
# global/ 디렉토리의 내용을 ~/.claude/에 설치한다.
#
# 사용법:
#   로컬 (심볼릭 링크): ./install.sh --link [레포경로] [--type common|server|blog|all]
#   원격 (다운로드):     curl -fsSL https://raw.githubusercontent.com/SeongJinAI/claude-config-template/main/install.sh | bash
#
# --type 옵션:
#   common  — 공통 에이전트/스킬만 설치 (기본값)
#   server  — common + 서버 운영용 에이전트/스킬
#   blog    — common + 블로그 에이전트/스킬
#   all     — 전부 설치

set -e

REPO_URL="https://raw.githubusercontent.com/SeongJinAI/claude-config-template/main"
CLAUDE_DIR="$HOME/.claude"

# 카테고리별 설치 대상 정의
CATEGORIES_COMMON="common"
CATEGORIES_SERVER="common server"
CATEGORIES_BLOG="common blog"
CATEGORIES_ALL="common server blog"

# 설치 타입 파싱
parse_type() {
    local type="${1:-common}"
    case "$type" in
        common) echo "$CATEGORIES_COMMON" ;;
        server) echo "$CATEGORIES_SERVER" ;;
        blog)   echo "$CATEGORIES_BLOG" ;;
        all)    echo "$CATEGORIES_ALL" ;;
        *)      echo "$CATEGORIES_COMMON" ;;
    esac
}

# 카테고리별 에이전트/스킬 심볼릭 링크
link_categorized() {
    local global_dir="$1"
    local target_type="$2"  # agents 또는 skills
    local categories="$3"
    local dest_dir="$CLAUDE_DIR/$target_type"

    mkdir -p "$dest_dir"

    for category in $categories; do
        local src_dir="$global_dir/$target_type/$category"
        [ -d "$src_dir" ] || continue

        for item in "$src_dir"/*; do
            [ -e "$item" ] || continue
            local name=$(basename "$item")
            local dest="$dest_dir/$name"

            if [ -L "$dest" ]; then
                rm "$dest"
            elif [ -e "$dest" ]; then
                mv "$dest" "${dest}.backup"
            fi

            ln -s "$item" "$dest"
            echo "    [$category] $name"
        done
    done
}

# ─── 심볼릭 링크 모드 (로컬 개발용) ───
if [ "$1" = "--link" ]; then
    DOTFILES_DIR="${2:-.}"
    DOTFILES_DIR=$(cd "$DOTFILES_DIR" && pwd)
    GLOBAL_DIR="$DOTFILES_DIR/global"

    # --type 파싱
    INSTALL_TYPE="common"
    if [ "$3" = "--type" ] && [ -n "$4" ]; then
        INSTALL_TYPE="$4"
    fi
    INSTALL_CATEGORIES=$(parse_type "$INSTALL_TYPE")

    if [ ! -d "$GLOBAL_DIR" ]; then
        echo "오류: $GLOBAL_DIR 디렉토리가 없습니다."
        exit 1
    fi

    echo "심볼릭 링크 모드: $GLOBAL_DIR → $CLAUDE_DIR"
    echo "설치 타입: $INSTALL_TYPE ($INSTALL_CATEGORIES)"
    echo ""

    mkdir -p "$CLAUDE_DIR"

    # 기존 commands 심볼릭 링크가 남아있으면 제거
    if [ -L "$CLAUDE_DIR/commands" ]; then
        rm "$CLAUDE_DIR/commands"
        echo "  정리: 기존 commands 심볼릭 링크 제거"
    fi

    # 단일 파일/디렉토리 심볼릭 링크 (카테고리 무관)
    for target in settings.json CLAUDE.md rules hooks; do
        SOURCE="$GLOBAL_DIR/$target"
        DEST="$CLAUDE_DIR/$target"

        if [ ! -e "$SOURCE" ]; then
            echo "  건너뜀: $target (소스 없음)"
            continue
        fi

        if [ -L "$DEST" ]; then
            rm "$DEST"
        elif [ -e "$DEST" ]; then
            mv "$DEST" "${DEST}.backup"
            echo "  백업: $target → ${target}.backup"
        fi

        ln -s "$SOURCE" "$DEST"
        echo "  연결: ~/.claude/$target → global/$target"
    done

    # 카테고리별 에이전트 설치
    echo ""
    echo "  agents/ ($INSTALL_TYPE):"
    # 기존 에이전트 심볼릭 링크 정리
    if [ -L "$CLAUDE_DIR/agents" ]; then
        rm "$CLAUDE_DIR/agents"
    fi
    link_categorized "$GLOBAL_DIR" "agents" "$INSTALL_CATEGORIES"

    # 카테고리별 스킬 설치
    echo ""
    echo "  skills/ ($INSTALL_TYPE):"
    if [ -L "$CLAUDE_DIR/skills" ]; then
        rm "$CLAUDE_DIR/skills"
    fi
    link_categorized "$GLOBAL_DIR" "skills" "$INSTALL_CATEGORIES"

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

    # agents 확인
    echo "  agents/"
    for f in "$CLAUDE_DIR/agents/"*.md; do
        [ -f "$f" ] && echo "    $(basename "$f")"
    done

    # rules 확인
    echo "  rules/"
    for f in "$CLAUDE_DIR/rules/"*.md; do
        [ -f "$f" ] && echo "    $(basename "$f")"
    done

    # ─── .env 설정 (환경변수) ───
    ENV_FILE="$CLAUDE_DIR/.env"
    echo ""

    SKIP_ENV=false
    if [ -f "$ENV_FILE" ]; then
        echo "기존 ~/.claude/.env 발견:"
        cat "$ENV_FILE"
        echo ""
        read -rp ".env를 다시 설정하시겠습니까? (y/N): " RESET_ENV
        if [ "$RESET_ENV" != "y" ] && [ "$RESET_ENV" != "Y" ]; then
            echo "  .env 유지"
            SKIP_ENV=true
        fi
    fi

    if [ "$SKIP_ENV" = false ]; then
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

        echo ""
        echo "  생성: ~/.claude/.env"
        cat "$ENV_FILE" | sed 's/^/    /'

        mkdir -p "$LOG_DIR"/{hooks,prompts,workflow} 2>/dev/null

        if [ -n "$KNOWLEDGE_REPO" ] && [ ! -d "$KNOWLEDGE_REPO" ]; then
            mkdir -p "$KNOWLEDGE_REPO"/{specs,architecture,manuals,errors,troubleshooting,insights}
            echo "  생성: 지식 레포 디렉토리 ($KNOWLEDGE_REPO)"
        fi
    fi

    echo ""

    # ─── 외부 스킬 설치 ───
    read -rp "외부 스킬(find-skills, karpathy-guidelines)을 설치하시겠습니까? (y/N): " INSTALL_PLUGINS
    if [ "$INSTALL_PLUGINS" = "y" ] || [ "$INSTALL_PLUGINS" = "Y" ]; then
        if [ -f "$DOTFILES_DIR/scripts/install-plugins.sh" ]; then
            bash "$DOTFILES_DIR/scripts/install-plugins.sh" --global
        else
            echo "  경고: scripts/install-plugins.sh를 찾을 수 없습니다."
        fi
    fi

    echo ""
    echo "설치 완료! (타입: $INSTALL_TYPE)"
    echo ""
    echo "📋 프로젝트 레벨 설정이 필요한 항목:"
    echo ""
    echo "  /notion     → .claude/skills/intg-notion.md (Block ID 매핑, 토큰 경로)"
    echo "  /clear      → handoff/ 디렉토리 생성 (멀티 세션 사용 시)"
    if echo "$INSTALL_CATEGORIES" | grep -q "server"; then
        echo "  /feature-docs-plan     → 프로젝트 문서 디렉토리 구조 설정"
        echo "  /feature-docs-complete → 프로젝트 문서 디렉토리 구조 설정"
    fi
    echo ""
    echo "  상세: https://github.com/SeongJinAI/claude-config 참조"

    exit 0
fi

# ─── 다운로드 모드 (원격 설치용) ───
echo "Claude 거버넌스 설치 시작..."
echo "설치 타입을 선택하세요:"
echo "  1) common  — 공통만 (기본)"
echo "  2) server  — 공통 + 서버 운영"
echo "  3) blog    — 공통 + 블로그"
echo "  4) all     — 전부"
read -rp "선택 [1]: " TYPE_CHOICE
case "$TYPE_CHOICE" in
    2) INSTALL_TYPE="server" ;;
    3) INSTALL_TYPE="blog" ;;
    4) INSTALL_TYPE="all" ;;
    *) INSTALL_TYPE="common" ;;
esac
INSTALL_CATEGORIES=$(parse_type "$INSTALL_TYPE")

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/rules"
mkdir -p "$CLAUDE_DIR/hooks/lib"
mkdir -p "$CLAUDE_DIR/agents"

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

# rules
echo "rules/ 다운로드..."
for f in 예외처리_원칙 코드리뷰_원칙 개발워크플로_원칙; do
    curl -fsSL "$REPO_URL/global/rules/${f}.md" -o "$CLAUDE_DIR/rules/${f}.md" 2>/dev/null || true
done

# hooks
echo "hooks/ 다운로드..."
for f in on-commit-quality-check on-commit-docs-sync-check on-push-security-signature-check \
         on-compact-workflow-handoff-save on-prompt-workflow-handoff-remind on-prompt-guide-api-dev \
         on-prompt-test-feedback on-prompt-ops-log on-prompt-quality-misunderstanding-detect \
         on-tooluse-ops-aiops-report on-prompt-ops-aiops-report on-hook-ops-aiops-report; do
    curl -fsSL "$REPO_URL/global/hooks/${f}.sh" -o "$CLAUDE_DIR/hooks/${f}.sh" 2>/dev/null || true
done
# Python hooks
curl -fsSL "$REPO_URL/global/hooks/aiops-sync-config.py" -o "$CLAUDE_DIR/hooks/aiops-sync-config.py" 2>/dev/null || true
for f in log-utils write-checkpoint; do
    curl -fsSL "$REPO_URL/global/hooks/lib/${f}.sh" -o "$CLAUDE_DIR/hooks/lib/${f}.sh" 2>/dev/null || true
done
chmod +x "$CLAUDE_DIR/hooks/"*.sh "$CLAUDE_DIR/hooks/lib/"*.sh 2>/dev/null || true

# 카테고리별 에이전트 다운로드
echo "agents/ 다운로드 ($INSTALL_TYPE)..."
declare -A AGENTS_COMMON=([quality-api-code-review]=1 [ops-aiops-connect]=1)
declare -A AGENTS_SERVER=([ops-hotfix-pipeline]=1)
declare -A AGENTS_BLOG=([content-blog-post]=1)

for category in $INSTALL_CATEGORIES; do
    local_var="AGENTS_$(echo $category | tr '[:lower:]' '[:upper:]')"
    eval "local_keys=\${!${local_var}[@]}"
    for agent in $local_keys; do
        curl -fsSL "$REPO_URL/global/agents/$category/${agent}.md" \
            -o "$CLAUDE_DIR/agents/${agent}.md" 2>/dev/null || true
        echo "  [$category] $agent"
    done
done

# 카테고리별 스킬 다운로드
echo "skills/ 다운로드 ($INSTALL_TYPE)..."

# common 스킬
if echo "$INSTALL_CATEGORIES" | grep -q "common"; then
    for skill in clear project-chat guideline-audit notion; do
        mkdir -p "$CLAUDE_DIR/skills/$skill"
        curl -fsSL "$REPO_URL/global/skills/common/${skill}/SKILL.md" \
            -o "$CLAUDE_DIR/skills/${skill}/SKILL.md" 2>/dev/null || true
        echo "  [common] $skill"
    done
    # clear 템플릿
    mkdir -p "$CLAUDE_DIR/skills/clear/references/templates"
    for f in handoff-template handoff-session-template handoff-index-template; do
        curl -fsSL "$REPO_URL/global/skills/common/clear/references/templates/${f}.md" \
            -o "$CLAUDE_DIR/skills/clear/references/templates/${f}.md" 2>/dev/null || true
    done
fi

# server 스킬
if echo "$INSTALL_CATEGORIES" | grep -q "server"; then
    for skill in feature-docs-plan feature-docs-complete feedback-to-pr misunderstanding-report; do
        mkdir -p "$CLAUDE_DIR/skills/$skill"
        curl -fsSL "$REPO_URL/global/skills/server/${skill}/SKILL.md" \
            -o "$CLAUDE_DIR/skills/${skill}/SKILL.md" 2>/dev/null || true
        echo "  [server] $skill"
    done
    # feature-docs-plan 템플릿
    mkdir -p "$CLAUDE_DIR/skills/feature-docs-plan/references/templates"
    for f in feature-spec-template architecture-template; do
        curl -fsSL "$REPO_URL/global/skills/server/feature-docs-plan/references/templates/${f}.md" \
            -o "$CLAUDE_DIR/skills/feature-docs-plan/references/templates/${f}.md" 2>/dev/null || true
    done
    # feature-docs-complete 템플릿
    mkdir -p "$CLAUDE_DIR/skills/feature-docs-complete/references/templates"
    for f in feature-spec-update-guide architecture-update-guide user-manual-template \
             error-messages-template troubleshooting-template insights-template architecture-notes-template; do
        curl -fsSL "$REPO_URL/global/skills/server/feature-docs-complete/references/templates/${f}.md" \
            -o "$CLAUDE_DIR/skills/feature-docs-complete/references/templates/${f}.md" 2>/dev/null || true
    done
fi

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
        echo "설치 완료! (타입: $INSTALL_TYPE)"
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

# ─── 외부 스킬 설치 ───
read -rp "외부 스킬(find-skills, karpathy-guidelines)을 설치하시겠습니까? (y/N): " INSTALL_PLUGINS
if [ "$INSTALL_PLUGINS" = "y" ] || [ "$INSTALL_PLUGINS" = "Y" ]; then
    echo "외부 스킬 설치 중..."
    if command -v npx &> /dev/null; then
        npx skills add https://github.com/vercel-labs/skills --skill find-skills -g -y 2>/dev/null || echo "  경고: find-skills 설치 실패"
        npx skills add https://github.com/forrestchang/andrej-karpathy-skills --skill karpathy-guidelines -g -y 2>/dev/null || echo "  경고: karpathy-guidelines 설치 실패"
    else
        echo "  경고: npx를 찾을 수 없습니다. 외부 스킬은 수동 설치 필요"
    fi
fi

echo ""
echo "설치 완료! (타입: $INSTALL_TYPE)"
echo ""
echo "📋 프로젝트 레벨 설정이 필요한 항목:"
echo ""
echo "  /notion     → .claude/skills/intg-notion.md (Block ID 매핑, 토큰 경로)"
echo "  /clear      → handoff/ 디렉토리 생성 (멀티 세션 사용 시)"
if echo "$INSTALL_CATEGORIES" | grep -q "server"; then
    echo "  /feature-docs-plan     → 프로젝트 문서 디렉토리 구조 설정"
    echo "  /feature-docs-complete → 프로젝트 문서 디렉토리 구조 설정"
fi
echo ""
echo "  상세: https://github.com/SeongJinAI/claude-config 참조"
echo ""
echo "사용 예시:"
echo "  ./install.sh --link . --type server   # 서버 프로젝트용"
echo "  ./install.sh --link . --type blog     # 블로그용"
echo "  ./install.sh --link . --type all      # 전부 설치"
