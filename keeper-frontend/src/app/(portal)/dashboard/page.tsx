'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { SectionCard } from '@/components/SectionCard';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import { TrendBars } from '@/features/dashboard/TrendBars';
import api from '@/lib/api';
import { formatCurrency, formatDate } from '@/lib/format';
import { KeeperAnalytics, KeeperDashboard, KeeperTraffic, ShopSummary } from '@/lib/types';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { useAuth } from '@/context/AuthContext';

export default function DashboardPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [trafficLoading, setTrafficLoading] = useState(false);
  const [mainError, setMainError] = useState('');
  const [trafficError, setTrafficError] = useState('');
  const [dashboard, setDashboard] = useState<KeeperDashboard | null>(null);
  const [analytics, setAnalytics] = useState<KeeperAnalytics | null>(null);
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [traffic, setTraffic] = useState<KeeperTraffic | null>(null);
  const [selectedShopId, setSelectedShopId] = useState('');

  useEffect(() => {
    let active = true;

    async function load() {
      setLoading(true);
      setMainError('');

      try {
        const [dashboardResponse, analyticsResponse, shopsResponse] = await Promise.allSettled([
          api.get('/keeper/dashboard'),
          api.get('/keeper/analytics'),
          api.get('/keeper/shops'),
        ]);

        if (!active) {
          return;
        }

        const nextErrors: string[] = [];

        if (dashboardResponse.status === 'fulfilled') {
          setDashboard(unwrapApiData<KeeperDashboard>(dashboardResponse.value));
        } else {
          setDashboard(null);
          nextErrors.push(getApiErrorMessage(dashboardResponse.reason, 'Unable to load dashboard totals.'));
        }

        if (analyticsResponse.status === 'fulfilled') {
          setAnalytics(unwrapApiData<KeeperAnalytics>(analyticsResponse.value));
        } else {
          setAnalytics(null);
          nextErrors.push(getApiErrorMessage(analyticsResponse.reason, 'Unable to load analytics totals.'));
        }

        if (shopsResponse.status === 'fulfilled') {
          const nextShops = unwrapApiData<ShopSummary[]>(shopsResponse.value);
          setShops(nextShops);
          setSelectedShopId((current) => nextShops.some((shop) => shop.id === current) ? current : nextShops[0]?.id || '');
        } else {
          setShops([]);
          setSelectedShopId('');
          nextErrors.push(getApiErrorMessage(shopsResponse.reason, 'Unable to load keeper shops.'));
        }

        setMainError(nextErrors.join(' '));
      } catch (err) {
        if (active) {
          setMainError(getApiErrorMessage(err, 'Unable to load the keeper dashboard.'));
        }
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    void load();

    return () => {
      active = false;
    };
  }, []);

  const selectedShop = useMemo(
    () => shops.find((shop) => shop.id === selectedShopId) || null,
    [shops, selectedShopId],
  );

  const selectedShopHasCoordinates = Boolean(
    selectedShop &&
    selectedShop.latitude != null &&
    selectedShop.longitude != null,
  );

  useEffect(() => {
    let active = true;

    async function loadTraffic() {
      if (!selectedShopId) {
        setTraffic(null);
        setTrafficError('');
        setTrafficLoading(false);
        return;
      }

      if (!selectedShopHasCoordinates) {
        setTraffic(null);
        setTrafficError('');
        setTrafficLoading(false);
        return;
      }

      setTrafficLoading(true);
      setTrafficError('');
      try {
        const response = await api.get('/keeper/traffic', {
          params: {
            shopId: selectedShopId,
          },
        });

        if (active) {
          setTraffic(unwrapApiData<KeeperTraffic>(response));
          setTrafficError('');
        }
      } catch (err) {
        if (active) {
          setTraffic(null);
          setTrafficError(getApiErrorMessage(err, 'Unable to load traffic analytics for the selected shop.'));
        }
      } finally {
        if (active) {
          setTrafficLoading(false);
        }
      }
    }

    void loadTraffic();

    return () => {
      active = false;
    };
  }, [selectedShopHasCoordinates, selectedShopId]);

  const trendItems = useMemo(
    () => (dashboard?.redemptionTrend || []).map((item) => ({
      label: formatDate(item.date),
      value: item.count,
    })),
    [dashboard],
  );

  const trafficItems = useMemo(
    () => (traffic?.predictedTraffic || []).map((item) => ({
      label: `${String(item.hour).padStart(2, '0')}:00`,
      value: item.predictedCount,
    })),
    [traffic],
  );

  return (
    <div className="field-stack">
      <PageHeader
        title="Dashboard"
        description="A daily operating view of offers, redemptions, and the shop activity around your business."
        actions={
          user?.canManage && shops.length === 0 ? (
            <Link href="/shops/new" className="button">
              Create first shop
            </Link>
          ) : shops.length > 0 ? (
            <div className="field" style={{ minWidth: '220px' }}>
              <label htmlFor="dashboardShop">Traffic shop</label>
              <select id="dashboardShop" value={selectedShopId} onChange={(event) => setSelectedShopId(event.target.value)} disabled={loading}>
                {shops.map((shop) => (
                  <option key={shop.id} value={shop.id}>
                    {shop.name}
                  </option>
                ))}
              </select>
            </div>
          ) : undefined
        }
      />

      {mainError ? <InlineNotice tone="error" message={mainError} /> : null}

      {!user?.canManage ? (
        <InlineNotice tone="info" message="Approval is still required before operational actions unlock. Dashboard totals and review updates remain visible in the meantime." />
      ) : null}

      <div className="stat-grid">
        <div className="stat-card">
          <span className="muted-text tiny-text">Active offers</span>
          <strong>{loading ? '--' : dashboard?.activeOffersCount ?? 0}</strong>
          <p className="muted-text tiny-text">Campaigns currently live for customer redemption.</p>
        </div>
        <div className="stat-card">
          <span className="muted-text tiny-text">Total redemptions</span>
          <strong>{loading ? '--' : dashboard?.totalRedemptions ?? 0}</strong>
          <p className="muted-text tiny-text">Completed customer redemptions across all keeper offers.</p>
        </div>
        <div className="stat-card">
          <span className="muted-text tiny-text">Estimated value</span>
          <strong>{loading ? '--' : formatCurrency(dashboard?.totalSalesValue)}</strong>
          <p className="muted-text tiny-text">Approximate savings or value created through redeemed offers.</p>
        </div>
      </div>

      <div className="panel-grid">
        <SectionCard title="Redemption trend" description="Recent day-by-day redemption activity.">
          <TrendBars title="No redemption trend yet" items={trendItems} emptyMessage="Once customers redeem your offers, the daily trend appears here." />
        </SectionCard>

        <SectionCard title="Traffic outlook" description="Predicted nearby demand by hour for the selected shop.">
          {trafficError ? <InlineNotice tone="error" message={trafficError} /> : null}
          {trafficLoading ? (
            <p className="muted-text">Loading traffic trend...</p>
          ) : !selectedShopId ? (
            <EmptyState title="No shop selected" message="Add a shop to begin using shop-level traffic insights." />
          ) : !selectedShopHasCoordinates ? (
            <EmptyState title="Coordinates needed" message="Add latitude and longitude to this shop before traffic predictions can be calculated." />
          ) : (
            <TrendBars title="No traffic prediction yet" items={trafficItems} emptyMessage="Add a shop with coordinates to start seeing traffic predictions." />
          )}
        </SectionCard>
      </div>

      <div className="panel-grid">
        <SectionCard title="Network summary" description="Shop and offer totals across the current keeper account.">
          <div className="list-grid">
            <div className="list-item">
              <strong>{analytics?.totalShops ?? 0}</strong>
              <p className="muted-text tiny-text">Total shops</p>
            </div>
            <div className="list-item">
              <strong>{analytics?.activeShops ?? 0}</strong>
              <p className="muted-text tiny-text">Active shops</p>
            </div>
            <div className="list-item">
              <strong>{analytics?.totalOffers ?? 0}</strong>
              <p className="muted-text tiny-text">Total offers</p>
            </div>
            <div className="list-item">
              <strong>{formatCurrency(analytics?.totalSavings)}</strong>
              <p className="muted-text tiny-text">Total savings</p>
            </div>
          </div>
        </SectionCard>

        <SectionCard title="Application updates" description="Recent admin messages from your keeper review flow.">
          {user?.keeper?.reviewMessages?.length ? (
            <div className="message-list">
              {user.keeper.reviewMessages.slice(0, 4).map((message) => (
                <div key={message.messageId} className="message-item">
                  <div className="inline-row" style={{ justifyContent: 'space-between' }}>
                    <strong>{message.adminName}</strong>
                    <span className="mini-pill pill-muted">{formatDate(message.createdAt)}</span>
                  </div>
                  <p className="tiny-text muted-text" style={{ marginTop: '0.45rem' }}>{message.message}</p>
                </div>
              ))}
            </div>
          ) : (
            <EmptyState title="No admin messages yet" message="Status updates and information requests from admins will show up here." />
          )}
        </SectionCard>
      </div>

      <SectionCard title="Shop performance" description="Offer volume and redemption activity by shop.">
        {analytics?.shops?.length ? (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Shop</th>
                  <th>Offers</th>
                  <th>Redemptions</th>
                  <th>Savings</th>
                </tr>
              </thead>
              <tbody>
                {analytics.shops.map((shop) => (
                  <tr key={shop.shopId}>
                    <td>{shop.shopName}</td>
                    <td>{shop.offerCount}</td>
                    <td>{shop.redemptionCount}</td>
                    <td>{formatCurrency(shop.savings)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <EmptyState title="No shop analytics yet" message="Create the first shop and launch an offer to begin populating the analytics table." />
        )}

        {!loading && shops.length === 0 && user?.canManage ? (
          <div style={{ marginTop: '1rem' }}>
            <Link href="/shops/new" className="button">
              Create first shop
            </Link>
          </div>
        ) : null}
      </SectionCard>

      <SectionCard title="Nearby audience" description="Current viewers close to the selected shop.">
        {selectedShopId && selectedShopHasCoordinates ? (
          <div className="list-item">
            <strong>{traffic?.currentViewersNearShop ?? 0}</strong>
            <p className="muted-text tiny-text">Customers recently active near this location.</p>
          </div>
        ) : selectedShopId ? (
          <EmptyState title="Coordinates needed" message="This shop needs map coordinates before nearby audience data can be measured." />
        ) : (
          <EmptyState title="No shop selected" message="Add at least one shop to unlock traffic analysis." />
        )}
      </SectionCard>
    </div>
  );
}
