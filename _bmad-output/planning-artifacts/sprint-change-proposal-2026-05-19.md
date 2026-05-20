# Sprint Change Proposal — Epic 2 PIVOT (Crawler 전면 재작성 + 검색엔진형 확장 계획)

> **Date:** 2026-05-19  
> **Author:** Tracker (with BMad Correct Course workflow)  
> **Branch:** `feat/epic-2-crawler-rewrite`  
> **Scope classification:** **Moderate** (백로그 재편 + 문서 retroactive 정합화, 코드 변경 0)  
> **Status:** Drafted — awaiting user approval

---

## Section 1. Issue Summary

### 문제 진술

Epic 2 (자동 크롤링 및 전처리 파이프라인) 의 기존 구현 (`crawler/` 디렉터리, Stories 2-1~2-7 완료분) 이 통합 운영에 부족함이 확인되어, 별도 폴더 `crawler_test/` 에서 더 견고한 신규 구현을 개발해 왔다. 이번 PIVOT에서 `crawler_test/` 의 신규 구현을 `crawler/` 로 통째 승격 (deleted 103 / modified 10 / added 8 — 142 PASS, 외부 네트워크 호출 0건). 동시에 신규 구현이 도입한 능력 (`content_validator`, `url_dedup_checker`, Bahamut NC 8게임 분리, `title_keywords` 사전 필터, inter-site/inter-board delay) 과 향후 확장 계획 (검색엔진형 8개 사이트) 을 BMad 트래킹에 retroactive로 정합화할 필요가 있다.

### 발견 맥락

- **유형:** Failed approach + New requirement emerged (체크리스트 1.2 분류)
- **트리거:** Epic 2 기존 코드가 통합 운영 수준에 미달 → 별도 트랙 (`crawler_test/`) 에서 재작성 → PIVOT으로 통합 승격
- **증거:**
  1. 142 unit + integration tests PASS (외부 네트워크 0건)
  2. deleted 103 / modified 10 / added 8 (브랜치 `feat/epic-2-crawler-rewrite`)
  3. 외부 contract 호환 검증 완료:
     - Redis `posts:queue` 채널 — 그대로
     - `shared.models.CrawlEvent` 필드 — 그대로
     - `crawl:trigger` PubSub (api/CrawlTriggerService 연동) — 그대로
     - Dockerfile entry (`crawler.src.scheduler.crawl_scheduler.__main__`) — 그대로
     - `infra/compose.prod.yml` — 변경 불필요
  4. Cross-system 영향 0:
     - `api/`, `detection/`, `shared/` — 어디서도 crawler import 안 함
     - `shared/` 자체 변경 0
- **향후 신호 (forward-looking, 별도 PIVOT 예정):**
  - Epic 3 재설계 검토 중 — VARCO Translation + language detection 제거, 텍스트 LLM + 이미지 VLM 직결 구조. 본 Epic 2 PIVOT 범위 외, 메모로만 등록.

---

## Section 2. Impact Analysis

### Epic Impact

| Epic | 영향 |
|---|---|
| **Epic 1** (토대 인프라) | ✅ 영향 없음 (CrawlEvent contract 동일성 유지) |
| **Epic 2** (크롤링) | ❗ **`done → in-progress` 회귀**. Stories 2-1~2-7 신규 코드에 흡수 매핑. Stories 2-8~2-12 신규 backlog 추가 (검색엔진 트랙) |
| **Epic 3** (탐지) | ✅ 본 PIVOT 영향 없음 (CrawlEvent contract 호환). 단, 별도 forward-looking 메모: VARCO Translation/language detection 제거 재설계 검토 중 |
| **Epic 4** (대시보드) | ✅ 영향 없음 |
| **Epic 5** (운영) | ✅ 영향 없음 (Dockerfile entry / compose.prod.yml 호환) |

### Story Impact

#### 흡수 매핑 (Stories 2-1 ~ 2-7, 모두 done 유지)

