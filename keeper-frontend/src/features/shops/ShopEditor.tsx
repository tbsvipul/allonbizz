'use client';

import { FormEvent, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { CategoryTree, ShopDetail } from '@/lib/types';
import { useToast } from '@/context/ToastContext';
import { InlineNotice } from '@/components/InlineNotice';
import { SectionCard } from '@/components/SectionCard';
import { StatusPill } from '@/components/StatusPill';

interface CategoryOption {
  id: string;
  label: string;
}

interface ShopFormState {
  name: string;
  description: string;
  address: string;
  phoneNumber: string;
  email: string;
  imageUrl: string;
  categoryId: string;
  latitude: string;
  longitude: string;
  isOpen: boolean;
  notificationRadius: string;
  amenities: string;
  tags: string;
}

function flattenCategories(tree: CategoryTree[], depth = 0): CategoryOption[] {
  return tree.flatMap((node) => [
    {
      id: node.categoryId,
      label: `${'-- '.repeat(depth)}${node.name}`,
    },
    ...flattenCategories(node.children || [], depth + 1),
  ]);
}

function toFormState(shop: ShopDetail | null): ShopFormState {
  return {
    name: shop?.name || '',
    description: shop?.description || '',
    address: shop?.address || '',
    phoneNumber: shop?.phoneNumber || '',
    email: shop?.email || '',
    imageUrl: shop?.imageUrl || '',
    categoryId: shop?.categoryId || '',
    latitude: shop?.latitude != null ? String(shop.latitude) : '',
    longitude: shop?.longitude != null ? String(shop.longitude) : '',
    isOpen: shop?.isOpen ?? true,
    notificationRadius: shop?.notificationRadius != null ? String(shop.notificationRadius) : '',
    amenities: shop?.amenities?.join(', ') || '',
    tags: shop?.tags?.join(', ') || '',
  };
}

function toNumberOrNull(value: string) {
  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  return Number(trimmed);
}

export function ShopEditor({ shopId }: { shopId?: string }) {
  const router = useRouter();
  const { showToast } = useToast();
  const isEditing = Boolean(shopId);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [error, setError] = useState('');
  const [shop, setShop] = useState<ShopDetail | null>(null);
  const [categories, setCategories] = useState<CategoryOption[]>([]);
  const [availableTags, setAvailableTags] = useState<{ tagId: string; name: string }[]>([]);
  const [form, setForm] = useState<ShopFormState>(toFormState(null));
  
  const [isTagModalOpen, setIsTagModalOpen] = useState(false);
  const [tagSearchQuery, setTagSearchQuery] = useState('');
  const [tagInputValue, setTagInputValue] = useState('');

  const categoryOptions = useMemo(() => categories, [categories]);

  const handleAddTag = (tagName: string) => {
    const currentTags = form.tags.split(',').map((t) => t.trim()).filter(Boolean);
    if (!currentTags.some(t => t.toLowerCase() === tagName.toLowerCase())) {
      updateField('tags', currentTags.length > 0 ? `${currentTags.join(', ')}, ${tagName}` : tagName);
    }
  };

  const handleRemoveTag = (tagName: string) => {
    const currentTags = form.tags.split(',').map((t) => t.trim()).filter(Boolean);
    const newTags = currentTags.filter(t => t.toLowerCase() !== tagName.toLowerCase());
    updateField('tags', newTags.join(', '));
  };

  const selectedTags = useMemo(() => {
    return form.tags.split(',').map((t) => t.trim()).filter(Boolean);
  }, [form.tags]);

  const availableTagsToDisplay = useMemo(() => {
    return availableTags.filter(tag => !selectedTags.some(t => t.toLowerCase() === tag.name.toLowerCase()));
  }, [availableTags, selectedTags]);

  const filteredModalTags = useMemo(() => {
    return availableTagsToDisplay.filter(tag => tag.name.toLowerCase().includes(tagSearchQuery.toLowerCase()));
  }, [availableTagsToDisplay, tagSearchQuery]);

  function updateField<Key extends keyof ShopFormState>(key: Key, value: ShopFormState[Key]) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  useEffect(() => {
    let active = true;

    async function load() {
      setLoading(true);
      setError('');

      try {
        const categoryResponse = await api.get('/categories');
        const categoryTree = unwrapApiData<CategoryTree[]>(categoryResponse);
        const nextCategories = flattenCategories(categoryTree);

        const tagsResponse = await api.get('/public/tags').catch(() => null);
        const nextTags = tagsResponse ? unwrapApiData<{ tagId: string; name: string }[]>(tagsResponse) : [];

        let nextShop: ShopDetail | null = null;
        if (shopId) {
          const shopResponse = await api.get(`/keeper/shop/${shopId}`);
          nextShop = unwrapApiData<ShopDetail>(shopResponse);
        }

        if (!active) {
          return;
        }

        setCategories(nextCategories);
        setAvailableTags(nextTags || []);
        setShop(nextShop);
        setForm(toFormState(nextShop));
      } catch (err) {
        if (active) {
          setError(getApiErrorMessage(err, 'Unable to load the shop editor.'));
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
  }, [shopId]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSaving(true);
    setError('');

    try {
      const hasLatitude = Boolean(form.latitude.trim());
      const hasLongitude = Boolean(form.longitude.trim());
      if (hasLatitude !== hasLongitude) {
        throw new Error('Latitude and longitude must both be filled, or both left empty.');
      }
      if ((hasLatitude && Number.isNaN(Number(form.latitude))) || (hasLongitude && Number.isNaN(Number(form.longitude)))) {
        throw new Error('Latitude and longitude must be valid numbers.');
      }
      if (hasLatitude && (Number(form.latitude) < -90 || Number(form.latitude) > 90)) {
        throw new Error('Latitude must be between -90 and 90.');
      }
      if (hasLongitude && (Number(form.longitude) < -180 || Number(form.longitude) > 180)) {
        throw new Error('Longitude must be between -180 and 180.');
      }
      if (form.notificationRadius.trim() && (Number.isNaN(Number(form.notificationRadius)) || Number(form.notificationRadius) <= 0)) {
        throw new Error('Notification radius must be a valid number greater than zero.');
      }

      if (isEditing && shopId) {
        await api.put(`/keeper/shop/${shopId}`, {
          name: form.name.trim(),
          description: form.description.trim() || null,
          address: form.address.trim() || null,
          phoneNumber: form.phoneNumber.trim() || null,
          email: form.email.trim() || null,
          imageUrl: form.imageUrl.trim() || null,
          categoryId: form.categoryId || null,
          latitude: toNumberOrNull(form.latitude),
          longitude: toNumberOrNull(form.longitude),
          isOpen: form.isOpen,
          notificationRadius: toNumberOrNull(form.notificationRadius),
          amenities: form.amenities.split(',').map((item) => item.trim()).filter(Boolean),
          tags: form.tags.split(',').map((item) => item.trim()).filter(Boolean),
        });

        showToast('Shop updated successfully.', 'success');
      } else {
        const response = await api.post('/keeper/shop', {
          name: form.name.trim(),
          description: form.description.trim() || null,
          address: form.address.trim(),
          phoneNumber: form.phoneNumber.trim() || null,
          email: form.email.trim() || null,
          latitude: toNumberOrNull(form.latitude),
          longitude: toNumberOrNull(form.longitude),
          imageUrl: form.imageUrl.trim() || null,
          categoryId: form.categoryId || null,
          isOpen: form.isOpen,
          notificationRadius: toNumberOrNull(form.notificationRadius),
          amenities: form.amenities.split(',').map((item) => item.trim()).filter(Boolean),
          tags: form.tags.split(',').map((item) => item.trim()).filter(Boolean),
        });

        const payload = unwrapApiData<{ shopId: string }>(response);
        showToast('Shop created successfully.', 'success');
        router.replace(`/shops/${payload.shopId}`);
        return;
      }
    } catch (err) {
      const message = err instanceof Error && (
        err.message === 'Latitude and longitude must both be filled, or both left empty.' ||
        err.message === 'Latitude and longitude must be valid numbers.' ||
        err.message === 'Latitude must be between -90 and 90.' ||
        err.message === 'Longitude must be between -180 and 180.' ||
        err.message === 'Notification radius must be a valid number greater than zero.'
      )
        ? err.message
        : getApiErrorMessage(err, 'Unable to save the shop.');
      setError(message);
    } finally {
      setSaving(false);
    }
  }

  async function handleGoogleSync() {
    if (!shopId) {
      return;
    }

    setSyncing(true);
    setError('');

    try {
      await api.post(`/keeper/shop/${shopId}/google-sync`);
      showToast('Google sync completed.', 'success');

      const refreshed = await api.get(`/keeper/shop/${shopId}`);
      const nextShop = unwrapApiData<ShopDetail>(refreshed);
      setShop(nextShop);
      setForm(toFormState(nextShop));
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to sync with Google Business Profile.'));
    } finally {
      setSyncing(false);
    }
  }

  return (
    <div className="field-stack">
      {error ? <InlineNotice tone="error" message={error} /> : null}

      {isEditing && shop ? (
        <SectionCard
          title="Current shop status"
          description="Quick view of verification and live operational flags."
          action={<StatusPill status={shop.isVerified ? 'Approved' : 'PendingApproval'} />}
        >
          <div className="list-grid">
            <div className="list-item">
              <strong>{shop.isActive ? 'Active listing' : 'Inactive listing'}</strong>
              <p className="muted-text tiny-text">Customers can {shop.isActive ? 'find the shop in the app.' : 'no longer see the shop publicly.'}</p>
            </div>
            <div className="list-item">
              <strong>{shop.isVerified ? 'Verified' : 'Unverified'}</strong>
              <p className="muted-text tiny-text">Google sync can refresh verification and business visibility metadata.</p>
            </div>
            <div className="list-item">
              <strong>{shop.isOpen ? 'Currently open' : 'Currently closed'}</strong>
              <p className="muted-text tiny-text">Use the shop open toggle below to reflect day-to-day availability.</p>
            </div>
          </div>
        </SectionCard>
      ) : null}

      <SectionCard
        title={isEditing ? 'Edit shop' : 'Create shop'}
        description={isEditing ? 'Update public listing details and operational metadata.' : 'Capture the public listing details, operating state, and discovery metadata in one pass.'}
        action={
          isEditing ? (
            <button type="button" className="button-ghost" onClick={() => void handleGoogleSync()} disabled={syncing}>
              {syncing ? 'Syncing...' : 'Google sync'}
            </button>
          ) : undefined
        }
      >
        <form className="form-stack" onSubmit={handleSubmit}>
          <div className="field-grid">
            <div className="field">
              <label htmlFor="shopName">Shop name</label>
              <input id="shopName" value={form.name} onChange={(event) => updateField('name', event.target.value)} disabled={loading || saving} required />
            </div>
            <div className="field">
              <label htmlFor="categoryId">Category</label>
              <select id="categoryId" value={form.categoryId} onChange={(event) => updateField('categoryId', event.target.value)} disabled={loading || saving}>
                <option value="">Select a category</option>
                {categoryOptions.map((category) => (
                  <option key={category.id} value={category.id}>
                    {category.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="field">
            <label htmlFor="shopDescription">Description</label>
            <textarea id="shopDescription" value={form.description} onChange={(event) => updateField('description', event.target.value)} disabled={loading || saving} />
          </div>

          <div className="field">
            <label htmlFor="shopAddress">Address</label>
            <input id="shopAddress" value={form.address} onChange={(event) => updateField('address', event.target.value)} disabled={loading || saving} required />
          </div>

          <div className="field-grid">
            <div className="field">
              <label htmlFor="shopLatitude">Latitude</label>
              <input id="shopLatitude" value={form.latitude} onChange={(event) => updateField('latitude', event.target.value)} disabled={loading || saving} />
            </div>
            <div className="field">
              <label htmlFor="shopLongitude">Longitude</label>
              <input id="shopLongitude" value={form.longitude} onChange={(event) => updateField('longitude', event.target.value)} disabled={loading || saving} />
            </div>
          </div>

          <div className="field-grid">
            <div className="field">
              <label htmlFor="shopNotificationRadius">Notification radius (km)</label>
              <input
                id="shopNotificationRadius"
                type="number"
                min="0.1"
                step="0.1"
                value={form.notificationRadius}
                onChange={(event) => updateField('notificationRadius', event.target.value)}
                disabled={loading || saving}
              />
            </div>
            <div className="field">
              <label className="inline-row" style={{ alignItems: 'center', gap: '0.65rem', marginTop: '1.9rem' }}>
                <input
                  type="checkbox"
                  checked={form.isOpen}
                  onChange={(event) => updateField('isOpen', event.target.checked)}
                  disabled={loading || saving}
                />
                <span>Shop currently open</span>
              </label>
            </div>
          </div>

          <div className="field-grid">
            <div className="field">
              <label htmlFor="shopPhone">Phone number</label>
              <input id="shopPhone" value={form.phoneNumber} onChange={(event) => updateField('phoneNumber', event.target.value)} disabled={loading || saving} />
            </div>
            <div className="field">
              <label htmlFor="shopEmail">Contact email</label>
              <input id="shopEmail" type="email" value={form.email} onChange={(event) => updateField('email', event.target.value)} disabled={loading || saving} />
            </div>
          </div>

          <div className="field">
            <label htmlFor="shopImage">Image URL</label>
            <input id="shopImage" value={form.imageUrl} onChange={(event) => updateField('imageUrl', event.target.value)} disabled={loading || saving} />
          </div>

          <div className="field">
            <label htmlFor="shopTags">Tags</label>
            <div 
              style={{
                display: 'flex', 
                flexWrap: 'wrap', 
                gap: '0.4rem', 
                width: '100%',
                border: '1px solid var(--field-border)',
                borderRadius: 'var(--radius-md)',
                background: 'var(--field-bg)',
                padding: '0.4rem 0.6rem',
                minHeight: '44px',
                alignItems: 'center',
                transition: 'border-color 0.18s ease, box-shadow 0.18s ease',
                cursor: 'text'
              }}
              onClick={() => document.getElementById('shopTags')?.focus()}
            >
              {selectedTags.map((tag, idx) => (
                <span
                  key={idx}
                  style={{
                    display: 'inline-flex', alignItems: 'center', gap: '0.3rem',
                    padding: '0.2rem 0.6rem', fontSize: '0.85rem', borderRadius: '999px',
                    background: 'var(--accent-soft)', color: 'var(--accent-strong)', fontWeight: 'bold'
                  }}
                >
                  {tag}
                  <button
                    type="button"
                    onClick={(e) => { e.stopPropagation(); handleRemoveTag(tag); }}
                    style={{ background: 'transparent', border: 'none', color: 'inherit', cursor: 'pointer', fontSize: '1.2rem', lineHeight: 0.5, padding: 0 }}
                    aria-label="Remove tag"
                  >
                    &times;
                  </button>
                </span>
              ))}
              <input
                id="shopTags"
                value={tagInputValue}
                onChange={(event) => setTagInputValue(event.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ',') {
                    e.preventDefault();
                    if (tagInputValue.trim()) {
                      handleAddTag(tagInputValue.trim());
                      setTagInputValue('');
                    }
                  } else if (e.key === 'Backspace' && !tagInputValue && selectedTags.length > 0) {
                    handleRemoveTag(selectedTags[selectedTags.length - 1]);
                  }
                }}
                onBlur={() => {
                  if (tagInputValue.trim()) {
                    handleAddTag(tagInputValue.trim());
                    setTagInputValue('');
                  }
                }}
                disabled={loading || saving}
                placeholder={selectedTags.length === 0 ? "Type a tag and press Enter" : "Add more..."}
                style={{
                  flex: 1,
                  minWidth: '120px',
                  border: 'none',
                  background: 'transparent',
                  color: 'var(--text)',
                  outline: 'none',
                  padding: '0.3rem',
                  fontSize: 'inherit',
                  boxShadow: 'none'
                }}
              />
            </div>
            {availableTagsToDisplay.length > 0 && (
              <div style={{ marginTop: '0.5rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                {availableTagsToDisplay.slice(0, 10).map((tag) => (
                  <button
                    key={tag.tagId}
                    type="button"
                    style={{ padding: '0.2rem 0.6rem', fontSize: '0.85rem', borderRadius: '999px', border: '1px solid var(--border)', background: 'var(--surface-muted)', color: 'var(--text)', cursor: 'pointer' }}
                    onClick={() => handleAddTag(tag.name)}
                  >
                    + {tag.name}
                  </button>
                ))}
                {availableTagsToDisplay.length > 10 && (
                  <button
                    type="button"
                    style={{ padding: '0.2rem 0.6rem', fontSize: '0.85rem', borderRadius: '1rem', border: '1px dashed var(--accent)', color: 'var(--accent)', background: 'transparent', cursor: 'pointer', fontWeight: 'bold' }}
                    onClick={() => setIsTagModalOpen(true)}
                  >
                    + {availableTagsToDisplay.length - 10} more...
                  </button>
                )}
              </div>
            )}
          </div>

          <div className="field">
            <label htmlFor="shopAmenities">Amenities</label>
            <input
              id="shopAmenities"
              value={form.amenities}
              onChange={(event) => updateField('amenities', event.target.value)}
              disabled={loading || saving}
              placeholder="wifi, parking, outdoor seating"
            />
          </div>

          <p className="muted-text tiny-text">Coordinates are optional, but add both latitude and longitude together when you have them. Notification radius controls nearby audience and traffic views.</p>

          <button type="submit" className="button" disabled={loading || saving}>
            {saving ? 'Saving shop...' : isEditing ? 'Save shop changes' : 'Create shop'}
          </button>
        </form>
      </SectionCard>

      {isTagModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 1000,
          display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>
          <div style={{
            background: 'var(--surface)', padding: '2rem', borderRadius: 'var(--radius-xl)',
            width: '90%', maxWidth: '500px', maxHeight: '80vh', display: 'flex', flexDirection: 'column',
            boxShadow: 'var(--shadow)', border: '1px solid var(--border)'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h3 style={{ margin: 0, color: 'var(--text)' }}>All Available Tags</h3>
              <button type="button" onClick={() => setIsTagModalOpen(false)} style={{ background: 'transparent', border: 'none', fontSize: '1.5rem', cursor: 'pointer', color: 'var(--text-muted)' }}>&times;</button>
            </div>
            <input
              type="text"
              placeholder="Search tags..."
              value={tagSearchQuery}
              onChange={(e) => setTagSearchQuery(e.target.value)}
              style={{ marginBottom: '1rem', padding: '0.6rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--field-border)', background: 'var(--field-bg)', color: 'var(--text)', width: '100%' }}
            />
            <div style={{ overflowY: 'auto', display: 'flex', gap: '0.5rem', flexWrap: 'wrap', paddingBottom: '1rem' }}>
              {filteredModalTags.length > 0 ? filteredModalTags.map(tag => (
                <button
                  key={tag.tagId}
                  type="button"
                  style={{ padding: '0.3rem 0.8rem', fontSize: '0.9rem', borderRadius: '999px', border: '1px solid var(--border)', background: 'var(--surface-muted)', color: 'var(--text)', cursor: 'pointer' }}
                  onClick={() => handleAddTag(tag.name)}
                >
                  + {tag.name}
                </button>
              )) : (
                <p className="muted-text">No tags match your search.</p>
              )}
            </div>
            <div style={{ marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid var(--border)', textAlign: 'right' }}>
              <button type="button" className="button" onClick={() => setIsTagModalOpen(false)}>Done</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
