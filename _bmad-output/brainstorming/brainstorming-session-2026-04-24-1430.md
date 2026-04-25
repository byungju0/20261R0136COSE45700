---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: ['tracker_기획서.md']
session_topic: 'Tracker 프로젝트 미결 기술 결정 사항 해소'
session_goals: '7개 미결 항목(아키텍처 옵션, 크롤링 주기/사이트/브라우저/프록시, BERT, EC2 타입)에 대한 판단 기준 및 결정안 도출'
selected_approach: 'ai-recommended'
techniques_used: ['Six Thinking Hats']
ideas_generated: 7
session_active: false
workflow_completed: true
context_file: 'tracker_기획서.md'
---

# Brainstorming Session Results

**팀:** Tracker
**날짜:** 2026-04-24

## Session Overview

**주제:** Tracker 프로젝트 미결 기술 결정 사항 해소
**목표:** 7개 미결 항목에 대한 판단 기준 및 결정안 도출

### Context Guidance

기획서(tracker_기획서.md) 기반. 미결 항목:
1. 아키텍처 옵션 A vs B (전처리 위치)
2. 크롤링 주기
3. 크롤링 대상 사이트 MVP 범위
4. 브라우저 스텔스 (Nodriver vs Playwright+stealth)
5. 프록시 프로바이더
6. BERT 2차 필터 도입 여부/모델
7. Detection EC2 인스턴스 타입

### Session Setup

기획서 내 7개 팀 결정 필요 항목을 브레인스토밍을 통해 결정안을 도출하는 세션.

---

## Technique Execution Results

**Six Thinking Hats — 7개 항목 순차 검토**

---

## 결정 사항 정리

### 인프라 / 아키텍처

**[결정 #1]**: 아키텍처 옵션 A — Crawler EC2 인라인 전처리
- Crawler EC2가 수집 + 전처리(HTML·언어감지·해시·키워드) 인라인 수행
- S3 재읽기 없음, API EC2 SPOF 위험 제거, Detection EC2는 AI 전담
- **결론: 옵션 A 채택**

**[결정 #7]**: Detection EC2 인스턴스 타입
- VARCO는 외부 API 호출이므로 EC2 연산 부하 거의 없음
- t3.medium으로 시작, BERT 도입 확정 시 t3.large 또는 g4dn으로 업사이징
- **결론: t3.medium (BERT 결정과 연동)**

---

### 크롤링 전략

**[결정 #2]**: 크롤링 주기
- MVP 기본: 1시간 주기
- APScheduler interval을 환경변수로 외부화 → 재배포 없이 15분 전환 가능
- **결론: 1시간 기본, 15분 확장 가능 설계**

**[결정 #3]**: 크롤링 대상 사이트 (최종 수정)
- tailstar.net (한국, 리니지 매크로 — NC 타이틀 직접 연관)
- PTT, Dcard (대만, 번체 중국어 — GFW 이슈 없음)
- tieba.baidu.com, 52pojie.cn, bbs.nga.cn (중국 본토 — 연결 성공 확인 시 운영)
- **결론: 총 6개 사이트, 연결 성공 확인된 사이트만 MVP 운영**

**[결정 #4]**: 브라우저 스텔스
- 팀 협업 시 문서·예제 풍부한 Playwright + stealth plugin 채택
- Cloudflare는 FlareSolverr 병행
- **결론: Playwright + stealth (Nodriver 대비 팀 생산성 우선)**

**[결정 #5]**: 프록시 프로바이더 (최종 수정)
- 개발·PoC: ProxyBroker (무료 오픈소스)
- 중간발표·본 운영: NodeMaven (중국 IP 전문, ~$50~80/월, GFW 우회 강점)
- 한국/대만 사이트 차단 시 IPRoyal ISP 병행 가능
- Tor: GFW exit 노드 공개 차단, 속도 3~10초 → 배제
- **결론: 단계별 업그레이드 (ProxyBroker → NodeMaven)**

---

### AI 파이프라인

**[결정 #6]**: BERT 2차 필터 도입 여부
- MVP는 BERT 없이 키워드 필터 → VARCO LLM 운영
- 5~7주차 VARCO LLM 탐지 F1 측정 결과 보고 AI 담당자(일드매) 결정
- **결론: AI 담당자 위임 (실측 데이터 기반 결정, 결정 #7 EC2 타입과 연동)**

---

## 기획서 반영 필요 사항

| 섹션 | 변경 내용 |
|------|-----------|
| 1.3 MVP KPI | 크롤링 주기: 1시간 (15분 확장 가능) |
| 2.1.2 아키텍처 옵션 | **옵션 A 확정** — 옵션 B 항목 삭제 또는 각주 처리 |
| 2.2 다이어그램 | 옵션 A 다이어그램만 유지 |
| 3.1 크롤링 사이트 | tailstar.net + PTT + Dcard + 중국 3개 (총 6개로 업데이트) |
| 3.2.1 브라우저 스텔스 | **Playwright + stealth 확정** |
| 3.2.3 프록시 | ProxyBroker(개발) → NodeMaven(본 운영) 단계별 전략으로 업데이트 |
| 4.2 탐지 파이프라인 | BERT [TBD] 항목: "AI 담당자 실측 후 결정" 명시 |
| 2.1 Detection EC2 | t3.medium으로 명시 (BERT 도입 시 업그레이드 조건 추가) |

---

## Session Summary

**세션 성과:**
- 7개 미결 항목 전부 결정 완료
- 연쇄 결정(BERT ↔ EC2 타입) 관계 명확화
- 크롤링 사이트 6개로 재구성 (대만 추가, 중국 조건부 포함)
- 프록시 단계별 전략으로 비용 최소화

**핵심 인사이트:**
- 중국 본토 제외 → 재포함으로 방향 전환, NodeMaven이 최적 선택
- BERT는 선결정보다 실측 기반 결정이 오버엔지니어링 방지에 유리
- 아키텍처 A 선택으로 API EC2 SPOF 위험 제거

**다음 액션:**
1. tracker_기획서.md 위 표 반영 항목 업데이트
2. tailstar.net, PTT, Dcard 접속 테스트 (Playwright + ProxyBroker)
3. 중국 사이트 3개 차단율 실측 → NodeMaven 도입 시점 결정
4. VARCO LLM 연동 후 F1 측정 → BERT 도입 여부 일드매 결정
