import { useEffect, useState } from 'react';
import { Sun, Moon } from 'lucide-react';
import { ManualCrawlButton } from '@/components/tracker/ManualCrawlButton';

type Theme = 'light' | 'dark';

function readInitialTheme(): Theme {
  if (typeof window === 'undefined') return 'light';
  // index.html의 인라인 스크립트가 이미 data-theme을 설정 — 그 값을 신뢰원으로.
  const fromDom = document.documentElement.getAttribute('data-theme');
  if (fromDom === 'dark' || fromDom === 'light') return fromDom;
  try {
    const saved = localStorage.getItem('theme');
    if (saved === 'dark' || saved === 'light') return saved;
  } catch {
    /* Private Mode 등에서 localStorage 접근 차단 → fallthrough */
  }
  try {
    if (window.matchMedia?.('(prefers-color-scheme: dark)').matches) return 'dark';
  } catch {
    /* matchMedia 미지원 환경 fallthrough */
  }
  return 'light';
}

export function Topbar() {
  const [theme, setTheme] = useState<Theme>(readInitialTheme);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    try {
      localStorage.setItem('theme', theme);
    } catch {
      /* localStorage 쓰기 실패는 무시 (인메모리만 유지) */
    }
  }, [theme]);

  return (
    <div
      className="flex items-center justify-end gap-2.5 border-b"
      style={{
        height: 'var(--h-topbar)',
        padding: '0 var(--pad-topbar-x)',
        borderColor: 'var(--border-1)',
      }}
    >
      <ManualCrawlButton />
      <ThemeToggle theme={theme} onToggle={() => setTheme(theme === 'dark' ? 'light' : 'dark')} />
    </div>
  );
}

function ThemeToggle({ theme, onToggle }: { theme: Theme; onToggle: () => void }) {
  const Icon = theme === 'dark' ? Sun : Moon;
  return (
    <button
      type="button"
      onClick={onToggle}
      aria-label="테마 전환"
      title={theme === 'dark' ? '라이트로 전환' : '다크로 전환'}
      className="inline-flex size-8 cursor-pointer items-center justify-center rounded-md border bg-transparent transition-colors"
      style={{
        borderColor: 'var(--border-1)',
        color: 'var(--fg-2)',
      }}
    >
      <Icon className="size-3.5" />
    </button>
  );
}
