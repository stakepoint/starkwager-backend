export async function paginate<T>(
  data: T[], // The raw data returned by the service
  total: number, // The total number of records
  page: number,
  limit: number,
): Promise<{ data: T[]; meta: PaginationMeta }> {
  const totalPages = Math.ceil(total / limit);

  return {
    data,
    meta: {
      total,
      page,
      limit,
      totalPages,
    },
  };
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}
