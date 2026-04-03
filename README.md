# Claude Dotfiles

Claude Code 개인 설정 중앙 관리 레포. `install.sh` 한 번으로 Agents, Hooks, Skills, Rules, Settings를 `~/.claude/`에 심볼릭 링크합니다.

## 새 환경 셋업 (처음부터)

### 전제 조건

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) 설치 완료
- `python3` (Hook JSON 파싱 — 필수)
- `jq` (Hook JSON 파싱 — 권장, 없으면 python3 폴백)
- Node.js 18+ (`npx` — 외부 스킬 설치용, 선택)
- Git

### Step 1. 레포 클론

```bash
git clone https://github.com/seongjin-ha/claude-dotfiles.git ~/claude-dotfiles
cd ~/claude-dotfiles
```

> WSL 환경이면 Windows 경로(`/mnt/c/Personal/claude-dotfiles`)도 가능합니다.

### Step 2. 전역 설정 설치

```bash
./install.sh --link .
```

이 명령이 하는 일:
- `~/.claude/settings.json` → `global/settings.json`
- `~/.claude/agents/` → `global/agents/`
- `~/.claude/hooks/` → `global/hooks/`
- `~/.claude/skills/` → `global/skills/`
- `~/.claude/rules/` → `global/rules/`
- `~/.claude/CLAUDE.md` → `global/CLAUDE.md`

**대화형 입력**이 나옵니다:

| 질문 | 입력값 | 설명 |
|------|--------|------|
| `CLAUDE_LOG_DIR` | Enter (기본값) | Hook 로그 저장 경로 |
| `CLAUDE_TEST_REPO` | 테스트 레포 절대경로 | 없으면 빈칸 |
| `CLAUDE_KNOWLEDGE_REPO` | 지식 레포 절대경로 | 없으면 빈칸 |

### Step 3. 외부 스킬 설치

```bash
./scripts/install-plugins.sh --global
```

설치되는 스킬: `find-skills` (스킬 검색), `karpathy-guidelines` (LLM 코딩 가이드)

### Step 4. 설치 확인

```bash
# 심볼릭 링크 확인
ls -la ~/.claude/settings.json ~/.claude/agents ~/.claude/hooks ~/.claude/skills ~/.claude/rules

# Claude Code에서 확인 — Claude Code 실행 후:
#   /notion, /clear, /guideline-audit 등 스킬이 보이면 성공
#   "API 코드 리뷰 해줘" → api-code-review-orchestrator 에이전트 동작 확인
```

### Step 5. 프로젝트별 추가 설정 (선택)

#### Notion 연동 (`/notion` 스킬 사용 시)

프로젝트 루트에 `.claude/.mcp.json` 생성:

```json
{
  "mcpServers": {
    "notion-work": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": {
        "NOTION_TOKEN": "your-notion-integration-token"
      }
    }
  }
}
```

#### 프로젝트별 플러그인 (feature-dev 등)

`.claude/settings.local.json` 생성:

```json
{
  "enabledPlugins": {
    "feature-dev@claude-plugins-official": true
  }
}
```

#### 에이전트 오버라이딩 (프로젝트 특화)

프로젝트 `.claude/agents/`에 동일 파일명으로 오버라이딩:

```bash
# 글로벌 범용 에이전트를 프로젝트 특화 버전으로 확장
cp ~/.claude/agents/api-code-review-orchestrator.md .claude/agents/
# → 프로젝트 스택, 도메인 규칙, 추가 Critical Rules 등을 추가
```

---

## 포함된 기능 요약

### Agents (범용 에이전트)

| 에이전트 | 트리거 | 기능 |
|---------|--------|------|
| `api-code-review-orchestrator` | "API 코드 리뷰 해줘" | 8단계 파이프라인 (Discovery→CodeReview→Security→Performance→BugFix→QA→Docs→Conductor) |

> 프로젝트에서 `.claude/agents/` 동일 파일명으로 오버라이딩하여 프로젝트 특화 가능

### Skills (슬래시 명령)