| Story | 기존 책임 | 신규 구현 매핑 |
|---|---|---|
| 2-1 Cloudflare 우회 검증 | Playwright + stealth | `BrowserConfig(enable_stealth=True)` + SiteConfig 단위 토글 |
| 2-2 ProxyProvider 추상화 | ProxyBroker → NodeMaven 교체 가능 | `SiteConfig.proxy` 필드로 단순화 통합 |
| 2-3 crawl4ai 전처리 | crawl4ai + language/dedup/keyword | `crawl4ai_crawler.py` + `preprocessor/{language_detector, dedup_checker, url_dedup_checker, content_validator, serializer}.py` (html_parser, keyword_filter 제거) |
| 2-4 S3 아카이브 | S3Uploader + 로컬 저장 | `s3_uploader.py` + `storage.py` 분리 |
| 2-5 APScheduler | scheduler + trigger_listener | `scheduler/crawl_scheduler.py` + `scheduler/trigger_listener.py` 분리, inter-site/inter-board delay ±25% jitter 신규 |
| 2-6 PTT·Dcard SiteConfig | 4 보드 | `sites/registry.py` 통합 (ptt + ptt_mobile_game + dcard + dcard_online) |
| 2-7 중국 사이트 SiteConfig | tieba + 52pojie + nga | `sites/registry.py` 통합. Bahamut NC 8게임 분리 신규 |

#### 신규 등록 (Stories 2-8 ~ 2-12, 모두 backlog)

| Story | 대상 사이트 | 비고 |
|---|---|---|
| 2-8 SearchEngineConfig + GitHub | github (글로벌) | 추상화 검증용 첫 도전 |
| 2-9 Reddit | reddit (글로벌) | |
| 2-10 Bing + DuckDuckGo (CN) | bing, duckduckgo_cn | 한국 IP 접근 가능 |
| 2-11 Facebook | facebook (via Bing) | 가장 어려운 케이스 |
| 2-12 중국 검색엔진 | baidu, sogou, bilibili | **중국 residential proxy 선결 필요** |

### Artifact Conflicts

| 산출물 | 변경 |
|---|---|
| **`sprint-status.yaml`** | Epic 2 status 회귀 + Stories 2-1~2-7 흡수 매모 + 2-8~2-12 backlog + 최상단 PIVOT 메모 (forward-looking Epic 3 신호 포함) |
| **`epics.md`** | Epic 2 본문에 2026-05-19 PIVOT 메모 + 신규 능력 컴포넌트 등록 + Epic 2 검색엔진 트랙 서브섹션 (Stories 2.8~2.12) 신설 |
| **`architecture.md`** | `crawler/` 디렉터리 트리 갱신, Decision 항목 10 PIVOT 메모 + 항목 11~13 신규 추가, SearchEngineConfig vs SiteConfig 비교 표 신설, Data Flow 도표 갱신, 항목 14 (Epic 3 forward-looking) 추가 |
| **`prd.md`** | Executive Summary "최대 6개" → "15개 데이터 소스" 갱신, 데이터 소스 우선순위 표 신설 (게시판 7 부모 + 검색 8), MVP 전처리 단계 갱신, Growth Features 에 검색엔진 트랙 추가 |
| **`ux-design-specification.md`** | ✅ 영향 없음 (대시보드 UI 무변경) |
| **인프라** (`infra/compose.prod.yml`, `Dockerfile`, CI/CD) | ✅ 영향 없음 |
| **Code** (api/, detection/, shared/) | ✅ 변경 0 |

---

## Section 3. Recommended Approach

### 선택: **Option 1 (Direct Adjustment) + Hybrid (신규 트랙 추가)**

#### Path Forward Evaluation

| 옵션 | 평가 | 효과 |
|---|---|---|
| ❌ Option 2 (Rollback) | 142 PASS + 외부 contract 호환 검증 완료 → 롤백 가치 없음 | Not viable |
| ❌ Option 3 (MVP Review) | MVP 코어 (탐지 파이프라인) 무영향, Epic 3 진행 중 | Not viable |
| ✅ **Option 1 + Hybrid** | 문서 retroactive 정합화 + 신규 검색엔진 트랙 backlog 등록 | Effort: Medium / Risk: Low |

#### Rationale

