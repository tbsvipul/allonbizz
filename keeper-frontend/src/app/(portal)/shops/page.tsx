/* eslint-disable @next/next/no-img-element */
'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { resolveMediaSource } from '@/lib/media';
import { getShopListingStatusLabel, getShopVerificationStatusLabel } from '@/lib/shop-status';
import { ShopSummary } from '@/lib/types';
import { useAuth } from '@/context/AuthContext';
import { StatusPill } from '@/components/StatusPill';
import { MapPin, Building, ArrowRight, Store, Search, Power } from 'lucide-react';

export default function ShopsPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [search, setSearch] = useState('');
  const [togglingId, setTogglingId] = useState<string | null>(null);
  const [toggleMsg, setToggleMsg] = useState<{ id: string; text: string; ok: boolean } | null>(null);

  useEffect(() => {
    let active = true;

    async function load() {
      setLoading(true);
      setError('');

      try {
        const response = await api.get('/keeper/shops');
        if (active) {
          setShops(unwrapApiData<ShopSummary[]>(response));
        }
      } catch (err) {
        if (active) {
          setError(getApiErrorMessage(err, 'Unable to load shops.'));
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

  const handleToggleOpen = async (shopId: string) => {
    setTogglingId(shopId);
    try {
      const response = await api.post(`/keeper/shop/${shopId}/toggle-open`);
      const data = unwrapApiData<{ isOpen: boolean }>(response);
      setShops(prev =>
        prev.map(s => (s.id === shopId ? { ...s, isOpen: data.isOpen } : s)),
      );
      const shop = shops.find(s => s.id === shopId);
      setToggleMsg({
        id: shopId,
        text: `${shop?.name ?? 'Shop'} is now ${data.isOpen ? 'Open' : 'Closed'}`,
        ok: true,
      });
      setTimeout(() => setToggleMsg(null), 2500);
    } catch (err) {
      setToggleMsg({
        id: shopId,
        text: getApiErrorMessage(err, 'Unable to toggle shop status.'),
        ok: false,
      });
      setTimeout(() => setToggleMsg(null), 3000);
    } finally {
      setTogglingId(null);
    }
  };

  const filteredShops = shops.filter(shop =>
    shop.name.toLowerCase().includes(search.toLowerCase()) ||
    shop.businessName.toLowerCase().includes(search.toLowerCase()) ||
    shop.location.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div className="animate-fade-in" style={{ display: 'grid', gap: '1.5rem', paddingBottom: '2rem' }}>
      <style
        dangerouslySetInnerHTML={{
          __html: `
            .shops-hero-grid {
              display: grid;
              grid-template-columns: minmax(0, 1.5fr) repeat(auto-fit, minmax(200px, 1fr));
              gap: 1rem;
              align-items: stretch;
            }

            .shop-list {
              display: flex;
              flex-direction: column;
              gap: 0.95rem;
            }

            .shop-row {
              display: grid;
              grid-template-columns: minmax(0, 1.6fr) minmax(200px, 0.85fr) auto;
              gap: 1rem;
              align-items: center;
              padding: 1.1rem;
              border-radius: 22px;
              border: 1px solid rgba(148, 163, 184, 0.18);
              background: linear-gradient(180deg, rgba(255, 255, 255, 0.045) 0%, rgba(255, 255, 255, 0.02) 100%);
              transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
            }

            .shop-row:hover {
              transform: translateY(-2px);
              border-color: rgba(99, 102, 241, 0.28);
              box-shadow: 0 18px 36px rgba(15, 23, 42, 0.08);
            }

            .shop-primary {
              display: flex;
              align-items: flex-start;
              gap: 1rem;
              min-width: 0;
            }

            .shop-avatar {
              width: 58px;
              height: 58px;
              border-radius: 18px;
              overflow: hidden;
              flex: 0 0 auto;
              display: flex;
              align-items: center;
              justify-content: center;
              background: linear-gradient(135deg, rgba(99, 102, 241, 0.18) 0%, rgba(16, 185, 129, 0.12) 100%);
              border: 1px solid rgba(99, 102, 241, 0.18);
              color: hsl(var(--primary));
            }

            .shop-inline-meta {
              display: flex;
              align-items: center;
              gap: 0.75rem;
              flex-wrap: wrap;
              margin-top: 0.55rem;
            }

            .shop-meta-chip {
              display: inline-flex;
              align-items: center;
              gap: 0.42rem;
              padding: 0.42rem 0.65rem;
              border-radius: 999px;
              background: rgba(148, 163, 184, 0.1);
              border: 1px solid rgba(148, 163, 184, 0.15);
              color: hsl(var(--muted-foreground));
              font-size: 0.76rem;
              font-weight: 700;
              max-width: 100%;
            }

            .shop-meta-chip span {
              overflow: hidden;
              text-overflow: ellipsis;
              white-space: nowrap;
            }

            .shop-side {
              display: flex;
              flex-direction: column;
              gap: 0.55rem;
            }

            .shop-actions {
              display: flex;
              flex-direction: column;
              justify-content: center;
              gap: 0.5rem;
              align-items: flex-end;
              min-width: 0;
            }

            .toggle-open-btn {
              display: inline-flex;
              align-items: center;
              gap: 0.4rem;
              padding: 0.5rem 0.85rem;
              border-radius: 12px;
              font-weight: 700;
              font-size: 0.75rem;
              cursor: pointer;
              border: 1px solid transparent;
              transition: all 0.2s ease;
              white-space: nowrap;
            }

            .toggle-open-btn:disabled {
              opacity: 0.6;
              cursor: not-allowed;
            }

            .toggle-open-btn.is-open {
              background: rgba(239, 68, 68, 0.08);
              color: #ef4444;
              border-color: rgba(239, 68, 68, 0.2);
            }

            .toggle-open-btn.is-closed {
              background: linear-gradient(135deg, #10b981 0%, #059669 100%);
              color: #fff;
              box-shadow: 0 4px 12px rgba(16, 185, 129, 0.22);
            }

            .toggle-open-btn.is-open:hover:not(:disabled) {
              background: rgba(239, 68, 68, 0.14);
            }

            .toggle-open-btn.is-closed:hover:not(:disabled) {
              box-shadow: 0 4px 18px rgba(16, 185, 129, 0.35);
              transform: translateY(-1px);
            }

            .open-status-dot {
              position: relative;
              display: inline-flex;
              align-items: center;
              gap: 0.4rem;
              padding: 0.28rem 0.65rem;
              border-radius: 999px;
              font-size: 0.72rem;
              font-weight: 700;
              letter-spacing: 0.03em;
              text-transform: uppercase;
            }

            @keyframes shop-ping {
              0% { transform: scale(1); opacity: 0.75; }
              100% { transform: scale(2); opacity: 0; }
            }
            .shop-ping { animation: shop-ping 1.6s cubic-bezier(0,0,0.2,1) infinite; }

            @media (max-width: 1200px) {
              .shops-hero-grid {
                grid-template-columns: 1fr;
              }

              .shop-row {
                grid-template-columns: minmax(0, 1fr);
              }

              .shop-actions {
                align-items: flex-start;
                flex-direction: row;
                flex-wrap: wrap;
              }
            }

            @media (max-width: 720px) {
              .shop-primary {
                flex-direction: column;
              }

              .shop-avatar {
                width: 64px;
                height: 64px;
              }
            }
          `,
        }}
      />

      <PageHeader
        title="Shops"
        description="Own the public details for each location, keep coordinates accurate, and push verification metadata when needed."
        actions={
          user?.canManage ? (
            <Link href="/shops/new" className="button">
              Add shop
            </Link>
          ) : (
            <span className="button-secondary">Approval required for new shops</span>
          )
        }
      />

      {/* Toast notification for toggle */}
      {toggleMsg && (
        <div
          style={{
            position: 'fixed',
            top: '1.5rem',
            right: '1.5rem',
            zIndex: 1100,
            padding: '0.85rem 1.4rem',
            borderRadius: '14px',
            background: toggleMsg.ok
              ? 'linear-gradient(135deg, #10b981 0%, #059669 100%)'
              : 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
            color: '#fff',
            fontWeight: 600,
            fontSize: '0.875rem',
            boxShadow: '0 10px 25px rgba(0,0,0,0.25)',
            border: '1px solid rgba(255,255,255,0.1)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            transition: 'all 0.3s ease',
          }}
        >
          <Power size={16} />
          {toggleMsg.text}
        </div>
      )}

      {error ? <InlineNotice tone="error" message={error} /> : null}

      <section className="glass-card" style={{ padding: '1.5rem', background: 'var(--surface)', borderRadius: 'var(--radius-xl)' }}>
        <div style={{ position: 'relative', marginBottom: '1.5rem', maxWidth: '400px' }}>
          <Search size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
          <input
            placeholder="Search shops..."
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            style={{
              width: '100%',
              padding: '0.85rem 1rem 0.85rem 2.75rem',
              borderRadius: '16px',
              border: '1px solid hsl(var(--border))',
              background: 'hsl(var(--secondary))',
              color: 'hsl(var(--foreground))',
              outline: 'none',
              fontWeight: 500,
            }}
          />
        </div>

        {loading ? (
          <p className="muted-text">Loading shops...</p>
        ) : filteredShops.length === 0 ? (
          <EmptyState title={search ? 'No matches found' : 'No shops yet'} message={search ? 'Try a different search term.' : 'Create the first shop to unlock traffic analytics and offer assignment.'} />
        ) : (
          <div className="shop-list">
            {filteredShops.map((shop) => {
              const isOpen = shop.isOpen === true;
              const isToggling = togglingId === shop.id;

              return (
                <div key={shop.id} className="shop-row">
                  {/* Primary Info */}
                  <div className="shop-primary">
                    <div className="shop-avatar">
                      {shop.shopProfileImage ? (
                        <img src={resolveMediaSource(shop.shopProfileImage)} alt={shop.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      ) : (
                        <Store size={24} />
                      )}
                    </div>
                    <div style={{ minWidth: 0, width: '100%' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
                        <h3 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 800, color: 'hsl(var(--foreground))' }}>
                          {shop.name}
                        </h3>
                        {shop.rejectionReason && (
                          <span style={{ fontSize: '0.7rem', padding: '0.2rem 0.5rem', borderRadius: '4px', background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', fontWeight: 700 }}>
                            REJECTED
                          </span>
                        )}
                      </div>
                      <div className="shop-inline-meta">
                        <div className="shop-meta-chip">
                          <Building size={13} />
                          <span>{shop.businessName}</span>
                        </div>
                        <div className="shop-meta-chip">
                          <MapPin size={13} />
                          <span>{shop.location}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Status Column */}
                  <div className="shop-side">
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <StatusPill status={getShopVerificationStatusLabel(shop.verifyStatus, shop.isVerified)} />
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <StatusPill status={getShopListingStatusLabel(shop.status, shop.status.toLowerCase() === 'active')} />
                    </div>
                    {/* Open/Closed Indicator */}
                    <div
                      className="open-status-dot"
                      style={{
                        background: isOpen ? 'rgba(16, 185, 129, 0.1)' : 'rgba(245, 158, 11, 0.1)',
                        color: isOpen ? '#10b981' : '#f59e0b',
                        border: `1px solid ${isOpen ? 'rgba(16,185,129,0.2)' : 'rgba(245,158,11,0.2)'}`,
                        width: 'fit-content',
                      }}
                    >
                      <span style={{ position: 'relative', display: 'flex', height: '7px', width: '7px' }}>
                        <span
                          className="shop-ping"
                          style={{
                            position: 'absolute',
                            display: 'inline-flex',
                            height: '100%',
                            width: '100%',
                            borderRadius: '50%',
                            backgroundColor: isOpen ? '#10b981' : '#f59e0b',
                            opacity: 0.75,
                          }}
                        />
                        <span style={{ position: 'relative', display: 'inline-flex', borderRadius: '50%', height: '7px', width: '7px', backgroundColor: isOpen ? '#10b981' : '#f59e0b' }} />
                      </span>
                      {isOpen ? 'Open' : 'Closed'}
                    </div>
                  </div>

                  {/* Actions Column */}
                  <div className="shop-actions">
                    {/* Toggle Open/Close */}
                    {user?.canManage && (
                      <button
                        className={`toggle-open-btn ${isOpen ? 'is-open' : 'is-closed'}`}
                        onClick={() => void handleToggleOpen(shop.id)}
                        disabled={isToggling}
                        title={isOpen ? 'Click to close shop' : 'Click to open shop'}
                      >
                        <Power size={13} />
                        {isToggling ? '...' : isOpen ? 'Close Shop' : 'Open Shop'}
                      </button>
                    )}

                    {/* Manage Link */}
                    <Link
                      href={`/shops/${shop.id}`}
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '0.4rem',
                        padding: '0.62rem 0.9rem',
                        borderRadius: '12px',
                        background: 'rgba(99, 102, 241, 0.1)',
                        color: '#6366f1',
                        fontWeight: 700,
                        fontSize: '0.8rem',
                        textDecoration: 'none',
                      }}
                    >
                      Manage
                      <ArrowRight size={14} />
                    </Link>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
}
