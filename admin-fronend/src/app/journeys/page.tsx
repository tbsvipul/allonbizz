'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { createPortal } from 'react-dom';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import {
  Navigation, Compass, CheckCircle, TrendingUp,
  Search, RefreshCw, Calendar, MapPin,
  Clock, ChevronLeft, ChevronRight, X, Tag, Store, Award,
  Eye, Heart, Trash2, BarChart3, Activity, XCircle, Filter
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { unwrapApiData, unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';
import CustomSelect from '@/components/CustomSelect';
import {
  ResponsiveContainer, AreaChart, Area, XAxis, YAxis,
  CartesianGrid, Tooltip, PieChart, Pie, Cell,
  BarChart, Bar, Legend
} from 'recharts';

/* ─── Types ─── */
interface JourneySummary {
  totalJourneys: number;
  activeJourneys: number;
  completedJourneys: number;
  totalDistanceKm: number;
  avgDistanceKm: number;
  avgDurationMinutes: number;
  totalOffersRedeemed: number;
  totalSavings: number;
}

interface TimeSeriesPoint { date: string; count: number; totalDistance: number; }
interface TypeDist { type: string; count: number; }
interface StatusDist { status: string; count: number; }
interface TopUser { userId: string; email: string; name: string; journeyCount: number; totalDistance: number; }

interface JourneyRow {
  journeyId: string;
  userId: string;
  userEmail: string;
  userName: string;
  type: string;
  status: string;
  startName: string | null;
  endName: string | null;
  distance: number;
  duration: number;
  offersRedeemed: number;
  totalSavings: number;
  startTime: string;
  endTime: string | null;
  startLat?: number;
  startLng?: number;
  endLat?: number;
  endLng?: number;
  likesCount?: number;
  viewsCount?: number;
  tags?: string[];
  shopsEncountered?: string[];
}

interface AnalyticsData {
  summary: JourneySummary;
  timeSeries: TimeSeriesPoint[];
  typeDistribution: TypeDist[];
  statusDistribution: StatusDist[];
  topUsers: TopUser[];
  recent: JourneyRow[];
}

/* ─── Colors ─── */
const CHART_COLORS = ['#7c3aed', '#a855f7', '#c084fc', '#e9d5ff', '#6366f1'];
const STATUS_COLORS: Record<string, string> = {
  active: '#10b981',
  completed: '#6366f1',
  abandoned: '#ef4444',
};

/* ─── Helpers ─── */
const fmt = (n: number = 0) => (n || 0) >= 1000 ? `${((n || 0) / 1000).toFixed(1)}k` : (n || 0).toString();
const fmtDist = (km: number = 0) => (km || 0) >= 100 ? `${(km || 0).toFixed(0)} km` : `${(km || 0).toFixed(1)} km`;
const fmtDur = (min: number = 0) => (min || 0) >= 60 ? `${((min || 0) / 60).toFixed(1)} hr` : `${(min || 0).toFixed(0)} min`;

const StatusBadge = ({ status }: { status: string }) => {
  const color = STATUS_COLORS[status] || '#94a3b8';
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: '0.35rem',
      padding: '0.25rem 0.75rem', borderRadius: '20px',
      fontSize: '0.75rem', fontWeight: 600,
      background: `${color}18`, color
    }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%', background: color }} />
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
};

/* ─── Custom Tooltip ─── */
const ChartTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div style={{
      background: 'hsl(var(--card))', border: '1px solid hsl(var(--border))',
      borderRadius: '8px', padding: '0.75rem 1rem', fontSize: '0.8rem',
      boxShadow: '0 4px 12px rgba(0,0,0,0.15)'
    }}>
      <p style={{ fontWeight: 600, marginBottom: '0.25rem' }}>{label}</p>
      {payload.map((p: any, i: number) => (
        <p key={i} style={{ color: p.color }}>{p.name}: {p.value}</p>
      ))}
    </div>
  );
};

