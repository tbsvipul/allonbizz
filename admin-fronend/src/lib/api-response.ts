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

export function unwrapApiData<T>(response: any): T {
  return response?.data?.data as T;
}

export function unwrapPagedResponse<T>(response: any): { data: T[]; pagination: PaginationMeta } {
  const payload = response?.data?.data;

  if (payload?.data && payload?.pagination) {
    return {
      data: payload.data as T[],
      pagination: { ...defaultPagination, ...payload.pagination },
    };
  }

  if (Array.isArray(payload)) {
    return {
      data: payload as T[],
      pagination: { ...defaultPagination, totalCount: payload.length, totalPages: 1 },
    };
  }

  return { data: [], pagination: defaultPagination };
}
