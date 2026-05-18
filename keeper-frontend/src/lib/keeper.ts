import { KeeperProfile } from '@/lib/types';

const KEEPER_STATUS_BY_ENUM_VALUE: Record<string, string> = {
  '0': 'pendingapproval',
  '1': 'onhold',
  '2': 'approved',
  '3': 'rejected',
  '4': 'suspended',
  '5': 'active',
};

const MANAGEABLE_STATUSES = new Set(['approved', 'active']);

export function normalizeKeeperStatus(status?: unknown) {
  const raw = String(status ?? '').trim();
  if (!raw) {
    return '';
  }

  return KEEPER_STATUS_BY_ENUM_VALUE[raw] || raw.toLowerCase();
}

export function canManageKeeper(status?: unknown) {
  return MANAGEABLE_STATUSES.has(normalizeKeeperStatus(status));
}

export function formatKeeperStatus(status?: unknown) {
  const normalized = normalizeKeeperStatus(status);
  const value = normalized || 'unknown';
  if (!value) {
    return 'Unknown';
  }

  return value
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/[_-]+/g, ' ')
    .replace(/\b\w/g, (match) => match.toUpperCase());
}

export function getKeeperStatusMessage(keeper?: KeeperProfile | null) {
  if (!keeper) {
    return 'Keeper account details are not available yet.';
  }

  const status = normalizeKeeperStatus(keeper.status);
  if (status === 'pendingapproval') {
    return 'Your application is still under review. You can complete profile details while the admin team checks your business.';
  }

  if (status === 'onhold') {
    return keeper.holdReason
      ? `Your account is on hold: ${keeper.holdReason}`
      : 'Your account is on hold until the admin team completes an additional review.';
  }

  if (status === 'rejected') {
    return keeper.rejectionReason
      ? `Your application needs updates: ${keeper.rejectionReason}`
      : 'Your application was rejected. Review the feedback and update your profile before trying again.';
  }

  if (status === 'suspended') {
    return keeper.rejectionReason
      ? `Your account is suspended: ${keeper.rejectionReason}`
      : 'Your account is suspended. Contact support if you think this is a mistake.';
  }

  return 'Your account can manage shops, offers, reviews, and loyalty settings.';
}

export function statusTone(status?: unknown) {
  const normalized = normalizeKeeperStatus(status);

  if (normalized === 'approved' || normalized === 'active') {
    return 'success';
  }

  if (normalized === 'pendingapproval' || normalized === 'onhold') {
    return 'warning';
  }

  if (normalized === 'rejected' || normalized === 'suspended') {
    return 'danger';
  }

  return 'info';
}
