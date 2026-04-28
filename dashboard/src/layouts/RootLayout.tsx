import { useNavigate, NavLink, Outlet } from 'react-router-dom';
import { useStatsQuery } from '@/api/stats';
import { FreshnessIndicator } from '@/components/common/FreshnessIndicator';
import { ManualCrawlButton } from '@/components/tracker/ManualCrawlButton';
import { NewDetectionsBadge } from '@/components/tracker/NewDetectionsBadge';
import { Separator } from '@/components/ui/separator';
import { useShortcut } from '@/lib/shortcuts';
import { cn } from '@/lib/utils';

const NAV_ITEMS = [
  { to: '/', label: '대시보드', end: true, chord: 'd' },
  { to: '/detections', label: '탐지 목록', end: false, chord: 'l' },
  { to: '/stats', label: '통계', end: false, chord: 's' },
] as const;

export function RootLayout() {
  // RootLayout이 useStatsQuery를 호출해 모든 페이지 헤더에서 freshness 표시.
  // TanStack Query 캐싱으로 Dashboard에서 또 호출해도 추가 fetch 없음.
  const { dataUpdatedAt, isFetching } = useStatsQuery();
  const navigate = useNavigate();

  // g+d / g+l / g+s — 어디서든 페이지 점프 (UX Spec Pattern 2)
  useShortcut('g+d', () => navigate('/'));
  useShortcut('g+l', () => navigate('/detections'));
  useShortcut('g+s', () => navigate('/stats'));

  return (
    <div className="bg-muted min-h-screen">
      <header className="bg-background sticky top-0 z-10 border-b">
        <div className="mx-auto flex h-15 max-w-7xl items-center justify-between gap-4 px-8">
          <div className="flex items-center gap-8">
            <strong className="text-lg font-bold tracking-tight">Tracker</strong>
            <nav className="flex gap-1">
              {NAV_ITEMS.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.end}
                  className={({ isActive }) =>
                    cn(
                      'rounded-md px-3 py-1.5 text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-muted text-foreground'
                        : 'text-muted-foreground hover:bg-muted hover:text-foreground',
                    )
                  }
                >
                  {item.label}
                </NavLink>
              ))}
            </nav>
          </div>
          <div className="flex items-center gap-3">
            <NewDetectionsBadge />
            <ManualCrawlButton />
            <Separator orientation="vertical" className="h-5" />
            <FreshnessIndicator
              lastUpdatedAt={dataUpdatedAt}
              isFetching={isFetching}
            />
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-7xl">
        <Outlet />
      </main>
    </div>
  );
}
