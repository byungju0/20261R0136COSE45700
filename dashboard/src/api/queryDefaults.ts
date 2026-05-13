/**
 * 60s 자동 폴링 — Tracker 운영 도구 표준.
 * staleTime을 refetchInterval과 정렬해 페이지 전환 시 cache hit 보장 (cold mount 시
 * 즉시 stale 판정 후 fetch 발생하던 30s 갭 제거). background polling이 신선도 유지.
 */
export const POLLING_QUERY_OPTIONS = {
  refetchInterval: 60_000,
  staleTime: 60_000,
} as const;
