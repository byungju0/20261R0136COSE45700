import { useEffect, useRef } from 'react';
import { formatDistanceToNow } from 'date-fns';
import { ko } from 'date-fns/locale';
import { ChevronRight } from 'lucide-react';
import { TableCell, TableRow } from '@/components/ui/table';
import { ConfidenceBadge } from './ConfidenceBadge';
import { TypeIcon } from './TypeIcon';
import { cn } from '@/lib/utils';
import type { Detection } from '@/types/api';

interface DetectionRowProps {
  detection: Detection;
  /** Currently focused via j/k navigation. Auto-scrolls into view. */
  focused?: boolean;
  /** Already visited in this session. Renders muted. */
  visited?: boolean;
  onSelect: () => void;
}

/**
 * 탐지 목록 한 행. 키보드 j/k로 focused, enter로 선택.
 * UX Spec Pattern 2 + DetectionRow C6.
 *
 * 본문 스니펫은 1줄 truncate. 실제 본문은 detail에서 BilingualPanel.
 */
export function DetectionRow({
  detection,
  focused = false,
  visited = false,
  onSelect,
}: DetectionRowProps) {
  const ref = useRef<HTMLTableRowElement | null>(null);

  // focused 상태가 되면 자동으로 시야에 스크롤
  useEffect(() => {
    if (focused && ref.current) {
      ref.current.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }
  }, [focused]);

  const time = formatDistanceToNow(new Date(detection.detectedAt), {
    addSuffix: true,
    locale: ko,
  });

  return (
    <TableRow
      ref={ref}
      role="row"
      tabIndex={0}
      aria-selected={focused}
      data-focused={focused || undefined}
      data-visited={visited || undefined}
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          onSelect();
        }
      }}
      className={cn(
        'cursor-pointer',
        'data-[focused]:bg-accent data-[focused]:ring-ring/40 data-[focused]:ring-2',
        'data-[visited]:opacity-70',
      )}
    >
      <TableCell className="w-[88px]">
        <ConfidenceBadge score={detection.confidence} />
      </TableCell>
      <TableCell className="w-[170px]">
        <TypeIcon type={detection.type} />
      </TableCell>
      <TableCell className="text-muted-foreground w-[180px] font-mono text-xs">
        {detection.siteName}
      </TableCell>
      <TableCell className="text-muted-foreground max-w-0 truncate text-sm">
        {detection.translatedText ?? detection.rawText}
      </TableCell>
      <TableCell className="text-muted-foreground w-[120px] text-right font-mono text-xs">
        {time}
      </TableCell>
      <TableCell className="w-[40px] text-right">
        <ChevronRight
          className="text-muted-foreground inline-block size-4"
          aria-hidden
        />
      </TableCell>
    </TableRow>
  );
}
