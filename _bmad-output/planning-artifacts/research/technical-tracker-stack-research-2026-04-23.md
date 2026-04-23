# Tracker 기술 리서치 — 상세 비교 분석

**날짜:** 2026-04-23
**목적:** 7개 팀 결정 이슈 중 기술 선택 근거 확보

---

## 1. BERT 2차 필터 — 경량 텍스트 분류 모델 비교

### 후보 모델

| 모델 | 유형 | 한국어 지원 | 추론 속도 | 학습 데이터 필요량 | 권장 용도 |
|------|------|------------|---------|-----------------|---------|
| **KoELECTRA** | ELECTRA 기반 | 네이티브 | 빠름 | 중간 (fine-tuning) | 한국어 분류 최강 |
| **KcBERT** | BERT 기반 | 네이티브 | 중간 | 중간 | 댓글/구어체 특화 |
| **SetFit + ModernBERT** | few-shot | 부분 | 매우 빠름 (67x faster) | 매우 적음 | 라벨 데이터 부족 시 |
| **FastText** | n-gram | 부분 | 최고속 | 적음 | 키워드 수준 분류 |
| **미도입 (키워드 필터만)** | 규칙 기반 | 완전 | 즉시 | 없음 | 단순 필터링 |

### 핵심 발견

- **SetFit (ModernBERT)**: few-shot 시나리오에서 GPT-3보다 우수, 1/1600 크기. 라벨 데이터가 적을 때 강점. IMDB 기준 표준 ModernBERT 62.5% → SetFit+ModernBERT 92.7%.
- **KoELECTRA**: 한국어 댓글/커뮤니티 텍스트에 최적. 불법 프로그램 판매 게시글 도메인에 fine-tuning 시 높은 정확도 기대.
- **FastText**: 속도는 최고이나 문맥 이해 부재. 키워드 필터(3.4단계)와 중복 역할.
- **미도입**: 키워드 필터 → VARCO LLM 직접 투입 구조. VARCO 호출 비용 증가하나 구현 단순.

### 권고

> **11주 일정 + 소규모 팀** 기준: **미도입(키워드 필터만) 또는 KoELECTRA 선택지 2개로 압축.**
> - 수동 라벨링 데이터셋 100건 이상 확보 가능 → KoELECTRA fine-tuning 권장
> - 확보 불가 또는 일정 압박 → BERT 미도입, VARCO LLM 직접 호출

---

## 2. 크롤링 스텔스 브라우저 — Playwright+stealth vs Nodriver/Zendriver

### 벤치마크 결과 (anti-bot 서비스 우회율)

| 도구 | Cloudflare | DataDome | 전반적 성공률 | 비고 |
|------|-----------|---------|------------|------|
| **Zendriver** (Nodriver fork) | ✅ 75% | 측정중 | 높음 | 2025 최신 포크, 활발한 유지보수 |
| **Nodriver** | ❌ 0% | 25% | 25% | Cloudflare 최신 버전에 취약 |
| **Playwright + stealth** | ❌ 낮음 | 낮음 | 25% | 기본 지문 우회만, 프로토콜 노출 |
| **Selenium** | ❌ | ❌ | 낮음 | 사실상 탐지됨 |

### 핵심 발견

- **Nodriver의 한계**: 원래 기획서 선정안이나, Cloudflare 최신 버전(2025)에서 **우회율 0%**. Zendriver(Nodriver fork)가 75%로 훨씬 우수.
- **Playwright+stealth**: 지문(fingerprint) 수준 우회만 가능. WebDriver 프로토콜 자체가 노출되어 현대 anti-bot에 취약. Python 패키지(v2.0.2)는 유지보수 활발하나 근본적 한계 존재.
- **Zendriver**: Nodriver의 fork로 같은 아키텍처 + 빠른 업데이트 주기. 현재(2025-2026) 가장 높은 Cloudflare 우회율.
- **FlareSolverr**: 별도 컨테이너로 Cloudflare JS 챌린지 자동 해결. Playwright/Nodriver와 병행 사용 가능.

### 권고

> 기획서의 **Nodriver → Zendriver로 교체** 권장.
> Cloudflare 우회율 0% → 75% 향상. API 호환성은 Nodriver와 거의 동일해 마이그레이션 비용 최소.
> FlareSolverr는 추가 보험으로 유지.

---

## 3. Redis 메시지 큐 — BRPOPLPUSH vs Redis Streams

### 기능 비교

| 항목 | BRPOPLPUSH (LIST 기반) | Redis Streams |
|------|----------------------|--------------|
| **구현 복잡도** | 낮음 | 높음 |
| **메시지 확인(ACK)** | 수동 구현 필요 | 내장 (XACK) |
| **재시도/DLQ** | 수동 Watchdog 필요 | 내장 (Pending Entries List) |
| **다중 Consumer** | 단순 경쟁 소비 | Consumer Group으로 정교 분배 |
| **메시지 영속성** | 없음 (pop 후 소멸) | 있음 (스트림 보존) |
| **운영 복잡도** | 낮음 | 높음 (스트림 trimming 필요) |
| **Redis 버전** | 구버전 호환 | Redis 5.0+ |

