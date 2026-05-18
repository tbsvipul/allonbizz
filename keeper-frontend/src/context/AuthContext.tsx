'use client';

import { createContext, startTransition, useContext, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import api, {
  clearStoredSession,
  getStoredAccessToken,
  getStoredUser,
  setStoredSession,
  setStoredUser,
} from '@/lib/api';
import { unwrapApiData } from '@/lib/api-response';
import { canManageKeeper } from '@/lib/keeper';
import { KeeperProfile, SessionUser, UserProfile } from '@/lib/types';
import { useToast } from '@/context/ToastContext';

interface AuthContextValue {
  user: SessionUser | null;
  loading: boolean;
  login: (accessToken: string, refreshToken: string) => Promise<void>;
  logout: () => Promise<void>;
  refreshUser: () => Promise<SessionUser | null>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

function composeSessionUser(userProfile: UserProfile, keeperProfile: KeeperProfile | null): SessionUser {
  return {
    ...userProfile,
    keeper: keeperProfile,
    canManage: canManageKeeper(keeperProfile?.status),
  };
}

async function fetchSessionUser() {
  const userResponse = await api.get('/user/profile');
  const userProfile = unwrapApiData<UserProfile>(userResponse);

  let keeperProfile: KeeperProfile | null = null;
  try {
    const keeperResponse = await api.get('/keeper/profile');
    keeperProfile = unwrapApiData<KeeperProfile>(keeperResponse);
  } catch (error) {
    if (String(userProfile.role || '').toLowerCase() === 'keeper') {
      throw error;
    }
  }

  return composeSessionUser(userProfile, keeperProfile);
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { showToast } = useToast();
  const [user, setUser] = useState<SessionUser | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshUser = useMemo(() => async () => {
    const nextUser = await fetchSessionUser();
    setUser(nextUser);
    setStoredUser(nextUser);
    return nextUser;
  }, []);

  useEffect(() => {
    let cancelled = false;

    const restore = async () => {
      const token = getStoredAccessToken();
      if (!token) {
        if (!cancelled) {
          setLoading(false);
          setUser(null);
        }
        return;
      }

      const cachedUser = getStoredUser<SessionUser>();
      if (cachedUser && !cancelled) {
        setUser(cachedUser);
      }

      try {
        const nextUser = await fetchSessionUser();
        if (!cancelled) {
          setUser(nextUser);
          setStoredUser(nextUser);
        }
      } catch {
        clearStoredSession();
        if (!cancelled) {
          setUser(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    void restore();

    return () => {
      cancelled = true;
    };
  }, []);

  const login = async (accessToken: string, refreshToken: string) => {
    setStoredSession(accessToken, refreshToken);
    const nextUser = await refreshUser();
    showToast(`Welcome back, ${nextUser?.firstName || 'keeper'}.`, 'success');
    startTransition(() => {
      router.replace('/dashboard');
    });
  };

  const logout = async () => {
    try {
      await api.post('/auth/logout');
    } catch {
      // Ignore logout transport failures and clear local state anyway.
    } finally {
      clearStoredSession();
      setUser(null);
      startTransition(() => {
        router.replace('/login');
      });
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used inside AuthProvider.');
  }

  return context;
}