1. **코드 측면 안전성 확보**: 신규 구현은 142 tests PASS + 외부 네트워크 0 + cross-system 영향 0. 즉시 운영 가능 상태.
2. **외부 contract 호환**: `posts:queue`, `CrawlEvent`, `crawl:trigger`, Dockerfile entry, compose 모두 그대로 → Epic 3·4·5 무영향.
3. **신규 능력 명시화**: `content_validator` (품질 가드), `url_dedup_checker` (2계층 dedup), `title_keywords` 사전 필터, Bahamut NC 8게임 분리 등이 architecture/PRD에 등록되어 향후 작업 참조 지점 확보.
4. **검색엔진 트랙 분리 등록**: `SearchEngineConfig` 추상화는 board-1-hop vs search-2-hop의 모델 차이를 명시. Epic 2 서브트랙 (Stories 2-8~2-12) 으로 편입 (출력 CrawlEvent 동일성 근거).
5. **Epic 3 forward-looking 신호 보존**: 향후 재설계 (Translation/language detection 제거, LLM/VLM 직결) 가 검토 중임을 메모로 남겨 본 PIVOT의 의사결정이 미래 PIVOT을 차단하지 않도록 함.

#### Effort · Risk · Timeline

- **Effort:** Medium (4개 문서 retroactive 정합화 — 코드 변경 0)
- **Risk:** Low (외부 contract 호환 검증 완료, cross-system 영향 0)
- **Timeline impact:** None on Epic 3 진행 (현재 in-progress, 본 PIVOT과 무관). 신규 검색엔진 트랙은 Epic 3 완료 후 착수.

---

## Section 4. Detailed Change Proposals

### Proposal 1: `sprint-status.yaml`

**Changes:**
- 1A — 최상단 PIVOT 메모 추가 (line 2~3) + forward-looking Epic 3 신호 append
- 1B — Epic 2 status `done → in-progress` 회귀 + PIVOT 메모 (line 135)
- 1C — Stories 2-1~2-7 흡수 매핑 메모 (line 136~142)
- 1D — Stories 2-8~2-12 backlog 신규 등록 + Epic 2 검색엔진 트랙 헤더 (line 143 직전)
- 1E — `last_updated` 헤더 (line 117) PIVOT 메모 prepend

**상세 diff:** 워크플로우 대화 로그 Proposal 1 참조 (Approved).

### Proposal 2: `epics.md`

**Changes:**
- 2A — Epic List Epic 2 엔트리 (line 145~156) 에 2026-05-19 PIVOT 블록 추가
- 2B — Epic 2 본문 (line 292) PIVOT 메모 + 신규 능력 컴포넌트 등록 블록
- 2C — Epic 2 본문에 "Epic 2 검색엔진 트랙 (Stories 2.8~2.12)" 서브섹션 신설 (line 426 직전). 5개 신규 Story 정의 + AC 초안 포함.

**상세 diff:** 워크플로우 대화 로그 Proposal 2 참조 (Approved — Epic 2 서브트랙 편입).

### Proposal 3: `architecture.md` (개정판)

**Changes:**
- 3A — `crawler/` 디렉터리 트리 (line 540~553) 갱신: preprocessor 5개 파일 정합화 (html_parser, keyword_filter 제거 / content_validator, url_dedup_checker, serializer 신규), `search/` 디렉터리 (Stories 2-8~2-12 예정), `scripts/smoke_each_site.py`, `README.md`, `STATUS.md`, 테스트 파일 갱신
- 3B — Decision 항목 10 에 PIVOT 메모 + 항목 11 (URL Dedup 이중화), 12 (Content Validator 8-kind 품질 가드), 13 (Title Keywords 사전 필터), 14 (Epic 3 forward-looking) 신규 추가
- 3C — "FR 카테고리 → 디렉토리 매핑" 표 직후에 `SearchEngineConfig` vs `SiteConfig` 비교 섹션 신설 + 공통 컴포넌트 목록 정합화
- 3D — Data Flow 도표 (line 750~755) 갱신: `title_keywords` 사전 필터 → `url_dedup_checker` 본문 fetch 전 차단 → `crawl4ai_crawler` 본문 fetch → preprocessor (language_detector → dedup_checker → content_validator → serializer) → redis_publisher

**상세 diff:** 워크플로우 대화 로그 Proposal 3 v2 참조 (Approved — crawler_test/ 교차 검증 완료).

### Proposal 4: `prd.md`

