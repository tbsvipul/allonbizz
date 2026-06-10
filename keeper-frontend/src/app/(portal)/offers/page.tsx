'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import { SectionCard } from '@/components/SectionCard';
import { StatusPill } from '@/components/StatusPill';
import api from '@/lib/api';
import { formatDateTime } from '@/lib/format';
import { OfferDetail, ShopSummary } from '@/lib/types';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { useAuth } from '@/context/AuthContext';

export default function OffersPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [offers, setOffers] = useState<OfferDetail[]>([]);
  const [shops, setShops] = useState<ShopSummary[]>([]);

  useEffect(() => {
    let active = true;

    async function load() {
      setLoading(true);
      setError('');

      try {
        const [offersResponse, shopsResponse] = await Promise.all([
          api.get('/keeper/offers'),
          api.get('/keeper/shops'),
        ]);
        if (active) {
          setOffers(unwrapApiData<OfferDetail[]>(offersResponse));
          setShops(unwrapApiData<ShopSummary[]>(shopsResponse));
        }
      } catch (err) {
        if (active) {
          setError(getApiErrorMessage(err, 'Unable to load offers.'));
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

  return (
    <div className="field-stack">
      <PageHeader
        title="Offers"
        description="Create campaigns and assign them to the right shop."
        actions={
          loading ? undefined : user?.canManage && shops.length > 0 ? (
            <Link href="/offers/new" className="button">
              New offer
            </Link>
          ) : user?.canManage ? (
            <Link href="/shops/new" className="button">
              Create first shop
            </Link>
          ) : (
            <span className="button-secondary">Approval required for offer changes</span>
          )
        }
      />

      {error ? <InlineNotice tone="error" message={error} /> : null}

      {loading ? (
        <p className="muted-text">Loading offers...</p>
      ) : user?.canManage && shops.length === 0 ? (
        <SectionCard
          title="Create a shop before creating offers"
          description="Offers must belong to one of your shops so analytics stay linked to a real location."
          action={
            <Link href="/shops/new" className="button">
              Create shop
            </Link>
          }
        >
          <EmptyState title="No shops yet" message="Add your first shop, then return here to launch offers." />
        </SectionCard>
      ) : offers.length === 0 ? (
        <EmptyState title="No offers yet" message="Launch the first campaign to start generating dashboard activity." />
      ) : (
        <section className="table-card">
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Offer</th>
                  <th>Shop</th>
                  <th>Status</th>
                  <th>Window</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {offers.map((offer) => (
                  <tr key={offer.offerId}>
                    <td>
                      <div className="item-stack">
                        <strong>{offer.title}</strong>
                        <span className="muted-text tiny-text">{offer.description || 'No description'}</span>
                      </div>
                    </td>
                    <td>{offer.shopName}</td>
                    <td>
                      <StatusPill status={offer.status} />
                    </td>
                    <td>
                      <div className="item-stack">
                        <span>{formatDateTime(offer.startDate)}</span>
                        <span className="muted-text tiny-text">to {formatDateTime(offer.endDate)}</span>
                      </div>
                    </td>
                    <td>
                      <Link href={`/offers/${offer.offerId}`} className="button-ghost">
                        Edit offer
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  );
}
