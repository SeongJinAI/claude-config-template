# CLAUDE.md

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

[프로젝트명] - Next.js 기반 프론트엔드

## 빌드 및 실행 명령어

```bash
npm install            # 의존성 설치
npm run dev            # 개발 서버 실행
npm run build          # 프로덕션 빌드
npm run start          # 프로덕션 서버 실행
npm run lint           # 린트 검사
npx tsc --noEmit       # 타입 검사
```

## 아키텍처

### 기술 스택

- Next.js 14 (App Router)
- React 18
- TypeScript
- TailwindCSS
- Zustand (상태 관리)

### 패키지 구조

```
src/
├── app/                  # App Router 페이지
│   ├── (auth)/           # 인증 관련 페이지
│   ├── (main)/           # 메인 페이지
│   ├── layout.tsx        # 루트 레이아웃
│   └── page.tsx          # 홈페이지
├── components/
│   ├── ui/               # 재사용 UI 컴포넌트
│   └── {feature}/        # 기능별 컴포넌트
├── lib/
│   ├── api/              # API 클라이언트
│   └── utils/            # 유틸리티 함수
├── stores/               # Zustand 스토어
├── types/                # TypeScript 타입
└── styles/               # 전역 스타일
```

## 환경 변수

```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:8000
```

`NEXT_PUBLIC_` 접두사: 클라이언트에서 접근 가능

## 기능 개발 체크리스트

- [ ] 컴포넌트 작성
- [ ] 타입 정의
- [ ] API 연동
- [ ] 린트/타입 검사 통과
