import { useNavigate, Link } from 'react-router-dom';
import { formatDistanceToNow } from 'date-fns';
import { ko } from 'date-fns/locale';
import { AlertTriangle, AlertCircle, Circle } from 'lucide-react';
import { useDetectionsQuery } from '@/api/detections';
import { TypeIcon } from './TypeIcon';
import { getTypeLabel } from './labels';
import { cn } from '@/lib/utils';
import type { Detection } from '@/types/api';

const RECENT_LIMIT = 5;

type Severity = 'high' | 'medium' | 'low';

function severityOf(score: number): Severity {
  if (!Number.isFinite(score)) return 'low';
  const s = Math.max(0, Math.min(1, score));
  if (s >= 0.8) return 'high';
  if (s >= 0.5) return 'medium';
  return 'low';
}

function formatScore(score: number): string {
  if (!Number.isFinite(score)) return '—';
  const s = Math.max(0, Math.min(0.99, score));
  return s.toFixed(2).replace(/^0/, '');
}

function formatRelativeTime(iso: string): string {
  const t = Date.parse(iso);
  if (!Number.isFinite(t)) return '—';
  return formatDistanceToNow(new Date(t), { addSuffix: true, locale: ko });
}

/**
 * Recent · High confidence — Dashboard Hero 아래 노출되는 최신 탐지 5건.
 * mockup의 alert-row + sev-v14 (N1) 패턴.
 */
export function RecentAlertList() {
  const navigate = useNavigate();
  const { data, isLoading, isError } = useDetectionsQuery({ size: RECENT_LIMIT });

  const items = data?.content?.slice(0, RECENT_LIMIT) ?? [];
  const total = data?.totalElements ?? 0;

  return (
    <section style={{ marginBottom: 'var(--pad-section)' }}>
      <div className="mb-4 flex items-baseline justify-between">
        <span
          className="text-xs font-semibold uppercase"
          style={{ color: 'var(--fg-3)', letterSpacing: 'var(--tracking-wider)' }}
        >
          Recent · High confidence
        </span>
        <Link
          to="/detections"
          className="text-xs no-underline hover:underline"
          style={{ color: 'var(--accent)' }}
        >
          전체 {total}건 →
        </Link>
      </div>

      <div
        role="list"
        className="overflow-hidden rounded-md border"
        style={{
          background: 'var(--bg-elev)',
          borderColor: 'var(--border-1)',
        }}
      >
        {isLoading ? (
          <div
            className="px-6 py-8 text-center text-sm"
            style={{ color: 'var(--fg-3)' }}
          >
            불러오는 중…
          </div>
        ) : isError ? (
          <div
            role="alert"
            className="px-6 py-8 text-center text-sm"
            style={{ color: 'var(--crit)' }}
          >
            탐지 목록을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.
          </div>
        ) : items.length === 0 ? (
          <div
            className="px-6 py-8 text-center text-sm"
            style={{ color: 'var(--fg-3)' }}
          >
            아직 탐지된 항목이 없습니다
          </div>
        ) : (
          items.map((d) => (
            <AlertRow
              key={d.id}
              detection={d}
              onClick={() => navigate(`/detections/${d.id}`)}
            />
          ))
        )}
      </div>
    </section>
  );
}

function AlertRow({ detection, onClick }: { detection: Detection; onClick: () => void }) {
  const severity = severityOf(detection.confidence);
  const time = formatRelativeTime(detection.detectedAt);
  const snippet = detection.translatedText ?? detection.rawText;

  return (
    <button
      type="button"
      role="listitem"
      onClick={onClick}
      data-severity={severity}
      title={snippet}
      className={cn(
        'group grid w-full cursor-pointer items-center border-t bg-transparent text-left transition-colors first:border-t-0 hover:bg-[var(--hover)]',
        // 좌측 6px 색 막대 (box-shadow inset) + tint — color-mix로 테마 자동 swap
        'data-[severity=high]:shadow-[inset_6px_0_0_var(--crit-bg)] data-[severity=high]:bg-[color-mix(in_oklch,var(--crit-bg)_8%,transparent)]',
        'data-[severity=medium]:shadow-[inset_6px_0_0_var(--warn-bg)] data-[severity=medium]:bg-[color-mix(in_oklch,var(--warn-bg)_6%,transparent)]',
      )}
      style={{
        gridTemplateColumns: '52px 28px minmax(120px, 180px) minmax(0, 1fr) 90px',
        gap: 'clamp(10px, 1vw, 18px)',
        padding: 'var(--pad-alert-row-y) var(--pad-alert-row-x)',
        borderColor: 'var(--border-1)',
      }}
    >
      <SeverityBadge confidence={detection.confidence} severity={severity} />
      <TypeIcon type={detection.type} showLabel={false} />
      <div className="flex min-w-0 flex-col gap-0.5">
        <span
          className="font-medium"
          style={{ fontSize: 'var(--size-alert-type)', color: 'var(--fg)' }}
        >
          {getTypeLabel(detection.type)}
        </span>
        <span
          className="font-mono text-xs"
          style={{ color: 'var(--fg-3)', fontFeatureSettings: "'liga' off" }}
        >
          {detection.siteName}
        </span>
      </div>
      <span
        className="overflow-hidden text-ellipsis whitespace-nowrap"
        style={{
          fontSize: 'var(--size-alert-snippet)',
          color: 'var(--fg-2)',
        }}
      >
        {snippet}
      </span>
      <span
        className="font-mono text-right text-xs tabular-nums"
        style={{ color: 'var(--fg-3)' }}
      >
        {time}
      </span>
    </button>
  );
}

function SeverityBadge({
  confidence,
  severity,
}: {
  confidence: number;
  severity: Severity;
}) {
  const Icon = severity === 'high' ? AlertTriangle : severity === 'medium' ? AlertCircle : Circle;
  const numText = formatScore(confidence);

  const chipClass =
    severity === 'high'
      ? 'bg-confidence-high-bg text-white'
      : severity === 'medium'
        ? 'bg-confidence-medium-bg text-white'
        : 'border';

  const lowStyle: React.CSSProperties =
    severity === 'low'
      ? { borderColor: 'var(--border-1)', color: 'var(--fg-3)' }
      : {};

  return (
    <span
      aria-hidden
      className={cn(
        'inline-flex size-11 flex-col items-center justify-center gap-[3px] rounded-md font-mono leading-none',
        chipClass,
      )}
      style={lowStyle}
    >
      <Icon
        className={severity === 'low' ? 'size-2.5' : 'size-[13px]'}
        strokeWidth={2.5}
      />
      <span className="text-[13px] font-bold tabular-nums tracking-tight">
        {numText}
      </span>
    </span>
  );
}
