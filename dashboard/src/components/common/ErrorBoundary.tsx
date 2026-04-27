import { isRouteErrorResponse, useRouteError } from 'react-router-dom';
import { ProblemDetailError } from '../../api/client';

export function ErrorBoundary() {
  const error = useRouteError();

  let title = '문제가 발생했습니다';
  let detail = '잠시 후 다시 시도해 주세요.';
  let errorCode: string | undefined;

  if (error instanceof ProblemDetailError) {
    title = error.problem.title;
    detail = error.problem.detail;
    errorCode = error.errorCode;
  } else if (isRouteErrorResponse(error)) {
    title = `${error.status} ${error.statusText}`;
    detail = typeof error.data === 'string' ? error.data : detail;
  } else if (error instanceof Error) {
    detail = error.message || detail;
  }

  return (
    <div role="alert" style={{ padding: 24, maxWidth: 720 }}>
      <h2 style={{ marginTop: 0 }}>{title}</h2>
      <p>{detail}</p>
      {errorCode && (
        <p style={{ fontSize: 12, color: '#888' }}>
          오류 코드: <code>{errorCode}</code>
        </p>
      )}
      <button type="button" onClick={() => window.location.reload()}>
        새로고침
      </button>
    </div>
  );
}
