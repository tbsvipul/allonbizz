'use client';

import Link from 'next/link';
import { ChangeEvent, useEffect, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import { SectionCard } from '@/components/SectionCard';
import { StatusPill } from '@/components/StatusPill';
import api from '@/lib/api';
import { formatDateTime } from '@/lib/format';
import { BulkOfferUploadResult, OfferDetail, ShopSummary } from '@/lib/types';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { useAuth } from '@/context/AuthContext';

export default function OffersPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');
  const [offers, setOffers] = useState<OfferDetail[]>([]);
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [file, setFile] = useState<File | null>(null);
  const [uploadResult, setUploadResult] = useState<BulkOfferUploadResult | null>(null);

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

  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    setFile(event.target.files?.[0] || null);
  }

  async function handleUpload() {
    if (!file) {
      setError('Choose a CSV file before uploading.');
      return;
    }

    setUploading(true);
    setError('');

    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await api.post('/keeper/offer/bulk', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      setUploadResult(unwrapApiData<BulkOfferUploadResult>(response));

      const refreshed = await api.get('/keeper/offers');
      setOffers(unwrapApiData<OfferDetail[]>(refreshed));
      setFile(null);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Bulk upload failed.'));
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="field-stack">
      <PageHeader
        title="Offers"
        description="Create campaigns, assign them to the right shop, and bulk-load seasonal promotions when needed."
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

      {user?.canManage && shops.length > 0 ? (
        <SectionCard title="Bulk upload CSV" description="Expected columns: title, description, discountPercentage, discountAmount, startDate, endDate, shopId, termsAndConditions (optional).">
          <div className="button-row">
            <input type="file" accept=".csv" onChange={handleFileChange} />
            <button type="button" className="button-secondary" onClick={() => void handleUpload()} disabled={uploading || !file}>
              {uploading ? 'Uploading...' : 'Upload CSV'}
            </button>
          </div>

          {uploadResult ? (
            <div className="field-stack" style={{ marginTop: '1rem' }}>
              <InlineNotice
                tone={uploadResult.failedRowCount > 0 ? 'info' : 'success'}
                message={`Imported ${uploadResult.importedCount} offer(s). ${uploadResult.failedRowCount} row(s) failed validation.`}
              />

              {uploadResult.failedRows.length > 0 ? (
                <div className="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>Row</th>
                        <th>Reason</th>
                      </tr>
                    </thead>
                    <tbody>
                      {uploadResult.failedRows.map((row) => (
                        <tr key={`${row.rowNumber}-${row.message}`}>
                          <td>{row.rowNumber}</td>
                          <td>{row.message}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : null}
            </div>
          ) : null}
        </SectionCard>
      ) : null}

      {loading ? (
        <p className="muted-text">Loading offers...</p>
      ) : user?.canManage && shops.length === 0 ? (
        <SectionCard
          title="Create a shop before creating offers"
          description="Offers must belong to one of your shops so redemption and analytics stay linked to a real location."
          action={
            <Link href="/shops/new" className="button">
              Create shop
            </Link>
          }
        >
          <EmptyState title="No shops yet" message="Add your first shop, then return here to launch offers and bulk uploads." />
        </SectionCard>
      ) : offers.length === 0 ? (
        <EmptyState title="No offers yet" message="Launch the first campaign to start generating redemptions and dashboard activity." />
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
                  <th>Redemptions</th>
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
                    <td>{offer.redemptionCount}</td>
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
