# Claude Dotfiles

Claude Code 설정 및 템플릿 저장소

## 빠른 시작

### 로컬 설치 (심볼릭 링크 — 권장)

```bash
git clone https://github.com/[YOUR_ID]/claude-dotfiles.git ~/claude-dotfiles
cd ~/claude-dotfiles
./install.sh --link .
```

### 원격 설치 (다운로드)

```bash
curl -fsSL https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main/install.sh | bash
```

### 프로젝트 템플릿 적용

```bash
curl -fsSL https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main/scripts/init-project.sh | bash -s spring-boot
```

---

## Rules 3-Tier Architecture

Claude Code는 `~/.claude/rules/`(글로벌)와 `.claude/rules/`(프로젝트)를 자동 로딩합니다.
**원칙(글로벌) → 구현(프레임워크 템플릿) → 커스텀(프로젝트)** 3계층 구조로 규칙을 관리합니다.

```
┌─────────────────────────────────────────────────────────┐
│  Global Rules (~/.claude/rules/)      [거버넌스 레포]    │
│  ├── 예외처리_원칙.md    4계층 분류, ERR_, 로깅 레벨     │
│  ├── 코드리뷰_원칙.md    시나리오 검증, DDD 계층 책임    │
│  └── 개발워크플로_원칙.md 개발순서, 산출물, HANDOFF      │
├─────────────────────────────────────────────────────────┤
│  Template Rules (.claude/rules/)  [init-project.sh]     │
│  ├── 코드스타일_가이드.md  프레임워크별 컨벤션           │
│  └── 예외처리_가이드.md    프레임워크별 예외 구현         │
├─────────────────────────────────────────────────────────┤
│  Project Rules (.claude/rules/)   [개발자 커스텀]       │
│  └── 추가/수정 자유 (template 오버라이딩)               │
└─────────────────────────────────────────────────────────┘
```

### 파일명 전략

- `_원칙.md` → 글로벌 (프레임워크 무관 원칙)
- `_가이드.md` → 프레임워크별 (구현 패턴, 컨벤션)

이름이 다르므로 충돌 없이 **보완 관계**를 유지합니다.

### 우선순위 (낮음 → 높음)

```
~/.claude/rules/*.md     → 글로벌 (모든 프로젝트 공통)
.claude/rules/*.md       → 프로젝트 (프레임워크별 + 커스텀, 글로벌 오버라이드 가능)
```

---

## Settings 3단계 계층 구조

Claude Code는 Global > Project > Local 순으로 설정 범위가 나뉘며, **상위에서 열어준 범위 내에서만 하위가 설정 가능**합니다.

### 설계 원칙

```
Global  ─── 회사/조직 보안 경계를 정의 (무엇을 허용하고 금지할지)
  │
  ├── Project ─── 팀 개발 규칙을 정의 (어떻게 일할지)
  │     │
  │     └── Local ─── 개인 환경을 커스터마이징 (나는 어떤 도구를 쓸지)
```

| 레벨 | 수정 권한 | 역할 |
|------|----------|------|
| **Global** (`~/.claude/settings.json`) | AI 리더만 | 회사 보안 정책 — 허용/금지 경계 설정 |
| **Project** (`.claude/settings.json`) | 프로젝트 리더만 | 팀 개발 규칙 — 자동화, 출력 표준 |
| **Local** (`.claude/settings.local.json`) | 누구나 | 개인 환경 — 플러그인, 추가 허용 |

### 병합 규칙

| 설정 유형 | 병합 방식 | 주의사항 |
|----------|----------|---------|
| `permissions.allow` | Merge (합집합) | 상위 deny에 해당하면 하위 allow 무효 |
| `permissions.deny` | Merge (합집합) | 상위에서 금지하면 하위에서 해제 불가 |
| `hooks` | Merge (합집합) | **한 레벨에서만 정의** — 중복 시 같은 hook 다중 실행 |
| `enabledPlugins` | Merge (합집합) | 개인이 자유롭게 추가 |
| 단일 값 (`language`, `outputStyle`) | Override | Local > Project > Global 우선순위 |

---

### Global (`~/.claude/settings.json`)

**역할**: 회사 보안 정책 — 모든 프로젝트의 보안 경계를 정의
**수정**: AI 리더만 (나머지 읽기 전용)

| 키 | 역할 | 설명 |
|----|------|------|
| `permissions.allow` | 공통 허용 | 모든 프로젝트에서 기본 허용할 명령어 |
| `permissions.deny` | 금지된 행위 | 어떤 레벨에서도 해제 불가한 금지 명령 |
| `permissions.defaultMode` | 기본 권한 모드 | `plan`, `default`, `dontAsk` 등 |
| `language` | 공용 언어 | 회사 표준 응답 언어 |

