---
description: Notion 업무 체크리스트 관리
---

# /notion

Notion 업무 페이지의 체크리스트 항목을 관리합니다.

## 사용법

```bash
/notion add <메뉴> "<항목>"                          # 체크리스트 항목 추가
/notion add <메뉴> "<항목>" --detail "<상세내용>"     # 수정 완료 후 해결 기록 포함 추가
/notion done "<키워드>"                               # 키워드로 항목 찾아 체크 처리
/notion list <메뉴>                                   # 특정 메뉴 하위 항목 조회
/notion list                                          # 전체 메뉴 목록 조회
```

## to_do 항목 양식

### 기본 형식

```
구분 > [기능명] > 작업유형 > 설명
```

| 요소 | 값 | 선택 기준 |
|------|-----|----------|
| 구분 | `API` / `DB` / `확인` | API: 코드 수정, DB: DDL/마이그레이션/주석, 확인: 기획 의도 확인 필요 |
| 기능명 | 실제 기능명 | 해당 도메인의 세부 기능 (예: 급여계산, 증명서발급, 숙소임차비) |
| 작업유형 | `신규` / `수정` / `개선` / `제거` | 신규: 새 기능, 수정: 버그 수정, 개선: 성능/구조 개선, 제거: 삭제 |
| 설명 | 자유 텍스트 | 무엇을 왜 변경하는지 간결하게 |

**IMPORTANT**: 기능명은 반드시 **실제 기능명**을 사용합니다. 추상적 라벨(예: `[코드리뷰-급여]`) 금지.

### toggle("기록") — 해결 과정 기록

toggle("기록")은 **수정 완료 후** 해결 과정을 기록하는 용도입니다. 이슈 등록 시점에는 to_do만 생성하고, 수정 완료 후 toggle을 추가합니다.

## 수행 작업

### add — 항목 추가

1. 메뉴명으로 대상 toggle block ID 결정
2. Notion API로 to_do 블록 추가
3. 결과 출력: `[add] 메뉴명 > + 항목 텍스트`

### add --detail — 해결 기록 포함 추가 (수정 완료 후)

to_do 블록 생성 후, **하위에 toggle 블록("기록") → 그 안에 paragraph 블록**으로 해결 과정을 구조화합니다.

**블록 구조**:
```
to_do ("구분 > [기능명] > 작업유형 > 설명")
  └── toggle ("기록")
        ├── paragraph ([심각도] ...)
        ├── paragraph ([현상] ...)
        ├── paragraph ([원인] ...)
        ├── paragraph ([수정 내용] ...)
        └── paragraph ([수정 파일] ...)
```

**API 호출 순서** (3단계 — Notion API는 2단계까지만 중첩 가능):
1. `PATCH /blocks/{MENU_TOGGLE_ID}/children` — to_do 블록 생성 → **to_do block ID** 획득
2. `PATCH /blocks/{TODO_BLOCK_ID}/children` — toggle 블록("기록") 생성 → **toggle block ID** 획득
3. `PATCH /blocks/{TOGGLE_BLOCK_ID}/children` — paragraph 블록들(해결 과정) 일괄 생성

**IMPORTANT**: to_do 하위에 직접 paragraph를 넣지 않습니다. 반드시 toggle("기록")을 중간에 두어 접기/펼치기가 가능하게 합니다.

**해결 기록 필드** (각각 paragraph 블록):

| 필드 | 형식 | 필수 |
|------|------|------|
| 심각도 | `[심각도]` bold + 등급 텍스트 | O |
| 현상 | `[현상]` bold + 설명 | O |
| 원인 | `[원인]` bold + 설명 | 선택 |
| 수정 내용 | `[수정 내용]` bold + 번호 목록 | O |
| 수정 파일 | `[수정 파일]` bold + 파일명 나열 | O |

#### 심각도별 스타일

| 심각도 | to_do 텍스트 | paragraph 색상 |
|--------|-------------|---------------|
| CRITICAL (운영 버그) | `[운영버그]` bold+red 접두사, 전체 텍스트 red | `"color": "red"` |
| HIGH | 기본 | `"color": "orange"` |
| MEDIUM / LOW | 기본 | 기본 |

**CRITICAL 항목 to_do rich_text 예시**:
```json
[
  {"type": "text", "text": {"content": "[운영버그] "}, "annotations": {"bold": true, "color": "red"}},
  {"type": "text", "text": {"content": "항목 텍스트"}, "annotations": {"color": "red"}}
]
```

### done — 항목 체크 처리

1. 키워드로 대상 메뉴 하위 to_do 블록 검색
2. 매칭되는 항목을 `checked: true`로 업데이트
3. 여러 개 매칭 시 목록을 보여주고 사용자에게 선택 요청

### list — 항목 조회

1. 메뉴 지정 시: 해당 toggle 하위 to_do 항목 목록 출력
2. 메뉴 미지정 시: 전체 메뉴(toggle) 목록 출력
3. 출력 형식: `[x]`/`[ ]` + 항목 텍스트

## 프로젝트별 설정

이 스킬은 인터페이스입니다. 프로젝트 `.claude/skills/notion.md`에서 오버라이딩하여 다음을 정의합니다:

- **Notion 토큰 위치**: `.claude/.mcp.json` 등
- **페이지 ID**: 대상 Notion 페이지
- **메뉴 → Block ID 매핑**: 프로젝트 메뉴 구조에 맞는 매핑 테이블
- **기능명 목록**: 프로젝트의 실제 기능명 매핑 (양식의 `[기능명]`에 사용)
- **메뉴명 매칭 규칙**: 부분 일치, 하위 메뉴 직접 지정 등

## 출력 형식

```
[add] <메뉴>
  + <항목 텍스트>

[add+detail] <메뉴>
  + <항목 텍스트>
    └── 기록 (toggle)

[done] <메뉴>
  [x] <항목 텍스트>

[list] <메뉴>
  [x] 완료된 항목
  [ ] 미완료 항목
```

**IMPORTANT**: Notion 업데이트 실패 시 에러를 출력하고, 코드 작업은 중단하지 않습니다.
**IMPORTANT**: 토큰은 런타임에 설정 파일에서 읽어야 합니다. 하드코딩 금지.
