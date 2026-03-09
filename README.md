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
  "language": "Korean"
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
│  └── language             회사 공용 언어                       │
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
├── README.md
├── install.sh                        # 설치 스크립트 (--link 또는 curl)
│
├── global/                           # Global 레벨 설정
│   ├── CLAUDE.md                     # 전역 지침
│   ├── settings.json                 # permissions + language
│   ├── rules/                        # Global Rules → ~/.claude/rules/
│   │   ├── 예외처리_원칙.md           # 4계층 분류, ERR_, 로깅
│   │   ├── 코드리뷰_원칙.md           # 시나리오 검증, DDD
│   │   └── 개발워크플로_원칙.md        # 개발순서, 산출물, HANDOFF
│   └── commands/
│       └── clear.md                  # /clear 커스텀 명령어
│
├── templates/                        # 프로젝트 CLAUDE.md + Rules 템플릿
│   ├── spring-boot/
│   │   ├── CLAUDE.md
│   │   └── rules/
│   │       ├── 코드스타일_가이드.md    # Entity/DTO/Controller/Service 컨벤션
│   │       └── 예외처리_가이드.md      # BusinessException, ErrorCode
│   ├── fastapi/
│   │   ├── CLAUDE.md
│   │   └── rules/
│   │       ├── 코드스타일_가이드.md    # Router/Schema/Service 컨벤션
│   │       └── 예외처리_가이드.md      # BusinessError, exception_handler
│   └── nextjs/
│       ├── CLAUDE.md
│       └── rules/
│           └── 코드스타일_가이드.md    # App Router/Component/Zustand 컨벤션
│
├── hooks/                            # Claude Code 훅 스크립트
│   ├── on-commit-quality-check.sh    # git commit 전 코드 품질 검사
│   ├── on-commit-doc-sync-check.sh   # git commit 시 문서-코드 동기화 확인
│   ├── on-push-signature-check.sh    # git push 전 서명/브랜치 확인
│   ├── on-compact-handoff-save.sh    # compact 전 HANDOFF.md 저장 알림
│   ├── on-prompt-handoff-remind.sh   # /clear·/compact 시 HANDOFF 리마인더
│   └── on-prompt-api-dev-guide.sh    # 신규 API 개발 워크플로 가이드 (플랜모드)
│
├── docs/
│   └── templates/                    # 문서 템플릿
│       ├── SPEC_TEMPLATE.md          # 기능명세서
│       ├── MANUAL_TEMPLATE.md        # 사용자매뉴얼
│       ├── FEEDBACK_TEMPLATE.md      # 피드백
│       └── STORYBOARD_WORKFLOW.md    # 스토리보드 기반 개발 워크플로
│
└── scripts/
    ├── init-project.sh               # 프로젝트 초기화 (CLAUDE.md + Rules 복사)
    └── sync.sh                       # 설정 동기화
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

| 훅 | 이벤트 | 트리거 | 기능 |
|----|--------|--------|------|
| `on-commit-quality-check.sh` | PreToolUse(Bash) | `git commit` | 주석, unused 코드, 컨벤션 검사 |
| `on-commit-doc-sync-check.sh` | PreToolUse(Bash) | `git commit` | 코드 변경 시 문서 업데이트 경고 |
| `on-push-signature-check.sh` | PreToolUse(Bash) | `git push` | Claude 서명 감지, 보호 브랜치 경고 |
| `on-compact-handoff-save.sh` | PreCompact | compact | HANDOFF.md 업데이트 알림 |
| `on-prompt-handoff-remind.sh` | UserPromptSubmit | `/clear`·`/compact` | HANDOFF.md 업데이트 리마인더 |
| `on-prompt-api-dev-guide.sh` | UserPromptSubmit | 신규 개발 키워드 | API 개발 워크플로 가이드 (플랜모드만) |

> Hooks는 **Project settings**에서 등록합니다 (`.claude/settings.json`).
> 스크립트 파일은 `~/.claude/hooks/` 심볼릭 링크를 통해 이 레포에서 중앙 관리합니다.

---

## 커스터마이징

### 새 프로젝트 템플릿

1. `templates/[프레임워크명]/CLAUDE.md` 작성
2. `templates/[프레임워크명]/rules/` 에 컨벤션 파일 추가
3. `scripts/init-project.sh` 에 템플릿 등록

### 새 Hook 추가

1. `hooks/on-{이벤트}-{목적}.sh` 작성 + `chmod +x`
2. 프로젝트의 `.claude/settings.json`에 등록
3. 심볼릭 링크 사용 시 자동 반영

### 새 문서 템플릿

1. `docs/templates/{TEMPLATE_NAME}.md` 생성
2. `[placeholder]` 패턴으로 커스터마이징 포인트 표시
