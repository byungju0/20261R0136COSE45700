# Tracker

불법 프로그램 탐지 AI — NC AI 게임 보안 담당자를 위한 자동화된 불법 프로그램 유포 탐지 시스템.

## 프로젝트 구조 개요

본 저장소는 4개 서브시스템 + 공유 모듈로 구성된 **모노레포**입니다.

```
.
├── crawler/          # Python — 웹 크롤링 + 전처리 (Playwright + APScheduler)
├── detection/        # Python — VARCO Translation/LLM 기반 AI 탐지
├── api/              # Java Spring Boot 3.5 — REST API
├── dashboard/        # React + Vite + TypeScript — 운영자 대시보드
├── shared/           # Python 공유 모듈 (placeholder, Story 1.2)
├── infra/            # Docker Compose, Prometheus, Grafana (placeholder, Story 1.3)
├── tests/            # 크로스 컴포넌트 테스트 (fixtures/e2e/performance/chaos)
├── .github/workflows/  # CI/CD 워크플로우 (placeholder, Story 1.5)
└── _bmad-output/     # 기획·구현 산출물 (BMad Method)
```

## 사전 요구사항

- **Python 3.11+** (개발 환경 검증: 3.14)
- **Java 21 LTS** (Gradle Foojay Toolchain Resolver가 자동 다운로드 가능)
- **Node.js 20.19+** (개발 환경 검증: 25)
- **npm** (Node.js와 함께 설치됨)

> Java 21이 로컬에 없어도 `./gradlew build` 첫 실행 시 Foojay 리졸버가 자동으로 다운로드합니다.

## 로컬 셋업

신규 팀원이 저장소를 클론한 뒤 실행하는 표준 절차입니다.

```bash
git clone <repository-url>
cd 20261R0136COSE45700

# 1) crawler 셋업 (Python venv + 의존성 + Playwright Chromium)
python3 -m venv crawler/.venv
crawler/.venv/bin/pip install -r crawler/requirements.txt
crawler/.venv/bin/playwright install chromium

# 2) detection 셋업 (Python venv + 의존성)
python3 -m venv detection/.venv
detection/.venv/bin/pip install -r detection/requirements.txt

# 3) api 셋업 (Spring Boot — Gradle이 의존성 자동 다운로드)
cd api && ./gradlew build && cd ..

# 4) dashboard 셋업 (Vite + React)
cd dashboard && npm install && cd ..
```

각 서브시스템의 가상환경/의존성 캐시(`.venv/`, `node_modules/`, `.gradle/`, `build/`)는 git에서 제외되며, 위 명령으로 각 개발자 머신에서 동일하게 재현됩니다.

## 빠른 검증

각 서브시스템이 셋업되었는지 확인하는 명령:

```bash
# crawler
crawler/.venv/bin/python -c "import playwright; print(playwright.__version__)"
# 출력: 1.58.0

# detection
detection/.venv/bin/python -c "import httpx, redis, boto3, dotenv; print('detection OK')"

# api
cd api && ./gradlew build && cd ..
# 출력: BUILD SUCCESSFUL

# dashboard
cd dashboard && npm run build && cd ..
# 출력: ✓ built in <time>
```

## 다음 단계

본 스토리(1.1)는 **스캐폴딩만** 포함합니다. 후속 스토리에서 다음이 채워집니다:

- **Story 1.2** — `shared/` 공유 인터페이스 계약 (`correlation_id.py`, `crawl_event.py`, `varco.py` 등) 및 구조화 로깅 표준
- **Story 1.3** — `infra/docker-compose.yml` 로컬 개발 환경 (Redis + PostgreSQL), `.env.example` 본문
- **Story 1.4** — Flyway DB 초기 스키마, VARCO Mock 서버, 테스트 픽스처
- **Story 1.5** — GitHub Actions CI 파이프라인 4개 워크플로우

## 기획·아키텍처 문서

- [PRD](_bmad-output/planning-artifacts/prd.md) — 제품 요구사항 정의서
- [Architecture](_bmad-output/planning-artifacts/architecture.md) — 시스템 아키텍처 결정 문서
- [Epics](_bmad-output/planning-artifacts/epics.md) — 에픽 및 스토리 분해
- [Sprint Status](_bmad-output/implementation-artifacts/sprint-status.yaml) — 스프린트 진행 현황
