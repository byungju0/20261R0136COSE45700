---
stepsCompleted: [1, 2, 3]
inputDocuments: ['tracker_기획서.md', '_bmad-output/planning-artifacts/research/technical-tracker-stack-research-2026-04-23.md']
session_topic: 'Tracker 프로젝트 7개 팀 결정 필요 항목'
session_goals: '각 이슈별 최적 선택지 결정 및 근거 도출'
selected_approach: 'Expert Panel Review'
techniques_used: ['Expert Panel Review', 'Technical Research']
ideas_generated: ['옵션 A 확정', 'BERT 미도입', 't3.medium', 'Zendriver', 'Oxylabs DC → IPRoyal ISP', '하루 2~4회 → 1시간', '3주차 실측 확정']
context_file: 'tracker_기획서.md'
status: 'completed'
---

# Brainstorming Session Results

**진행자:** Tracker
**날짜:** 2026-04-23

## Session Overview

**주제:** Tracker 프로젝트 — 7개 팀 결정 필요 항목
**목표:** 각 이슈별 최적 선택지 결정 및 근거 도출

### 진행 방식
**Expert Panel Review** — 도메인 전문가 패널 (Alex·Jin·Sara·Min) 심층 분석
**Technical Research** — 웹 리서치로 최신 벤치마크 데이터 보강

---

## 최종 결정 사항

| # | 이슈 | 결정 | 근거 |
|---|------|------|------|
| 1 | **아키텍처 옵션** | **옵션 A** (Crawler 인라인 전처리) | S3 재읽기 제거, SPOF 위험 감소, 구현 단순성 |
| 2 | **BERT 2차 필터** | **미도입** (키워드→VARCO LLM 직행) | 수동 라벨링 시간 없음, 일정 현실 반영 |
| 3 | **Detection EC2** | **t3.medium** | BERT 미도입으로 GPU 불필요, 부하 시 t3.large 업그레이드 |
| 4 | **스텔스 브라우저** | **Zendriver** (Nodriver 교체) | Cloudflare 우회율 Nodriver 0% → Zendriver 75% |
| 5 | **프록시** | **MVP: Oxylabs DC / 본운영: IPRoyal ISP** | 단계별 비용 최적화, ProxyProvider 인터페이스 추상화 필수 |
| 6 | **크롤링 주기** | **MVP: 하루 2~4회 / 본운영: 1시간** | VARCO API 비용 절감, 발표 시 수동 트리거 활용 |
| 7 | **MVP 사이트 리스트** | **3주차 실측 후 확정** | GFW·Cloudflare 대응 결과 나와봐야 판단 가능 |

---

## 이슈별 상세 논의

### 이슈 1 — 아키텍처 옵션 A vs B

**패널 의견:**
- **Alex (크롤링)**: 크롤러 메모리에 데이터가 있는데 S3에 올렸다 다시 읽는 건 불필요한 I/O
- **Sara (비용)**: 옵션 B는 API EC2에 Spring + Redis + Worker 집중 → SPOF 위험. 11주 프로젝트에서 SPOF 복구 대응 어려움
- **Min (백엔드)**: Redis와 Worker가 같은 EC2에 있으면 API 트래픽 + 전처리 부하 동시 → Redis 지연 → Detection EC2도 영향
- **Jin (AI/ML)**: 중립. 전처리 로직 개선 용이성은 두 옵션 동일

**결정:** 옵션 A (3:1)

---

### 이슈 2 — BERT 2차 필터

**패널 의견:**
- **Jin**: KoELECTRA가 한국어 댓글 분류 최적. 단, fine-tuning에 라벨 데이터 100건+ 필요
- **Sara**: BERT 있으면 VARCO LLM 호출 50~70% 절감. 예산 절감 효과 있음
- **Alex**: BERT 미도입 시 Detection EC2 GPU 불필요 → EC2 비용 절감. 3~5주 일정에 BERT fine-tuning 병행은 빡빡
- **Min**: BERT 도입 시 Detection EC2 모델 서빙 환경 추가. 테스트 케이스 증가

**팀 결정 요인:** 수동 라벨링 시간 없음 → **미도입**

---

### 이슈 3 — Detection EC2 인스턴스 타입

BERT 미도입으로 자동 결정.
- GPU 연산 없음 → g4dn 불필요
- VARCO API 호출(네트워크 I/O)만 → t3.medium(2 vCPU, 4GB) 충분
- 필요 시 t3.large 업그레이드

---

### 이슈 4 — 크롤링 브라우저 스텔스

**기술 리서치 핵심 발견:**
- Nodriver: Cloudflare 우회율 **0%** (2025 기준)
- Zendriver (Nodriver fork): Cloudflare 우회율 **75%**
- Playwright+stealth: WebDriver 프로토콜 노출로 현대 anti-bot에 근본적 취약

**결정:** Nodriver → Zendriver 교체. API 호환성 거의 동일해 마이그레이션 비용 최소. FlareSolverr 추가 보험 유지.

---

### 이슈 5 — 프록시 프로바이더

MVP(중간발표)와 본 운영 2단계 전략 채택.
- MVP: 연결 성공 확인이 목표 → 저비용 Oxylabs DC 또는 무료 풀
- 본 운영: 안정적 ISP 프록시 → IPRoyal ISP ($40~80/월)
- **ProxyProvider 인터페이스 추상화 필수** — 교체 시 코드 수정 최소화

---

### 이슈 6 — 크롤링 주기

- 15분: VARCO 비용 ~48배, 과도함
- 1시간: ~12배, 본 운영 고려
- 하루 2~4회: MVP 현실적. 발표 데모는 수동 트리거(`POST /crawl/trigger`)로 대응

---

### 이슈 7 — MVP 크롤링 대상 사이트

사전 확정 불가. 3주차 크롤러 개발 초기에 실측 후 확정.
- 한국 사이트 5개: Cloudflare 유무 실측
- 중국 사이트 3개: GFW + Cloudflare 우회 성공 여부 실측

---

## 기획서 반영 필요 사항

1. **Nodriver → Zendriver** 교체 (3.2.1절)
2. **BERT 2차 필터 미도입** 확정 (4.2절, 5.1절 `[TBD]` 제거)
3. **Detection EC2 t3.medium** 확정 (10.1절 이슈 7 해소)
4. **프록시 2단계 전략** 반영 (3.2.3절)
5. **크롤링 주기 MVP 하루 2~4회** 확정 (1.3절 옵션 선택 완료)

---

## 참고 리서치

[기술 스택 상세 비교 분석](_bmad-output/planning-artifacts/research/technical-tracker-stack-research-2026-04-23.md)
