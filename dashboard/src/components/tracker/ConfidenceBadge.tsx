import type { HTMLAttributes } from 'react';
import { AlertTriangle, AlertCircle, Circle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ConfidenceBadgeProps extends HTMLAttributes<HTMLSpanElement> {
  /** Confidence score 0~1 from VARCO LLM detection */
  score: number;
}

type Level = 'high' | 'medium' | 'low';

function levelOf(score: number): Level {
  if (score >= 0.8) return 'high';
  if (score >= 0.5) return 'medium';
  return 'low';
}

const LEVEL_LABEL: Record<Level, string> = {
  high: '높음',
  medium: '중간',
  low: '낮음',
};

const LEVEL_CHIP: Record<Level, string> = {
  high: 'bg-confidence-high-bg text-white',
  medium: 'bg-confidence-medium-bg text-white',
  low: 'border border-border text-muted-foreground',
};

const LEVEL_ICON = {
  high: AlertTriangle,
  medium: AlertCircle,
  low: Circle,
} as const;

/**
 * 신뢰도 배지 — 44×44 정사각 filled chip (N1 패턴).
 * pre-attentive 처리 위해 색+크기+아이콘 redundant encoding.
 * - high: red filled, ⚠ icon
 * - medium: orange filled, ⓘ icon
 * - low: outlined neutral, dot icon
 */
export function ConfidenceBadge({
  score,
  className,
  ...rest
}: ConfidenceBadgeProps) {
  const level = levelOf(score);
  const Icon = LEVEL_ICON[level];
  const numText = score.toFixed(2).replace(/^0/, '');

  return (
    <span
      role="status"
      aria-label={`신뢰도 ${score.toFixed(2)} (${LEVEL_LABEL[level]})`}
      className={cn(
        'inline-flex size-11 flex-col items-center justify-center gap-[3px] rounded-md font-mono leading-none',
        LEVEL_CHIP[level],
        className,
      )}
      {...rest}
    >
      <Icon
        aria-hidden
        className={cn('shrink-0', level === 'low' ? 'size-2.5' : 'size-[13px]')}
        strokeWidth={2.5}
      />
      <span className="text-[13px] font-bold tabular-nums tracking-tight">
        {numText}
      </span>
    </span>
  );
}
