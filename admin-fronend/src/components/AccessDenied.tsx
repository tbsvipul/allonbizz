'use client';

import { ShieldAlert } from 'lucide-react';

export default function AccessDenied() {
  return (
    <div className="glass-card" style={{ padding: '3rem', maxWidth: '640px', margin: '3rem auto', textAlign: 'center' }}>
      <div style={{ width: '64px', height: '64px', borderRadius: '50%', background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1rem' }}>
        <ShieldAlert size={28} />
      </div>
      <h2 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.5rem' }}>Access denied</h2>
      <p style={{ color: 'hsl(var(--muted-foreground))' }}>
        Your account does not have permission to view this section.
      </p>
    </div>
  );
}
