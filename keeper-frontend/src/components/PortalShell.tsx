'use client';

import Link from 'next/link';
import { FormEvent, useEffect, useMemo, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import {
  BadgeDollarSign,
  Bell,
  ChevronRight,
  LayoutDashboard,
  LogOut,
  PanelLeftClose,
  PanelLeftOpen,
  Moon,
  Search,
  ShieldCheck,
  MessageSquareReply,
  ShieldAlert,
  Store,
  Sun,
  UserRound,
  WalletCards,
  MessageCircle,
} from 'lucide-react';
import { LoadingScreen } from '@/components/LoadingScreen';
import { StatusPill } from '@/components/StatusPill';
import { NotificationBell } from '@/components/NotificationBell';
import { useAuth } from '@/context/AuthContext';
import { useTheme } from '@/context/ThemeContext';
import { getKeeperStatusMessage } from '@/lib/keeper';
import { resolveMediaSource } from '@/lib/media';

const navItems = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard, description: 'Daily performance and traffic' },
  { href: '/shops', label: 'Shops', icon: Store, description: 'Locations and storefront details' },
  { href: '/offers', label: 'Offers', icon: BadgeDollarSign, description: 'Campaigns' },
  { href: '/notifications', label: 'Notifications', icon: Bell, description: 'Send alerts to nearby users' },
  { href: '/reviews', label: 'Reviews', icon: MessageSquareReply, description: 'Customer sentiment and replies' },
  { href: '/profile', label: 'Profile', icon: UserRound, description: 'Business identity and approval' },
  { href: '/support', label: 'Support', icon: MessageCircle, description: 'Contact NaviDeals administrators' },
];

export function PortalShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, loading, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const [collapsed, setCollapsed] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    if (!loading && !user) {
      router.replace('/login');
    }
  }, [loading, router, user]);

  const filteredNavItems = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    if (!query) {
      return navItems;
    }

    return navItems.filter((item) =>
      item.label.toLowerCase().includes(query) ||
      item.description.toLowerCase().includes(query),
    );
  }, [searchQuery]);

  if (loading || !user) {
    return <LoadingScreen message="Loading keeper portal..." />;
  }

  const businessName = user.keeper?.businessName || 'Business Workspace';
  const contactLine = [user.email, user.keeper?.contactPhone].filter(Boolean).join(' | ');
  const initials = `${user.firstName?.[0] || ''}${user.lastName?.[0] || ''}`.trim() || user.email?.[0]?.toUpperCase() || 'K';
  const isKeeperAccount = String(user.role || '').toLowerCase() === 'keeper';

  function handleSearchSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const firstMatch = filteredNavItems[0];
    if (firstMatch) {
      router.push(firstMatch.href);
    }
  }

  return (
    <div className="app-frame">
      <div className="portal-shell" data-collapsed={collapsed}>
        <aside className="portal-sidebar" style={{ overflow: 'hidden' }}>
          <div className="portal-sidebar-top" style={{ padding: 0, margin: collapsed ? '-0.85rem -2rem -0.5rem -0.85rem' : '-1rem -2rem -0.5rem -1rem', height: '88px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'white' }}>
            <Link href="/dashboard" className="portal-brand-link" title="Go to dashboard" style={{ display: 'flex', alignItems: 'center', width: '100%', height: '100%', textDecoration: 'none' }}>
              {!collapsed ? (
                <img src="/h2logo.png" alt="ROUTENT" style={{ width: '100%', height: '100%', objectFit: 'contain', padding: '0.5rem' }} />
              ) : (
                <img src="/simplelogo.png" alt="ROUTENT" style={{ width: '100%', height: '100%', objectFit: 'contain', padding: '0.5rem' }} />
              )}
            </Link>
          </div>

          <nav className="portal-nav">
            {filteredNavItems.map((item) => {
              const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
              const Icon = item.icon;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={active ? 'portal-nav-link portal-nav-link-active' : 'portal-nav-link'}
                  title={collapsed ? item.label : undefined}
                >
                  <Icon size={18} />
                  {!collapsed ? (
                    <>
                      <div className="portal-nav-copy">
                        <span>{item.label}</span>
                      </div>
                      <ChevronRight size={16} className="portal-nav-arrow" />
                    </>
                  ) : null}
                </Link>
              );
            })}

            {!filteredNavItems.length ? (
              <div className="portal-sidebar-empty">
                {!collapsed ? (
                  <>
                    <strong>No menu matches</strong>
                    <p>Try another search term in the top bar.</p>
                  </>
                ) : (
                  <Search size={16} />
                )}
              </div>
            ) : null}
          </nav>

          <div className="portal-sidebar-footer">
            {!collapsed ? (
              <div className="portal-account-card">
                <span className="portal-eyebrow">Signed in as</span>
                <strong>{`${user.firstName} ${user.lastName}`.trim()}</strong>
                <p>{contactLine}</p>
                <div className="portal-account-meta">
                  <StatusPill status={user.keeper?.status} />
                </div>
              </div>
            ) : null}

            <button type="button" className="portal-logout-button" onClick={() => void logout()} title="Sign out">
              <LogOut size={16} />
              {!collapsed ? <span>Sign out</span> : null}
            </button>
          </div>
        </aside>

        <div className="portal-main">
          <header className="portal-topbar">
            <div className="portal-topbar-left">
              <button
                type="button"
                className="portal-icon-button portal-topbar-toggle"
                onClick={() => setCollapsed((current) => !current)}
                aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
              >
                {collapsed ? <PanelLeftOpen size={18} /> : <PanelLeftClose size={18} />}
              </button>
            </div>

            <div className="portal-topbar-right">
              <button
                type="button"
                className="portal-icon-button portal-theme-toggle"
                onClick={toggleTheme}
                aria-label={theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme'}
                title={theme === 'dark' ? 'Light mode' : 'Dark mode'}
              >
                {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
              </button>

              <NotificationBell />

              <span className="topbar-badge topbar-badge-success">
                <ShieldCheck size={14} />
                {user.canManage ? 'Operational access' : 'Restricted access'}
              </span>

              <Link href="/profile" className="portal-profile-chip">
                <div className="portal-profile-copy">
                  <strong>{businessName}</strong>
                  <span>{contactLine}</span>
                </div>
                <div className="portal-profile-avatar" style={{ overflow: 'hidden' }}>
                  {user.profilePhotoUrl ? (
                    <img src={resolveMediaSource(user.profilePhotoUrl)} alt="Profile" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  ) : initials}
                </div>
              </Link>
            </div>
          </header>

          {!user.canManage && isKeeperAccount ? (
            <div className="status-banner">
              <ShieldAlert size={20} />
              <div style={{ display: 'grid', gap: '0.3rem' }}>
                <strong>Management actions are limited right now</strong>
                <p className="tiny-text">{getKeeperStatusMessage(user.keeper)}</p>
              </div>
            </div>
          ) : null}

          <div className="portal-scroll">
            <main className="portal-content">{children}</main>
          </div>
        </div>
      </div>
    </div>
  );
}
