'use client';

/* eslint-disable @next/next/no-img-element */

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { motion } from 'framer-motion';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useTheme } from 'next-themes';
import api from '@/lib/api';
import {
  LayoutDashboard,
  Users,
  UserCheck,
  Settings,
  LogOut,
  Menu,
  X,
  Bell,
  Search,
  ShieldCheck,
  FolderTree,
  AlertCircle,
  Store,
  BarChart3,
  Tag,
  Star,
  Sun,
  Moon,
  MessageCircle
} from 'lucide-react';
import AccessDenied from '@/components/AccessDenied';
import { PERMISSIONS, pathPermission } from '@/lib/permissions';
import { NotificationBell } from '@/components/NotificationBell';

const sidebarItems = [
  { icon: LayoutDashboard, label: 'Dashboard', href: '/dashboard', permission: PERMISSIONS.systemView },
  { icon: Users, label: 'User Management', href: '/users', permission: PERMISSIONS.usersView },
  { icon: Store, label: 'Shops', href: '/shops', permission: PERMISSIONS.shopsView },
  { icon: Tag, label: 'Offers', href: '/offers', permission: PERMISSIONS.offersView },
  { icon: Star, label: 'Reviews', href: '/reviews', permission: [PERMISSIONS.reviewsView, PERMISSIONS.moderationView] },
  { icon: Bell, label: 'Notifications', href: '/notifications', permission: PERMISSIONS.notificationsView },
  { icon: UserCheck, label: 'Keeper Verification', href: '/keepers/verify', permission: PERMISSIONS.keepersView },
  { icon: BarChart3, label: 'Journey Analytics', href: '/journeys', permission: PERMISSIONS.journeysView },
  { icon: FolderTree, label: 'Categories', href: '/categories', permission: PERMISSIONS.categoriesView },
  { icon: Tag, label: 'Tags', href: '/tags', permission: PERMISSIONS.tagsView },
  { icon: AlertCircle, label: 'Content Moderation', href: '/moderation', permission: PERMISSIONS.moderationView },
  { icon: MessageCircle, label: 'Support Tickets', href: '/support', permission: PERMISSIONS.systemView },
  { icon: Settings, label: 'System Settings', href: '/settings', permission: [PERMISSIONS.systemView, PERMISSIONS.settingsEdit, PERMISSIONS.adminsManage] },
  { icon: Users, label: 'Admin Profile', href: '/profile', permission: null },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [isSidebarOpen, setSidebarOpen] = useState(true);
  const { user, logout, loading, hasPermission } = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    const frame = requestAnimationFrame(() => setMounted(true));
    return () => cancelAnimationFrame(frame);
  }, []);

  useEffect(() => {
    if (user && hasPermission(PERMISSIONS.systemView)) {
      api.get('/admin/support/unread-count')
        .then(res => {
          setUnreadCount(res.data.data?.unreadCount || 0);
        })
        .catch(err => console.error('Failed to fetch unread tickets count', err));
    }
  }, [user]);

  useEffect(() => {
    if (!loading && !user) {
      router.replace('/login');
    }
  }, [loading, router, user]);

  const visibleItems = sidebarItems.filter((item) => hasPermission(item.permission));
  const canAccessCurrentPage = hasPermission(pathPermission(pathname));

  if (loading || (!user && pathname !== '/login')) {
    return (
      <div className="flex-center" style={{ minHeight: '100vh' }}>
        <div className="premium-gradient" style={{ width: '40px', height: '40px', borderRadius: '50%', animation: 'pulse 2s infinite' }}></div>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', height: '100vh', overflow: 'hidden' }}>
      {/* Sidebar */}
      <motion.aside
        initial={false}
        animate={{ width: isSidebarOpen ? '280px' : '80px' }}
        className="glass-card"
        style={{
          height: '100%',
          borderRadius: 0,
          borderTop: 'none',
          borderBottom: 'none',
          borderLeft: 'none',
          zIndex: 50,
          display: 'flex',
          flexDirection: 'column',
          overflow: 'hidden'
        }}
      >
        <div style={{ padding: 0, margin: 0, height: '90px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'white' }}>
          {isSidebarOpen ? (
            <img src="/h2logo.png" alt="ROUTENT" style={{ width: '100%', height: '100%', objectFit: 'contain', padding: '0.5rem' }} />
          ) : (
            <img src="/simplelogo.png" alt="ROUTENT" style={{ width: '100%', height: '100%', objectFit: 'contain', padding: '0.5rem' }} />
          )}
        </div>

        <nav style={{ flex: 1, padding: '0.75rem', display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
          {visibleItems.map((item) => {
            const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`);
            return (
              <Link key={item.href} href={item.href} style={{ textDecoration: 'none' }}>
                <div
                  className={isActive ? 'premium-gradient' : ''}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '1rem',
                    padding: '0.75rem 1rem',
                    borderRadius: 'var(--radius)',
                    color: isActive ? 'white' : 'hsl(var(--foreground))',
                    transition: '0.25s',
                    justifyContent: isSidebarOpen ? 'flex-start' : 'center',
                    background: isActive ? undefined : (pathname === item.href ? 'hsl(var(--secondary))' : 'transparent'),
                    opacity: isActive ? 1 : 0.7
                  }}
                >
                  <item.icon size={20} />
                  {isSidebarOpen && <span style={{ fontWeight: 500 }}>{item.label}</span>}
                </div>
              </Link>
            );
          })}
        </nav>

        <div style={{ padding: '1rem', borderTop: '1px solid hsl(var(--border))' }}>
          <button
            onClick={logout}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '1rem',
              padding: '0.75rem',
              borderRadius: 'var(--radius)',
              width: '100%',
              background: 'rgba(239, 68, 68, 0.1)',
              color: 'hsl(var(--destructive))',
              border: 'none',
              justifyContent: isSidebarOpen ? 'flex-start' : 'center'
            }}
          >
            <LogOut size={20} />
            {isSidebarOpen && <span style={{ fontWeight: 500 }}>Logout</span>}
          </button>
        </div>
      </motion.aside>

      {/* Main Content */}
      <main style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {/* Topbar */}
        <header className="glass-card" style={{
          height: '90px',
          borderRadius: 0,
          borderTop: 'none',
          borderLeft: 'none',
          borderRight: 'none',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 2rem',
          zIndex: 40
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', flex: 1 }}>
            <button
              onClick={() => setSidebarOpen(!isSidebarOpen)}
              style={{ background: 'none', border: 'none', color: 'hsl(var(--foreground))', display: 'flex', alignItems: 'center', cursor: 'pointer', padding: 0 }}
            >
              <Menu size={24} />
            </button>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
            <button
              onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
              style={{ background: 'none', border: 'none', color: 'hsl(var(--foreground))', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
            >
              {!mounted ? (
                <div style={{ width: 20, height: 20 }} />
              ) : theme === 'dark' ? (
                <Sun size={20} />
              ) : (
                <Moon size={20} />
              )}
            </button>
            <Link href="/support" style={{ background: 'none', border: 'none', color: 'hsl(var(--foreground))', position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }} title="Support Tickets">
              <MessageCircle size={20} />
              {unreadCount > 0 && (
                <span style={{ position: 'absolute', top: -6, right: -6, background: 'hsl(var(--destructive))', color: 'white', borderRadius: '10px', fontSize: '0.65rem', padding: '0 4px', minWidth: '16px', textAlign: 'center', fontWeight: 'bold' }}>
                  {unreadCount}
                </span>
              )}
            </Link>
            
            <NotificationBell />

            <div style={{ height: '32px', width: '1px', background: 'hsl(var(--border))' }}></div>
            <Link href="/profile" style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', textDecoration: 'none', color: 'inherit' }}>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '0.875rem', fontWeight: 600 }}>{user ? `${user.firstName} ${user.lastName}`.trim() : ''}</p>
                <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>{user?.role || ''}</p>
              </div>
              <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'hsl(var(--secondary))', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, overflow: 'hidden' }}>
                {user?.profilePhotoUrl ? (
                  <img src={user.profilePhotoUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                ) : (
                  user?.firstName?.[0] || user?.email?.[0] || '?'
                )}
              </div>
            </Link>
          </div>
        </header>

        {/* Page Content */}
        <div id="main-content" style={{ flex: 1, padding: '2rem', overflowY: 'auto' }}>
          {canAccessCurrentPage ? children : <AccessDenied />}
        </div>
      </main>
    </div>
  );
}
