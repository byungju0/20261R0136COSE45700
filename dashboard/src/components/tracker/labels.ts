import type { DetectionType } from '@/types/api';

const LABEL_MAP: Record<DetectionType, string> = {
  매크로_판매: '매크로 판매',
  핵_배포: '핵 배포',
  계정_거래: '계정 거래',
  리세마라: '리세마라',
  기타: '기타',
};

export function getTypeLabel(type: DetectionType): string {
  return LABEL_MAP[type];
}
