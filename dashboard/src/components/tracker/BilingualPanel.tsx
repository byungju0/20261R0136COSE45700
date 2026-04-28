import { cn } from '@/lib/utils';
import type { Language } from '@/types/api';

interface BilingualPanelProps {
  originalText: string;
  originalLang: Language;
  translatedText: string | null;
  className?: string;
}

const LANG_LABEL: Record<Language, string> = {
  ko: '원문 (한국어)',
  'zh-CN': '原文 (中文 简体)',
  'zh-TW': '原文 (中文 繁體)',
};

const LANG_FONT: Record<Language, string> = {
  // CJK system stacks: macOS (Apple SD Gothic Neo / PingFang) → Windows (Malgun Gothic / Microsoft YaHei) → fallback sans
  ko: '"Apple SD Gothic Neo", "Malgun Gothic", Pretendard, sans-serif',
  'zh-CN':
    '"PingFang SC", "Microsoft YaHei", "Hiragino Sans GB", "Noto Sans SC", sans-serif',
  'zh-TW':
    '"PingFang TC", "Microsoft JhengHei", "Hiragino Sans CNS", "Noto Sans TC", sans-serif',
};

/**
 * Tracker 시그니처 인터랙션 — 원문 ↔ 번역 side-by-side 렌더링.
 *
 * 한국어 게시글: 단일 컬럼 전체 폭 (translatedText === null 케이스).
 * 중국어/번체 게시글: 50:50 분할, 좌측 원문(시스템 CJK 폰트), 우측 한국어 번역(Pretendard).
 *
 * UX Spec Defining Experience: "탐지 상세 화면에서 원문·번역·신뢰도·근거를
 * 한 호흡에 검토하고 5초 안에 진짜/FP 판단" — 이 컴포넌트가 그 한 호흡의 핵심.
 *
 * line-height 1.7 (가독성), `lang` 속성 정확히 지정 (a11y).
 */
export function BilingualPanel({
  originalText,
  originalLang,
  translatedText,
  className,
}: BilingualPanelProps) {
  const isMonolingual = translatedText === null || originalLang === 'ko';

  if (isMonolingual) {
    return (
      <section
        aria-label="원문"
        className={cn(
          'bg-card rounded-lg border p-6',
          className,
        )}
      >
        <header className="text-muted-foreground mb-3 text-xs font-medium uppercase tracking-wide">
          {LANG_LABEL[originalLang]}
        </header>
        <p
          lang={originalLang}
          className="text-foreground whitespace-pre-wrap text-sm"
          style={{
            fontFamily: LANG_FONT[originalLang],
            lineHeight: 1.7,
          }}
        >
          {originalText}
        </p>
      </section>
    );
  }

  return (
    <section
      aria-label="원문과 번역"
      className={cn(
        'bg-card grid grid-cols-1 gap-0 rounded-lg border md:grid-cols-2',
        className,
      )}
    >
      <div className="border-b p-6 md:border-b-0 md:border-r">
        <header className="text-muted-foreground mb-3 text-xs font-medium uppercase tracking-wide">
          {LANG_LABEL[originalLang]}
        </header>
        <p
          lang={originalLang}
          className="text-foreground whitespace-pre-wrap text-sm"
          style={{
            fontFamily: LANG_FONT[originalLang],
            lineHeight: 1.7,
          }}
        >
          {originalText}
        </p>
      </div>
      <div className="p-6">
        <header className="text-muted-foreground mb-3 text-xs font-medium uppercase tracking-wide">
          번역 (한국어)
        </header>
        <p
          lang="ko"
          className="text-foreground whitespace-pre-wrap text-sm"
          style={{ lineHeight: 1.7 }}
        >
          {translatedText}
        </p>
      </div>
    </section>
  );
}
