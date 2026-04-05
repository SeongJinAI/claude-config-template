# CLAUDE.md

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

[프로젝트명] - React SPA (Vite 기반)

## 빌드 및 실행 명령어

```bash
npm install            # 의존성 설치
npm run dev            # 개발 서버 실행
npm run build          # tsc -b && vite build
npm run lint           # 린트 검사
npm run preview        # 빌드 결과 미리보기
```

## 아키텍처

### 기술 스택

- Vite + React 19
- TypeScript
- TailwindCSS
- React Query (서버 상태 관리)

### 패키지 구조

```
src/
├── components/
│   ├── ui/               # 재사용 UI 컴포넌트
│   └── {feature}/        # 기능별 컴포넌트
├── pages/                # 페이지 컴포넌트
├── hooks/                # 커스텀 훅
├── lib/
│   ├── api/              # API 클라이언트
│   └── utils/            # 유틸리티 함수
├── types/                # TypeScript 타입
├── constants/            # 상수
├── App.tsx               # 루트 컴포넌트
└── main.tsx              # 진입점
```

## 환경 변수

```bash
# .env
VITE_API_URL=http://localhost:8000
```

`VITE_` 접두사: 클라이언트에서 접근 가능
