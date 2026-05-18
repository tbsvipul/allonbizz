export function LoadingScreen({ message = 'Loading...' }: { message?: string }) {
  return (
    <div className="loading-screen">
      <div className="loading-card" style={{ padding: '1.5rem', display: 'grid', gap: '0.85rem', justifyItems: 'center' }}>
        <div className="spinner" aria-hidden="true" />
        <p className="muted-text">{message}</p>
      </div>
    </div>
  );
}
