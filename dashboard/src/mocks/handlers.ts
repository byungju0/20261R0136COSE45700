import { http, HttpResponse } from 'msw';
import type { StatsResponse } from '../types/api';

const STATS_MOCK: StatsResponse = {
  todayCount: 12,
  deltaFromYesterday: 3,
  typeDistribution: [
    { type: '매크로_판매', count: 5 },
    { type: '핵_배포', count: 3 },
    { type: '계정_거래', count: 2 },
    { type: '리세마라', count: 1 },
    { type: '기타', count: 1 },
  ],
  siteDistribution: [
    { site: 'tailstar.net', count: 4 },
    { site: 'ptt.cc', count: 3 },
    { site: 'dcard.tw', count: 2 },
    { site: 'tieba.baidu.com', count: 2 },
    { site: '52pojie.cn', count: 1 },
  ],
  langDistribution: [
    { lang: 'ko', count: 4 },
    { lang: 'zh-CN', count: 5 },
    { lang: 'zh-TW', count: 3 },
  ],
};

const baseUrl = import.meta.env.VITE_API_BASE_URL ?? '/api';

export const handlers = [
  http.get(`${baseUrl}/stats`, () => HttpResponse.json(STATS_MOCK)),
];
