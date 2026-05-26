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
import { MapPin, Building, ArrowRight, Store, Search, Filter } from 'lucide-react';

export default function ShopsPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [search, setSearch] = useState('');

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

  const filteredShops = shops.filter(shop => 
    shop.name.toLowerCase().includes(search.toLowerCase()) || 
    shop.businessName.toLowerCase().includes(search.toLowerCase()) ||
    shop.location.toLowerCase().includes(search.toLowerCase())
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
              grid-template-columns: minmax(0, 1.6fr) minmax(240px, 0.95fr) auto;
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
              gap: 0.7rem;
            }

            .shop-actions {
              display: flex;
              flex-wrap: wrap;
              justify-content: flex-end;
              gap: 0.6rem;
              align-items: center;
              min-width: 0;
            }

            @media (max-width: 1200px) {
              .shops-hero-grid {
                grid-template-columns: 1fr;
              }

              .shop-row {
                grid-template-columns: minmax(0, 1fr);
              }

              .shop-actions {
                justify-content: flex-start;
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
          <EmptyState title={search ? "No matches found" : "No shops yet"} message={search ? "Try a different search term." : "Create the first shop to unlock traffic analytics, loyalty, and offer assignment."} />
        ) : (
          <div className="shop-list">
            {filteredShops.map((shop) => (
              <div key={shop.id} className="shop-row">
                <div className="shop-primary">
                  <div className="shop-avatar">
                    {shop.imageUrl ? (
                      <img src={resolveMediaSource(shop.imageUrl)} alt={shop.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
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

                <div className="shop-side">
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <StatusPill status={getShopVerificationStatusLabel(shop.verifyStatus, shop.isVerified)} />
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <StatusPill status={getShopListingStatusLabel(shop.status, shop.status.toLowerCase() === 'active')} />
                  </div>
                </div>

                <div className="shop-actions">
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
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
