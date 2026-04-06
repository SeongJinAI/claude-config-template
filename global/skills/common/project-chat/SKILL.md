---
description: 프로젝트 문서 기반 Q&A
---

# /project-chat

프로젝트의 문서(기능명세서, 사용자매뉴얼, 도메인 문서)를 기반으로 질문에 답변합니다.
**지식 레포**와 프로젝트 내 docs/ 디렉토리 모두 검색합니다.

## 사용법

```bash
/project-chat 주문 취소는 어떻게 작동하나요?
/project-chat --source=specs 결제 실패 시 처리 흐름
/project-chat --verbose 사용자 인증 방식
```

## 검색 대상

1. **프로젝트 내 문서** (항상 검색)
   - `src/docs/` 또는 `docs/` 디렉토리
   - specs/, architecture/, user-guide/, issues/, insights/ 등
2. **지식 레포** (`CLAUDE_KNOWLEDGE_REPO` 설정 시 추가 검색)
   - specs/, architecture/, manuals/, errors/, troubleshooting/, insights/

현재 프로젝트명으로 필터링하여 관련 문서를 우선 검색합니다.

## 수행 작업

### 1. 문서 검색

질문 키워드 분석 후 우선순위 결정:
1. YAML 프론트매터의 `keywords`, `tags` 매칭
2. 문서 제목 매칭
3. 본문 내용 검색

### 2. 답변 생성

- 문서에 있는 내용: 정확한 출처(파일경로:라인)와 함께 답변
- 문서에 없는 내용: "문서에 없음" 명시, 코드 유추 가능 시 별도 표시
- 상충 정보: 여러 문서에서 다른 정보가 있으면 모두 언급

## 옵션

| 옵션 | 설명 |
|------|------|
| `--source=<type>` | 특정 문서 유형만 참조 (specs, manuals, architecture, errors, troubleshooting, insights) |
| `--verbose` | 참조 문서 상세 내용 포함 |
| `--suggest` | 문서 개선 제안 포함 |

**IMPORTANT**: 항상 답변의 출처를 명시하고, 문서에 없는 내용은 반드시 별도로 표시하세요. CLAUDE_KNOWLEDGE_REPO가 설정되지 않으면 프로젝트 내 docs/만 검색합니다.
