'use client';

import Link from 'next/link';
import { FormEvent, useEffect, useMemo, useState } from 'react';
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
import { Image as ImageIcon, Store, Tag, UploadCloud, X } from 'lucide-react';

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
  tags: string;
}

const MAX_TAG_SUGGESTIONS = 8;

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
    tags: offer?.tags?.join(', ') || '',
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
  const [availableTags, setAvailableTags] = useState<{ tagId: string; name: string }[]>([]);
  const [tagInputValue, setTagInputValue] = useState('');

  const handleAddTag = (tagName: string) => {
    const currentTags = form.tags.split(',').map((tag) => tag.trim()).filter(Boolean);
    if (!currentTags.some((tag) => tag.toLowerCase() === tagName.toLowerCase())) {
      updateField('tags', currentTags.length > 0 ? `${currentTags.join(', ')}, ${tagName}` : tagName);
    }
  };

  const handleSelectSuggestedTag = (tagName: string) => {
    handleAddTag(tagName);
    setTagInputValue('');
    requestAnimationFrame(() => document.getElementById('offerTags')?.focus());
  };

  const handleRemoveTag = (tagName: string) => {
    const currentTags = form.tags.split(',').map((tag) => tag.trim()).filter(Boolean);
    const nextTags = currentTags.filter((tag) => tag.toLowerCase() !== tagName.toLowerCase());
    updateField('tags', nextTags.join(', '));
  };

  const selectedTags = useMemo(() => form.tags.split(',').map((tag) => tag.trim()).filter(Boolean), [form.tags]);
  const availableTagsToDisplay = useMemo(
    () => availableTags.filter((tag) => !selectedTags.some((selectedTag) => selectedTag.toLowerCase() === tag.name.toLowerCase())),
    [availableTags, selectedTags],
  );
  const matchingTagSuggestions = useMemo(
    () => {
      const query = tagInputValue.trim().toLowerCase();
      if (!query) {
        return availableTagsToDisplay.slice(0, MAX_TAG_SUGGESTIONS);
      }

      return availableTagsToDisplay
        .filter((tag) => tag.name.toLowerCase().includes(query))
        .sort((left, right) => {
          const leftStartsWithQuery = left.name.toLowerCase().startsWith(query);
          const rightStartsWithQuery = right.name.toLowerCase().startsWith(query);
          if (leftStartsWithQuery !== rightStartsWithQuery) {
            return leftStartsWithQuery ? -1 : 1;
          }

          return left.name.localeCompare(right.name);
        })
        .slice(0, MAX_TAG_SUGGESTIONS);
    },
    [availableTagsToDisplay, tagInputValue],
  );

  function updateField<Key extends keyof OfferFormState>(key: Key, value: OfferFormState[Key]) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  function handleImageFile(file?: File | null) {
    if (!file) {
      return;
    }

    if (!file.type.startsWith('image/')) {
      setError('Upload a valid image file for the offer.');
      return;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      if (event.target?.result) {
        updateField('imageUrl', event.target.result as string);
        setError('');
      }
    };
    reader.readAsDataURL(file);
  }

  useEffect(() => {
    let active = true;

    async function load() {
      setLoading(true);
      setError('');

      try {
        const shopsResponse = await api.get('/keeper/shops');
        const nextShops = unwrapApiData<ShopSummary[]>(shopsResponse);

        const tagsResponse = await api.get('/public/tags').catch(() => null);
        const nextTags = tagsResponse ? unwrapApiData<{ tagId: string; name: string }[]>(tagsResponse) : [];

        let nextOffer: OfferDetail | null = null;
        if (offerId) {
          const offerResponse = await api.get(`/keeper/offer/${offerId}`);
          nextOffer = unwrapApiData<OfferDetail>(offerResponse);
        }

        if (!active) {
          return;
        }

        setAvailableTags(nextTags || []);
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

      if (!form.imageUrl.trim()) {
        throw new Error('Upload at least one offer image before saving.');
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
        tags: form.tags.split(',').map((item) => item.trim()).filter(Boolean),
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
      const localValidationMessages = new Set([
        'Select a shop before saving the offer.',
        'Upload at least one offer image before saving.',
      ]);
      const message = err instanceof Error && localValidationMessages.has(err.message)
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
          description="Live status and context for this offer."
          action={<StatusPill status={offer.status} />}
        >
          <div className="list-grid">

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
              <label htmlFor="offerTags" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Tag size={16} /> Search Tags
              </label>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem', padding: '0.75rem', border: '1px solid var(--border)', borderRadius: 'var(--radius)', background: 'var(--input)', cursor: 'text', minHeight: '80px', alignItems: 'flex-start', alignContent: 'flex-start' }} onClick={() => document.getElementById('offerTags')?.focus()}>
                {selectedTags.map((tag, index) => (
                  <span key={`${tag}-${index}`} style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', background: 'rgba(99, 102, 241, 0.1)', border: '1px solid rgba(99, 102, 241, 0.2)', borderRadius: '30px', padding: '0.35rem 0.75rem', fontSize: '0.8rem', fontWeight: 600, color: 'hsl(var(--primary))' }}>
                    <span style={{ color: 'rgba(99, 102, 241, 0.7)' }}>#</span>{tag}
                    <button type="button" onClick={(e) => { e.preventDefault(); e.stopPropagation(); handleRemoveTag(tag); }} style={{ background: 'none', border: 'none', color: 'inherit', cursor: 'pointer', fontSize: '1.1rem', lineHeight: 1 }}>&times;</button>
                  </span>
                ))}
                <input
                  id="offerTags"
                  value={tagInputValue}
                  onChange={(event) => setTagInputValue(event.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ',') { e.preventDefault(); if (tagInputValue.trim()) { handleAddTag(tagInputValue.trim()); setTagInputValue(''); } }
                    else if (e.key === 'Backspace' && !tagInputValue && selectedTags.length > 0) { handleRemoveTag(selectedTags[selectedTags.length - 1]); }
                  }}
                  onBlur={() => { if (tagInputValue.trim()) { handleAddTag(tagInputValue.trim()); setTagInputValue(''); } }}
                  disabled={loading || saving}
                  placeholder={selectedTags.length === 0 ? "Type and press Enter..." : ""}
                  style={{ flex: 1, minWidth: '120px', border: 'none', background: 'transparent', outline: 'none', color: 'inherit', fontSize: '0.9rem', marginTop: '0.2rem' }}
                />
              </div>
              {matchingTagSuggestions.length > 0 ? (
                <div style={{ marginTop: '1rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                  {matchingTagSuggestions.map((tag) => (
                    <button
                      key={tag.tagId}
                      type="button"
                      onMouseDown={(event) => event.preventDefault()}
                      onClick={() => handleSelectSuggestedTag(tag.name)}
                      style={{ padding: '0.25rem 0.75rem', fontSize: '0.75rem', fontWeight: 600, borderRadius: '999px', border: '1px solid rgba(148, 163, 184, 0.3)', background: 'transparent', color: 'hsl(var(--muted-foreground))', cursor: 'pointer', transition: 'all 0.2s' }}
                    >
                      + {tag.name}
                    </button>
                  ))}
                </div>
              ) : null}
            </div>

            <div className="field">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
                <label htmlFor="offerImage" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem' }}>
                  <ImageIcon size={16} /> Offer image
                  <span style={{ fontSize: '0.72rem', fontWeight: 800, color: 'hsl(var(--danger))', background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.2)', borderRadius: '999px', padding: '0.15rem 0.45rem' }}>
                    Required
                  </span>
                </label>
                <label htmlFor="offerImage" className="button-secondary" style={{ cursor: loading || saving ? 'not-allowed' : 'pointer', padding: '0.65rem 1rem', opacity: loading || saving ? 0.55 : 1 }}>
                  <UploadCloud size={16} /> {form.imageUrl ? 'Replace image' : 'Upload image'}
                  <input
                    id="offerImage"
                    type="file"
                    accept="image/*"
                    disabled={loading || saving}
                    style={{ display: 'none' }}
                    onChange={(event) => {
                      handleImageFile(event.target.files?.[0]);
                      event.currentTarget.value = '';
                    }}
                  />
                </label>
              </div>
              {!form.imageUrl ? (
                <label
                  htmlFor="offerImage"
                  style={{ border: '1.5px dashed hsl(var(--primary))', borderRadius: 'var(--radius-lg)', background: 'rgba(99, 102, 241, 0.06)', minHeight: 168, padding: '1.25rem', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', gap: '0.65rem', textAlign: 'center', cursor: loading || saving ? 'not-allowed' : 'pointer', opacity: loading || saving ? 0.55 : 1 }}
                >
                  <span style={{ width: 52, height: 52, borderRadius: '999px', background: 'rgba(99, 102, 241, 0.12)', color: 'hsl(var(--primary))', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
                    <UploadCloud size={24} />
                  </span>
                  <strong style={{ color: 'hsl(var(--foreground))' }}>Upload offer image</strong>
                  <span className="muted-text" style={{ maxWidth: 420, fontSize: '0.86rem' }}>Choose one clear product, shop, or offer image. PNG, JPG, or WEBP files are supported.</span>
                </label>
              ) : null}
              {form.imageUrl && (
                <div style={{ marginTop: '0.5rem', position: 'relative', width: 'fit-content' }}>
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={form.imageUrl} alt="Offer preview" style={{ maxWidth: '100%', maxHeight: '200px', borderRadius: '8px', objectFit: 'cover', border: '1px solid var(--border)' }} />
                  <button 
                    type="button" 
                    onClick={() => updateField('imageUrl', '')}
                    disabled={loading || saving}
                    aria-label="Remove offer image"
                    title="Remove image"
                    style={{ position: 'absolute', top: 8, right: 8, background: 'rgba(15, 23, 42, 0.72)', color: 'white', border: '1px solid rgba(255,255,255,0.28)', borderRadius: '50%', width: 32, height: 32, cursor: loading || saving ? 'not-allowed' : 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 0 }}
                  >
                    <X size={16} />
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
