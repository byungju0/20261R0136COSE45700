import { LoadingSpinner } from './LoadingSpinner';

interface RefreshIndicatorProps {
  isFetching: boolean;
}

export function RefreshIndicator({ isFetching }: RefreshIndicatorProps) {
  if (!isFetching) return null;
  return <LoadingSpinner size="sm" label="갱신 중..." />;
}
