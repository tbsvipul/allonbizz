'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { ShopSummary } from '@/lib/types';
import { useAuth } from '@/context/AuthContext';
import { StatusPill } from '@/components/StatusPill';

export default function ShopsPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [shops, setShops] = useState<ShopSummary[]>([]);

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

  return (
    <div className="field-stack">
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

      {loading ? (
        <p className="muted-text">Loading shops...</p>
      ) : shops.length === 0 ? (
        <EmptyState title="No shops yet" message="Create the first shop to unlock traffic analytics, loyalty, and offer assignment." />
      ) : (
        <section className="table-card">
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Shop</th>
                  <th>Category</th>
                  <th>Location</th>
                  <th>Verification</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {shops.map((shop) => (
                  <tr key={shop.id}>
                    <td>
                      <div className="item-stack">
                        <strong>{shop.name}</strong>
                        <span className="muted-text tiny-text">{shop.businessName}</span>
                      </div>
                    </td>
                    <td>{shop.category}</td>
                    <td>{shop.location}</td>
                    <td>
                      <StatusPill status={shop.isVerified ? 'Approved' : 'PendingApproval'} />
                    </td>
                    <td>{shop.status}</td>
                    <td>
                      <Link href={`/shops/${shop.id}`} className="button-ghost">
                        View details
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
