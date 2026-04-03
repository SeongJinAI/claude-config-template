# 기술 인사이트: Claude Code 추천 플러그인

> **작성일**: 2026.04.03
> **관련 기능**: Claude Code 환경 세팅
> **태그**: #claude-code #plugins #skills #환경세팅

---

## 1. 개요

Claude Code에서 자주 사용하는 외부 플러그인(Skills)을 정리합니다. 새 프로젝트 세팅이나 팀원 온보딩 시 참고용으로, 검증된 플러그인만 기록합니다.

Skills CLI: `npx skills` — 오픈 에이전트 스킬 생태계 패키지 매니저
마켓플레이스: https://claudemarketplaces.com/

---

## 2. 추천 플러그인

### 2.1 find-skills — 스킬 검색/설치 도우미

| 항목 | 내용 |
|------|------|
| 출처 | `vercel-labs/skills` |
| 설치 수 | 661K+ |
| GitHub Stars | 11.2K+ |
| 용도 | 프로젝트에 맞는 외부 스킬을 자연어로 검색하고 설치 |

**설치**:
```bash
npx skills add https://github.com/vercel-labs/skills --skill find-skills
```

**사용 시점**:
- 새 프로젝트 시작 시 필요한 스킬 탐색
- "how do I do X" 형태의 질문 시 자동 트리거
- 기존 스킬로 해결 가능한 작업인지 빠르게 확인

**주요 기능**:
- `npx skills find [query]` — 키워드 기반 스킬 검색
- `npx skills add <package>` — 스킬 설치
- `npx skills check` / `npx skills update` — 업데이트 관리
- 카테고리별 검색: Web Development, Testing, DevOps, Documentation, Code Quality, Design 등

**참고**: https://claudemarketplaces.com/skills/vercel-labs/skills/find-skills

---

### 2.2 karpathy-guidelines — LLM 코딩 가이드라인

| 항목 | 내용 |
|------|------|
| 출처 | `forrestchang/andrej-karpathy-skills` |
| 설치 수 | 1.9K+ |
| GitHub Stars | 7.5K+ |
| 용도 | LLM의 일반적인 코딩 실수를 줄이기 위한 행동 지침 |

**설치**:
```bash
npx skills add https://github.com/forrestchang/andrej-karpathy-skills --skill karpathy-guidelines
```

**사용 시점**:
- Claude Code의 코드 생성 품질을 높이고 싶을 때
- 불필요한 추가 기능, 과도한 리팩토링 등 LLM 특유의 코딩 습관을 억제할 때

**4대 원칙**:

| 원칙 | 설명 |
|------|------|
| **Think Before Coding** | 가정을 명시적으로 표현하고, 혼란을 숨기지 않는다 |
| **Simplicity First** | 요청된 것 이상의 기능 없이 최소한의 코드로 문제 해결 |
| **Surgical Changes** | 필요한 것만 수정하고, 자신의 변경으로 인한 불필요한 코드만 정리 |
| **Goal-Driven Execution** | 성공 기준을 정의하고 검증할 때까지 반복 |

**참고**: https://claudemarketplaces.com/skills/forrestchang/andrej-karpathy-skills/karpathy-guidelines

---

### 2.3 codex-plugin-cc — Claude ↔ Codex 크로스 리뷰

| 항목 | 내용 |
|------|------|
| 출처 | `openai/codex-plugin-cc` (OpenAI 공식) |
| GitHub Stars | 10.7K+ |
| 용도 | Claude Code 안에서 OpenAI Codex를 호출하여 코드 리뷰/작업 위임 |

**설치**:
```bash
# Claude Code 플러그인 방식
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/reload-plugins
/codex:setup
```

**전제 조건**: ChatGPT 구독 또는 OpenAI API 키, Node.js 18.18+

**왜 사용하는가**:
- **크로스 모델 검증**: Claude가 자체 리뷰에서 놓치는 부분을 GPT 모델이 보완 — 두 AI의 맹점이 다르므로 교차 검증 시 정확도 향상
- **적대적 리뷰**: 설계 결정에 의문을 제기하는 방식으로, 가정/트레이드오프/실패 모드를 검증
- **작업 위임**: 버그 조사, 수정 등 시간이 걸리는 작업을 백그라운드로 Codex에 넘기고 Claude 작업 계속

**주요 명령어**:

| 명령어 | 설명 |
|--------|------|
| `/codex:review` | 표준 코드 리뷰 (읽기 전용) |
| `/codex:adversarial-review` | 설계 결정에 도전하는 심층 리뷰 |
| `/codex:rescue` | Codex에 작업 위임 (버그 조사, 수정 등) |
| `/codex:status` | 백그라운드 작업 상태 확인 |
| `/codex:result` | 완료된 작업 결과 조회 |
| `/codex:cancel` | 작업 취소 |

