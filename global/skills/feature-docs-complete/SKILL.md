---
description: 구현 완료 후 7종 문서를 지식 레포에 일괄 생성/업데이트
---

# /feature-docs-complete

코드 구현이 완료된 후, 코드를 분석하여 7종 문서를 **지식 레포**에 일괄 생성하거나 기존 문서를 업데이트합니다.

## 사용법

```bash
/feature-docs-complete [기능명]
/feature-docs-complete 주문 취소 기능
/feature-docs-complete --module=order        # 특정 모듈만
```

## 저장 위치

문서는 `CLAUDE_KNOWLEDGE_REPO` 환경변수 (또는 `~/.claude/.env`)에 지정된 지식 레포에 저장합니다.

```
{CLAUDE_KNOWLEDGE_REPO}/
├── specs/{프로젝트명}-{기능명}-기능명세서.md
├── architecture/{프로젝트명}-{기능명}-아키텍처.md
├── architecture/{프로젝트명}-{기능명}-아키텍처-특이사항.md
├── manuals/{프로젝트명}-{기능명}-사용자매뉴얼.md
├── errors/{프로젝트명}-{기능명}-에러메시지.md
├── troubleshooting/{프로젝트명}-{기능명}-트러블슈팅.md
└── insights/{프로젝트명}-{기능명}-인사이트.md
```

프로젝트명은 현재 git 루트의 디렉토리명을 사용합니다.

## 수행 작업

### 1. 코드 분석

구현된 코드에서 다음을 자동 추출:
- 엔드포인트 (Controller/Router 어노테이션/데코레이터)
- 서비스 레이어 (비즈니스 로직)
- 엔티티/모델 (데이터 구조)
- 에러 코드 (ErrorCode enum/상수)
- 검증 규칙 (@Valid, 커스텀 검증)

### 2. 문서 생성/업데이트 (7종)

| 순서 | 문서 | 상태 | 템플릿 |
|------|------|------|--------|
| 1 | 기능명세서 | 신규 생성 또는 초안 업데이트 | `feature-spec-update-guide.md` |
| 2 | 아키텍처 설명서 | 신규 생성 또는 초안 업데이트 | `architecture-update-guide.md` |
| 3 | 사용자 매뉴얼 | 신규 생성 | `user-manual-template.md` |
| 4 | 에러 메시지 문서 | 신규 생성 또는 추가 | `error-messages-template.md` |
| 5 | 트러블슈팅 문서 | 신규 생성 | `troubleshooting-template.md` |
| 6 | 인사이트 문서 | 신규 생성 | `insights-template.md` |
| 7 | 아키텍처 특이사항 | 신규 생성 | `architecture-notes-template.md` |

### 3. 문서-코드 검증

생성된 문서와 코드의 동기화 상태를 자동 검증:
- 문서에 기술된 엔드포인트가 코드에 존재하는지
- 코드에 있는 엔드포인트가 문서에 빠지지 않았는지
- 에러 코드가 일치하는지

## 생성 후 안내

```
문서 생성 완료 (7종) → {KNOWLEDGE_REPO}/
  1. specs/{프로젝트명}-{기능명}-기능명세서.md
  2. architecture/{프로젝트명}-{기능명}-아키텍처.md
  3. manuals/{프로젝트명}-{기능명}-사용자매뉴얼.md
  4. errors/{프로젝트명}-{기능명}-에러메시지.md
  5. troubleshooting/{프로젝트명}-{기능명}-트러블슈팅.md
  6. insights/{프로젝트명}-{기능명}-인사이트.md
  7. architecture/{프로젝트명}-{기능명}-아키텍처-특이사항.md

문서-코드 검증 결과:
  일치: N개 / 불일치: N개
```

## 옵션

| 옵션 | 설명 |
|------|------|
| `--module=<name>` | 특정 모듈만 대상 |
| `--update-only` | 기존 문서 업데이트만 (신규 생성 안 함) |
| `--dry-run` | 파일 생성 없이 미리보기 |

**IMPORTANT**: CLAUDE_KNOWLEDGE_REPO가 설정되지 않으면 사용자에게 안내 후 중단합니다. /feature-docs-plan으로 초안을 먼저 만들었다면 해당 문서를 업데이트합니다.
