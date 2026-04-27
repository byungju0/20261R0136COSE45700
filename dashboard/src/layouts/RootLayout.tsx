import { useIsFetching } from '@tanstack/react-query';
import { NavLink, Outlet } from 'react-router-dom';
import { RefreshIndicator } from '../components/common/RefreshIndicator';

const NAV_ITEMS = [
  { to: '/', label: '대시보드', end: true },
  { to: '/detections', label: '탐지 목록', end: false },
  { to: '/stats', label: '통계', end: false },
] as const;

export function RootLayout() {
  const fetchingCount = useIsFetching();
  const isFetching = fetchingCount > 0;

  return (
    <div style={{ minHeight: '100vh', background: '#f9fafb' }}>
      <header
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '12px 24px',
          background: '#fff',
          borderBottom: '1px solid #e5e7eb',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
          <strong style={{ fontSize: 18 }}>Tracker</strong>
          <nav style={{ display: 'flex', gap: 16 }}>
            {NAV_ITEMS.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.end}
                style={({ isActive }) => ({
                  color: isActive ? '#111827' : '#6b7280',
                  fontWeight: isActive ? 600 : 400,
                  textDecoration: 'none',
                })}
              >
                {item.label}
              </NavLink>
            ))}
          </nav>
        </div>
        <RefreshIndicator isFetching={isFetching} />
      </header>
      <main style={{ maxWidth: 1280, margin: '0 auto' }}>
        <Outlet />
      </main>
    </div>
  );
}
