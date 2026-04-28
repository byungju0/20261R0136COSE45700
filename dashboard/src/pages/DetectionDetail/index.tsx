import { useParams } from 'react-router-dom';

export function DetectionDetailPage() {
  const { id } = useParams<{ id: string }>();
  return (
    <div className="px-8 py-6">
      <h1 className="mb-2 text-2xl font-semibold tracking-tight">
        탐지 상세 (ID: <code className="font-mono text-xl">{id}</code>)
      </h1>
      <p className="text-muted-foreground text-sm">
        Story 4.5에서 구현됩니다.
      </p>
    </div>
  );
}
