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
} from 'recharts';
import { KeeperTraffic, ShopSummary } from '@/lib/types';

interface TrafficChartsProps {
  traffic: KeeperTraffic | null;
  shops: ShopSummary[];
  loading: boolean;
}

const COLORS = ['#2563eb', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

export function TrafficCharts({ traffic, shops, loading }: TrafficChartsProps) {
  const trafficData =
    traffic?.predictedTraffic?.map((item) => ({
      time: `${String(item.hour).padStart(2, '0')}:00`,
      traffic: item.predictedCount,
    })) || [];

  const shopDistribution = shops.map((shop) => ({
    name: shop.name,
    value: 1, // Represents one shop, you could map this to redemptions if needed
  }));

  if (loading) {
    return (
      <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>
        Loading charts...
      </div>
    );
  }

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', width: '100%' }}>
      {/* Bar Chart for Traffic */}
      <div className="glass-card" style={{ padding: '2rem', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
        <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '1.5rem', color: 'hsl(var(--foreground))' }}>
          Traffic Outlook
        </h3>
        {trafficData.length > 0 ? (
          <div style={{ width: '100%', height: '300px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={trafficData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(0,0,0,0.05)" />
                <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#64748b' }} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#64748b' }} />
                <RechartsTooltip
                  cursor={{ fill: 'rgba(37, 99, 235, 0.05)' }}
                  contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' }}
                />
                <Bar dataKey="traffic" fill="#2563eb" radius={[4, 4, 0, 0]} maxBarSize={40} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        ) : (
          <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'hsl(var(--muted-foreground))' }}>
            No traffic data available. Select a shop with map coordinates.
          </div>
        )}
      </div>

      {/* Doughnut Chart for Shop Distribution */}
      <div className="glass-card" style={{ padding: '2rem', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
        <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '1.5rem', color: 'hsl(var(--foreground))' }}>
          Shop Network Distribution
        </h3>
        {shopDistribution.length > 0 ? (
          <div style={{ width: '100%', height: '300px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={shopDistribution}
                  cx="50%"
                  cy="50%"
                  innerRadius={80}
                  outerRadius={110}
                  paddingAngle={5}
                  dataKey="value"
                  stroke="none"
                >
                  {shopDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <RechartsTooltip
                  contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        ) : (
          <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'hsl(var(--muted-foreground))' }}>
            No shops available to display network distribution.
          </div>
        )}
      </div>
    </div>
  );
}
