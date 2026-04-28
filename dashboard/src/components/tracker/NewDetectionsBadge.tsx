import { useEffect, useState } from 'react';

import { ArrowRight, Sparkles } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useDetectionsQuery } from '@/api/detections';
import { cn } from '@/lib/utils';

/**
 * Journey 2 — 수동 트리거 후 신규 탐지 도착 알림.
 * since=triggered 쿼리 결과 카운트가 양수면 헤더 우측 (FreshnessIndicator 위)에 표시.
 *
 * 5분 후 자동 dismiss 또는 사용자가 클릭 시 /detections?since=triggered로 이동.
 *
 * UX Spec Pattern 4 (Inline Action Feedback) + Journey 2 핵심 보강.
 */

const AUTO_DISMISS_MS = 5 * 60 * 1000;

export function NewDetectionsBadge() {
  const { data } = useDetectionsQuery({ since: 'triggered', size: 100 });
  const newCount = data?.totalElements ?? 0;
  const [dismissed, setDismissed] = useState(false);

  // 0 → 양수 전환을 render 중 감지해 dismissed 리셋. ("previous state in render" 패턴)
  // 다음 트리거 시 새 알림이 다시 보이도록.
  const [prevPositive, setPrevPositive] = useState(newCount > 0);
  if (!prevPositive && newCount > 0) {
    setPrevPositive(true);
    setDismissed(false);
  } else if (prevPositive && newCount === 0) {
    setPrevPositive(false);
  }

  useEffect(() => {
    if (newCount === 0 || dismissed) return;
    const id = setTimeout(() => setDismissed(true), AUTO_DISMISS_MS);
    return () => clearTimeout(id);
  }, [newCount, dismissed]);

  if (newCount === 0 || dismissed) return null;

  return (
    <Link
      to="/detections?since=triggered"
      className={cn(
        'bg-warning/10 text-warning hover:bg-warning/15 inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium transition-colors',
        'focus-visible:ring-warning/50 focus-visible:outline-none focus-visible:ring-2',
      )}
      onClick={() => setDismissed(true)}
    >
      <Sparkles className="size-3" aria-hidden />
      <span>{newCount}건 새로 들어옴</span>
      <ArrowRight className="size-3" aria-hidden />
    </Link>
  );
}
