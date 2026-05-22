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
import { PERMISSIONS, preferredLandingRoute } from '@/lib/permissions';

interface User {
  adminId: string;
  firstName: string;
  lastName: string;
  email: string;
  role: string;
  permissions: string[];
  profilePhotoUrl?: string | null;
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

const superAdminPermissions = Array.from(new Set(Object.values(PERMISSIONS))).sort();

function normalizeUser(user: User | null): User | null {
  if (!user) {
    return null;
  }

  if (user.role === 'super_admin') {
    return {
      ...user,
      permissions: superAdminPermissions,
    };
  }

  return {
    ...user,
    permissions: Array.isArray(user.permissions) ? user.permissions : [],
  };
}

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
        setUser(normalizeUser(cachedUser));
      }

      try {
        const response = await api.get('/admin/auth/me');
        const liveUser = normalizeUser(unwrapApiData<User>(response));
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
    const normalizedUser = normalizeUser(userData);
    setStoredSession(accessToken, refreshToken, normalizedUser);
    setUser(normalizedUser);
    router.push(preferredLandingRoute(normalizedUser?.permissions || []));
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
    if (user.role === 'super_admin') return true;

    const userPermissions = user.permissions || [];
    if (Array.isArray(permission)) {
      return permission.some((item) => userPermissions.includes(item));
    }

    return userPermissions.includes(permission);
  };

  const updateUser = (userData: Partial<User>) => {
    setUser((current) => {
      if (!current) return current;
      const nextUser = normalizeUser({ ...current, ...userData });
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
