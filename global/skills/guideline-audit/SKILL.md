---
description: 기능명세서 vs 코드베이스 가이드라인 위배 분석 및 Notion 리스트업
---

# /guideline-audit — 가이드라인 준수 감사

## 개요

src/docs/specs 기능명세서와 실제 코드베이스를 비교 분석하여 코드스타일 가이드라인 위배 사항을 발견하고, Notion에 작업 항목으로 등록합니다.

## 실행 조건

- `src/docs/specs/` 에 기능명세서가 존재해야 함
- `.claude/rules/코드스타일_가이드.md` 가 존재해야 함
- Notion 연동 시 `.claude/.mcp.json`의 `NOTION_TOKEN` 필요

## 워크플로

### Phase 1: 문서 분석

1. `src/docs/specs/` 의 모든 기능명세서 목록 파악
2. 각 명세서에서 API 엔드포인트, 데이터 모델, 에러 코드 추출
3. 도메인별 그룹핑 (최근 커밋 기반 우선순위 결정)

### Phase 2: 코드베이스 분석 (병렬 에이전트)

도메인별로 Explore 에이전트를 병렬 실행합니다. 각 에이전트의 분석 범위:

**에이전트 구성** (5개 그룹):
- 자재관리 (`domain/material/`, `domain/construction/` 중 철근/레미콘)
- 급여관리 (`domain/salary/`)
- 인사관리 (`domain/employee/`, `domain/user/`)
- 경비/공사관리 (`domain/construction/`)
- 공통/인증/기타 (`domain/auth/`, `domain/contract/`, `domain/management/`, `domain/attendance/`, `domain/workplan/`, `domain/dashboard/`, `domain/safety/`)

**10개 체크 항목**:

| # | 항목 | 근거 |
|---|------|------|
| 1 | Controller에서 Repository 직접 호출 금지 | feedback: Controller 레이어 분리 |
| 2 | API URL/함수명 camelCase | feedback: API camelCase 필수 |
| 3 | ErrorCode enum 사용 (문자열 리터럴 금지) | 코드스타일 8.2절 |
| 4 | Service 쓰기 메서드 void 반환 | 코드스타일 10.3절 |
| 5 | 신규 DTO는 record | 코드스타일 2절 |
| 6 | @Transactional 규칙 (클래스 readOnly, 쓰기만 @Transactional) | 코드스타일 4.1절 |
| 7 | Entity @NoArgsConstructor(access = PROTECTED) | 코드스타일 1.1절 |
| 8 | Controller 메서드명 `{entity}{Action}` 패턴 | 코드스타일 10.1절 |
| 9 | 명세서 API vs 실제 코드 구현 일치 | 워크플로 가이드 |
| 10 | 코드에 있지만 명세서에 없는 API (문서 미반영) | 워크플로 가이드 |

### Phase 3: 결과 종합

에이전트 결과를 수집하여 다음 형식으로 종합:

```markdown
| # | 도메인 | 위배 항목 | 심각도 | 건수 |
|---|--------|---------|--------|------|
```

심각도 기준:
- **P1**: 데이터 불일치(Entity/DB), 잘못된 예외 처리 → 운영 영향 가능
- **P2**: 컨벤션 위배(메서드명, DTO 타입), 문서 불일치 → 유지보수 영향
- **P3**: 사소한 개선 (validation 에러코드 등록 등) → 낮은 영향

### Phase 4: Notion 등록

위배 항목을 Notion 체크리스트로 등록합니다.

**메뉴 매핑 규칙**:
- 특정 도메인에 한정된 이슈 → 해당 메뉴 toggle
- 여러 도메인에 걸친 이슈 → `설계/인프라` toggle
- DB 스키마 관련 → `DB` 구분
- 명세서 확인 필요 → `확인` 구분
- 코드 수정 필요 → `API` 구분

**to_do 형식**: `/notion` 스킬의 양식 준수
```
구분(API/DB/확인) > [기능명] > 작업유형(수정/개선) > 설명 — 상세 (건수, 위치)
```

## 사용법

```
/guideline-audit              # 전체 도메인 감사
/guideline-audit 급여관리      # 특정 도메인만 감사
/guideline-audit --no-notion   # Notion 등록 없이 분석만
```

## 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| 도메인 지정 | 특정 도메인만 분석 | 전체 |
| `--no-notion` | Notion 등록 건너뛰기 | 등록 |
| `--recent` | 최근 30커밋 관련 도메인만 | 전체 |

## 에이전트 프롬프트 템플릿

각 Explore 에이전트에 전달하는 프롬프트:

```
프로젝트: {프로젝트 경로}

**분석 대상**: `domain/{도메인}/`

**먼저 기능명세서를 읽어라**:
- `src/docs/specs/{기능명}_기능명세서.md`

**그 다음 코드를 분석해라**:
해당 domain 하위 모든 Controller, Service, Entity, DTO, Repository 파일

**체크 항목**: (10개 체크 항목 전달)

**출력 형식**: 위배 항목별로 [파일경로:라인] + 위배 내용 + 수정 방향
thoroughness: very thorough
```
