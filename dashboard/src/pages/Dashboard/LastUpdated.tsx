import { useEffect, useState } from 'react';
import { formatDistanceToNow } from 'date-fns';
import { ko } from 'date-fns/locale';

interface LastUpdatedProps {
  dataUpdatedAt: number;
}

export function LastUpdated({ dataUpdatedAt }: LastUpdatedProps) {
  const [, forceTick] = useState(0);

  useEffect(() => {
    const id = setInterval(() => forceTick((n) => n + 1), 30_000);
    return () => clearInterval(id);
  }, []);

  if (!dataUpdatedAt) return null;

  const label = formatDistanceToNow(new Date(dataUpdatedAt), {
    addSuffix: true,
    locale: ko,
  });

  return (
    <span style={{ fontSize: 12, color: '#6b7280' }}>
      {label} 업데이트
    </span>
  );
}
