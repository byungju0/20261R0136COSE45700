import type { HTMLAttributes } from 'react';
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

const LEVEL_CLASSES: Record<Level, string> = {
  high: 'bg-confidence-high/10 text-confidence-high',
  medium: 'bg-confidence-medium/10 text-confidence-medium',
  low: 'bg-confidence-low/10 text-confidence-low',
};

export function ConfidenceBadge({
  score,
  className,
  ...rest
}: ConfidenceBadgeProps) {
  const level = levelOf(score);
  return (
    <span
      role="status"
      aria-label={`신뢰도 ${score.toFixed(2)} (${LEVEL_LABEL[level]})`}
      className={cn(
        'inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 font-mono text-xs font-medium',
        LEVEL_CLASSES[level],
        className,
      )}
      {...rest}
    >
      <span
        aria-hidden
        className={cn('size-1.5 rounded-full', {
          'bg-confidence-high': level === 'high',
          'bg-confidence-medium': level === 'medium',
          'bg-confidence-low': level === 'low',
        })}
      />
      {score.toFixed(2)}
    </span>
  );
}
