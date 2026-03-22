---
description: 컨텍스트 초기화 전 인수인계 문서 업데이트
---

# /clear

컨텍스트를 초기화하기 전에 현재 작업 상태를 HANDOFF.md에 기록합니다.

## 사용법

```bash
/clear
```

## 수행 작업

1. HANDOFF.md 파일 확인 (없으면 생성)
2. 현재 날짜/시간으로 새 엔트리 추가 (최신이 상단)
3. 다음 정보 기록:
   - 완료된 작업
   - 현재 상태
   - 다음 작업
   - 주의사항
   - 관련 파일
4. "인수인계 완료" 메시지 출력

## HANDOFF.md 형식

`references/templates/handoff-template.md` 양식을 따릅니다.

**IMPORTANT**: 이 스킬 실행 시 HANDOFF.md 업데이트는 필수입니다. 절대 건너뛰지 마세요.
