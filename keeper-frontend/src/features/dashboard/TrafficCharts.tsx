'use client';

import React from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts';
import { KeeperTraffic, ShopSummary } from '@/lib/types';
import { Users, TrendingUp } from 'lucide-react';

interface TrafficChartsProps {
  traffic: KeeperTraffic | null;
  shops: ShopSummary[];
  loading: boolean;
}

const COLORS = ['#2563eb', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

interface CustomTooltipProps {
  active?: boolean;
  payload?: Array<{ value: number }>;
  label?: string;
}

function CustomTrafficTooltip({ active, payload, label }: CustomTooltipProps) {
  if (!active || !payload?.length) return null;
  return (
    <div style={{
      background: 'rgba(15, 23, 42, 0.92)',
      border: '1px solid rgba(99,102,241,0.25)',
      borderRadius: 10,
      padding: '0.6rem 1rem',
      fontSize: '0.8rem',
      color: '#e2e8f0',
      boxShadow: '0 8px 20px rgba(0,0,0,0.3)',
    }}>
      <p style={{ fontWeight: 700, marginBottom: 3 }}>{label}</p>
      <p style={{ color: '#60a5fa' }}><strong>{payload[0].value}</strong> visitors detected</p>
    </div>
  );
}

export function TrafficCharts({ traffic, shops, loading }: TrafficChartsProps) {
  const trafficData =
    traffic?.predictedTraffic?.map((item) => ({
      time: `${String(item.hour).padStart(2, '0')}:00`,
      visitors: item.predictedCount,
    })) || [];

  const shopDistribution = shops.map((shop) => ({
    name: shop.name,
    value: 1,
  }));

  const currentViewers = traffic?.currentViewersNearShop ?? 0;

  if (loading) {
    return (
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', width: '100%' }}>
        {[0, 1].map(i => (
          <div
            key={i}
            className="glass-card"
            style={{
              padding: '2rem',
              background: 'var(--surface)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius-xl)',
              height: '340px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <div style={{ textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>
              <div style={{
                width: 40, height: 40, borderRadius: '50%',
                border: '3px solid rgba(99,102,241,0.3)',
                borderTopColor: '#6366f1',
                animation: 'spin 0.8s linear infinite',
                margin: '0 auto 1rem',
              }} />
              Loading charts...
            </div>
          </div>
        ))}
        <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      </div>
    );
  }

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', width: '100%' }}>

      {/* === Traffic Bar Chart === */}
      <div
        className="glass-card"
        style={{
          padding: '1.75rem 2rem',
          background: 'var(--surface)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius-xl)',
        }}
      >
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.25rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
              <TrendingUp size={18} color="#2563eb" />
              <h3 style={{ fontSize: '1rem', fontWeight: 700, color: 'hsl(var(--foreground))', margin: 0 }}>
                Traffic Outlook
              </h3>
            </div>
            <p style={{ fontSize: '0.72rem', color: 'hsl(var(--muted-foreground))', margin: 0, fontWeight: 500 }}>
              Real visitor data · past 14 days by hour
            </p>
          </div>

          {/* Live Nearby Count Badge */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.45rem',
            padding: '0.4rem 0.85rem',
            borderRadius: '999px',
            background: currentViewers > 0 ? 'rgba(16,185,129,0.1)' : 'rgba(148,163,184,0.1)',
            border: `1px solid ${currentViewers > 0 ? 'rgba(16,185,129,0.25)' : 'rgba(148,163,184,0.2)'}`,
            color: currentViewers > 0 ? '#10b981' : 'hsl(var(--muted-foreground))',
          }}>
            {currentViewers > 0 && (
              <span style={{ position: 'relative', display: 'flex', height: '7px', width: '7px' }}>
                <span style={{
                  position: 'absolute',
                  display: 'inline-flex',
                  height: '100%',
                  width: '100%',
                  borderRadius: '50%',
                  backgroundColor: '#10b981',
                  opacity: 0.75,
                  animation: 'tc-ping 1.6s cubic-bezier(0,0,0.2,1) infinite',
                }} />
                <span style={{ position: 'relative', display: 'inline-flex', borderRadius: '50%', height: '7px', width: '7px', backgroundColor: '#10b981' }} />
              </span>
            )}
            <Users size={12} />
            <span style={{ fontSize: '0.73rem', fontWeight: 700 }}>
              {currentViewers} nearby now
            </span>
          </div>
        </div>

        {trafficData.length > 0 ? (
          <div style={{ width: '100%', height: '260px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={trafficData} barCategoryGap="30%">
                <defs>
                  <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#2563eb" stopOpacity={1} />
                    <stop offset="100%" stopColor="#2563eb" stopOpacity={0.5} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(148,163,184,0.08)" />
                <XAxis
                  dataKey="time"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fontSize: 11, fill: '#64748b' }}
                  interval="preserveStartEnd"
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fontSize: 11, fill: '#64748b' }}
                  allowDecimals={false}
                  width={28}
                />
                <RechartsTooltip content={<CustomTrafficTooltip />} cursor={{ fill: 'rgba(37,99,235,0.05)' }} />
                <Bar dataKey="visitors" fill="url(#barGradient)" radius={[5, 5, 0, 0]} maxBarSize={32} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        ) : (
          <div style={{
            height: '260px',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '0.75rem',
            color: 'hsl(var(--muted-foreground))',
          }}>
            <TrendingUp size={36} style={{ opacity: 0.25 }} />
            <p style={{ fontSize: '0.85rem', textAlign: 'center', maxWidth: '240px', margin: 0 }}>
              No historical journey data yet. Data populates as users travel near your shop.
            </p>
          </div>
        )}

        <style>{`@keyframes tc-ping { 0% { transform: scale(1); opacity: 0.75; } 100% { transform: scale(2.2); opacity: 0; } }`}</style>
      </div>

      {/* === Shop Distribution Pie === */}
      <div
        className="glass-card"
        style={{
          padding: '1.75rem 2rem',
          background: 'var(--surface)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius-xl)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
          <div style={{ width: 14, height: 14, borderRadius: '50%', background: 'linear-gradient(135deg, #2563eb, #8b5cf6)' }} />
          <h3 style={{ fontSize: '1rem', fontWeight: 700, color: 'hsl(var(--foreground))', margin: 0 }}>
            Shop Network
          </h3>
        </div>
        <p style={{ fontSize: '0.72rem', color: 'hsl(var(--muted-foreground))', marginBottom: '1.25rem', marginTop: '0.1rem', fontWeight: 500 }}>
          Distribution across your active locations
        </p>

        {shopDistribution.length > 0 ? (
          <div style={{ width: '100%', height: '260px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <defs>
                  {COLORS.map((color, i) => (
                    <radialGradient key={i} id={`pieGrad-${i}`} cx="50%" cy="50%" r="50%">
                      <stop offset="0%" stopColor={color} stopOpacity={0.9} />
                      <stop offset="100%" stopColor={color} stopOpacity={0.6} />
                    </radialGradient>
                  ))}
                </defs>
                <Pie
                  data={shopDistribution}
                  cx="50%"
                  cy="48%"
                  innerRadius={68}
                  outerRadius={95}
                  paddingAngle={4}
                  dataKey="value"
                  stroke="none"
                >
                  {shopDistribution.map((_, index) => (
                    <Cell key={`cell-${index}`} fill={`url(#pieGrad-${index % COLORS.length})`} />
                  ))}
                </Pie>
                <Legend
                  iconType="circle"
                  iconSize={8}
                  formatter={(value) => (
                    <span style={{ fontSize: '0.75rem', color: 'hsl(var(--foreground))', fontWeight: 600 }}>{value}</span>
                  )}
                />
                <RechartsTooltip
                  contentStyle={{
                    background: 'rgba(15,23,42,0.92)',
                    border: '1px solid rgba(99,102,241,0.25)',
                    borderRadius: 10,
                    fontSize: '0.8rem',
                    color: '#e2e8f0',
                    boxShadow: '0 8px 20px rgba(0,0,0,0.3)',
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        ) : (
          <div style={{
            height: '260px',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '0.75rem',
            color: 'hsl(var(--muted-foreground))',
          }}>
            <div style={{ fontSize: '2rem', opacity: 0.2 }}>🏪</div>
            <p style={{ fontSize: '0.85rem', textAlign: 'center', maxWidth: '220px', margin: 0 }}>
              No shops available to display.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
