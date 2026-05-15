'use client';

import React, { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import DashboardShopMap from '@/components/DashboardShopMap';
import {
  Users, Store, TrendingUp, ArrowUpRight,
  ShieldCheck, Package, Clock, Activity,
  AlertCircle, CheckCircle2, Navigation, Layers, RefreshCw
} from 'lucide-react';
import { motion } from 'framer-motion';
import api from '@/lib/api';

interface RecentActivity {
  type: string;
  description: string;
  timestamp: string;
}

interface TopShop {
  shopId: string;
  name: string;
  category: string;
  offersCount: number;
  redemptionsCount: number;
  isActive: boolean;
}

interface DashboardStats {
  totalUsers: number;
  activeUsers: number;
  totalKeepers: number;
  totalShops: number;
  activeShops: number;
  totalOffers: number;
  activeOffers: number;
  totalJourneys: number;
  totalCategories: number;
  pendingKeepers: number;
  pendingShops: number;
  pendingOffers: number;
  pendingModeration: number;
  totalPlatformSavings: number;
  totalRedemptions: number;
  newUsersLast30Days: number;
  newShopsLast30Days: number;
  newOffersLast30Days: number;
  journeysLast30Days: number;
  recentActivity: RecentActivity[];
  topShops: TopShop[];
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchStats = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/dashboard');
      setStats(response.data.data);
    } catch (err) {
      console.error('Failed to fetch stats', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'user_registered': return <Users size={16} />;
      case 'shop_created': return <Store size={16} />;
      case 'keeper_applied': return <ShieldCheck size={16} />;
      case 'journey_completed': return <Navigation size={16} />;
      default: return <Activity size={16} />;
    }
  };

  const getActivityColor = (type: string) => {
    switch (type) {
      case 'user_registered': return '#6366f1';
      case 'shop_created': return '#10b981';
      case 'keeper_applied': return '#f59e0b';
      case 'journey_completed': return '#ec4899';
      default: return '#8b5cf6';
    }
  };

  const timeAgo = (dateStr: string) => {
    const d = new Date(dateStr);
    const now = new Date();
    const diff = Math.floor((now.getTime() - d.getTime()) / 1000);
    if (diff < 60) return 'Just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
  };

  const statCards = [
    { label: 'Total Users', value: stats?.totalUsers || 0, icon: Users, color: '#6366f1', sub: `${stats?.activeUsers || 0} active` },
    { label: 'Shops', value: stats?.totalShops || 0, icon: Store, color: '#10b981', sub: `${stats?.activeShops || 0} active` },
    { label: 'Offers', value: stats?.totalOffers || 0, icon: Package, color: '#f59e0b', sub: `${stats?.activeOffers || 0} active` },
    { label: 'Keepers', value: stats?.totalKeepers || 0, icon: ShieldCheck, color: '#8b5cf6', sub: `${stats?.pendingKeepers || 0} pending` },
    { label: 'Journeys', value: stats?.totalJourneys || 0, icon: Navigation, color: '#ec4899', sub: `${stats?.journeysLast30Days || 0} this month` },
    { label: 'Categories', value: stats?.totalCategories || 0, icon: Layers, color: '#14b8a6', sub: 'Platform categories' },
  ];

  const pendingCards = [
    { label: 'Pending Keepers', value: stats?.pendingKeepers || 0, icon: ShieldCheck, color: '#f59e0b' },
    { label: 'Unverified Shops', value: stats?.pendingShops || 0, icon: Store, color: '#ef4444' },
    { label: 'Moderation Queue', value: stats?.pendingModeration || 0, icon: AlertCircle, color: '#e11d48' },
  ];

  const growthCards = [
    { label: 'New Users (30d)', value: stats?.newUsersLast30Days || 0, icon: ArrowUpRight, color: '#6366f1' },
    { label: 'New Shops (30d)', value: stats?.newShopsLast30Days || 0, icon: ArrowUpRight, color: '#10b981' },
    { label: 'New Offers (30d)', value: stats?.newOffersLast30Days || 0, icon: ArrowUpRight, color: '#f59e0b' },
    { label: 'Redemptions', value: stats?.totalRedemptions || 0, icon: CheckCircle2, color: '#8b5cf6' },
  ];

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Dashboard Overview</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))' }}>Complete system status at a glance.</p>
          </div>
          <button
            onClick={fetchStats}
            style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.625rem 1.25rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', fontWeight: 600, cursor: 'pointer' }}
          >
            <RefreshCw size={16} /> Refresh
          </button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '1.25rem', marginBottom: '2rem' }}>
          {statCards.map((stat, i) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.06 }}
              className="glass-card"
              style={{ padding: '1.25rem' }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{
                  width: '42px', height: '42px', borderRadius: '10px',
                  background: `${stat.color}18`, display: 'flex',
                  alignItems: 'center', justifyContent: 'center', color: stat.color
                }}>
                  <stat.icon size={20} />
                </div>
              </div>
              <div style={{ marginTop: '1rem' }}>
                <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>{stat.label}</p>
                <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginTop: '0.15rem' }}>
                  {loading ? '...' : stat.value.toLocaleString()}
                </h3>
                <p style={{ fontSize: '0.75rem', color: stat.color, fontWeight: 600, marginTop: '0.25rem' }}>{stat.sub}</p>
              </div>
            </motion.div>
          ))}
        </div>

        <div style={{ marginBottom: '2rem' }}>
          <h2 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <AlertCircle size={18} color="#f59e0b" /> Action Required
          </h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: '1rem' }}>
            {pendingCards.map((card, i) => (
              <motion.div
                key={card.label}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.4 + i * 0.05 }}
                className="glass-card"
                style={{
                  padding: '1.25rem',
                  borderLeft: `3px solid ${card.color}`,
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <card.icon size={20} color={card.color} />
                  <div>
                    <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>{card.label}</p>
                    <h4 style={{ fontSize: '1.25rem', fontWeight: 700 }}>{loading ? '...' : card.value}</h4>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(320px, 0.9fr) minmax(0, 1.55fr)', gap: '1.5rem', marginBottom: '2rem', alignItems: 'stretch' }}>
          <div className="glass-card" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <TrendingUp size={18} color="#10b981" /> Growth (Last 30 Days)
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1rem' }}>
              {growthCards.map((card) => (
                <div key={card.label} style={{ padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.5rem' }}>
                    <card.icon size={16} color={card.color} />
                    <span style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>{card.label}</span>
                  </div>
                  <h4 style={{ fontSize: '1.25rem', fontWeight: 700 }}>{loading ? '...' : card.value}</h4>
                </div>
              ))}
            </div>
          </div>

          <DashboardShopMap />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '1.5rem' }}>
          <div className="glass-card" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Clock size={18} /> Recent Activity
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              {!loading && stats?.recentActivity && stats.recentActivity.length > 0 ? (
                stats.recentActivity.map((activity, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.6 + i * 0.05 }}
                    style={{
                      display: 'flex', alignItems: 'center', gap: '0.75rem',
                      padding: '0.75rem', borderRadius: 'var(--radius)',
                      background: 'rgba(255,255,255,0.02)', border: '1px solid hsl(var(--border))'
                    }}
                  >
                    <div style={{
                      width: '32px', height: '32px', borderRadius: '8px',
                      background: `${getActivityColor(activity.type)}18`,
                      color: getActivityColor(activity.type),
                      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
                    }}>
                      {getActivityIcon(activity.type)}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <p style={{ fontSize: '0.875rem', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{activity.description}</p>
                      <p style={{ fontSize: '0.7rem', color: 'hsl(var(--muted-foreground))' }}>{timeAgo(activity.timestamp)}</p>
                    </div>
                  </motion.div>
                ))
              ) : (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'hsl(var(--muted-foreground))' }}>
                  {loading ? 'Loading...' : 'No recent activity found.'}
                </div>
              )}
            </div>
          </div>

          <div className="glass-card" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Store size={18} color="#10b981" /> Top Shops
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              {!loading && stats?.topShops && stats.topShops.length > 0 ? (
                stats.topShops.map((shop, i) => (
                  <div
                    key={shop.shopId}
                    style={{
                      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                      padding: '0.75rem', borderRadius: 'var(--radius)',
                      background: 'rgba(255,255,255,0.02)', border: '1px solid hsl(var(--border))'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      <span style={{
                        width: '24px', height: '24px', borderRadius: '50%',
                        background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: '0.7rem', fontWeight: 700
                      }}>
                        {i + 1}
                      </span>
                      <div>
                        <p style={{ fontSize: '0.875rem', fontWeight: 600 }}>{shop.name}</p>
                        <p style={{ fontSize: '0.7rem', color: 'hsl(var(--muted-foreground))' }}>{shop.category}</p>
                      </div>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#10b981' }}>{shop.offersCount} offers</span>
                      <span style={{
                        width: '8px', height: '8px', borderRadius: '50%',
                        background: shop.isActive ? '#10b981' : '#ef4444'
                      }} />
                    </div>
                  </div>
                ))
              ) : (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'hsl(var(--muted-foreground))' }}>
                  {loading ? 'Loading...' : 'No shop data available.'}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
