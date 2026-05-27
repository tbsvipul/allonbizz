'use client';

import Link from 'next/link';
import { FormEvent, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { toDateTimeLocalInput } from '@/lib/format';
import { OfferDetail, ShopSummary } from '@/lib/types';
import { useToast } from '@/context/ToastContext';
import { InlineNotice } from '@/components/InlineNotice';
import { SectionCard } from '@/components/SectionCard';
import { StatusPill } from '@/components/StatusPill';
import CustomSelect from '@/components/CustomSelect';
import { Store } from 'lucide-react';

interface OfferFormState {
  shopId: string;
  title: string;
  description: string;
  discountPercentage: string;
  discountAmount: string;
  startDate: string;
  endDate: string;
  termsAndConditions: string;
  imageUrl: string;
}

function toFormState(offer: OfferDetail | null): OfferFormState {
  return {
    shopId: offer?.shopId || '',
    title: offer?.title || '',
    description: offer?.description || '',
    discountPercentage: offer?.discountPercentage != null ? String(offer.discountPercentage) : '',
    discountAmount: offer?.discountAmount != null ? String(offer.discountAmount) : '',
    startDate: toDateTimeLocalInput(offer?.startDate),
    endDate: toDateTimeLocalInput(offer?.endDate),
    termsAndConditions: offer?.termsAndConditions || '',
    imageUrl: offer?.imageUrl || '',
  };
}

export function OfferEditor({ offerId }: { offerId?: string }) {
  const router = useRouter();
  const { showToast } = useToast();
  const isEditing = Boolean(offerId);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState('');
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [offer, setOffer] = useState<OfferDetail | null>(null);
  const [form, setForm] = useState<OfferFormState>(toFormState(null));

  function updateField<Key extends keyof OfferFormState>(key: Key, value: OfferFormState[Key]) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  useEffect(() => {
    let active = true;

    async function load() {
      setLoading(true);
      setError('');

      try {
        const shopsResponse = await api.get('/keeper/shops');
        const nextShops = unwrapApiData<ShopSummary[]>(shopsResponse);

        let nextOffer: OfferDetail | null = null;
        if (offerId) {
          const offerResponse = await api.get(`/keeper/offer/${offerId}`);
          nextOffer = unwrapApiData<OfferDetail>(offerResponse);
        }

        if (!active) {
          return;
        }

        setShops(nextShops);
        setOffer(nextOffer);
        setForm(toFormState(nextOffer));
      } catch (err) {
        if (active) {
          setError(getApiErrorMessage(err, 'Unable to load the offer editor.'));
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
  }, [offerId]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSaving(true);
    setError('');

    try {
      if (!form.shopId) {
        throw new Error('Select a shop before saving the offer.');
      }

      const payload = {
        shopId: form.shopId,
        title: form.title.trim(),
        description: form.description.trim() || null,
        discountPercentage: form.discountPercentage.trim() ? Number(form.discountPercentage) : null,
        discountAmount: form.discountAmount.trim() ? Number(form.discountAmount) : null,
        startDate: new Date(form.startDate).toISOString(),
        endDate: new Date(form.endDate).toISOString(),
        termsAndConditions: form.termsAndConditions.trim() || null,
        imageUrl: form.imageUrl || null,
      };

      if (isEditing && offerId) {
        await api.put(`/keeper/offer/${offerId}`, payload);
        showToast('Offer updated successfully.', 'success');
      } else {
        const response = await api.post('/keeper/offer', payload);
        const created = unwrapApiData<{ offerId: string }>(response);
        showToast('Offer created successfully.', 'success');
        router.replace(`/offers/${created.offerId}`);
        return;
      }
    } catch (err) {
      const message = err instanceof Error && err.message === 'Select a shop before saving the offer.'
        ? err.message
        : getApiErrorMessage(err, 'Unable to save the offer.');
      setError(message);
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!offerId) {
      return;
    }

    setDeleting(true);
    setError('');

    try {
      await api.delete(`/keeper/offer/${offerId}`);
      showToast('Offer deleted.', 'success');
      router.replace('/offers');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to delete the offer.'));
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="field-stack">
      {error ? <InlineNotice tone="error" message={error} /> : null}

      {isEditing && offer ? (
        <SectionCard
          title="Offer performance"
          description="Live status and redemption context for this offer."
          action={<StatusPill status={offer.status} />}
        >
          <div className="list-grid">
            <div className="list-item">
              <strong>{offer.redemptionCount}</strong>
              <p className="muted-text tiny-text">Total redemptions so far</p>
            </div>
            <div className="list-item">
              <strong>{offer.shopName}</strong>
              <p className="muted-text tiny-text">Assigned shop</p>
            </div>
          </div>
        </SectionCard>
      ) : null}

      {!isEditing && !loading && shops.length === 0 ? (
        <SectionCard
          title="Create a shop first"
          description="Every offer must be attached to one of your shops so customers know where it can be redeemed."
          action={
            <Link href="/shops/new" className="button">
              Create shop
            </Link>
          }
        >
          <InlineNotice tone="info" message="Add your first shop, then come back here to create offers." />
        </SectionCard>
      ) : null}

      {(isEditing || loading || shops.length > 0) ? (
        <SectionCard
          title={isEditing ? 'Edit offer' : 'Create offer'}
          description="Set the timing, commercial terms, and shop assignment for this campaign."
          action={
            isEditing ? (
              <button type="button" className="button-danger" onClick={() => void handleDelete()} disabled={deleting}>
                {deleting ? 'Deleting...' : 'Delete offer'}
              </button>
            ) : undefined
          }
        >
          <form className="form-stack" onSubmit={handleSubmit}>
            <div className="field-grid">
              <div className="field">
                <label htmlFor="offerShop" style={{ fontSize: '0.85rem', fontWeight: 600, marginBottom: '0.25rem', display: 'block', color: 'hsl(var(--muted-foreground))' }}>Shop</label>
                <CustomSelect
                  value={form.shopId}
                  onChange={(val) => updateField('shopId', val)}
                  options={[
                    { value: '', label: 'Select a shop', icon: <Store size={16} /> },
                    ...shops.map(shop => ({
                      value: shop.id,
                      label: shop.name,
                      icon: <Store size={16} />
                    }))
                  ]}
                  style={{ width: '100%' }}
                />
              </div>
              <div className="field">
                <label htmlFor="offerTitle">Title</label>
                <input id="offerTitle" value={form.title} onChange={(event) => updateField('title', event.target.value)} disabled={loading || saving} required />
              </div>
            </div>

            <div className="field">
              <label htmlFor="offerDescription">Description</label>
              <textarea id="offerDescription" value={form.description} onChange={(event) => updateField('description', event.target.value)} disabled={loading || saving} />
            </div>

            <div className="field-grid">
              <div className="field">
                <label htmlFor="discountPercentage">Discount percentage</label>
                <input id="discountPercentage" type="number" step="0.01" value={form.discountPercentage} onChange={(event) => updateField('discountPercentage', event.target.value)} disabled={loading || saving} />
              </div>
              <div className="field">
                <label htmlFor="discountAmount">Discount amount</label>
                <input id="discountAmount" type="number" step="0.01" value={form.discountAmount} onChange={(event) => updateField('discountAmount', event.target.value)} disabled={loading || saving} />
              </div>
            </div>

            <div className="field-grid">
              <div className="field">
                <label htmlFor="offerStart">Start date</label>
                <input id="offerStart" type="datetime-local" value={form.startDate} onChange={(event) => updateField('startDate', event.target.value)} disabled={loading || saving} required />
              </div>
              <div className="field">
                <label htmlFor="offerEnd">End date</label>
                <input id="offerEnd" type="datetime-local" value={form.endDate} onChange={(event) => updateField('endDate', event.target.value)} disabled={loading || saving} required />
              </div>
            </div>

            <div className="field">
              <label htmlFor="offerTerms">Terms and conditions</label>
              <textarea id="offerTerms" value={form.termsAndConditions} onChange={(event) => updateField('termsAndConditions', event.target.value)} disabled={loading || saving} />
            </div>

            <div className="field">
              <label htmlFor="offerImage" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                Offer Image (Optional)
                <label style={{ cursor: 'pointer', fontSize: '0.75rem', color: '#6366f1', fontWeight: 700, textDecoration: 'underline' }}>
                  Upload File
                  <input
                    type="file"
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={(e) => {
                      const file = e.target.files?.[0];
                      if (!file) return;
                      const reader = new FileReader();
                      reader.onload = (ev) => {
                        if (ev.target?.result) {
                          updateField('imageUrl', ev.target.result as string);
                        }
                      };
                      reader.readAsDataURL(file);
                    }}
                  />
                </label>
              </label>
              {form.imageUrl && (
                <div style={{ marginTop: '0.5rem', position: 'relative', width: 'fit-content' }}>
                  <img src={form.imageUrl} alt="Offer preview" style={{ maxWidth: '100%', maxHeight: '200px', borderRadius: '8px', objectFit: 'cover', border: '1px solid var(--border)' }} />
                  <button 
                    type="button" 
                    onClick={() => updateField('imageUrl', '')}
                    style={{ position: 'absolute', top: 5, right: 5, background: 'rgba(0,0,0,0.5)', color: 'white', border: 'none', borderRadius: '50%', width: 24, height: 24, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px' }}
                  >
                    ✕
                  </button>
                </div>
              )}
            </div>

            <button type="submit" className="button" disabled={loading || saving || shops.length === 0}>
              {saving ? 'Saving offer...' : isEditing ? 'Save offer changes' : 'Create offer'}
            </button>
          </form>
        </SectionCard>
      ) : null}
    </div>
  );
}
