import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiClient } from './client';
import type {
  CrawlTriggerResponse,
  Detection,
  DetectionFilter,
  DetectionListResponse,
} from '@/types/api';

export const DETECTIONS_QUERY_KEY = 'detections' as const;

function buildSearchParams(filter: DetectionFilter): URLSearchParams {
  const params = new URLSearchParams();
  if (filter.date) params.set('date', filter.date);
  if (filter.site) params.set('site', filter.site);
  if (filter.type) params.set('type', filter.type);
  if (filter.lang) params.set('lang', filter.lang);
  if (filter.since) params.set('since', filter.since);
  if (filter.page !== undefined) params.set('page', String(filter.page));
  if (filter.size !== undefined) params.set('size', String(filter.size));
  return params;
}

async function fetchDetections(
  filter: DetectionFilter,
): Promise<DetectionListResponse> {
  const params = buildSearchParams(filter);
  const qs = params.toString();
  const response = await apiClient.get<DetectionListResponse>(
    qs ? `/detections?${qs}` : '/detections',
  );
  return response.data;
}

export function useDetectionsQuery(filter: DetectionFilter) {
  return useQuery({
    queryKey: [DETECTIONS_QUERY_KEY, 'list', filter],
    queryFn: () => fetchDetections(filter),
    refetchInterval: 60_000,
    staleTime: 30_000,
    placeholderData: (prev) => prev,
  });
}

async function fetchDetection(id: number): Promise<Detection> {
  const response = await apiClient.get<Detection>(`/detections/${id}`);
  return response.data;
}

export function useDetectionQuery(id: number | undefined) {
  return useQuery({
    queryKey: [DETECTIONS_QUERY_KEY, 'detail', id],
    queryFn: () => fetchDetection(id as number),
    enabled: id !== undefined && Number.isFinite(id),
    staleTime: 60_000,
  });
}

async function triggerCrawl(): Promise<CrawlTriggerResponse> {
  const response = await apiClient.post<CrawlTriggerResponse>(
    '/crawl/trigger',
    {},
  );
  return response.data;
}

export function useCrawlTriggerMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: triggerCrawl,
    onSuccess: () => {
      // 트리거 후 목록·통계 stale 처리 → 다음 폴링에서 갱신
      queryClient.invalidateQueries({ queryKey: [DETECTIONS_QUERY_KEY] });
      queryClient.invalidateQueries({ queryKey: ['stats'] });
    },
  });
}