| 명령 | 설명 |
|------|------|
| `/notion` | Notion 업무 체크리스트 add/done/list |
| `/clear` | HANDOFF.md 인수인계 후 세션 정리 |
| `/guideline-audit` | 명세서 vs 코드 가이드라인 감사 → Notion 등록 |
| `/feature-docs-plan` | 구현 전 명세서+아키텍처 초안 생성 |
| `/feature-docs-complete` | 구현 후 7종 문서 일괄 생성 |
| `/feedback-to-pr` | 피드백 수집 → PR 자동 생성 |
| `/project-chat` | 프로젝트 문서 기반 Q&A |

### Hooks (자동 실행)

| Hook | 트리거 | 기능 |
|------|--------|------|
| `on-commit-quality-check` | `git commit` | 주석/unused 코드/포맷 경고 |
| `on-commit-doc-sync-check` | `git commit` | 코드 변경 시 문서 미갱신 경고 |
| `on-push-signature-check` | `git push` | Claude 서명 감지 + 보호 브랜치 경고 |
| `on-prompt-handoff-remind` | `/clear`, `/compact` | HANDOFF.md 업데이트 지시 |
| `on-prompt-api-dev-guide` | "신규 개발" 키워드 | 개발 파이프라인 가이드 주입 |
| `on-prompt-test-feedback` | "테스트 결과 피드백 반영" | 테스트 레포에서 최신 결과 로드 |
| `on-compact-handoff-save` | compact 실행 | HANDOFF.md 최신 여부 확인 |
| `on-prompt-log` | 모든 프롬프트 | JSONL 로깅 |

### Rules (자동 로딩)

| 규칙 | 내용 |
|------|------|
| `개발워크플로_원칙` | 문서→코드→매뉴얼 순서, HANDOFF.md |
| `코드리뷰_원칙` | 시나리오 기반 검증, DDD 계층 책임 |
| `예외처리_원칙` | 4계층 분류, ERR_ 네이밍, 로깅 레벨 |

### 전역 플러그인

| 플러그인 | 설치 방식 | 용도 |
|---------|----------|------|
| `code-review` | settings.json (자동) | PR 코드 리뷰 |
| `find-skills` | npx skills (Step 3) | 스킬 검색/설치 |
| `karpathy-guidelines` | npx skills (Step 3) | LLM 코딩 가이드 |

---

## 디렉토리 구조

```
claude-dotfiles/
├── global/                  # → ~/.claude/ 심볼릭 링크 대상
│   ├── settings.json        #   permissions, hooks, plugins
│   ├── CLAUDE.md            #   전역 지침
│   ├── agents/              #   범용 에이전트 (1개)
│   ├── rules/               #   글로벌 규칙 (3개)
│   ├── skills/              #   슬래시 명령 (7개)
│   └── hooks/               #   Hook 스크립트 (8개 + lib)
├── scripts/                 # 유틸리티
│   ├── install-plugins.sh   #   외부 스킬 설치
│   └── sync.sh              #   설정 동기화 (push/pull)
└── docs/                    # 상세 문서
    ├── architecture.md      #   Settings 계층, 규칙 아키텍처
    └── formats/             #   문서 양식 템플릿 (8개)
```

## 외부 의존성

### ~/.claude/.env (install.sh가 대화형으로 생성)

| 변수 | 사용처 | 미설정 시 |
|------|--------|----------|
| `CLAUDE_LOG_DIR` | 모든 Hook 로깅 | `~/.claude/logs` 자동 사용 |
| `CLAUDE_TEST_REPO` | on-prompt-test-feedback Hook | "테스트 결과 피드백 반영" 미동작 |
| `CLAUDE_KNOWLEDGE_REPO` | /feature-docs-plan, /complete, /project-chat | 프로젝트 내 src/docs/로 폴백 |

### 프로젝트별 설정 (해당 기능 사용 시만)

| 설정 | 파일 | 사용처 |
|------|------|--------|
| `NOTION_TOKEN` | `.claude/.mcp.json` | /notion, /guideline-audit |
| `enabledPlugins` | `.claude/settings.local.json` | feature-dev 등 프로젝트별 플러그인 |

## 커스터마이징

- **Agent 추가**: `global/agents/{이름}.md` 생성 (frontmatter: name, description, model)
- **Hook 추가**: `global/hooks/on-{이벤트}-{목적}.sh` 생성 → `global/settings.json`에 등록
- **Skill 추가**: `global/skills/{이름}/SKILL.md` 생성
- **Rule 추가**: `global/rules/{이름}.md` 생성

상세: [docs/architecture.md](docs/architecture.md)
