# Story 4.1: Spring REST API 기반 구조 및 탐지 목록 엔드포인트

Status: done

## Story

백엔드 개발자로서,
Spring Boot REST API의 기본 레이어 구조와 `GET /detections` 엔드포인트가 구현되기를 원한다,
그래서 프론트엔드 개발자가 실제 API를 연동하여 탐지 목록을 표시할 수 있다.

## Acceptance Criteria

1. **Given** RDS `detections` 테이블에 탐지 결과가 저장된 상태에서 **When** `GET /detections?date=2026-04-24&site=tailstar.net&type=매크로_판매&lang=ko&page=0&size=20`을 요청하면 **Then** 신뢰도 임계값 0.70 이상인 결과만 반환된다 (FR22, 항상 적용, 클라이언트 파라미터 불필요)
2. **And** 응답 JSON 필드는 camelCase(`isIllegal`, `detectedAt`, `confidence`, `rawText`, `translatedText`, `postUrl`, `siteName`, `language`)를 사용한다 (architecture.md P1 규칙)
3. **And** `detectedAt`은 ISO 8601 UTC 문자열(`2026-04-24T14:30:00Z`)로 반환된다 (architecture.md P5 규칙)
4. **And** 응답은 confidence 내림차순으로 정렬되며 offset 기반 페이지네이션(`page`, `size`, `totalElements`, `content[]`)을 포함한다
5. **And** API 에러 응답은 ProblemDetail(RFC 9457) 형식(`type`, `title`, `status`, `detail`, `errorCode`)으로 반환되며 스택 트레이스를 응답에 노출하지 않는다
6. **And** Swagger UI(`/swagger-ui.html`)에서 `GET /detections` 엔드포인트가 자동 문서화된다
7. **And** `GlobalExceptionHandler`(`@ControllerAdvice`)가 모든 예외를 ProblemDetail 형식으로 처리한다
8. **And** `api/src/test/java/com/tracker/api/controller/DetectionControllerTest.java`에서 목록 조회·필터링·빈 결과·잘못된 파라미터 케이스를 검증한다

## Tasks / Subtasks

