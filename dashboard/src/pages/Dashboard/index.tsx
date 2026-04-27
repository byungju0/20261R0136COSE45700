import { useStatsQuery } from '../../api/stats';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { LastUpdated } from './LastUpdated';
import { SiteDistribution } from './SiteDistribution';
import { TodayCount } from './TodayCount';
import { TypeDistribution } from './TypeDistribution';

export function DashboardPage() {
  const { data, isLoading, error, dataUpdatedAt } = useStatsQuery();

  if (error) throw error;
  if (isLoading || !data) {
    return (
      <div style={{ padding: 32 }}>
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  const isEmpty = data.todayCount === 0;

  return (
    <div style={{ padding: 24, display: 'flex', flexDirection: 'column', gap: 16 }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h1 style={{ margin: 0, fontSize: 24 }}>메인 대시보드</h1>
        <LastUpdated dataUpdatedAt={dataUpdatedAt} />
      </header>

      {isEmpty ? (
        <section
          style={{
            padding: 48,
            border: '1px solid #e5e7eb',
            borderRadius: 8,
            textAlign: 'center',
            color: '#6b7280',
            background: '#fff',
          }}
        >
          오늘 탐지된 게시글이 없습니다.
        </section>
      ) : (
        <>
          <TodayCount count={data.todayCount} delta={data.deltaFromYesterday} />
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
              gap: 16,
            }}
          >
            <TypeDistribution data={data.typeDistribution} />
            <SiteDistribution data={data.siteDistribution} />
          </div>
        </>
      )}
    </div>
  );
}