**실전 활용 시나리오**:
```
# 배포 전 크로스 리뷰
/codex:review --base main

# 설계 방향 검증 (캐싱 전략이 맞는지?)
/codex:adversarial-review --base main 캐싱과 재시도 설계가 올바른지 검토

# CI 실패 원인을 Codex에 위임하고 Claude 작업 계속
/codex:rescue --background CI 빌드 실패 원인 조사
/codex:status
/codex:result
```

**리뷰 게이트**: `/codex:setup --enable-review-gate`로 활성화하면 Claude 응답마다 자동으로 Codex 리뷰 실행. 단, Codex 이용한도를 빠르게 소모하므로 적극 모니터링 시에만 사용.

**참고**: https://github.com/openai/codex-plugin-cc

---

### 2.4 pm-skills — AI 기반 프로덕트 매니지먼트

| 항목 | 내용 |
|------|------|
| 출처 | `phuryn/pm-skills` |
| 규모 | 65개 스킬, 36개 체인 워크플로우, 8개 플러그인 |
| 용도 | 제품 관리 프레임워크 — 기획/전략/실행/시장조사/분석을 구조화 |

**설치**:
```bash
# Claude Code CLI
claude plugin marketplace add phuryn/pm-skills
claude plugin install pm-toolkit@pm-skills
claude plugin install pm-product-strategy@pm-skills
# ... (총 8개 플러그인)
```

**왜 사용하는가**:
- **기획 구조화**: 아이디어 → 가정 → 검증 → PRD까지 검증된 방법론(Teresa Torres, Marty Cagan)으로 체계적으로 진행
- **PM 프레임워크 즉시 적용**: 비즈니스 모델 캔버스, SWOT, OKR, 로드맵 등을 슬래시 명령어로 바로 생성
- **개발자 ↔ 기획자 간극 좁히기**: PRD, 스프린트 계획, 이해관계자 맵 등을 개발 환경에서 직접 작성

**8개 플러그인 분류**:

| 플러그인 | 핵심 기능 | 개발자 활용도 |
|---------|----------|-------------|
| **Discovery** | 아이디어 브레인스토밍, 기회-솔루션 트리 | 기능 제안 시 |
| **Strategy** | 비즈니스 모델 캔버스, SWOT | 프로젝트 방향 설정 |
| **Execution** | PRD 작성, OKR, 스프린트 계획 | **자주 사용** |
| **Market Research** | 사용자 페르소나, 경쟁사 분석 | 신규 기능 기획 |
| **Analytics** | SQL 생성, A/B 테스트 분석 | 데이터 분석 |
| **Go-to-Market** | ICP 정의, 성장 루프 | 출시 전략 |
| **Marketing & Growth** | North Star Metric, 포지셔닝 | KPI 설정 |
| **Toolkit** | NDA, 개인정보보호정책 | 유틸리티 |

**빠른 시작**:
```
/discover           # 아이디어 발견
/strategy           # 전략 캔버스
/write-prd          # PRD 작성
/plan-launch        # 출시 계획
/north-star         # 핵심 지표 정의
```

**참고**: https://github.com/phuryn/pm-skills

---

## 3. 설치 관리

### 전역 설치 (모든 프로젝트 적용)

```bash
npx skills add <package> -g -y
```

`-g` 플래그로 글로벌 설치, `-y`로 확인 프롬프트 스킵.

### 프로젝트별 설치

```bash
npx skills add <package>
```

프로젝트 `.claude/skills/` 하위에 설치됩니다.

### 업데이트

```bash
npx skills check    # 업데이트 확인
npx skills update   # 전체 업데이트
```

---

## 4. 플러그인 선정 기준

외부 플러그인 추가 시 다음 기준으로 검증합니다:

| 기준 | 최소 조건 |
|------|----------|
| 설치 수 | 1K+ (검증된 사용량) |
| 출처 신뢰도 | 공식 소스(`vercel-labs`, `anthropics`) 또는 GitHub Stars 1K+ |
| 실제 사용 빈도 | 주 1회 이상 활용 가능 |
| 기존 도구와 중복 | 기존 커스텀 스킬/에이전트로 대체 불가 |

---

## 변경 이력

| 일자 | 변경 내용 |
|------|----------|
| 2026.04.03 | codex-plugin-cc, pm-skills 추가 |
| 2026.04.03 | 최초 작성 — find-skills, karpathy-guidelines 등록 |
