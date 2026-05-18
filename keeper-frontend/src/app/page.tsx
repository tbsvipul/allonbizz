'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LoadingScreen } from '@/components/LoadingScreen';
import { useAuth } from '@/context/AuthContext';

export default function HomePage() {
  const router = useRouter();
  const { user, loading } = useAuth();

  useEffect(() => {
    if (loading) {
      return;
    }

    router.replace(user ? '/dashboard' : '/login');
  }, [loading, router, user]);

  return <LoadingScreen message="Preparing your workspace..." />;
}