### 핵심 발견

- 기획서의 **BRPOPLPUSH + Watchdog 패턴**은 실질적으로 Redis Streams의 핵심 기능을 수동 구현한 것.
- 단순 큐잉 요구사항(부하 분산 큐)에는 Redis List가 더 단순하고 효율적.
- Streams는 스트림 처리 시맨틱·영속성·복잡한 재시도가 필요할 때 적합 — 이 프로젝트 규모 초과.

### 권고

> **기획서의 BRPOPLPUSH + Watchdog 패턴 유지** 권장.
> 11주 프로젝트에서 Streams로 마이그레이션은 복잡도 대비 이득 없음.
> DLQ(`posts:dlq`) + Watchdog 재큐잉 로직으로 충분히 안정적 운영 가능.

---

## 4. VARCO LLM/Vision — NC AI API 스펙 및 성능

### VARCO LLM

| 항목 | 내용 |
|------|------|
| **개발사** | NC AI (NCSOFT) |
| **한국어 성능** | Logickor 벤치마크 10B 이하 모델 중 1위 |
| **GPT 비교** | GPT-3.5 Turbo 수준 |
| **최신 버전** | VARCO LLM 2.0 (2024.4), Llama-VARCO LLM (HuggingFace 오픈소스) |
| **특징** | 게임 도메인 용어 이해, 한국어 특화, JSON 구조화 출력 |
| **평가 모델** | VARCO Judge LLM (2024.9) — LLM 성능 평가 전용 |

### VARCO Vision

| 항목 | 내용 |
|------|------|
| **모델** | VARCO-VISION 2.0 14B |
| **벤치마크** | 한국어 이미지 이해 — InternVL3-14B, Ovis2-16B 능가 |
| **용도** | OCR + 이미지 내 불법 콘텐츠 판단 |
| **논문** | VARCO-VISION: Expanding Frontiers in Korean Vision-Language Models (arXiv 2411.19103) |

### 핵심 발견

- VARCO LLM은 **한국어 + 게임 도메인** 조합에서 현재 가장 적합한 API. GPT-3.5 수준이나 게임 도메인 용어 처리에 강점.
- VARCO-VISION 14B는 한국어 벤치마크에서 동급 최강. 이미지로 올라온 불법 게시글 탐지에 실질적 효과 기대.
- **Rate Limit 제어 필수**: 기획서의 Redis 토큰 버킷 방식은 적절. VARCO API 할당량 초과 시 429 에러 처리 로직 사전 구현 필요.

---

## 요약 — 팀 결정 권고안

| 이슈 | 권고 | 근거 |
|------|------|------|
| BERT 2차 필터 | **라벨 100건+ 확보 시 KoELECTRA, 아니면 미도입** | 일정·데이터 현실 반영 |
| 크롤링 브라우저 | **Nodriver → Zendriver 교체** | Cloudflare 우회율 0% → 75% |
| Redis 큐 패턴 | **BRPOPLPUSH + Watchdog 유지** | 규모 대비 Streams 불필요 |
| VARCO 파이프라인 | **기획서 그대로 진행** | 한국어+게임 도메인 최적 |

---

*Sources:*
- [SetFit ModernBERT for text classification](https://moshewasserblat.medium.com/new-results-on-setfit-modernbert-for-text-classification-with-few-shot-training-53c154df7c0e)
- [BERT vs FastText Comparative Analysis](https://arxiv.org/html/2411.17661v2)
- [Nodriver/Zendriver vs Playwright Benchmark](https://medium.com/@dimakynal/baseline-performance-comparison-of-nodriver-zendriver-selenium-and-playwright-against-anti-bot-2e593db4b243)
- [Browser Automation Showdown](https://bytetunnels.com/posts/browser-automation-showdown-selenium-playwright-puppeteer-ulixee-hero-nodriver/)
- [Patchright alternatives 2026](https://roundproxies.com/blog/best-patchright-alternatives/)
- [Redis Lists for Message Queues](https://oneuptime.com/blog/post/2026-01-25-redis-lists-message-queues/view)
- [Redis Streams vs Lists comparison](https://dev.to/lovestaco/choosing-the-right-messaging-tool-redis-streams-redis-pubsub-kafka-and-more-577a)
- [NCSOFT VARCO LLM 2.0](https://about.ncsoft.com/en/news/article/news_update_240926)
- [VARCO-VISION arXiv](https://arxiv.org/pdf/2411.19103)
- [KcBERT GitHub](https://github.com/Beomi/KcBERT)
- [KoBERT GitHub](https://github.com/SKTBrain/KoBERT)
