# CLAUDE.md

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

[프로젝트명] - Spring Boot 기반 REST API 백엔드

## 빌드 및 실행 명령어

```bash
./gradlew build                    # 빌드
./gradlew bootRun                  # 로컬 실행
./gradlew test                     # 테스트 실행
./gradlew test --tests "com.example.SomeTestClass"  # 단일 테스트
./gradlew compileJava              # QueryDSL Q클래스 생성
./gradlew clean build              # 클린 빌드
```

## 아키텍처

### 기술 스택

- Java 21, Spring Boot 3.x, Gradle (Kotlin DSL)
- JPA + QueryDSL (+ MyBatis 선택적)
- MySQL/MariaDB/PostgreSQL
- Spring Security + JWT 인증
- Swagger/OpenAPI (springdoc-openapi)

### 패키지 구조

```
com.[회사명].[프로젝트명]
├── domain/           # 비즈니스 도메인 (DDD 스타일)
│   └── {도메인명}/
│       ├── controller/    # REST 엔드포인트
│       ├── dto/           # Request/Response DTO
│       ├── entity/        # JPA 엔티티
│       ├── repository/    # JPA 레포지토리
│       ├── service/       # 비즈니스 로직
│       └── specs/         # JPA Specifications
└── global/           # 공통 관심사
    ├── config/       # Spring 설정
    ├── enums/        # 공통 Enum
    ├── exception/    # 전역 예외 처리
    ├── response/     # API 응답 래퍼
    ├── security/     # JWT 인증
    └── util/         # 유틸리티
```

### 데이터 접근 우선순위

JPA 메서드 네이밍 → JPA Specifications (필터) → QueryDSL (동적 쿼리) → MyBatis (복잡 SQL)

## API 응답 패턴

```java
ApiResponse.success(data)           // 데이터 조회
ApiResponse.ok("생성 되었습니다.")    // CUD 성공
ApiResponse.error(errorCode)        // 에러
```

## 인증

`@AuthenticationPrincipal LoginUser loginUser` — `loginUser.userId()`, `loginUser.agencyCode()`

## API 문서

Swagger UI: `/swagger-ui/index.html`

## 스토리보드 기반 API 개발 워크플로

> 기획문서(스토리보드 PDF)가 있는 프로젝트에서 사용합니다.
> 상세 가이드: `claude-dotfiles/docs/templates/STORYBOARD_WORKFLOW.md`

### 스토리보드 파일 위치

| 항목 | 값 |
|------|-----|
| 위치 | `[기획문서 디렉토리 경로]` |
| 파일명 규칙 | `[파일명 패턴]` |

### 핵심 원칙

- **스토리보드 ≠ 최종 사양** → DB/비즈니스 로직은 기존 코드 분석 병행
- **유사 기능 참고 우선** → 기존 구현 패턴 분석 후 개발
- **문서 → 코드 → 매뉴얼** 순서 준수

## 기능 개발 체크리스트

- [ ] 기능명세서 작성
- [ ] 아키텍처 설명서 작성
- [ ] 사용자매뉴얼 작성
- [ ] ERROR_MESSAGES.md 업데이트
- [ ] 빌드 확인 (`./gradlew build`)
