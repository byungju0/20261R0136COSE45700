interface TodayCountProps {
  count: number;
  delta: number;
}

export function TodayCount({ count, delta }: TodayCountProps) {
  const sign = delta > 0 ? '+' : delta < 0 ? '−' : '';
  const deltaColor = delta > 0 ? '#dc2626' : delta < 0 ? '#6b7280' : '#9ca3af';

  return (
    <section
      style={{
        padding: 24,
        border: '1px solid #e5e7eb',
        borderRadius: 8,
        background: '#fff',
      }}
    >
      <h2 style={{ margin: 0, fontSize: 14, color: '#6b7280', fontWeight: 500 }}>
        오늘 탐지 수
      </h2>
      <div style={{ fontSize: 56, fontWeight: 700, lineHeight: 1.1, marginTop: 8 }}>
        {count.toLocaleString('ko-KR')}
      </div>
      <div style={{ fontSize: 14, color: deltaColor, marginTop: 8 }}>
        전일 대비 {sign}
        {Math.abs(delta).toLocaleString('ko-KR')}
      </div>
    </section>
  );
}