- [x] **Task 1: build.gradle 의존성 추가** (AC: #6)
  - [x] 1.1 `org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.8` 추가 (Swagger UI)
  - [x] 1.2 `application.properties`에 springdoc 기본 경로 설정 추가

- [x] **Task 2: V4 Flyway 마이그레이션 — translated_text 컬럼 추가** (AC: #2)
  - [x] 2.1 `api/src/main/resources/db/migration/V4__add_translated_text.sql` 작성
  - [x] 2.2 `detections` 테이블에 `translated_text TEXT` 컬럼 추가 (nullable, 중국어 게시글만 non-null)

- [x] **Task 3: JPA Entity 클래스 생성** (AC: #1, #2)
  - [x] 3.1 `api/src/main/java/com/tracker/api/domain/Source.java` 작성 (`@Entity @Table("sources")`)
  - [x] 3.2 `api/src/main/java/com/tracker/api/domain/Post.java` 작성 (`@Entity @Table("posts")`, `@ManyToOne Source`)
  - [x] 3.3 `api/src/main/java/com/tracker/api/domain/Detection.java` 작성 (`@Entity @Table("detections")`, `@ManyToOne Post`)
  - [x] 3.4 모든 컬럼명이 V1 스키마와 정확히 일치하는지 확인 (snake_case → `@Column(name=...)`)

- [x] **Task 4: Repository 계층 구현** (AC: #1, #3, #4)
  - [x] 4.1 `DetectionRepository.java` 작성 — `JpaRepository<Detection, Long>` 확장
  - [x] 4.2 `@Query` 커스텀 JPQL 메서드 `findFiltered(fromTime, toTime, site, type, lang, Pageable)` 구현
  - [x] 4.3 `countQuery` 별도 정의 (JOIN FETCH 없는 COUNT 쿼리)

- [x] **Task 5: DTO 정의 (Java 21 record)** (AC: #2, #3, #4)
  - [x] 5.1 `DetectionResponse.java` record 작성 — `from(Detection)` 정적 팩토리 메서드 포함
  - [x] 5.2 `DetectionListResponse.java` record 작성 — `content`, `page`, `size`, `totalElements`
  - [x] 5.3 프론트엔드 `types/api.ts`의 `Detection`, `DetectionListResponse` 인터페이스와 필드명 1:1 일치 확인

- [x] **Task 6: Service 계층 구현** (AC: #1, #4)
  - [x] 6.1 `DetectionService.java` 작성
  - [x] 6.2 `date` 파라미터 → `LocalDate` → `Instant` 범위 변환 (자정~익일 자정)
  - [x] 6.3 `confidence >= 0.70` 필터 항상 적용 (서비스 레이어 책임)
  - [x] 6.4 기본 정렬: `confidence DESC` → `Pageable`에 `Sort.by(DESC, "confidence")` 주입

- [x] **Task 7: Controller 구현** (AC: #1~#7)
  - [x] 7.1 `DetectionController.java` 작성 — `@RestController @RequestMapping("/api")`
  - [x] 7.2 `GET /api/detections` 엔드포인트 — 파라미터: `date`, `site`, `type`, `lang`, `page`(기본 0), `size`(기본 20)
  - [x] 7.3 응답에 `X-Correlation-ID` 헤더 에코 (요청 헤더 값 사용, 없으면 신규 UUID 생성)

- [x] **Task 8: Config 클래스 구현** (AC: #6, #7)
  - [x] 8.1 `SwaggerConfig.java` 작성 — `OpenAPI` Bean, info(title, version, description)
  - [x] 8.2 `WebConfig.java` 작성 — CORS `allowedOrigins("http://localhost:5173", "http://localhost:3000")`, `X-Correlation-ID` 허용 헤더 포함
  - [x] 8.3 `GlobalExceptionHandler.java` 작성 — `@ControllerAdvice`, `ResponseEntityExceptionHandler` 상속, `MethodArgumentTypeMismatchException` → 400, 공통 fallback → 500, 스택 트레이스 응답 제외

- [x] **Task 9: 테스트 작성** (AC: #8)
  - [x] 9.1 `api/src/test/java/com/tracker/api/controller/DetectionControllerTest.java` 작성
  - [x] 9.2 `@WebMvcTest(DetectionController.class)` + `@MockBean DetectionService`
  - [x] 9.3 테스트 케이스: 정상 조회(200), 빈 결과(200 + 빈 content), 잘못된 date 형식(400 ProblemDetail)

- [x] **Task 10: 통합 검증** (AC: #1~#8)
  - [x] 10.1 `docker compose -f infra/docker-compose.yml up -d` 후 Spring Boot 기동 → V4 마이그레이션 성공 확인
  - [x] 10.2 `./gradlew test` 통과 확인
  - [x] 10.3 Swagger UI (`http://localhost:8080/swagger-ui.html`) 접속 → `GET /api/detections` 문서화 확인
  - [x] 10.4 변경 파일 목록 File List에 기록
  - [x] 10.5 `sprint-status.yaml` `4-1-spring-rest-api-기반-구조-및-탐지-목록-엔드포인트` 상태 `review`로 업데이트

### Review Findings

- [x] [Review][Patch] 페이지네이션 범위 오류가 400 `INVALID_FILTER_PARAM`이 아니라 500 fallback으로 노출될 수 있음 [api/src/main/java/com/tracker/api/service/DetectionService.java:35]
- [x] [Review][Patch] `ResponseEntityExceptionHandler` 기본 MVC 예외 응답에는 필수 `errorCode`가 보장되지 않음 [api/src/main/java/com/tracker/api/exception/GlobalExceptionHandler.java:10]
- [x] [Review][Patch] AC #8의 필터링 검증이 mock 기반 controller test에 없어 실제 date/site/type/lang 전달 및 confidence 필터 회귀를 잡지 못함 [api/src/test/java/com/tracker/api/controller/DetectionControllerTest.java:30]

## Dev Notes

### 브랜치 전략

- **브랜치:** `feat/4-1` (main에서 분기)
- **PR 타겟:** `main`

### 이번 스토리 범위 (Scope Boundary)

| 이번 스토리에서 한다 | 이번 스토리에서 **하지 않는다** |
|---|---|
| JPA Entity: `Detection`, `Post`, `Source` | `PostImage` Entity (어떤 엔드포인트도 미사용) |
| `GET /api/detections` 목록 엔드포인트 | `GET /api/detections/{id}` 상세 (Story 4.2) |
| V4 마이그레이션 (`translated_text` 컬럼) | `POST /api/crawl/trigger` (Story 4.2) |
| `GlobalExceptionHandler`, `SwaggerConfig`, `WebConfig` | `GET /api/stats` (Story 4.3) |
| `DetectionControllerTest` (@WebMvcTest) | Redis 연동, `RedisConfig.java` (Story 4.3) |
| springdoc-openapi 의존성 추가 | `DetectionNotFoundException` 클래스 (Story 4.2에서 사용) |

### 기존 코드 현황 (재사용 / 수정 금지)

**이미 존재하는 파일 (수정 불가 또는 주의):**

| 파일 | 상태 | 주의사항 |
|---|---|---|
| `api/build.gradle` | 기존 | springdoc 의존성만 추가, 나머지 변경 금지 |
| `api/src/main/resources/application.properties` | 기존 | springdoc 설정만 추가 |
| `api/src/main/resources/db/migration/V1~V3__*.sql` | 완료 | 절대 수정 금지 — V4 신규 추가만 |
| `api/src/test/resources/application-test.properties` | 완료 | H2 + Flyway 비활성화 — 수정 금지 |
| `api/src/main/java/com/tracker/api/TrackerApiApplication.java` | 완료 | 루트 패키지 위치 (`com.tracker.api`) — 수정 금지 |

**Spring Boot 버전 주의:** `build.gradle`의 실제 버전은 **3.5.0** (architecture.md에 3.4.x로 명시되어 있지만 실제 구축 시 3.5.0 사용됨). `springdoc-openapi 2.8.8`은 Spring Boot 3.x 호환.

### Task 1 상세: build.gradle 및 설정

#### build.gradle 추가

```groovy
dependencies {
    // ... 기존 의존성 유지 (변경 금지) ...
    implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.8'
}
```

#### application.properties 추가

```properties
# Springdoc OpenAPI (Swagger UI)
springdoc.api-docs.path=/api-docs
springdoc.swagger-ui.path=/swagger-ui.html
```

**주의:** 기존 application.properties 내용은 그대로 유지. 위 2줄만 추가.

### Task 2 상세: V4 마이그레이션

#### api/src/main/resources/db/migration/V4__add_translated_text.sql (신규)

```sql
-- detections.translated_text: VARCO Translation 결과 (중국어 게시글만 non-null)
-- Story 3.x Detection 파이프라인이 번역 결과를 이 컬럼에 저장
ALTER TABLE detections ADD COLUMN translated_text TEXT;
```

**파일명 규칙:** `V4__add_translated_text.sql` — 더블 언더스코어 필수. `V4_add_translated_text.sql`(언더스코어 1개)은 Flyway 파싱 실패.

### Task 3 상세: JPA Entity

#### domain/Source.java

```java
package com.tracker.api.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "sources")
public class Source {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "site_name", nullable = false, length = 50)
    private String siteName;

    @Column(name = "board_name", length = 200)
    private String boardName;

    @Column(name = "base_url", nullable = false, length = 500)
    private String baseUrl;

    @Column(name = "created_at")
    private Instant createdAt;

    // getters (Lombok @Getter 사용 가능)
}
```

#### domain/Post.java

```java
package com.tracker.api.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "posts")
public class Post {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "source_id", nullable = false)
    private Source source;

    @Column(name = "post_id_at_source", length = 200)
    private String postIdAtSource;

    private String title;

    @Column(columnDefinition = "TEXT")
    private String body;

    private String author;

    @Column(name = "post_url", nullable = false, length = 1000)
    private String postUrl;

    @Column(length = 10)
    private String language;

    @Column(name = "crawled_at", nullable = false)
    private Instant crawledAt;

    // getters
}
```

#### domain/Detection.java

```java
package com.tracker.api.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "detections")
public class Detection {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    private Post post;

    @Column(name = "is_illegal", nullable = false)
    private boolean isIllegal;

    @Column(length = 50)
    private String type;

    @Column(nullable = false)
    private double confidence;

    @Column(columnDefinition = "TEXT")
    private String reason;

    @Column(name = "translated_text", columnDefinition = "TEXT")
    private String translatedText;

    @Column(name = "model_version", nullable = false, length = 50)
    private String modelVersion;

    @Column(name = "detected_at", nullable = false)
    private Instant detectedAt;

    // getters
}
```

**주의:** `@Getter` Lombok 사용 가능하나 `isIllegal` 필드는 boolean primitive라서 Lombok이 `isIsIllegal()`을 생성할 수 있음. 명시적 `getIsIllegal()` getter 또는 `@Getter(value=AccessLevel.NONE) + 수동 getter` 권장. 또는 필드명을 `illegal`로 변경하고 `@Column(name="is_illegal")`로 매핑.

### Task 4 상세: Repository

```java
package com.tracker.api.repository;

import com.tracker.api.domain.Detection;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.Instant;

public interface DetectionRepository extends JpaRepository<Detection, Long> {

    @Query(value = """
            SELECT d FROM Detection d
            JOIN FETCH d.post p
            JOIN FETCH p.source s
            WHERE d.confidence >= 0.70
            AND (:fromTime IS NULL OR d.detectedAt >= :fromTime)
            AND (:toTime   IS NULL OR d.detectedAt <  :toTime)
            AND (:site     IS NULL OR s.siteName = :site)
            AND (:type     IS NULL OR d.type = :type)
            AND (:lang     IS NULL OR p.language = :lang)
            """,
            countQuery = """
            SELECT COUNT(d) FROM Detection d
            JOIN d.post p JOIN p.source s
            WHERE d.confidence >= 0.70
            AND (:fromTime IS NULL OR d.detectedAt >= :fromTime)
            AND (:toTime   IS NULL OR d.detectedAt <  :toTime)
            AND (:site     IS NULL OR s.siteName = :site)
            AND (:type     IS NULL OR d.type = :type)
            AND (:lang     IS NULL OR p.language = :lang)
            """)
    Page<Detection> findFiltered(
            @Param("fromTime") Instant fromTime,
            @Param("toTime")   Instant toTime,
            @Param("site")     String site,
            @Param("type")     String type,
            @Param("lang")     String lang,
            Pageable pageable);
}
```

**JOIN FETCH + Pagination 주의:** `@ManyToOne`만 존재하므로 JOIN FETCH + LIMIT 조합에서 Hibernate 경고(`HHH90003004`)가 발생하지 않는다. `@OneToMany` 컬렉션 fetch가 아니기 때문. 검증: `./gradlew test`에서 경고 없어야 함.

### Task 5 상세: DTO (Java 21 record)

```java
package com.tracker.api.dto;

import com.tracker.api.domain.Detection;

public record DetectionResponse(
        Long id,
        boolean isIllegal,
        String type,
        double confidence,
        String reason,
        String rawText,
        String translatedText,
        String postUrl,
        String siteName,
        String language,
        String detectedAt  // ISO 8601 UTC: "2026-04-24T14:30:00Z"
) {
    public static DetectionResponse from(Detection d) {
        return new DetectionResponse(
                d.getId(),
                d.isIllegal(),       // getter명 주의 (Task 3 주석 참조)
                d.getType(),
                d.getConfidence(),
                d.getReason(),
                d.getPost().getBody(),          // rawText = posts.body
                d.getTranslatedText(),           // nullable (중국어만 non-null)
                d.getPost().getPostUrl(),
                d.getPost().getSource().getSiteName(),
                d.getPost().getLanguage(),
                d.getDetectedAt().toString()    // Instant.toString() = ISO 8601 UTC
        );
    }
}
```

```java
package com.tracker.api.dto;

import java.util.List;

public record DetectionListResponse(
        List<DetectionResponse> content,
        int page,
        int size,
        long totalElements
) {}
```

**프론트엔드 계약 검증:** `dashboard/src/types/api.ts`의 `DetectionListResponse` 인터페이스와 **정확히** 일치해야 한다:
```typescript
// dashboard/src/types/api.ts (변경 금지)
export interface DetectionListResponse {
  content: Detection[];   // ✅ content
  page: number;           // ✅ page
  size: number;           // ✅ size
  totalElements: number;  // ✅ totalElements
}
```

### Task 6 상세: Service

```java
package com.tracker.api.service;

import com.tracker.api.dto.DetectionListResponse;
import com.tracker.api.dto.DetectionResponse;
import com.tracker.api.repository.DetectionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;

@Service
@RequiredArgsConstructor
public class DetectionService {

    private final DetectionRepository detectionRepository;

    @Transactional(readOnly = true)
    public DetectionListResponse getDetections(
            LocalDate date, String site, String type, String lang, int page, int size) {

        // date → UTC Instant 범위 (자정~익일 자정)
        Instant fromTime = date != null ? date.atStartOfDay(ZoneOffset.UTC).toInstant() : null;
        Instant toTime   = date != null ? date.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant() : null;

        // 항상 confidence DESC 정렬
        var pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "confidence"));

        Page<com.tracker.api.domain.Detection> resultPage =
                detectionRepository.findFiltered(fromTime, toTime, site, type, lang, pageable);

        var content = resultPage.getContent().stream()
                .map(DetectionResponse::from)
                .toList();

        return new DetectionListResponse(
                content, page, size, resultPage.getTotalElements());
    }
}
```

**빈 파라미터 처리:** `site`, `type`, `lang`이 빈 문자열(`""`)로 오면 null로 변환해야 "IS NULL OR ..."  JPQL 조건이 올바르게 동작한다. Controller에서 `@RequestParam(required = false)`는 파라미터 없으면 null 반환 — 빈 문자열(`?site=`)은 `""` 반환. Service에서 `StringUtils.hasText()` 체크 추가 권장.

### Task 7 상세: Controller

```java
package com.tracker.api.controller;

import com.tracker.api.dto.DetectionListResponse;
import com.tracker.api.service.DetectionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Detections", description = "불법 게시글 탐지 결과 조회")
public class DetectionController {

    private final DetectionService detectionService;

    @GetMapping("/detections")
    @Operation(summary = "탐지 목록 조회", description = "confidence >= 0.70 필터 항상 적용. confidence 내림차순 정렬.")
    public ResponseEntity<DetectionListResponse> getDetections(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String site,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String lang,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest request) {

        var result = detectionService.getDetections(date, site, type, lang, page, size);

        String correlationId = request.getHeader("X-Correlation-ID");
        if (correlationId == null || correlationId.isBlank()) {
            correlationId = UUID.randomUUID().toString();
        }

        return ResponseEntity.ok()
                .header("X-Correlation-ID", correlationId)
                .body(result);
    }
}
```

**`/api` prefix:** 프론트엔드 `client.ts`의 `baseURL: import.meta.env.VITE_API_BASE_URL ?? '/api'`와 일치. Controller의 `@RequestMapping("/api")` + 엔드포인트 `@GetMapping("/detections")` → 전체 경로 `/api/detections`.

### Task 8 상세: Config 클래스

#### config/SwaggerConfig.java

```java
package com.tracker.api.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI trackerOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Tracker API")
                        .version("1.0.0")
                        .description("불법 게시글 탐지 결과 조회 및 통계 API"));
    }
}
```

#### config/WebConfig.java

```java
package com.tracker.api.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins(
                        "http://localhost:5173",   // Vite dev server
                        "http://localhost:3000"     // 대안 포트
                )
                .allowedMethods("GET", "POST", "OPTIONS")
                .allowedHeaders("*")
                .exposedHeaders("X-Correlation-ID")  // 프론트엔드가 읽을 수 있도록 노출
                .maxAge(3600);
    }
}
```

#### exception/GlobalExceptionHandler.java

```java
package com.tracker.api.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    // 잘못된 파라미터 타입 (예: date=not-a-date)
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ProblemDetail handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        var pd = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST,
                "파라미터 '%s'의 값이 올바르지 않습니다: %s".formatted(
                        ex.getName(), ex.getValue()));
        pd.setTitle("Invalid Parameter");
        pd.setProperty("errorCode", "INVALID_FILTER_PARAM");
        return pd;
    }

    // 공통 fallback — 스택 트레이스 절대 노출 금지
    @ExceptionHandler(Exception.class)
    public ProblemDetail handleAll(Exception ex) {
        logger.error("Unhandled exception", ex);  // 서버 로그에만 기록
        var pd = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "서버 내부 오류가 발생했습니다.");
        pd.setTitle("Internal Server Error");
        pd.setProperty("errorCode", "INTERNAL_SERVER_ERROR");
        return pd;
    }
}
```

**`errorCode` 필드:** 프론트엔드 `ProblemDetail` 타입(`dashboard/src/types/api.ts`)에서 `errorCode`를 필수 필드로 정의함. `pd.setProperty("errorCode", ...)` 호출로 응답 JSON에 포함.

**아키텍처 에러 코드 명세 (architecture.md P4):**
- `DETECTION_NOT_FOUND` — Story 4.2에서 사용
- `INVALID_FILTER_PARAM` — 잘못된 필터 파라미터
- `CRAWL_TRIGGER_FAILED` — Story 4.2에서 사용

### Task 9 상세: 테스트

```java
package com.tracker.api.controller;

import com.tracker.api.dto.DetectionListResponse;
import com.tracker.api.dto.DetectionResponse;
import com.tracker.api.service.DetectionService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(DetectionController.class)
class DetectionControllerTest {

    @Autowired MockMvc mockMvc;
    @MockBean  DetectionService detectionService;

    @Test
    void getDetections_returnsOk() throws Exception {
        // 정상 조회
        var mockDetection = new DetectionResponse(1L, true, "매크로_판매", 0.95,
                "이유", "원문", null, "http://example.com", "tailstar.net", "zh-CN",
                "2026-04-24T14:30:00Z");
        when(detectionService.getDetections(any(), any(), any(), any(), eq(0), eq(20)))
                .thenReturn(new DetectionListResponse(List.of(mockDetection), 0, 20, 1L));

        mockMvc.perform(get("/api/detections"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].isIllegal").value(true))
                .andExpect(jsonPath("$.content[0].detectedAt").value("2026-04-24T14:30:00Z"))
                .andExpect(header().exists("X-Correlation-ID"));
    }

    @Test
    void getDetections_emptyResult_returns200() throws Exception {
        when(detectionService.getDetections(any(), any(), any(), any(), eq(0), eq(20)))
                .thenReturn(new DetectionListResponse(List.of(), 0, 20, 0L));

        mockMvc.perform(get("/api/detections"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isEmpty())
                .andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    void getDetections_invalidDateFormat_returns400ProblemDetail() throws Exception {
        mockMvc.perform(get("/api/detections").param("date", "not-a-date"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("INVALID_FILTER_PARAM"))
                .andExpect(jsonPath("$.status").value(400));
    }
}
```

**`@WebMvcTest` 주의:** `application-test.properties`의 H2 설정은 `@SpringBootTest`에서만 적용됨. `@WebMvcTest`는 웹 레이어만 로드하므로 DB 설정 불필요. `@MockBean DetectionService`로 DB 없이 테스트 가능.

**`@SpringBootTest` 사용 시:** `TrackerApiApplicationTests`에 이미 `@ActiveProfiles("test")`가 추가되어 있음 (Story 1.4에서 완료). H2 + Flyway 비활성화 설정 자동 적용.

### 패키지 구조 (이번 스토리 생성 파일)

```
api/src/main/java/com/tracker/api/
├── domain/
│   ├── Detection.java      ✅ 이번 스토리 (신규)
│   ├── Post.java           ✅ 이번 스토리 (신규)
│   └── Source.java         ✅ 이번 스토리 (신규)
├── repository/
│   └── DetectionRepository.java    ✅ 이번 스토리 (신규)
├── service/
│   └── DetectionService.java       ✅ 이번 스토리 (신규)
├── controller/
│   └── DetectionController.java    ✅ 이번 스토리 (신규)
├── dto/
│   ├── DetectionResponse.java      ✅ 이번 스토리 (신규)
│   └── DetectionListResponse.java  ✅ 이번 스토리 (신규)
├── config/
│   ├── SwaggerConfig.java  ✅ 이번 스토리 (신규)
│   └── WebConfig.java      ✅ 이번 스토리 (신규)
├── exception/
│   └── GlobalExceptionHandler.java ✅ 이번 스토리 (신규)
└── TrackerApiApplication.java      기존 — 수정 금지

api/src/main/resources/
├── application.properties          기존 — springdoc 2줄만 추가
└── db/migration/
    ├── V1__init_schema.sql         기존 — 수정 금지
    ├── V2__add_indexes.sql         기존 — 수정 금지
    ├── V3__add_unique_detection.sql 기존 — 수정 금지
    └── V4__add_translated_text.sql ✅ 이번 스토리 (신규)

api/src/test/java/com/tracker/api/
└── controller/
    └── DetectionControllerTest.java ✅ 이번 스토리 (신규)
```

### Anti-Patterns to Avoid

1. ❌ **`@Column(name = "isIllegal")` 사용** — DB 컬럼명은 `is_illegal` (snake_case). 반드시 `@Column(name = "is_illegal")`.
2. ❌ **Lombok `@Getter`의 `isIllegal` boolean 자동 생성 문제** — Lombok은 `boolean isIllegal` 필드에 `isIsIllegal()` getter를 생성. 필드명을 `illegal`로 변경하고 `@Column(name = "is_illegal")` 사용하거나, 명시적 getter 작성.
3. ❌ **JOIN FETCH 없는 지연 로딩** — `Detection.getPost().getBody()` 호출 시 `post`가 LAZY면 LazyInitializationException 발생. Repository `@Query`에 `JOIN FETCH d.post p JOIN FETCH p.source s` 필수.
4. ❌ **`ORDER BY d.confidence DESC` JPQL + `Pageable` 동시 사용** — JPQL에 ORDER BY가 있으면 Pageable의 Sort가 무시되거나 충돌. JPQL에서 ORDER BY 제거하고 Service에서 `Sort.by(DESC, "confidence")` 사용.
5. ❌ **`detectedAt` Unix timestamp 반환** — `Instant.toString()`은 ISO 8601 UTC. `Date.getTime()`(long) 반환 금지.
6. ❌ **V4 없이 `translated_text` 매핑** — `Detection.translatedText`를 엔티티에 추가하면 Hibernate `validate` 모드에서 컬럼이 없어 기동 실패. V4 마이그레이션 필수.
7. ❌ **GlobalExceptionHandler에서 스택 트레이스 응답 포함** — `ex.getMessage()` 또는 `ex.getStackTrace()` 응답 body 포함 금지. 서버 로그에만 기록.
8. ❌ **스프링 시큐리티 없이 CORS 설정 누락** — 브라우저가 CORS 오류. `WebConfig.addCorsMappings()`에 `/api/**` 경로 + `localhost:5173` 허용 필수.
9. ❌ **`since` 파라미터 처리** — 프론트엔드가 `since=triggered`를 보낼 수 있음. 이번 스토리에서는 무시 (4.2에서 구현). `@RequestParam(required = false) String since` 선언만 하고 서비스에 전달 안 해도 됨. 또는 Controller에서 `@RequestParam(required = false) String since` 파라미터 선언 없이 그냥 무시해도 됨.

### DB 스키마 ↔ 프론트엔드 필드 매핑 (계약 검증용)

| 프론트 `Detection` 필드 | DB 출처 | 경로 |
|---|---|---|
| `id` | `detections.id` | `Detection.id` |
| `isIllegal` | `detections.is_illegal` | `Detection.isIllegal` |
| `type` | `detections.type` | `Detection.type` |
| `confidence` | `detections.confidence` | `Detection.confidence` |
| `reason` | `detections.reason` | `Detection.reason` |
| `rawText` | `posts.body` | `Detection.post.body` |
| `translatedText` | `detections.translated_text` (V4 신규) | `Detection.translatedText` (nullable) |
| `postUrl` | `posts.post_url` | `Detection.post.postUrl` |
| `siteName` | `sources.site_name` | `Detection.post.source.siteName` |
| `language` | `posts.language` | `Detection.post.language` |
| `detectedAt` | `detections.detected_at` | `Detection.detectedAt.toString()` (ISO 8601) |

### 검증 명령

```bash
# 1. 로컬 PostgreSQL + Flyway V4 마이그레이션 확인
docker compose -f infra/docker-compose.yml up -d postgres
cd api && ./gradlew bootRun
# 기동 후 확인:
docker compose -f infra/docker-compose.yml exec postgres \
  psql -U tracker_user -d tracker \
  -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'detections';"
# 예상: translated_text 컬럼 포함 확인

# 2. Flyway history 확인
docker compose -f infra/docker-compose.yml exec postgres \
  psql -U tracker_user -d tracker \
  -c "SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank;"
# 예상: V1, V2, V3, V4 모두 success=true

# 3. 단위 테스트
cd api && ./gradlew test
# 예상: DetectionControllerTest 3개 케이스 PASS

# 4. Swagger UI 접속
open http://localhost:8080/swagger-ui.html
# 예상: GET /api/detections 문서화 확인

# 5. 실제 API 호출 (DB에 데이터 있어야 함)
curl -s "http://localhost:8080/api/detections?page=0&size=5" \
  -H "X-Correlation-ID: test-uuid-1234" | jq .
# 예상: {"content":[], "page":0, "size":5, "totalElements":0} (DB 비어있으면 빈 결과)
```

### 프론트엔드 연동 전제조건

- 프론트엔드 `dashboard/src/api/client.ts`: `baseURL: import.meta.env.VITE_API_BASE_URL ?? '/api'` 사용
- `VITE_API_BASE_URL` 미설정 시 Vite 프록시(`vite.config.ts`)에서 `/api → http://localhost:8080/api`로 프록시
- API 응답의 `X-Correlation-ID` 헤더는 `WebConfig.exposedHeaders()`에 등록되어야 JS에서 접근 가능

### Epic 4 Frontend Retro에서의 인사이트

Epic 4 프론트 회고(`epic-4-frontend-retro-2026-04-29.md`)에서 백엔드 의존 Deferred 항목 확인:
- **AI-3:** Hero correlation pill — `unique`, `중복` 구분 데이터 필요 → 백엔드 grouping 필드 추가 필요 (Story 4.3에서 처리)
- **AI-4:** REVIEWED_FRACTION → Stats API `reviewed count` 필드 필요 (Story 4.3에서 처리)
- **AI-5:** RecentAlertList `minConfidence` 필터 → `GET /detections?minConfidence=0.9` 지원 여부 결정 (이번 스토리는 0.70 하드코딩; 향후 파라미터화 가능)
- **AI-6:** FreshnessIndicator 복원 — 백엔드 `detectedAt` 데이터 정확도 의존 → 이번 스토리에서 정확한 `detected_at` 반환으로 해결

이번 스토리 구현 후 백엔드 `GET /api/detections`가 실제 동작하면, 프론트엔드의 MSW 핸들러(`dashboard/src/mocks/handlers.ts`)는 자동으로 실제 API로 대체됨 (`import.meta.env.DEV` 분기로 MSW가 dev에서만 활성화되므로, `VITE_API_BASE_URL` 환경변수를 실제 API로 설정하면 됨).

### 이전 스토리 패턴 인사이트

**Story 1.4에서 확립된 패턴:**
- `application-test.properties`: H2 + `spring.flyway.enabled=false` + `ddl-auto=create-drop` — 이번 스토리 단위 테스트에서 `@WebMvcTest`로 DB 불필요하므로 그대로 활용
- `@ActiveProfiles("test")`: `TrackerApiApplicationTests`에 이미 추가됨 — 통합 테스트 시 자동 H2 사용
- Flyway 파일명 규칙: `V{n}__{설명}.sql` — V4에서도 동일하게 적용 필수

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 — BMad `create-story` workflow

### Debug Log References

- `boolean isIllegal` 필드명 → Lombok `isIsIllegal()` 문제: Detection 엔티티 필드명을 `illegal`로 변경, `@Column(name="is_illegal")` 매핑으로 해결. Lombok이 `isIllegal()` getter 생성.
- `@MockBean` deprecation 경고(Spring Boot 3.4.0+): 컴파일/실행 정상, 동작에 영향 없음.

### Completion Notes List

- Task 1~9 전체 구현 완료. `./gradlew test` 전체 통과(DetectionControllerTest 3케이스 + TrackerApiApplicationTests).
- Detection entity: `boolean illegal` + `@Column(name="is_illegal")` 패턴으로 Lombok isIsIllegal() 버그 회피.
- DetectionService: `StringUtils.hasText()` 빈 문자열 → null 변환 추가.
- GlobalExceptionHandler: `ResponseEntityExceptionHandler` 상속, 스택 트레이스 응답 미포함.
- Task 10.1: tracker-postgres 기동 후 Spring Boot bootRun 실행 → Flyway V1~V4 마이그레이션 전체 success 확인. `detections.translated_text` 컬럼 정상 추가 확인.
- Task 10.3: Swagger UI(`http://localhost:8080/swagger-ui/index.html`) 200 OK 확인.
- **버그 수정 (통합 검증 중 발견):** `DetectionRepository.findFiltered()` JPQL에서 PostgreSQL `? IS NULL` 타입 추론 오류(`could not determine data type of parameter $1`) 발생. Hibernate 6 HQL `cast(:param as Type)` 구문으로 파라미터 타입 명시하여 해결. 변경 대상: `fromTime/toTime → cast as Instant`, `site/type/lang → cast as String`.

### File List
- `api/build.gradle` — springdoc-openapi 의존성 추가
- `api/src/main/resources/application.properties` — springdoc 설정 추가
- `api/src/main/resources/db/migration/V4__add_translated_text.sql` — 신규
- `api/src/main/java/com/tracker/api/domain/Source.java` — 신규
- `api/src/main/java/com/tracker/api/domain/Post.java` — 신규
- `api/src/main/java/com/tracker/api/domain/Detection.java` — 신규
- `api/src/main/java/com/tracker/api/repository/DetectionRepository.java` — 신규
- `api/src/main/java/com/tracker/api/service/DetectionService.java` — 신규
- `api/src/main/java/com/tracker/api/controller/DetectionController.java` — 신규
- `api/src/main/java/com/tracker/api/dto/DetectionResponse.java` — 신규
- `api/src/main/java/com/tracker/api/dto/DetectionListResponse.java` — 신규
- `api/src/main/java/com/tracker/api/config/SwaggerConfig.java` — 신규
- `api/src/main/java/com/tracker/api/config/WebConfig.java` — 신규
- `api/src/main/java/com/tracker/api/exception/GlobalExceptionHandler.java` — 신규
- `api/src/test/java/com/tracker/api/controller/DetectionControllerTest.java` — 신규
