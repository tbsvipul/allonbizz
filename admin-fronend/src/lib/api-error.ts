import { AxiosError } from 'axios';

const SERVER_UNAVAILABLE_MESSAGE = 'The server is not reachable right now. Please start the API server and try again.';

function isServerUnavailableError(error: Partial<AxiosError>) {
  const status = error.response?.status;
  if (status && [502, 503, 504].includes(status)) {
    return true;
  }

  if (error.response) {
    return false;
  }

  const code = String(error.code || '').toUpperCase();
  const message = String(error.message || '').toLowerCase();

  return Boolean(
    error.request ||
      code === 'ERR_NETWORK' ||
      code === 'ECONNABORTED' ||
      message.includes('network error') ||
      message.includes('failed to fetch') ||
      message.includes('timeout'),
  );
}

export function getApiErrorMessage(error: unknown, fallback: string): string {
  const axiosError = (error || {}) as AxiosError<{
    detail?: string;
    message?: string;
    error?: { message?: string };
    errors?: Record<string, string[]>;
  }>;

  if (isServerUnavailableError(axiosError)) {
    return SERVER_UNAVAILABLE_MESSAGE;
  }

  const payload = axiosError.response?.data;
  const firstValidationError = payload?.errors
    ? Object.values(payload.errors)[0]?.[0]
    : null;

  return (
    payload?.detail ||
    payload?.message ||
    payload?.error?.message ||
    firstValidationError ||
    (axiosError.response ? fallback : null) ||
    (error instanceof Error && error.message ? error.message : null) ||
    fallback
  );
}
