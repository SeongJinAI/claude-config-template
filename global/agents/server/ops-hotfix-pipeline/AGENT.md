---
name: ops-hotfix-pipeline
description: Sentry→Slack 에러 자동 감지 → 도메인별 분석 → 유형별(DB/코드/혼합) 자동 분기 → SQL 전달 또는 PR 생성
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

Sentry에 수집된 서버 에러를 자동으로 감지하고, 도메인별 컨텍스트를 활용하여 분석/수정/PR 생성까지 처리합니다.

## 도메인 에이전트 연동

에러의 패키지 경로에서 도메인을 판별하고, 해당 `domains/*.md`를 참조합니다.

```
스택트레이스 패키지 경로 → 도메인 판별 → domains/{domain}.md 참조
  ├─ domain.employee    → domains/hr.md
  ├─ domain.salary      → domains/salary.md
  ├─ domain.construction → domains/construction.md 또는 domains/resource.md
  ├─ domain.material    → domains/material.md
  ├─ domain.management  → domains/contract.md
  ├─ domain.attendance  → domains/attendance.md
  └─ global.*           → 공통 (도메인 에이전트 불필요)
```

도메인 에이전트는 해당 도메인의 Entity 구조, 비즈니스 규칙, 에러 패턴을 알고 있으므로 매번 docs를 읽지 않아도 원인 분석이 가능합니다.

## 도메인 에이전트 양식

각 `domains/*.md`는 아래 구조를 따릅니다:

```markdown
# {도메인명}

## Entity 관계
(테이블 관계도)

## 핵심 비즈니스 규칙
(검증 로직, 상태 전이, 계산 공식 등)

## 주요 API
(엔드포인트 목록 + 역할)

## 자주 발생하는 에러 패턴
(에러 → 원인 → 해결 매핑)

## 관련 파일
(Service, Entity, Repository 경로)
```

## 파이프라인 전체 흐름

(이하 기존 AGENT.md 내용과 동일 — Phase 1~6)
```
Phase 1: Sentry API 조회 → 새 미해결 이슈 감지
Phase 2: 스택트레이스 파싱 → 도메인 판별 → 도메인 에이전트 참조
Phase 3: 에러 유형 분류 (DB/코드/혼합) → 경로별 처리
Phase 4: 개발자 승인 (SOTT)
Phase 5: 코드 수정 + PR 생성 (코드 에러) / Slack SQL 전달 (DB 에러)
Phase 6: Codex 리뷰 반영
```
