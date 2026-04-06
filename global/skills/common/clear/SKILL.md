---
description: 컨텍스트 초기화 전 인수인계 문서 업데이트 (멀티 세션 지원)
---

# /clear

컨텍스트를 초기화하기 전에 현재 작업 상태를 handoff 파일에 기록합니다.

## 사용법

```bash
/clear
```

## 수행 작업

### 멀티 세션 모드 (`handoff/` 디렉토리 존재 시)

1. `handoff/INDEX.md` 확인 → 현재 세션 식별
   - 사용자가 명시한 세션 > 브랜치 패턴(`hotfix/*`→hotfix, `infra/*`→infra) > 기본값(`main`)
2. 해당 세션 파일(`handoff/{session}.md`) 업데이트
3. 다음 정보 기록:
   - 완료된 작업
   - 현재 상태 (브랜치, 커밋 상태)
   - 다음 작업
   - 주의사항
   - 관련 파일
   - 다음 세션 시작 프롬프트
4. `handoff/INDEX.md` 마지막 업데이트 갱신
5. "인수인계 완료 (세션: {name})" 메시지 출력

### 레거시 모드 (`handoff/` 없고 `HANDOFF.md` 존재 시)

1. HANDOFF.md 파일 확인 (없으면 생성)
2. 현재 날짜/시간으로 새 엔트리 추가 (최신이 상단)
3. `references/templates/handoff-template.md` 양식 따름
4. "인수인계 완료" 메시지 출력

## 세션 파일 형식

`references/templates/handoff-session-template.md` 양식을 따릅니다.

## 규칙

- 자기 세션 파일만 **쓰기**, 다른 세션 파일은 **읽기만**
- `/clear` 시 handoff 업데이트는 **필수**. 절대 건너뛰지 마세요.
