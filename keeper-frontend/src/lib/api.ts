'use client';

import axios from 'axios';

export const ACCESS_TOKEN_KEY = 'keeper_access_token';
export const REFRESH_TOKEN_KEY = 'keeper_refresh_token';
export const USER_CACHE_KEY = 'keeper_user';

const defaultApiBaseUrl = 'http://localhost:5247/api/v1';
export const configuredBaseUrl = (process.env.NEXT_PUBLIC_API_BASE_URL || defaultApiBaseUrl).replace(/\/$/, '');

const api = axios.create({
  baseURL: configuredBaseUrl,
  headers: {
    'Content-Type': 'application/json',
  },
});

export function getStoredAccessToken() {
  return typeof window !== 'undefined' ? localStorage.getItem(ACCESS_TOKEN_KEY) : null;
}

export function getStoredRefreshToken() {
  return typeof window !== 'undefined' ? localStorage.getItem(REFRESH_TOKEN_KEY) : null;
}

export function getStoredUser<T>() {
  if (typeof window === 'undefined') {
    return null;
  }

  const raw = localStorage.getItem(USER_CACHE_KEY);
  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export function setStoredUser<T>(user: T | null) {
  if (typeof window === 'undefined') {
    return;
  }

  if (user === null) {
    localStorage.removeItem(USER_CACHE_KEY);
    return;
  }

  localStorage.setItem(USER_CACHE_KEY, JSON.stringify(user));
}

export function setStoredSession(accessToken: string, refreshToken: string, user?: unknown) {
  if (typeof window === 'undefined') {
    return;
  }

  localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
  localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
  if (user !== undefined) {
    setStoredUser(user);
  }
}

export function clearStoredSession() {
  if (typeof window === 'undefined') {
    return;
  }

  localStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
  localStorage.removeItem(USER_CACHE_KEY);
}

let refreshRequest: Promise<string | null> | null = null;

async function refreshAccessToken() {
  const refreshToken = getStoredRefreshToken();
  if (!refreshToken) {
    return null;
  }

  if (!refreshRequest) {
    refreshRequest = axios
      .post(`${configuredBaseUrl}/auth/refresh-token`, { refreshToken }, {
        headers: {
          'Content-Type': 'application/json',
        },
      })
      .then((response) => {
        const payload = response?.data?.data;
        if (!payload?.accessToken || !payload?.refreshToken) {
          clearStoredSession();
          return null;
        }

        const cachedUser = getStoredUser<unknown>();
        setStoredSession(payload.accessToken, payload.refreshToken, cachedUser ?? undefined);
        return payload.accessToken as string;
      })
      .catch(() => {
        clearStoredSession();
        return null;
      })
      .finally(() => {
        refreshRequest = null;
      });
  }

  return refreshRequest;
}

api.interceptors.request.use((config) => {
  const token = getStoredAccessToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error?.config as {
      _retry?: boolean;
      url?: string;
      headers?: Record<string, string>;
    };

    if (
      error.response?.status === 401 &&
      originalRequest &&
      !originalRequest._retry &&
      !String(originalRequest.url || '').includes('/auth/user-login') &&
      !String(originalRequest.url || '').includes('/auth/register-keeper') &&
      !String(originalRequest.url || '').includes('/auth/refresh-token')
    ) {
      originalRequest._retry = true;
      const nextAccessToken = await refreshAccessToken();

      if (nextAccessToken) {
        originalRequest.headers = originalRequest.headers || {};
        originalRequest.headers.Authorization = `Bearer ${nextAccessToken}`;
        return api(originalRequest);
      }
    }

    if (error.response?.status === 401 && typeof window !== 'undefined') {
      clearStoredSession();
      if (!['/login', '/register', '/forgot-password', '/reset-password'].includes(window.location.pathname)) {
        window.location.href = '/login';
      }
    }

    return Promise.reject(error);
  },
);

export default api;
