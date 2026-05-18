import { AxiosError } from 'axios';

export interface PaginationMeta {
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages?: number;
  hasNextPage?: boolean;
  hasPreviousPage?: boolean;
}

const defaultPagination: PaginationMeta = {
  page: 1,
  pageSize: 10,
  totalCount: 0,
  totalPages: 1,
  hasNextPage: false,
  hasPreviousPage: false,
};

export function unwrapApiData<T>(response: unknown): T {
  const payload = response as { data?: { data?: T } };
  return payload?.data?.data as T;
}

export function unwrapPagedResponse<T>(response: unknown): { data: T[]; pagination: PaginationMeta } {
  const payload = (response as { data?: { data?: { data?: T[]; pagination?: PaginationMeta } | T[] } })?.data?.data;

  if (payload && !Array.isArray(payload) && 'data' in payload && 'pagination' in payload) {
    return {
      data: payload.data || [],
      pagination: { ...defaultPagination, ...payload.pagination },
    };
  }

  if (Array.isArray(payload)) {
    return {
      data: payload,
      pagination: { ...defaultPagination, totalCount: payload.length },
    };
  }

  return {
    data: [],
    pagination: defaultPagination,
  };
}

export function getApiErrorMessage(error: unknown, fallback: string) {
  const axiosError = error as AxiosError<{
    detail?: string;
    message?: string;
    error?: { message?: string };
    errors?: Record<string, string[]>;
  }>;

  const payload = axiosError.response?.data;
  if (!payload) {
    return fallback;
  }

  const firstValidationError = payload.errors
    ? Object.values(payload.errors)[0]?.[0]
    : null;

  return payload.detail || payload.message || payload.error?.message || firstValidationError || fallback;
}
