---
name: hotfix-pipeline
description: Sentry→Slack 에러 자동 감지 → 유형별 분기(DB/코드/혼합) → 수정 → PR/SQL 전달 자동화
model: opus
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - WebFetch
---

# Hotfix Pipeline Agent

## 전체 흐름

```
Sentry 에러 → Slack 알림
         ↓
Scheduled Trigger (주기적 Sentry API 체크)
         ↓
    에러 분석 + 유형 분류
         ↓
  ┌──────┼──────────┐
  ▼      ▼          ▼
 DB    코드      혼합(DB+코드)
  │      │          │
  ▼      ▼          ▼
Slack   PR 생성   Slack(SQL)
SQL전달  플로우    + PR 생성
```

---

## Phase 1: 에러 감지 (자동 — Scheduled Trigger)

Sentry API를 주기적으로 조회하여 새 미해결 이슈를 감지합니다.

```bash
# 미해결 이슈 조회
curl -s "https://sentry.io/api/0/projects/{org}/{project}/issues/?query=is:unresolved&sort=date" \
  -H "Authorization: Bearer $SENTRY_TOKEN"

# 이슈 상세 (스택트레이스)
curl -s "https://sentry.io/api/0/issues/{issue_id}/events/latest/" \
  -H "Authorization: Bearer $SENTRY_TOKEN"
```

감지 결과를 `handoff/hotfix.md`에 대기 목록으로 기록합니다.

---

## Phase 2: 에러 분석 + 유형 분류 (자동)

### 분류 기준

| 유형 | 판별 기준 | 대응 경로 |
|------|----------|----------|
| **DB** | SQLSyntaxErrorException, Unknown column, Data too long, DataIntegrityViolation(스키마 원인) | **Slack으로 SQL 직접 전달** |
| **코드** | NullPointerException, RuntimeException, 로직 버그, Sentry.captureException 직접 호출 | **코드 수정 → PR 생성** |
| **혼합** | Entity↔DB 컬럼 불일치 (Entity에는 있지만 DB에 없음) | **Slack(SQL) + PR(Entity 수정 필요 시)** |

### 판별 로직

```
에러 메시지 분석
  │
  ├─ "Unknown column" / "Data too long" / "Table doesn't exist"
  │   → DB 유형
  │   → DDL/DML 파일 + Entity 비교로 누락 컬럼 특정
  │
  ├─ "NullPointerException" / 코드 라인 지정 에러
  │   → 코드 유형
  │   → 스택트레이스에서 파일/메서드/라인 추출 → 코드 분석
  │
  └─ DataIntegrityViolationException
      → 원인 세분화:
        ├─ 제약조건 위반 (NOT NULL, UNIQUE) → 코드 검증 누락 → 코드 유형
        └─ 컬럼 타입 불일치 → DB 유형
```

### 심각도 분류

| 등급 | 기준 | 예시 |
|------|------|------|
| P0 | 서비스 중단, 데이터 손실 | 서버 다운, DB 커넥션 풀 고갈 |
| P1 | 핵심 기능 장애 | 급여 계산 오류, 로그인 실패 |
| P2 | 보조 기능 장애 | 조회 느림, 필터 오작동 |
| P3 | 경미한 오류 | 정렬 오류, 빈 응답 |

---

## Phase 3-A: DB 에러 → Slack SQL 전달 (PR 없음)

DB 레벨 수정은 코드 변경으로 해결되지 않으므로 **Slack으로 해결책을 직접 전달**합니다.

### 분석 절차
1. 에러 메시지에서 누락/불일치 컬럼 특정
2. Entity 파일에서 해당 필드의 `@Column` 정의 확인
3. `src/sql/` DDL 파일과 비교
4. ALTER TABLE / ALTER PROCEDURE SQL 생성

### Slack 전달 형식
```
🔴 [P1] DB 스키마 불일치 — AttestationIssueHistory.DocumentUrl

Sentry: #{issue_id}
에러: Unknown column 'aih1_0.DocumentUrl' in 'SELECT'

원인: Entity에 DocumentUrl 필드가 정의되어 있지만 실제 DB 테이블에 컬럼이 없음

해결 SQL:
ALTER TABLE AttestationIssueHistory
    ADD COLUMN DocumentUrl VARCHAR(500) NULL COMMENT '증명서 문서 URL'
    AFTER SealName;

Entity 정의: AttestationIssueHistory.java:104
DDL 참조: src/sql/migration/증명서발급_DDL.sql:104
```