```json
{
  "permissions": {
    "allow": [
      "Bash(cat:*)", "Bash(rm:*)", "Bash(grep:*)",
      "Bash(git branch:*)", "Bash(git merge:*)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(git push --force origin main)",
      "Bash(git push --force origin master)",
      "Bash(git reset --hard)"
    ],
    "defaultMode": "plan"
  },
  "language": "Korean",
  "enabledPlugins": {
    "code-review@claude-plugins-official": true
  }
}
```

---

### Project (`.claude/settings.json`)

**역할**: 팀 개발 규칙 — 프로젝트의 자동화와 표준을 정의
**수정**: 프로젝트 리더만 (나머지 읽기 전용)
**관리**: git에 커밋하여 팀원 공유

| 키 | 역할 | 설명 |
|----|------|------|
| `hooks` | 프로젝트 자동화 | commit 검사, handoff 리마인더, 개발 가이드 등 |
| `outputStyle` | 팀 표준 출력 | 팀 전체가 사용하는 응답 스타일 |

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "hooks": [...] }],
    "UserPromptSubmit": [{ "hooks": [...] }],
    "PreCompact": [{ "hooks": [...] }]
  },
  "outputStyle": "Explanatory"
}
```

> 프로젝트별로 hooks가 다를 수 있으므로 이 레벨에서 관리합니다.
> Hook 스크립트 파일은 `~/.claude/hooks/` (심볼릭 링크)를 통해 dotfiles 레포에서 중앙 관리합니다.

---

### Local (`.claude/settings.local.json`)

**역할**: 개인 환경 커스터마이징
**수정**: 누구나 자유롭게
**관리**: `.gitignore`에 포함 — 커밋하지 않음

| 키 | 역할 | 설명 |
|----|------|------|
| `permissions.allow` | 추가 허용 | 개인 워크플로에 필요한 추가 명령어 |
| `enabledPlugins` | 개인 플러그인 | 개인이 사용하는 플러그인 |

```json
{
  "permissions": {
    "allow": [
      "Bash(tree:*)", "Bash(./gradlew build:*)",
      "WebSearch", "Bash(find:*)", "Bash(ls:*)"
    ]
  },
  "enabledPlugins": {
    "code-review@claude-code-plugins": true,
    "feature-dev@claude-plugins-official": true
  }
}
```

> Global의 `deny`에 해당하는 명령어는 여기서 `allow`해도 실행되지 않습니다.

---

### 한눈에 보기

```
┌──────────────────────────────────────────────────────────────┐
│  Global (~/.claude/settings.json)          [AI 리더만 수정]   │
│  ├── permissions.allow    공통 허용 기본값                     │
│  ├── permissions.deny     금지된 행위 (하위에서 해제 불가)      │
│  ├── language             회사 공용 언어                       │
│  └── enabledPlugins       전역 활성 플러그인                   │
├──────────────────────────────────────────────────────────────┤
│  Project (.claude/settings.json)    [프로젝트 리더만 수정]     │
│  ├── hooks                프로젝트 자동화 규칙                  │
│  └── outputStyle          팀 표준 출력 스타일                   │
├──────────────────────────────────────────────────────────────┤
│  Local (.claude/settings.local.json)       [누구나 수정]       │
│  ├── permissions.allow    개인 추가 허용                       │
│  └── enabledPlugins       개인 플러그인                        │
└──────────────────────────────────────────────────────────────┘

     ↓ 권한 흐름: 상위에서 열어준 범위 내에서만 하위가 설정 가능 ↓
```

---

## 구조

```
claude-dotfiles/
├── README.md                         # 빠른 시작 가이드
├── install.sh                        # 설치 스크립트 (--link 또는 curl)
│
├── global/                           # → ~/.claude/ 심볼릭 링크 대상
│   ├── CLAUDE.md                     # 전역 지침
│   ├── settings.json                 # permissions + hooks + plugins
│   ├── rules/                        # 글로벌 규칙 (3개)
│   ├── agents/                       # 카테고리별 에이전트
│   │   ├── common/                   #   모든 프로젝트 (quality-api-code-review)
│   │   ├── server/                   #   서버 운영 (ops-hotfix-pipeline)
│   │   └── blog/                     #   블로그 (content-blog-post)
│   ├── skills/                       # 카테고리별 스킬
│   │   ├── common/                   #   모든 프로젝트 (clear, notion, project-chat, guideline-audit)
│   │   ├── server/                   #   서버 개발 (feature-docs-*, feedback-to-pr, misunderstanding-report)
│   │   └── blog/                     #   블로그 (향후 추가)
│   └── hooks/                        # Hook 스크립트 (9개 + lib)
│
├── project-templates/                # 프레임워크별 초기화 템플릿
│   ├── spring-boot/                  # CLAUDE.md + rules + skills + agents
│   ├── fastapi/                      # CLAUDE.md + rules
│   └── nextjs/                       # CLAUDE.md + rules
│
├── docs/                             # 상세 문서
│   ├── architecture.md               # 이 파일 (3-Tier, Settings, 5-레포)
│   └── formats/                      # 문서 양식 템플릿 (8개)
│
└── scripts/                          # 유틸리티
    ├── init-project.sh               # 프로젝트 템플릿 적용
    ├── install-plugins.sh            # 외부 스킬 설치
    └── sync.sh                       # 설정 동기화 (push/pull)
