import { PieChart } from '../../components/charts/PieChart';
import { TYPE_COLORS } from '../../components/charts/colors';
import type { TypeDistributionEntry } from '../../types/api';

interface TypeDistributionProps {
  data: TypeDistributionEntry[];
}

export function TypeDistribution({ data }: TypeDistributionProps) {
  const chartData = data.map((entry) => ({ name: entry.type, value: entry.count }));
  const colors = data.map((entry) => TYPE_COLORS[entry.type]);

  return (
    <section
      style={{
        padding: 24,
        border: '1px solid #e5e7eb',
        borderRadius: 8,
        background: '#fff',
      }}
    >
      <h2 style={{ margin: 0, fontSize: 16, fontWeight: 600 }}>탐지 유형별 분포</h2>
      {data.length === 0 ? (
        <EmptyMessage />
      ) : (
        <PieChart data={chartData} colors={colors} />
      )}
    </section>
  );
}

function EmptyMessage() {
  return (
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
  );
}
