import { ArrowRight, ListChecks } from 'lucide-react';
import { Link } from 'react-router-dom';
import { cn } from '@/lib/utils';

interface DashboardCTAProps {
  count: number;
  /** TanStack Query dataUpdatedAt (epoch ms). Optional secondary text. */
  lastUpdatedAt?: number;
  className?: string;
}

export function DashboardCTA({ count, className }: DashboardCTAProps) {
  return (
    <Link
      to="/detections"
      className={cn(
        'group bg-primary text-primary-foreground flex items-center justify-between rounded-lg px-8 py-6 transition-opacity hover:opacity-90 focus-visible:ring-ring/50 focus-visible:outline-none focus-visible:ring-2',
        className,
      )}
      aria-label={`탐지 목록 보러 가기 — ${count}건 검토 대기 중`}
    >
      <div className="flex items-center gap-4">
        <span className="bg-primary-foreground/10 flex size-10 items-center justify-center rounded-md">
          <ListChecks className="size-5" aria-hidden />
        </span>
        <div>
          <div className="text-base font-semibold leading-tight">
            탐지 목록 보러 가기
          </div>
          <div className="text-primary-foreground/70 mt-0.5 text-xs">
            {count}건 검토 대기 중
          </div>
        </div>
      </div>
      <ArrowRight
        className="size-5 opacity-80 transition-transform group-hover:translate-x-0.5"
        aria-hidden
      />
    </Link>
  );
}
