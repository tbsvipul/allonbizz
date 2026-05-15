'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import { preferredLandingRoute } from '@/lib/permissions';

export default function Home() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading) {
      if (user) {
        router.push(preferredLandingRoute(user.permissions));
      } else {
        router.push('/login');
      }
    }
  }, [user, loading, router]);

  return (
    <div className="flex-center" style={{ minHeight: '100vh' }}>
      <div className="premium-gradient" style={{ width: '40px', height: '40px', borderRadius: '50%', animation: 'pulse 2s infinite' }}></div>
      <style jsx>{`
        @keyframes pulse {
          0% { transform: scale(0.95); opacity: 0.5; }
          50% { transform: scale(1.05); opacity: 0.8; }
          100% { transform: scale(0.95); opacity: 0.5; }
        }
      `}</style>
    </div>
  );
}
