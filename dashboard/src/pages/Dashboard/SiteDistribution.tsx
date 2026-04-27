import { BarChart } from '../../components/charts/BarChart';
import type { SiteDistributionEntry } from '../../types/api';

interface SiteDistributionProps {
  data: SiteDistributionEntry[];
}

export function SiteDistribution({ data }: SiteDistributionProps) {
  return (
    <section
      style={{
        padding: 24,
        border: '1px solid #e5e7eb',
        borderRadius: 8,
        background: '#fff',
      }}
    >
      <h2 style={{ margin: 0, fontSize: 16, fontWeight: 600 }}>사이트별 탐지 수</h2>
      {data.length === 0 ? (
        <div
          style={{
            height: 300,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#9ca3af',
          }}
        >
          탐지된 게시글이 없습니다.
        </div>
      ) : (
        <BarChart data={data.map((entry) => ({ name: entry.site, value: entry.count }))} />
      )}
    </section>
  );
}
