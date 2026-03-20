# CLAUDE.md

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

[프로젝트명] - FastAPI 기반 REST API 백엔드

## 빌드 및 실행 명령어

```bash
cd backend
source venv/bin/activate           # 가상환경 활성화
pip install -r requirements.txt    # 의존성 설치
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000  # 개발 서버
pytest                             # 테스트 실행
pytest tests/test_file.py::test_name  # 단일 테스트
alembic upgrade head               # DB 마이그레이션 적용
alembic revision --autogenerate -m "설명"  # 마이그레이션 생성
```

## 아키텍처

### 기술 스택

- Python 3.11+, FastAPI
- SQLAlchemy 2.0 (async)
- PostgreSQL
- Pydantic v2
- JWT 인증

### 패키지 구조

```
app/
├── api/
│   ├── v1/           # 라우트 핸들러
│   └── deps.py       # FastAPI 의존성 (get_db, get_current_user)
├── services/         # 비즈니스 로직
├── models/           # SQLAlchemy ORM 모델
├── schemas/          # Pydantic 스키마
├── core/             # 설정, 상수, 보안
├── db/               # 데이터베이스 설정
└── main.py           # 앱 진입점
```

### 의존성 주입 타입 별칭

```python
DBSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]
```

## 환경 변수

```bash
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/dbname
JWT_SECRET=your-secret-key
JWT_ALGORITHM=HS256
```

## API 문서

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 기능 개발 체크리스트

- [ ] 기능명세서 작성
- [ ] ERROR_MESSAGES.md 업데이트
- [ ] 테스트 작성
- [ ] 마이그레이션 생성 (DB 변경 시)
