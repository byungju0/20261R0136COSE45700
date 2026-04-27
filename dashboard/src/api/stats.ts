import { useQuery } from '@tanstack/react-query';
import { apiClient } from './client';
import type { StatsResponse } from '../types/api';

export const STATS_QUERY_KEY = ['stats'] as const;

async function fetchStats(): Promise<StatsResponse> {
  const response = await apiClient.get<StatsResponse>('/stats');
  return response.data;
}

export function useStatsQuery() {
  return useQuery({
    queryKey: STATS_QUERY_KEY,
    queryFn: fetchStats,
    refetchInterval: 60_000,
    staleTime: 30_000,
  });
}
