'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import api, {
  clearStoredSession,
  getStoredAccessToken,
  getStoredUser,
  setStoredSession,
  setStoredUser,
} from '@/lib/api';
import { unwrapApiData } from '@/lib/api-response';
import { preferredLandingRoute } from '@/lib/permissions';

interface User {
  adminId: string;
  firstName: string;
  lastName: string;
  email: string;
  role: string;
  permissions: string[];
  is2FAEnabled?: boolean;
  lastLoginAt?: string | null;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (accessToken: string, refreshToken: string, userData: User) => void;
  logout: () => void;
  hasPermission: (permission?: string | string[] | null) => boolean;
  updateUser: (userData: Partial<User>) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    let cancelled = false;

    const restoreSession = async () => {
      const token = getStoredAccessToken();
      if (!token) {
        if (!cancelled) {
          setUser(null);
          setLoading(false);
        }
        return;
      }

      const cachedUser = getStoredUser<User>();
      if (!cancelled && cachedUser) {
        setUser(cachedUser);
      }

      try {
        const response = await api.get('/admin/auth/me');
        const liveUser = unwrapApiData<User>(response);
        if (!cancelled) {
          setUser(liveUser);
        }
        setStoredUser(liveUser);
      } catch {
        if (!cancelled) {
          setUser(null);
        }
        clearStoredSession();
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    void restoreSession();

    return () => {
      cancelled = true;
    };
  }, []);

  const login = (accessToken: string, refreshToken: string, userData: User) => {
    setStoredSession(accessToken, refreshToken, userData);
    setUser(userData);
    router.push(preferredLandingRoute(userData.permissions));
  };

  const logout = async () => {
    try {
      await api.post('/admin/auth/logout');
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      clearStoredSession();
      setUser(null);
      router.push('/login');
    }
  };

  const hasPermission = (permission?: string | string[] | null) => {
    if (!permission) return true;
    if (!user) return false;

    const userPermissions = user.permissions || [];
    if (Array.isArray(permission)) {
      return permission.some((item) => userPermissions.includes(item));
    }

    return userPermissions.includes(permission);
  };

  const updateUser = (userData: Partial<User>) => {
    setUser((current) => {
      if (!current) return current;
      const nextUser = { ...current, ...userData };
      setStoredUser(nextUser);
      return nextUser;
    });
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, hasPermission, updateUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
