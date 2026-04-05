---
description: AI 오해 감지 데이터를 분석하여 개선 리포트 생성
---

# /misunderstanding-report

.aiops/misunderstandings/ 에 축적된 오해 감지 데이터를 분석하여 패턴 리포트를 생성합니다.

## 사용법

```bash
/misunderstanding-report              # 최근 7일 분석
/misunderstanding-report --days=30    # 최근 30일 분석
```

## 수행 작업

1. 프로젝트의 `.aiops/misunderstandings/*.jsonl` 파일 읽기
2. 패턴별 통계 분석 (rejection/correction/retry)
3. 반복 오해 패턴 식별 (같은 키워드가 3회 이상)
4. prev_prompt → prompt 연결로 "어떤 요청에서 오해가 발생하는지" 분석
5. 개선 제안 생성

## 출력 형식

```
오해 감지 분석 리포트 (최근 7일)

전체: N건
  rejection (거부): N건
  correction (수정): N건
  retry (재시도): N건

반복 패턴:
  - "아니야" 키워드 N회 — 주로 [상황] 에서 발생
  - "다시 해봐" 키워드 N회 — 주로 [상황] 에서 발생

개선 제안:
  - [구체적 개선 방안]
```

**IMPORTANT**: 데이터가 없으면 "오해 감지 데이터가 없습니다. 개발을 더 진행한 후 다시 실행해보세요."로 안내합니다.
