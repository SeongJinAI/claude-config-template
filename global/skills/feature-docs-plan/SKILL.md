---
description: 기능 계획 단계에서 기능명세서와 아키텍처 설명서 초안을 생성
---

# /feature-docs-plan

코드 구현 전, 기획 내용을 기반으로 기능명세서와 아키텍처 설명서 초안을 생성합니다.
문서는 **지식 레포**에 저장됩니다.

## 사용법

```bash
/feature-docs-plan [기능명]
/feature-docs-plan 주문 취소 기능
```

## 저장 위치

문서 저장 위치 (우선순위):

1. `CLAUDE_KNOWLEDGE_REPO` 환경변수가 설정된 경우 → 지식 레포에 저장
2. 프로젝트에 `src/docs/` 디렉토리가 있는 경우 → 프로젝트 내 저장
3. 둘 다 없으면 → 프로젝트 루트 `docs/`에 저장

```
# CLAUDE_KNOWLEDGE_REPO 설정 시
{CLAUDE_KNOWLEDGE_REPO}/specs/{프로젝트명}-{기능명}-기능명세서.md
{CLAUDE_KNOWLEDGE_REPO}/architecture/{프로젝트명}-{기능명}-아키텍처.md

# 프로젝트 내 저장 시 (폴백)
{PROJECT_ROOT}/src/docs/specs/{기능명}_기능명세서.md
{PROJECT_ROOT}/src/docs/architecture/{기능명}_아키텍처_설명서.md
```

## 수행 작업

### 1. 기능 정보 수집

사용자에게 다음을 질문:
- 기능 개요 (무엇을 만드는가)
- 관련 엔티티/모델
- 주요 API 엔드포인트
- 비즈니스 규칙
- 참고할 기존 기능 (있다면)

### 2. 기능명세서 초안 생성

`references/templates/feature-spec-template.md` 양식에 따라 작성:
- API 엔드포인트 목록 (Method, URL, 요청/응답)
- 검증 흐름도 (ASCII 다이어그램)
- 검증 체크리스트 (항목별 조건/에러코드)
- 에러 코드 정의

### 3. 아키텍처 설명서 초안 생성

`references/templates/architecture-template.md` 양식에 따라 작성:
- 전체 흐름 (Big Picture)
- 시퀀스 다이어그램 (주요 흐름)
- Entity 관계도
- 테스트 시나리오
- 권한 구분 (해당 시)

## 생성 후 안내

```
기능명세서 초안 생성 완료: {KNOWLEDGE_REPO}/specs/{프로젝트명}-{기능명}-기능명세서.md
아키텍처 설명서 초안 생성 완료: {KNOWLEDGE_REPO}/architecture/{프로젝트명}-{기능명}-아키텍처.md

다음 단계:
  1. 초안 검토 후 보완
  2. 코드 구현 시작
  3. 구현 완료 후 /feature-docs-complete 실행
```

**IMPORTANT**: CLAUDE_KNOWLEDGE_REPO가 설정되지 않으면 프로젝트 내 docs 디렉토리에 저장합니다 (src/docs/ > docs/ 순으로 탐색). 이 단계의 문서는 초안이며, /feature-docs-complete에서 최종 반영합니다.
