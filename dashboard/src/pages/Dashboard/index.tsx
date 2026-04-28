import { PieChart } from '@/components/charts/PieChart';
import { BarChart } from '@/components/charts/BarChart';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import { ChartCard } from '@/components/tracker/ChartCard';
import { DashboardCTA } from '@/components/tracker/DashboardCTA';
import { EmptyState } from '@/components/tracker/EmptyState';
import { useStatsQuery } from '@/api/stats';
import { getTypeLabel } from '@/components/tracker/labels';
import { colorForType } from '@/components/charts/colors';

export function DashboardPage() {
  const { data, isLoading, error } = useStatsQuery();

  if (error) throw error;
  if (isLoading || !data) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center p-8">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  const isEmpty = data.todayCount === 0;

  return (
    <div className="flex flex-col gap-4 px-8 py-6">
      <header className="flex items-baseline justify-between">
        <h1 className="text-foreground text-2xl font-semibold tracking-tight">
          오늘의 탐지 현황
        </h1>
      </header>

      {isEmpty ? (
        <EmptyState
          variant="healthy"
          title="오늘 탐지된 게시글이 없습니다"
          message="시스템 정상 작동 중 · 다음 크롤링 주기에 다시 확인하세요"
        />
      ) : (
        <>
          <SummaryStrip
            count={data.todayCount}
            delta={data.deltaFromYesterday}
          />

          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
            <ChartCard
              title="유형별 분포"
              subtitle={`오늘 ${data.todayCount}건 기준`}
              empty={data.typeDistribution.length === 0}
              emptyMessage="유형별 데이터 없음"
            >
              <PieChart
                data={data.typeDistribution.map((entry) => ({
                  name: getTypeLabel(entry.type),
                  value: entry.count,
                }))}
                colors={data.typeDistribution.map((entry) =>
                  colorForType(entry.type),
                )}
              />
            </ChartCard>

            <ChartCard
              title="사이트별 분포"
              subtitle={`오늘 ${data.todayCount}건 기준`}
              empty={data.siteDistribution.length === 0}
              emptyMessage="사이트별 데이터 없음"
            >
              <BarChart
                data={data.siteDistribution.map((entry) => ({
                  name: entry.site,
                  value: entry.count,
                }))}
              />
            </ChartCard>
          </div>

          <DashboardCTA count={data.todayCount} />
        </>
      )}
    </div>
  );
}

interface SummaryStripProps {
  count: number;
  delta: number;
}

function SummaryStrip({ count, delta }: SummaryStripProps) {
  const sign = delta > 0 ? '↑ +' : delta < 0 ? '↓ ' : '';
  const deltaLabel =
    delta === 0 ? '전일과 동일' : `${sign}${Math.abs(delta)} 전일 대비`;
  const deltaClass =
    delta > 0
      ? 'text-destructive'
      : delta < 0
        ? 'text-muted-foreground'
        : 'text-muted-foreground';

  return (
    <section className="bg-card flex items-baseline gap-4 rounded-lg border px-6 py-4">
      <span className="font-mono text-3xl font-semibold leading-none tracking-tight">
        {count.toLocaleString('ko-KR')}
      </span>
      <span className="text-muted-foreground text-sm">건 탐지됨</span>
      <span className={`ml-auto text-sm font-medium ${deltaClass}`}>
        {deltaLabel}
      </span>
    </section>
  );
}