### Notion 기록
```
DB > [증명서발급] > 핫픽스 > AttestationIssueHistory DocumentUrl 컬럼 누락 (P1)
```

**개발자가 SQL을 직접 실행 → Sentry에서 resolve 처리**

---

## Phase 3-B: 코드 에러 → 분석 + 계획 → PR 생성

### 분석 절차
1. 스택트레이스에서 파일/메서드/라인 추출
2. 해당 코드 읽기 → 원인 파악
3. 호출 체인 추적 → 영향 범위 판단
4. 수정 계획 작성

### Slack/Notion 공유
수정 계획을 Slack + Notion에 게시하고 **개발자 승인을 대기**합니다.

```
🟡 [P2] 코드 버그 — EmployeeUserSyncService 동기화 실패

Sentry: #{issue_id}
에러: Employee-User 동기화 실패: 주민번호로 User를 찾을 수 없음

원인: syncOnEmployeeUpdate()에서 주민번호 불일치 시 예외 발생
수정 계획: old/new fallback 조회 + 못 찾으면 Sentry 알림(비차단)
영향 범위: 직원 정보 수정 API
파일: EmployeeUserSyncService.java, User.java

승인 시 hotfix 브랜치 생성 → PR 올립니다.
```

### 승인 후 실행
```bash
git checkout dev && git pull origin dev
git checkout -b hotfix/{description}
# 코드 수정 + 문서 업데이트
git add {files}
git commit -m "fix: {description}"
git push -u origin hotfix/{description}
gh pr create --title "fix: {에러 요약}" --base dev
```

---

## Phase 3-C: 혼합 에러 → SQL + PR 동시

Entity에 필드가 있지만 DB에 없는 경우 등 양쪽 수정이 필요합니다.

1. **Slack**: ALTER TABLE SQL 전달 (DB 먼저)
2. **PR**: Entity/코드 수정이 추가로 필요한 경우 (선택)

```
🟠 [P1] 스키마 불일치 — EmployeeForeignerInfo.ForeignName

DB 수정 (즉시):
ALTER TABLE EmployeeForeignerInfo
    ADD COLUMN ForeignName VARCHAR(255) NULL AFTER EmployeeCode;

코드 수정 (필요 시):
해당 없음 — Entity에 이미 정의되어 있으므로 DB 컬럼 추가만으로 해결
```

---

## Phase 4: Codex 리뷰 반영 (PR 생성된 경우, 자동)

```bash
# PR 리뷰 확인
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments

# 리뷰 분석 → 코드 수정 → 재커밋
git add {files}
git commit -m "fix: address review comments"
git push
```

리뷰 반영 완료 후 Slack 알림:
"PR #{number} 리뷰 반영 완료 — 최종 확인 후 dev 머지 부탁드립니다."

---

## 핫픽스 세션 초기 세팅

새 핫픽스 세션 시작 시 자동 실행:

```
1. handoff/hotfix.md 읽기
2. Sentry API 조회 → 새 미해결 이슈 체크
3. 열린 PR 상태 확인 (gh pr list)
4. 열린 PR에 미반영 리뷰 확인
5. 개발자에게 브리핑:

핫픽스 세션을 시작합니다.

🔴 DB 수정 필요: 1건
  [P1] AttestationIssueHistory.DocumentUrl 컬럼 누락 — SQL 전달 완료, 적용 대기

🟡 코드 수정 대기: 1건
  [P2] Employee 동기화 NPE — 승인 대기

🔄 진행 중 PR: 1건
  #45 fix: attendance timeout — Codex 리뷰 2건 미반영

어떤 항목부터 처리할까요?
```

---

## 필요 설정

- [ ] `SENTRY_TOKEN` — Sentry API 인증 토큰
- [ ] `SENTRY_ORG` / `SENTRY_PROJECT` — 조직/프로젝트 슬러그
- [ ] `SLACK_WEBHOOK_URL` — 알림 전송용 웹훅
- [ ] Scheduled Trigger 등록 (Sentry 주기적 체크)
