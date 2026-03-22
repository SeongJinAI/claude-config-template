---
description: 사용자 피드백을 PR로 변환
---

# /feedback-to-pr

사용자 피드백을 수집/분석하고 개선사항을 PR로 자동 생성합니다.

## 사용법

```bash
/feedback-to-pr                           # 대화형 피드백 수집
/feedback-to-pr --file=feedback.md        # 피드백 파일에서 읽기
/feedback-to-pr --issue=123               # GitHub 이슈에서 읽기
/feedback-to-pr --dry-run                 # PR 생성 없이 미리보기
```

## 수행 작업

### 1. 피드백 수집

- **대화형 모드**: 사용자에게 피드백 내용 직접 입력 받음
- **파일 모드**: `references/templates/feedback-template.md` 양식의 파일에서 읽기
- **이슈 모드**: GitHub 이슈에서 읽기

### 2. 피드백 분석 및 분류

| 카테고리 | 설명 |
|---------|------|
| 버그 | 기능이 의도대로 동작하지 않음 |
| UI/UX | 사용성 개선 |
| 기능 요청 | 새로운 기능 추가 |
| 성능 | 속도/리소스 관련 |
| 문서 | 문서 보완 필요 |

### 3. 개선 작업 도출

분석 결과 출력:
- 분류, 관련 모듈, 우선순위
- 도출된 작업 목록
- 관련 파일 경로

### 4. PR 생성

`references/templates/pr-template.md` 양식으로 PR 생성:
1. 피처 브랜치 생성
2. 코드 수정 수행
3. 커밋 + PR 생성

## 옵션

| 옵션 | 설명 |
|------|------|
| `--file=<path>` | 피드백 파일 경로 |
| `--issue=<number>` | GitHub 이슈 번호 |
| `--dry-run` | PR 생성 없이 분석 결과만 출력 |
| `--auto` | 확인 없이 자동 진행 |
| `--branch=<name>` | 브랜치명 직접 지정 |

**IMPORTANT**: PR 생성 전 반드시 사용자에게 작업 내용을 확인받으세요.
