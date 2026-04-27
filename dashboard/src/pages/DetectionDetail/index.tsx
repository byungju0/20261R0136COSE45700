import { useParams } from 'react-router-dom';

export function DetectionDetailPage() {
  const { id } = useParams<{ id: string }>();
  return (
    <div style={{ padding: 24 }}>
      <h1 style={{ marginTop: 0 }}>탐지 상세 (ID: {id})</h1>
      <p style={{ color: '#6b7280' }}>Story 4.5에서 구현됩니다.</p>
    </div>
  );
}
