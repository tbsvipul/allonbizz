import { EmptyState } from '@/components/EmptyState';

interface TrendItem {
  label: string;
  value: number;
  meta?: string;
}

export function TrendBars({
  title,
  items,
  emptyMessage,
}: {
  title: string;
  items: TrendItem[];
  emptyMessage: string;
}) {
  if (items.length === 0) {
    return <EmptyState title={title} message={emptyMessage} />;
  }

  const max = Math.max(...items.map((item) => item.value), 1);

  return (
    <div className="chart-list">
      {items.map((item) => (
        <div key={`${item.label}-${item.value}`} className="bar-row">
          <div className="inline-row" style={{ justifyContent: 'space-between' }}>
            <strong>{item.label}</strong>
            <span className="muted-text tiny-text">
              {item.value}
              {item.meta ? ` | ${item.meta}` : ''}
            </span>
          </div>
          <div className="bar-track" aria-hidden="true">
            <div className="bar-fill" style={{ width: `${(item.value / max) * 100}%` }} />
          </div>
        </div>
      ))}
    </div>
  );
}