**Changes:**
- 4A — Executive Summary (line 21) "최대 6개" → "게시판 7 부모 + 검색 8 = 15개 데이터 소스"
- 4B — `## Product Scope` 와 `### MVP` 사이에 `### 데이터 소스 (2026-05-19 PIVOT 반영)` 섹션 신설. 게시판형 7 부모 + 검색엔진형 8 우선순위 표 + 진행 트랙 4종 (A: 즉시 / B: proxy 선결 / C: Epic 3 완료 후 / D: Known issues)
- 4C — `### MVP` 본문 전처리 단계 갱신: HTML 파싱·키워드 필터 제거, 언어 감지·URL 중복·content 중복·content_validator 품질 가드·serialize 명시
- 4D — `### Growth Features` 에 "검색엔진형 데이터 소스 (Stories 2-8~2-12)" 항목 + 프록시 업그레이드 항목에 PIVOT 메모 append

**상세 diff:** 워크플로우 대화 로그 Proposal 4 참조 (Approved — 부모 사이트 기준 15).

---

## Section 5. Implementation Handoff

### Scope Classification: **Moderate**

- **이유:** 백로그 재편성 (5개 신규 Story + 1개 Epic 상태 회귀) + 4개 문서 retroactive 정합화. 코드 변경 0. PO 합의 (백로그 우선순위) + Tech writer/PM 협조 (문서 작성) 필요.

### Routing

| 역할 | 책임 | 산출물 |
|---|---|---|
| **PM / 기획 (John 에이전트)** | (1) Sprint Change Proposal 최종 승인 (2) Stories 2-8~2-12 우선순위 확정 (Epic 3 완료 후 착수 권고) (3) 중국 residential proxy 인프라 트랙 의사결정 (별도) | 본 문서 승인 sign-off |
| **PO / Tracker (사용자)** | sprint-status.yaml + epics.md + architecture.md + prd.md 실제 파일 편집 적용 (Step 5에서 일괄 수행 가능) | 4 files committed on `feat/epic-2-crawler-rewrite` 또는 별도 docs 브랜치 |
| **Dev (Amelia 에이전트)** | (1) 신규 brunch의 PR 번호 확정 후 메모에 채워넣기 (2) Known issues 단발 fix 트래킹 (dcard_online wait_for / ptt_mobile_game·dcard /f/game 페이지네이션) | Issue / Story 단위 분해 |
| **Test architect (Murat 에이전트)** | 142 PASS 회귀 보호 — Epic 3 진행 중 crawler 회귀 시 즉시 알림 / Story 2.8 (SearchEngineConfig 추상화 검증) 시 ATDD 도움 | 테스트 가드 |

### Success Criteria

1. 4개 문서 파일이 본 PIVOT 메모를 반영하여 git에 commit 됨
2. `sprint-status.yaml` 에서 Epic 2 status = `in-progress`, Stories 2-8~2-12 backlog 등록 확인
3. Epic 3 진행에 영향 없음을 회귀 테스트 (detection 28 tests PASS) 로 확인
4. PR 번호가 메모에 채워짐 (`PR # (채워넣기)` 자리)
5. Forward-looking Epic 3 신호가 sprint-status + architecture 두 위치에 메모됨 (별도 PIVOT 트래킹 가능)

### Deferred / Out of Scope

- **Epic 3 재설계** (VARCO Translation + language detection 제거, 텍스트 LLM + 이미지 VLM 직결) — 별도 Correct Course 세션
- **중국 residential proxy 인프라 트랙** — 별도 의사결정 (tieba/NGA/52pojie + baidu/sogou/bilibili 모두 영향 받음)
- **Known issues 단발 fix** (dcard_online wait_for / ptt_mobile_game·dcard /f/game 페이지네이션) — `[QQ] /bmad-quick-dev` 로 별도 처리

---

## Appendix: 워크플로우 실행 로그

- **Step 1 (Initialize):** 변경 트리거 (Tracker 직접 설명) + Incremental 모드 — Complete
- **Step 2 (Checklist):** 6 sections × ~25 items 평가 완료 — Complete
- **Step 3 (Drafts):** Proposal 1~4 incremental 협의 — Complete (1 Approved, 2 Approved, 3 Edit→v2 Approved, 4 Approved)
- **Step 4 (This document):** Generated 2026-05-19
- **Step 5 (Approval & Routing):** Pending user approval
- **Step 6 (Completion):** Pending
