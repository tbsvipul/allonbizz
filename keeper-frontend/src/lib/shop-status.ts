function normalizeStatus(status?: string | null) {
  return String(status || '').trim().toLowerCase();
}

export function getShopVerificationStatusLabel(status?: string | null, isVerified?: boolean) {
  const normalized = normalizeStatus(status);

  if (normalized === 'verified' || isVerified) {
    return 'Verified';
  }

  if (normalized === 'rejected') {
    return 'Rejected';
  }

  return 'Pending';
}

export function getShopListingStatusLabel(status?: string | null, isActive?: boolean) {
  const normalized = normalizeStatus(status);

  if (normalized === 'active' || isActive === true) {
    return 'Active';
  }

  if (normalized === 'inactive' || isActive === false) {
    return 'Inactive';
  }

  return status || 'Inactive';
}