```

## 5-레포 시스템 상호작용

```
거버넌스 (이 레포)
  │  install.sh → ~/.claude/ 심볼릭 링크
  │  모든 레포에서 Hook 자동 발동
  │
  ├──→ 프로젝트 레포: 코드 품질 검사, 문서 동기화 경고, 워크플로우 가이드
  ├──→ 테스트 레포: 테스트 피드백 주입
  ├──→ 지식 레포: feature-docs skills로 문서 저장
  └──→ 대시보드: JSONL 로그 → 시각화

환경변수 (~/.claude/.env):
  CLAUDE_LOG_DIR        → 대시보드가 읽는 JSONL 로그 경로
  CLAUDE_TEST_REPO      → 테스트 레포 경로 (테스트 피드백 Hook용)
  CLAUDE_KNOWLEDGE_REPO → 지식 레포 경로 (문서 저장 Skills용)
```

---

## Hook 스크립트

### 설치

```bash
# 심볼릭 링크 (권장)
./install.sh --link /path/to/claude-dotfiles

# 수동 복사
cp hooks/*.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*.sh
```

### 네이밍 컨벤션

`on-{이벤트}-{목적}.sh` — 파일명만으로 언제, 무엇을 하는지 파악 가능

### 훅 목록

| 훅 | 카테고리 | 이벤트 | 트리거 | 기능 |
|----|---------|--------|--------|------|
| `on-commit-quality-check.sh` | quality | PreToolUse(Bash) | `git commit` | 주석, unused 코드, 컨벤션 검사 |
| `on-commit-docs-sync-check.sh` | docs | PreToolUse(Bash) | `git commit` | 코드 변경 시 문서 업데이트 경고 |
| `on-push-security-signature-check.sh` | security | PreToolUse(Bash) | `git push` | Claude 서명 감지, 보호 브랜치 경고 |
| `on-compact-workflow-handoff-save.sh` | workflow | PreCompact | compact | Handoff 업데이트 알림 (멀티 세션 지원) |
| `on-prompt-workflow-handoff-remind.sh` | workflow | UserPromptSubmit | `/clear`·`/compact` | Handoff 업데이트 리마인더 (멀티 세션 지원) |
| `on-prompt-guide-api-dev.sh` | guide | UserPromptSubmit | 신규 개발 키워드 | API 개발 워크플로 가이드 (플랜모드만) |
| `on-prompt-ops-log.sh` | ops | UserPromptSubmit | 매 프롬프트 | JSONL 로그 기록 |
| `on-prompt-test-feedback.sh` | test | UserPromptSubmit | 테스트 관련 | 테스트 피드백 주입 |
| `on-prompt-quality-misunderstanding-detect.sh` | quality | UserPromptSubmit | 매 프롬프트 | AI 오해 감지 |

### 네이밍 컨벤션

`on-{이벤트}-{카테고리}-{목적}.sh`

| 카테고리 | 용도 |
|---------|------|
| `quality-` | 코드 품질, 컨벤션 검사 |
| `docs-` | 문서 동기화, 업데이트 |
| `security-` | 서명, 보안 체크 |
| `workflow-` | 핸드오프, 워크플로 관리 |
| `guide-` | 개발 가이드 주입 |
| `ops-` | 운영 로깅 |
| `test-` | 테스트 피드백 |

> Hooks는 **Project settings**에서 등록합니다 (`.claude/settings.json`).
> 스크립트 파일은 `~/.claude/hooks/` 심볼릭 링크를 통해 이 레포에서 중앙 관리합니다.

---

## 플러그인 & 외부 스킬

Claude Code에서 사용하는 플러그인은 **내장 플러그인**(settings.json)과 **외부 스킬**(npx skills)로 구분됩니다.

### 내장 플러그인 (settings.json 관리)

| 플러그인 | 스코프 | 용도 |
|---------|--------|------|
| `code-review@claude-plugins-official` | 전역 | PR 코드 리뷰 |
| `feature-dev@claude-plugins-official` | 프로젝트별 | 가이드 기반 기능 개발 |

- **전역 플러그인**: `global/settings.json`의 `enabledPlugins`에 등록 → install.sh로 자동 설치
- **프로젝트별 플러그인**: `.claude/settings.local.json`의 `enabledPlugins`에 등록

### 외부 스킬 (npx skills 관리)

| 스킬 | 출처 | 용도 |
|------|------|------|
| `find-skills` | `vercel-labs/skills` | 스킬 검색/설치 도우미 |
| `karpathy-guidelines` | `forrestchang/andrej-karpathy-skills` | LLM 코딩 품질 가이드라인 |

### 설치

```bash
# install.sh 실행 시 자동 설치 (프롬프트 확인)
./install.sh --link .

# 또는 별도 실행
./scripts/install-plugins.sh --global
```

> 상세 플러그인 정보: `global/insights/기술_Claude_Code_추천_플러그인.md` 참조

---

## 커스터마이징

### 새 프로젝트 템플릿

1. `project-templates/[프레임워크명]/CLAUDE.md` 작성
2. `project-templates/[프레임워크명]/rules/` 에 컨벤션 파일 추가
3. `scripts/init-project.sh` 에 템플릿 등록

### 새 Hook 추가

1. `global/hooks/on-{이벤트}-{목적}.sh` 작성 + `chmod +x`
2. `global/settings.json`에 등록
3. 심볼릭 링크 사용 시 자동 반영

### 새 Skill 추가

1. `global/skills/[스킬명]/SKILL.md` 생성 (전역) 또는 `project-templates/[프레임워크]/skills/[스킬명]/SKILL.md` (프레임워크별)
2. 필요 시 `references/templates/` 하위에 양식 추가
3. 심볼릭 링크 사용 시 자동 반영, 다운로드 모드는 install.sh 업데이트 필요

### 새 Agent 추가

1. `global/agents/[에이전트명].md` 생성 (글로벌) 또는 `project-templates/[프레임워크]/agents/` (프레임워크별)
2. frontmatter에 `name`, `description`, `model` 정의
3. 프로젝트에서 `.claude/agents/[에이전트명].md`로 오버라이딩하여 프로젝트 특화 컨텍스트 추가

---

## Global Agents

| 에이전트 | 카테고리 | 구조 | 용도 |
|---------|---------|------|------|
| `quality-api-code-review.md` | common | 단일 파일 | API 코드 리뷰 파이프라인 |
| `ops-hotfix-pipeline/` | server | **패키지** (AGENT.md + domains/) | Sentry 에러 감지 → 도메인 서브에이전트 분석 → 유형별 자동 분기 |
| `content-blog-post.md` | blog | 단일 파일 | 인프라 자동화 에이전트 추가 시 블로그 포스팅 |

### ops-hotfix-pipeline 패키지 구조

```
ops-hotfix-pipeline/
├── AGENT.md              ← 메인 파이프라인 (도메인 라우팅 + Phase 1~6)
└── domains/
    ├── _template.md      ← 도메인 에이전트 양식 (인터페이스)
    └── {domain}.md       ← 프로젝트에서 실제 내용을 채움
```

프로젝트에서 `domains/` 하위에 도메인별 컨텍스트(hr.md, salary.md 등)를 채우면, 메인 에이전트가 스택트레이스의 패키지 경로를 보고 해당 도메인 서브에이전트를 자동 호출합니다.

---

## Handoff 멀티 세션

Claude Code Remote로 여러 세션을 동시에 운영할 때 세션 간 핸드오프 충돌을 방지합니다.

### 구조

```
handoff/
├── INDEX.md              ← 활성 세션 목록 + 라우팅 규칙
├── main.md               ← 메인 기능 개발 세션
├── hotfix.md             ← 핫픽스/이슈 처리 세션
├── infra.md              ← 인프라/자동화 세션
└── archive/
    └── HANDOFF_legacy.md ← 마이그레이션 전 아카이브
```

### 세션 식별

1. 사용자 명시 > 2. 브랜치 패턴(`hotfix/*`→hotfix, `infra/*`→infra) > 3. 기본값(`main`)

### 규칙

- 자기 세션 파일만 쓰기, 다른 세션 파일은 읽기만
- `/clear` 시: 해당 세션 파일 업데이트 + INDEX.md 갱신
- hooks(`on-prompt-handoff-remind.sh`, `on-compact-handoff-save.sh`)가 `handoff/` 디렉토리를 자동 인식 (레거시 `HANDOFF.md` fallback 지원)

### 템플릿

- `global/skills/clear/references/templates/handoff-index-template.md`
- `global/skills/clear/references/templates/handoff-session-template.md`