/* ═════════════════════ PAGE ═════════════════════ */
export default function JourneysPage() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => { setMounted(true); }, []);

  const { hasPermission } = useAuth();
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [timeRange, setTimeRange] = useState('month');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [selectedJourney, setSelectedJourney] = useState<JourneyRow | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [tablePage, setTablePage] = useState(1);
  const [totalTablePages, setTotalTablePages] = useState(1);
  const [totalJourneys, setTotalJourneys] = useState(0);
  const [recentJourneys, setRecentJourneys] = useState<JourneyRow[]>([]);
  const [tableLoading, setTableLoading] = useState(false);
  const [analyticsError, setAnalyticsError] = useState<string | null>(null);
  const [tableError, setTableError] = useState<string | null>(null);
  const [shopNames, setShopNames] = useState<Record<string, string>>({});

  useEffect(() => {
    if (selectedJourney?.shopsEncountered?.length) {
      const fetchShopNames = async () => {
        const names: Record<string, string> = { ...shopNames };
        let updated = false;
        
        await Promise.all(selectedJourney.shopsEncountered!.map(async (id) => {
          if (!names[id] && id.length > 20) {
            try {
              const res = await api.get(`/admin/shops/${id}`);
              const shop = unwrapApiData<any>(res);
              if (shop?.name) {
                names[id] = shop.name;
                updated = true;
              }
            } catch {
              names[id] = 'Unknown Shop';
              updated = true;
            }
          } else if (!names[id] && id.length <= 20) {
            names[id] = id;
            updated = true;
          }
        }));

        if (updated) {
          setShopNames(names);
        }
      };
      fetchShopNames();
    }
  }, [selectedJourney]);

  const fetchAnalytics = useCallback(async () => {
    setLoading(true);
    setAnalyticsError(null);
    try {
      const res = await api.get('/admin/analytics/journeys', { params: { range: timeRange } });
      setAnalytics(unwrapApiData<AnalyticsData>(res));
    } catch (err) {
      console.error('Failed to fetch journey analytics', err);
      setAnalyticsError(getApiErrorMessage(err, 'Failed to fetch journey analytics.'));
    }
    finally { setLoading(false); }
  }, [timeRange]);

  const fetchTableData = useCallback(async () => {
    setTableLoading(true);
    setTableError(null);
    try {
      const res = await api.get('/admin/journeys', { 
        params: { 
          pageNumber: tablePage, 
          pageSize: 10,
          search,
          status: statusFilter || undefined
        } 
      });
      const { data, pagination } = unwrapPagedResponse<JourneyRow>(res);
      setRecentJourneys(data || []);
      setTotalTablePages(pagination?.totalPages || 1);
      setTotalJourneys(pagination?.totalCount || 0);
    } catch (err) {
      console.error('Failed to fetch journey table data', err);
      setTableError(getApiErrorMessage(err, 'Failed to fetch journey list.'));
      setRecentJourneys([]);
    }
    finally { setTableLoading(false); }
  }, [tablePage, search, statusFilter]);

  useEffect(() => { fetchAnalytics(); }, [fetchAnalytics]);
  useEffect(() => { fetchTableData(); }, [fetchTableData]);

  // Lock body scroll when modal is open
  useEffect(() => {
    const mainContent = document.getElementById('main-content');
    if (selectedJourney && mainContent) {
      mainContent.style.overflow = 'hidden';
    } else if (mainContent) {
      mainContent.style.overflow = 'auto';
    }
    return () => { if (mainContent) mainContent.style.overflow = 'auto'; };
  }, [selectedJourney]);

  const openDetail = async (j: JourneyRow) => {
    setDetailLoading(true);
    setSelectedJourney(j);
    try {
      const res = await api.get(`/admin/journeys/${j.journeyId}`);
      setSelectedJourney(unwrapApiData<JourneyRow>(res));
    } catch { /* fallback to list data */ }
    finally { setDetailLoading(false); }
  };

  const deleteJourney = async (id: string) => {
    if (!confirm('Delete this journey permanently?')) return;
    try {
      await api.delete(`/admin/journeys/${id}`);
      setSelectedJourney(null);
      fetchAnalytics();
      fetchTableData();
    } catch (err) { console.error('Delete failed', err); }
  };

  const summary = analytics?.summary;
  const displayedJourneys =
    recentJourneys.length > 0
      ? recentJourneys
      : !tableLoading && !search && !statusFilter && tablePage === 1
        ? analytics?.recent ?? []
        : [];

  /* ─── KPI Cards ─── */
  const kpis = [
    { label: 'Total Journeys', value: fmt(summary?.totalJourneys || 0), icon: Navigation, color: '#7c3aed', sub: `${fmtDist(summary?.totalDistanceKm || 0)} total` },
    { label: 'Active Now', value: fmt(summary?.activeJourneys || 0), icon: Compass, color: '#10b981', sub: 'In progress' },
    { label: 'Completed', value: fmt(summary?.completedJourneys || 0), icon: CheckCircle, color: '#6366f1', sub: `Avg ${fmtDist(summary?.avgDistanceKm || 0)}` },
    { label: 'Avg Duration', value: fmtDur(summary?.avgDurationMinutes || 0), icon: Clock, color: '#f59e0b', sub: `${summary?.totalOffersRedeemed || 0} offers redeemed` },
  ];

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        {/* ─── Header ─── */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem', flexWrap: 'wrap', gap: '1rem' }}>
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.35rem' }}>
              <span className="text-gradient">Journey Analytics</span>
            </h1>
            <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.9rem' }}>
              Real-time insights into user navigation activity and route patterns.
            </p>
          </div>
          <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
            <button onClick={() => { fetchAnalytics(); fetchTableData(); }}
              style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1.1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', fontWeight: 600, fontSize: '0.875rem' }}>
              <RefreshCw size={16} className={loading ? 'spin' : ''} /> Refresh
            </button>
            <CustomSelect 
              value={timeRange} 
              onChange={val => setTimeRange(val)}
              options={[
                { value: 'week', label: 'Past 7 Days', icon: <Calendar size={16} /> },
                { value: 'month', label: 'Past 30 Days', icon: <Calendar size={16} /> },
                { value: 'year', label: 'Past Year', icon: <Calendar size={16} /> },
              ]}
              style={{ minWidth: '160px' }}
            />
          </div>
        </div>

        {/* ─── KPI Cards ─── */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: '1.25rem', marginBottom: '1.75rem' }}>
          {kpis.map((kpi, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.08 }}
              className="glass-card" style={{ padding: '1.5rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                <div style={{ width: 42, height: 42, borderRadius: 12, background: `${kpi.color}12`, color: kpi.color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <kpi.icon size={22} />
                </div>
                <Activity size={14} color="hsl(var(--muted-foreground))" />
              </div>
              <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.8rem', marginBottom: '0.2rem' }}>{kpi.label}</p>
              <h3 style={{ fontSize: '1.6rem', fontWeight: 700 }}>{loading ? '…' : kpi.value}</h3>
              <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.75rem', marginTop: '0.35rem' }}>{kpi.sub}</p>
            </motion.div>
          ))}
        </div>

        {(analyticsError || tableError) && (
          <div style={{ marginBottom: '1.5rem', padding: '0.875rem 1rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444', fontSize: '0.875rem', fontWeight: 600 }}>
            {analyticsError || tableError}
          </div>
        )}

        {/* ─── Charts Row ─── */}
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.25rem', marginBottom: '1.75rem' }}>
          {/* Area Chart — Journeys Over Time */}
          <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }}
            className="glass-card" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontWeight: 700, marginBottom: '1.25rem', fontSize: '1rem' }}>
              <BarChart3 size={16} style={{ display: 'inline', marginRight: 8, verticalAlign: 'text-bottom' }} />
              Journeys Over Time
            </h3>
            <div style={{ width: '100%', height: 280 }}>
              {!loading && analytics?.timeSeries && (
                <ResponsiveContainer>
                  <AreaChart data={analytics.timeSeries} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
                    <defs>
                      <linearGradient id="areaGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#7c3aed" stopOpacity={0.3} />
                        <stop offset="95%" stopColor="#7c3aed" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                    <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={v => v.slice(5)} stroke="hsl(var(--muted-foreground))" />
                    <YAxis tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" allowDecimals={false} />
                    <Tooltip content={<ChartTooltip />} cursor={{ stroke: 'rgba(124, 58, 237, 0.2)', strokeWidth: 2 }} />
                    <Area type="monotone" dataKey="count" name="Journeys" stroke="#7c3aed" strokeWidth={2.5} fill="url(#areaGrad)" dot={false} activeDot={{ r: 5, fill: '#7c3aed' }} />
                  </AreaChart>
                </ResponsiveContainer>
              )}
              {loading && <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'hsl(var(--muted-foreground))' }}>Loading chart…</div>}
            </div>
          </motion.div>

          {/* Donut — Type Distribution */}
          <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }}
            className="glass-card" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontWeight: 700, marginBottom: '1.25rem', fontSize: '1rem' }}>Journey Types</h3>
            <div style={{ width: '100%', height: 220 }}>
              {!loading && analytics?.typeDistribution && analytics.typeDistribution.length > 0 ? (
                <ResponsiveContainer>
                  <PieChart>
                    <Pie data={analytics.typeDistribution} dataKey="count" nameKey="type" cx="50%" cy="50%"
                      innerRadius={55} outerRadius={85} paddingAngle={4} strokeWidth={0}>
                      {analytics.typeDistribution.map((_, i) => (
                        <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip content={<ChartTooltip />} />
                    <Legend iconType="circle" wrapperStyle={{ fontSize: '0.8rem' }} />
                  </PieChart>
                </ResponsiveContainer>
              ) : loading ? (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'hsl(var(--muted-foreground))' }}>Loading…</div>
              ) : (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'hsl(var(--muted-foreground))' }}>No type data</div>
              )}
            </div>
            {/* Status breakdown below donut */}
            {!loading && analytics?.statusDistribution && (
              <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'center', marginTop: '0.75rem', flexWrap: 'wrap' }}>
                {analytics.statusDistribution.map((s, i) => (
                  <div key={i} style={{ textAlign: 'center' }}>
                    <StatusBadge status={s.status} />
                    <p style={{ fontSize: '0.8rem', fontWeight: 700, marginTop: '0.25rem' }}>{s.count}</p>
                  </div>
                ))}
              </div>
            )}
          </motion.div>
        </div>

        {/* ─── Secondary Row: Top Users + Stats ─── */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem', marginBottom: '1.75rem' }}>
          {/* Bar Chart — Top Users */}
          <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.5 }}
            className="glass-card" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontWeight: 700, marginBottom: '1.25rem', fontSize: '1rem' }}>Top Explorers</h3>
            <div style={{ width: '100%', height: 260 }}>
              {!loading && analytics?.topUsers && analytics.topUsers.length > 0 ? (
                <ResponsiveContainer>
                  <BarChart data={analytics.topUsers} margin={{ top: 5, right: 10, left: -20, bottom: 0 }} barSize={32}>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                    <XAxis dataKey="name" tick={{ fontSize: 10 }} stroke="hsl(var(--muted-foreground))" />
                    <YAxis tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" allowDecimals={false} />
                    <Tooltip content={<ChartTooltip />} cursor={{ fill: 'rgba(124, 58, 237, 0.1)' }} />
                    <Bar dataKey="journeyCount" name="Journeys" fill="#7c3aed" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              ) : loading ? (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'hsl(var(--muted-foreground))' }}>Loading…</div>
              ) : (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'hsl(var(--muted-foreground))' }}>No user data</div>
              )}
            </div>
          </motion.div>

          {/* Stats Panel */}
          <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.55 }}
            className="glass-card" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            <h3 style={{ fontWeight: 700, fontSize: '1rem' }}>Performance Metrics</h3>
            {[
              { icon: TrendingUp, label: 'Total Distance', value: fmtDist(summary?.totalDistanceKm || 0), color: '#7c3aed' },
              { icon: Award, label: 'Offers Redeemed', value: fmt(summary?.totalOffersRedeemed || 0), color: '#f59e0b' },
              { icon: Clock, label: 'Avg Duration', value: fmtDur(summary?.avgDurationMinutes || 0), color: '#ec4899' },
              { icon: MapPin, label: 'Avg Distance', value: fmtDist(summary?.avgDistanceKm || 0), color: '#6366f1' },
            ].map((m, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '1rem', padding: '0.75rem', background: 'hsl(var(--secondary))', borderRadius: 'var(--radius)' }}>
                <div style={{ width: 38, height: 38, borderRadius: 10, background: `${m.color}12`, color: m.color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <m.icon size={18} />
                </div>
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>{m.label}</p>
                  <p style={{ fontWeight: 700, fontSize: '1.1rem' }}>{loading ? '…' : m.value}</p>
                </div>
              </div>
            ))}
          </motion.div>
        </div>

        {/* ─── Journey Table ─── */}
        <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.6 }}
          className="glass-card" style={{ padding: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', flexWrap: 'wrap', gap: '0.75rem' }}>
            <h3 style={{ fontWeight: 700, fontSize: '1rem' }}>Recent Journeys</h3>
            <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
              <div style={{ position: 'relative', width: '260px' }}>
                <Search size={15} style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
                <input placeholder="Search user, route…" value={search} onChange={e => { setSearch(e.target.value); setTablePage(1); }}
                  style={{ width: '100%', padding: '0.5rem 1rem 0.5rem 2.25rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none', fontSize: '0.85rem' }} />
              </div>
              <CustomSelect 
                value={statusFilter} 
                onChange={val => { setStatusFilter(val); setTablePage(1); }}
                options={[
                  { value: '', label: 'All Status', icon: <Filter size={16} /> },
                  { value: 'active', label: 'Active', icon: <Compass size={16} />, color: '#10b981' },
                  { value: 'completed', label: 'Completed', icon: <CheckCircle size={16} />, color: '#6366f1' },
                  { value: 'abandoned', label: 'Abandoned', icon: <XCircle size={16} />, color: '#ef4444' },
                ]}
                style={{ minWidth: '150px' }}
              />
            </div>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 0.4rem' }}>
              <thead>
                <tr style={{ textAlign: 'left', color: 'hsl(var(--muted-foreground))', fontSize: '0.8rem' }}>
                  <th style={{ padding: '0.75rem 1rem' }}>Route</th>
                  <th style={{ padding: '0.75rem 1rem' }}>User</th>
                  <th style={{ padding: '0.75rem 1rem' }}>Type</th>
                  <th style={{ padding: '0.75rem 1rem' }}>Status</th>
                  <th style={{ padding: '0.75rem 1rem' }}>Distance</th>
                  <th style={{ padding: '0.75rem 1rem' }}>Duration</th>
                  <th style={{ padding: '0.75rem 1rem' }}>Date</th>
                  <th style={{ padding: '0.75rem 1rem', textAlign: 'right' }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {displayedJourneys.length > 0 ? displayedJourneys.map(j => (
                  <tr key={j.journeyId} style={{ background: 'rgba(255,255,255,0.02)', transition: '0.2s', cursor: 'pointer' }}
                    className="hover-highlight" onClick={() => openDetail(j)}>
                    <td style={{ padding: '0.75rem 1rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                        <div style={{ padding: '0.4rem', background: 'rgba(124, 58, 237, 0.1)', borderRadius: '8px', color: '#7c3aed' }}>
                          <Navigation size={16} />
                        </div>
                        <div>
                          <p style={{ fontWeight: 600, fontSize: '0.875rem' }}>{j.startName || 'Unknown Start'}</p>
                          {j.endName && <p style={{ fontSize: '0.7rem', color: 'hsl(var(--muted-foreground))' }}>→ {j.endName}</p>}
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.85rem' }}>{j.userName || j.userEmail}</td>
                    <td style={{ padding: '0.75rem 1rem' }}>
                      <span style={{ fontSize: '0.75rem', fontWeight: 600, color: j.type === 'freeRoam' ? '#a855f7' : '#6366f1' }}>
                        {j.type === 'freeRoam' ? 'Free Roam' : 'Destination'}
                      </span>
                    </td>
                    <td style={{ padding: '0.75rem 1rem' }}><StatusBadge status={j.status} /></td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.85rem', fontWeight: 500 }}>{fmtDist(j.distance)}</td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.85rem' }}>{fmtDur(j.duration / 60)}</td>
                    <td style={{ padding: '0.75rem 1rem', fontSize: '0.8rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                        <Calendar size={13} color="hsl(var(--muted-foreground))" />
                        {new Date(j.startTime).toLocaleDateString()}
                      </div>
                    </td>
                    <td style={{ padding: '0.75rem 1rem', textAlign: 'right' }}>
                      <button onClick={e => { e.stopPropagation(); openDetail(j); }}
                        style={{ padding: '0.35rem', borderRadius: '4px', border: '1px solid hsl(var(--border))', background: 'none' }}>
                        <ChevronRight size={15} />
                      </button>
                    </td>
                  </tr>
                )) : (
                  <tr>
                    <td colSpan={8} style={{ padding: '3rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>
                      {tableLoading ? 'Loading journey data...' : 'No journeys match your filters.'}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          {/* Pagination */}
          {!tableLoading && displayedJourneys.length > 0 && (
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '1.5rem', padding: '0 1rem' }}>
              <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))' }}>
                Showing {displayedJourneys.length} of {totalJourneys || summary?.totalJourneys || displayedJourneys.length} journeys
              </p>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button 
                  onClick={() => setTablePage(p => Math.max(1, p - 1))}
                  disabled={tablePage === 1}
                  style={{ background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', padding: '0.5rem', borderRadius: 'var(--radius)', opacity: tablePage === 1 ? 0.5 : 1 }}
                >
                  <ChevronLeft size={18} />
                </button>
                <div style={{ display: 'flex', alignItems: 'center', padding: '0 1rem', fontSize: '0.875rem', fontWeight: 600 }}>
                  Page {tablePage} of {totalTablePages}
                </div>
                <button 
                  onClick={() => setTablePage(p => Math.min(totalTablePages, p + 1))}
                  disabled={tablePage === totalTablePages}
                  style={{ background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', padding: '0.5rem', borderRadius: 'var(--radius)', opacity: tablePage === totalTablePages ? 0.5 : 1 }}
                >
                  <ChevronRight size={18} />
                </button>
              </div>
            </div>
          )}
        </motion.div>

        {/* ─── Detail Drawer (Right Side) ─── */}
        {mounted && createPortal(
          <AnimatePresence>
            {selectedJourney && (
              <>
                {/* Backdrop */}
                <motion.div 
                  initial={{ opacity: 0 }} 
                  animate={{ opacity: 1 }} 
                  exit={{ opacity: 0 }}
                  onClick={() => setSelectedJourney(null)}
                  style={{ 
                    position: 'fixed', 
                    inset: 0, 
                    background: 'rgba(0, 0, 0, 0.5)', 
                    backdropFilter: 'blur(4px)', 
                    zIndex: 99998 
                  }} 
                />
                
                {/* Right Side Panel */}
                <motion.div 
                  initial={{ x: '100%' }}
                  animate={{ x: 0 }}
                  exit={{ x: '100%' }}
                  transition={{ type: 'spring', damping: 25, stiffness: 200 }}
                  style={{
                    position: 'fixed',
                    top: 0,
                    right: 0,
                    width: '100%',
                    maxWidth: '460px',
                    height: '100vh',
                    zIndex: 99999,
                    background: 'hsl(var(--background))',
                    borderLeft: '1px solid hsl(var(--border))',
                    boxShadow: '-10px 0 50px -12px rgba(0, 0, 0, 0.5)',
                    overflowY: 'auto',
                    display: 'flex',
                    flexDirection: 'column'
                  }}
                >
                  {/* Header */}
                  <div style={{ 
                    padding: '1.5rem 2rem', 
                    borderBottom: '1px solid hsl(var(--border))',
                    display: 'flex', 
                    justifyContent: 'space-between', 
                    alignItems: 'center',
                    background: 'hsl(var(--background))',
                    position: 'sticky',
                    top: 0,
                    zIndex: 10
                  }}>
                    <div>
                      <h2 style={{ fontWeight: 800, fontSize: '1.25rem', marginBottom: '0.25rem' }}>Journey Details</h2>
                      <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>ID: {selectedJourney.journeyId.substring(0, 8)}...</p>
                    </div>
                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      {hasPermission(PERMISSIONS.journeysDelete) && (
                        <button onClick={() => deleteJourney(selectedJourney.journeyId)}
                          title="Delete Journey"
                          style={{ padding: '0.5rem', borderRadius: '8px', border: '1px solid hsl(var(--destructive))', background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', transition: '0.2s', cursor: 'pointer' }}
                        >
                          <Trash2 size={16} />
                        </button>
                      )}
                      <button onClick={() => setSelectedJourney(null)}
                        title="Close"
                        style={{ padding: '0.5rem', borderRadius: '8px', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', transition: '0.2s', cursor: 'pointer', color: 'hsl(var(--foreground))' }}
                      >
                        <X size={16} />
                      </button>
                    </div>
                  </div>

                  {detailLoading ? (
                    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '1rem' }}>
                      <RefreshCw size={28} className="spin" color="#7c3aed" />
                      <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.9rem' }}>Loading journey data...</p>
                    </div>
                  ) : (
                    <div className="animate-fade-in" style={{ padding: '2rem', display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                      
                      {/* User Profile Summary */}
                      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                        <div style={{ width: 56, height: 56, borderRadius: '16px', background: 'linear-gradient(135deg, #7c3aed, #c084fc)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, fontSize: '1.5rem', boxShadow: '0 4px 12px rgba(124, 58, 237, 0.3)' }}>
                          {selectedJourney.userName?.charAt(0) || 'U'}
                        </div>
                        <div>
                          <h3 style={{ fontWeight: 700, fontSize: '1.1rem', color: 'hsl(var(--foreground))' }}>{selectedJourney.userName || 'Unknown User'}</h3>
                          <p style={{ fontSize: '0.85rem', color: 'hsl(var(--muted-foreground))' }}>{selectedJourney.userEmail || 'No email provided'}</p>
                        </div>
                      </div>

                      {/* Status & Type */}
                      <div style={{ display: 'flex', gap: '0.75rem' }}>
                        <StatusBadge status={selectedJourney.status} />
                        <span style={{ padding: '0.35rem 1rem', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 700, background: 'rgba(124, 58, 237, 0.1)', color: '#a855f7', border: '1px solid rgba(124, 58, 237, 0.2)' }}>
                          {selectedJourney.type === 'freeRoam' ? 'Free Roam' : 'Destination Nav'}
                        </span>
                      </div>

                      {/* Route Info */}
                      <div className="glass-card" style={{ padding: '1.5rem', borderRadius: '16px', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))' }}>
                        <h4 style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'hsl(var(--muted-foreground))', marginBottom: '1rem', letterSpacing: '0.05em' }}>Route Information</h4>
                        <div style={{ display: 'flex', alignItems: 'flex-start', gap: '1rem' }}>
                          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginTop: '0.25rem' }}>
                            <div style={{ width: 12, height: 12, borderRadius: '50%', border: '3px solid #7c3aed', background: 'transparent' }} />
                            <div style={{ width: 2, height: 30, background: 'linear-gradient(to bottom, #7c3aed, #10b981)', margin: '4px 0' }} />
                            <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#10b981', border: '3px solid rgba(16, 185, 129, 0.3)', backgroundClip: 'padding-box' }} />
                          </div>
                          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Origin</p>
                              <p style={{ fontWeight: 600, fontSize: '0.95rem', color: 'hsl(var(--foreground))' }}>{selectedJourney.startName || 'Unknown Origin'}</p>
                            </div>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Destination</p>
                              <p style={{ fontWeight: 600, fontSize: '0.95rem', color: 'hsl(var(--foreground))' }}>{selectedJourney.endName || 'No specific destination'}</p>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Quick Stats Grid */}
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem' }}>
                        {[
                          { label: 'Total Distance', value: fmtDist(selectedJourney.distance), icon: MapPin, color: '#6366f1', bg: 'rgba(99, 102, 241, 0.1)' },
                          { label: 'Duration', value: fmtDur(selectedJourney.duration / 60), icon: Clock, color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.1)' },
                          { label: 'Offers Redeemed', value: selectedJourney.offersRedeemed?.toString() || '0', icon: Award, color: '#10b981', bg: 'rgba(16, 185, 129, 0.1)' },
                          { label: 'Total Savings', value: `$${selectedJourney.totalSavings?.toFixed(2) || '0.00'}`, icon: Tag, color: '#ec4899', bg: 'rgba(236, 72, 153, 0.1)' },
                        ].map((stat, i) => (
                          <div key={i} style={{ padding: '1.25rem', borderRadius: '16px', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <div style={{ width: 32, height: 32, borderRadius: '8px', background: stat.bg, color: stat.color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                              <stat.icon size={16} />
                            </div>
                            <div>
                              <p style={{ fontWeight: 800, fontSize: '1.1rem', color: 'hsl(var(--foreground))' }}>{stat.value}</p>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>{stat.label}</p>
                            </div>
                          </div>
                        ))}
                      </div>

                      {/* Shops */}
                      {selectedJourney.shopsEncountered && selectedJourney.shopsEncountered.length > 0 && (
                        <div>
                          <h4 style={{ fontSize: '0.85rem', fontWeight: 600, color: 'hsl(var(--foreground))', marginBottom: '0.75rem' }}>Shops Encountered</h4>
                          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                            {selectedJourney.shopsEncountered.map((s, i) => (
                              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem 0.8rem', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', borderRadius: '12px', fontSize: '0.8rem', fontWeight: 500, color: 'hsl(var(--foreground))' }}>
                                <Store size={14} color="#a855f7" /> {shopNames[s] || 'Loading...'}
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Timeline */}
                      <div style={{ marginTop: 'auto', paddingTop: '1.5rem', borderTop: '1px dashed hsl(var(--border))', display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                          <span>Session Start</span>
                          <span style={{ fontWeight: 600, color: 'hsl(var(--foreground))' }}>{new Date(selectedJourney.startTime).toLocaleString()}</span>
                        </div>
                        {selectedJourney.endTime && (
                          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                            <span>Session End</span>
                            <span style={{ fontWeight: 600, color: 'hsl(var(--foreground))' }}>{new Date(selectedJourney.endTime).toLocaleString()}</span>
                          </div>
                        )}
                      </div>
                    </div>
                  )}
                </motion.div>
              </>
            )}
          </AnimatePresence>,
          document.body
        )}
      </div>

      {/* Spin animation for refresh icon */}
      <style jsx global>{`
        @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
        .spin { animation: spin 1s linear infinite; }
        .hover-highlight:hover { background: rgba(124, 58, 237, 0.04) !important; }
      `}</style>
    </DashboardLayout>
  );
}
