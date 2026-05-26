'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import { KeeperShopMap } from '@/components/KeeperShopMap';
import { TrafficCharts } from '@/features/dashboard/TrafficCharts';
import api from '@/lib/api';
import { KeeperDashboard, KeeperTraffic, ShopSummary } from '@/lib/types';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { useAuth } from '@/context/AuthContext';
import { Tag, Store, Star, Power } from 'lucide-react';

export default function DashboardPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [trafficLoading, setTrafficLoading] = useState(false);
  const [mainError, setMainError] = useState('');
  const [dashboard, setDashboard] = useState<KeeperDashboard | null>(null);
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [traffic, setTraffic] = useState<KeeperTraffic | null>(null);
  const [selectedShopId, setSelectedShopId] = useState('');

  useEffect(() => {
    let active = true;

    async function load() {
      setLoading(true);
      setMainError('');

      try {
        const [dashboardResponse, shopsResponse] = await Promise.allSettled([
          api.get('/keeper/dashboard'),
          api.get('/keeper/shops'),
        ]);

        if (!active) return;

        const nextErrors: string[] = [];

        if (dashboardResponse.status === 'fulfilled') {
          setDashboard(unwrapApiData<KeeperDashboard>(dashboardResponse.value));
        } else {
          setDashboard(null);
          nextErrors.push(getApiErrorMessage(dashboardResponse.reason, 'Unable to load dashboard totals.'));
        }

        let firstShopId = '';
        let firstShopHasCoords = false;

        if (shopsResponse.status === 'fulfilled') {
          const nextShops = unwrapApiData<ShopSummary[]>(shopsResponse.value);
          setShops(nextShops);
          
          const targetShop = nextShops[0];
          if (targetShop) {
            firstShopId = targetShop.id;
            firstShopHasCoords = targetShop.latitude != null && targetShop.longitude != null;
            setSelectedShopId(firstShopId);
          }
        } else {
          setShops([]);
          nextErrors.push(getApiErrorMessage(shopsResponse.reason, 'Unable to load keeper shops.'));
        }

        setMainError(nextErrors.join(' '));

        if (firstShopId && firstShopHasCoords) {
           setTrafficLoading(true);
           try {
             const trafficRes = await api.get('/keeper/traffic', { params: { shopId: firstShopId } });
             if (active) {
               setTraffic(unwrapApiData<KeeperTraffic>(trafficRes));
             }
           } catch {
             if (active) setTraffic(null);
           } finally {
             if (active) setTrafficLoading(false);
           }
        }

      } catch (err) {
        if (active) setMainError(getApiErrorMessage(err, 'Unable to load the keeper dashboard.'));
      } finally {
        if (active) setLoading(false);
      }
    }

    void load();

    return () => { active = false; };
  }, []);

  const selectedShopHasCoordinates = useMemo(() => {
    const shop = shops.find(s => s.id === selectedShopId);
    return Boolean(shop && shop.latitude != null && shop.longitude != null);
  }, [shops, selectedShopId]);

  useEffect(() => {
    if (loading) return;
    let active = true;

    async function loadTraffic() {
      if (!selectedShopId || !selectedShopHasCoordinates) {
        setTraffic(null);
        setTrafficLoading(false);
        return;
      }

      setTrafficLoading(true);
      try {
        const response = await api.get('/keeper/traffic', { params: { shopId: selectedShopId } });
        if (active) setTraffic(unwrapApiData<KeeperTraffic>(response));
      } catch {
        if (active) setTraffic(null);
      } finally {
        if (active) setTrafficLoading(false);
      }
    }

    void loadTraffic();

    return () => { active = false; };
  }, [selectedShopHasCoordinates, selectedShopId, loading]);

  const handleToggleOpen = async () => {
    if (!selectedShopId) return;
    try {
      const response = await api.post(`/keeper/shop/${selectedShopId}/toggle-open`);
      const data = unwrapApiData<{ isOpen: boolean }>(response);
      setShops(prev => prev.map(s => s.id === selectedShopId ? { ...s, isOpen: data.isOpen } : s));
    } catch (err) {
      alert(getApiErrorMessage(err, 'Unable to toggle shop status.'));
    }
  };

  return (
    <div className="field-stack" style={{ gap: '2rem' }}>
      <PageHeader
        title="Dashboard"
        description="A comprehensive view of your active offers, shops, and nearby traffic."
        actions={
          user?.canManage && shops.length === 0 ? (
            <Link href="/shops/new" className="button">
              Create first shop
            </Link>
          ) : shops.length > 0 ? (
            <div style={{ display: 'flex', gap: '1rem', alignItems: 'flex-end' }}>
              <div className="field" style={{ minWidth: '220px', margin: 0 }}>
                <label htmlFor="dashboardShop">Select shop for traffic</label>
                <select id="dashboardShop" value={selectedShopId} onChange={(e) => setSelectedShopId(e.target.value)} disabled={loading}>
                  {shops.map((shop) => (
                    <option key={shop.id} value={shop.id}>{shop.name}</option>
                  ))}
                </select>
              </div>
              <button 
                onClick={handleToggleOpen} 
                style={{ 
                  padding: '0.625rem 1.25rem', 
                  whiteSpace: 'nowrap', 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '0.5rem', 
                  marginBottom: '2px',
                  borderRadius: 'var(--radius)',
                  fontWeight: 600,
                  fontSize: '0.875rem',
                  cursor: loading ? 'not-allowed' : 'pointer',
                  opacity: loading ? 0.7 : 1,
                  transition: 'all 0.2s ease',
                  border: '1px solid transparent',
                  background: shops.find(s => s.id === selectedShopId)?.isOpen 
                    ? 'linear-gradient(135deg, rgba(239, 68, 68, 0.1) 0%, rgba(220, 38, 38, 0.1) 100%)' 
                    : 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                  color: shops.find(s => s.id === selectedShopId)?.isOpen ? '#ef4444' : '#fff',
                  borderColor: shops.find(s => s.id === selectedShopId)?.isOpen ? 'rgba(239, 68, 68, 0.2)' : 'transparent',
                  boxShadow: shops.find(s => s.id === selectedShopId)?.isOpen ? 'none' : '0 4px 14px rgba(16, 185, 129, 0.25)',
                }}
                disabled={loading}
              >
                {shops.find(s => s.id === selectedShopId)?.isOpen ? (
                   <>
                     <Power size={16} color="#ef4444" />
                     Close Shop
                   </>
                ) : (
                   <>
                     <Power size={16} color="#fff" />
                     Open Shop
                   </>
                )}
              </button>
            </div>
          ) : undefined
        }
      />

      {mainError && <InlineNotice tone="error" message={mainError} />}
      {!user?.canManage && (
        <InlineNotice tone="info" message="Approval is required before operational actions unlock." />
      )}

      {/* Top Mock Boxes Section */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem' }}>
        <div className="glass-card" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1.25rem', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
          <div style={{ padding: '1rem', background: 'rgba(37, 99, 235, 0.1)', borderRadius: '12px', color: '#2563eb' }}>
            <Tag size={28} />
          </div>
          <div>
            <p style={{ margin: 0, fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Total Offers</p>
            <h2 style={{ margin: 0, fontSize: '2rem', fontWeight: 800, color: 'hsl(var(--foreground))' }}>
              {loading ? '--' : dashboard?.activeOffersCount ?? 0}
            </h2>
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1.25rem', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
          <div style={{ padding: '1rem', background: 'rgba(16, 185, 129, 0.1)', borderRadius: '12px', color: '#10b981' }}>
            <Store size={28} />
          </div>
          <div>
            <p style={{ margin: 0, fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Total Shops</p>
            <h2 style={{ margin: 0, fontSize: '2rem', fontWeight: 800, color: 'hsl(var(--foreground))' }}>
              {loading ? '--' : shops.length}
            </h2>
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1.25rem', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
          <div style={{ padding: '1rem', background: 'rgba(245, 158, 11, 0.1)', borderRadius: '12px', color: '#f59e0b' }}>
            <Star size={28} />
          </div>
          <div>
            <p style={{ margin: 0, fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Total Reviews</p>
            <h2 style={{ margin: 0, fontSize: '2rem', fontWeight: 800, color: 'hsl(var(--foreground))' }}>
              {loading ? '--' : dashboard?.totalReviews ?? 0}
            </h2>
          </div>
        </div>
      </div>

      {/* Charts Section */}
      <TrafficCharts traffic={traffic} shops={shops} loading={trafficLoading || loading} />

      {/* Map Section */}
      <div style={{ marginTop: '1rem' }}>
        <KeeperShopMap shops={shops} />
      </div>
    </div>
  );
}
