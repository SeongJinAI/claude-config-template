# Handoff Sessions

> 활성 세션 목록. 각 세션은 독립적으로 운영되며, `/clear` 시 해당 세션 파일만 업데이트합니다.

## Active Sessions

| 세션 | 파일 | 용도 | 마지막 업데이트 |
|------|------|------|----------------|
| main | [main.md](main.md) | 메인 기능 개발 | - |
| hotfix | [hotfix.md](hotfix.md) | 핫픽스/이슈 처리 | - |
| infra | [infra.md](infra.md) | 인프라/자동화 | - |

## Session Routing

1. 사용자가 세션을 명시하면 해당 파일 사용
2. 미지정 시 브랜치 패턴: `hotfix/*` → hotfix, `infra/*` → infra
3. 기본값: `main`

## Rules

- 자기 세션 파일만 **쓰기**, 다른 세션 파일은 **읽기만**
- `/clear` 시: 세션 파일 업데이트 + INDEX.md 마지막 업데이트 갱신
- 세션 추가 시: 이 파일에 행 추가 + 새 파일 생성
