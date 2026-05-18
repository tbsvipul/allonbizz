import { formatKeeperStatus, statusTone } from '@/lib/keeper';

export function StatusPill({ status }: { status?: string | null }) {
  const tone = statusTone(status);
  const className =
    tone === 'success'
      ? 'status-pill pill-success'
      : tone === 'warning'
        ? 'status-pill pill-warning'
        : tone === 'danger'
          ? 'status-pill pill-danger'
          : 'status-pill pill-info';

  return <span className={className}>{formatKeeperStatus(status)}</span>;
}
