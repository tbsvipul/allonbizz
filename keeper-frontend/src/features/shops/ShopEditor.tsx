/* eslint-disable @next/next/no-img-element */
'use client';

import { ChangeEvent, FormEvent, useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { readFilesAsDataUrls, resolveMediaSource } from '@/lib/media';
import { getShopListingStatusLabel, getShopVerificationStatusLabel } from '@/lib/shop-status';
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
  shopImages: string[];
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
    shopImages: shop?.shopImages || [],
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

function hasOnlyImageFiles(files: File[]) {
  return files.every((file) => file.type.startsWith('image/'));
}

export function ShopEditor({ shopId }: { shopId?: string }) {
  const router = useRouter();
  const { showToast } = useToast();
  const isEditing = Boolean(shopId);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [reapplying, setReapplying] = useState(false);
  const [uploadingCover, setUploadingCover] = useState(false);
  const [uploadingGallery, setUploadingGallery] = useState(false);
  const [error, setError] = useState('');
  const [shop, setShop] = useState<ShopDetail | null>(null);
  const [categories, setCategories] = useState<CategoryOption[]>([]);
  const [availableTags, setAvailableTags] = useState<{ tagId: string; name: string }[]>([]);
  const [form, setForm] = useState<ShopFormState>(toFormState(null));

  const [isTagModalOpen, setIsTagModalOpen] = useState(false);
  const [tagSearchQuery, setTagSearchQuery] = useState('');
  const [tagInputValue, setTagInputValue] = useState('');
  const [activePreviewImage, setActivePreviewImage] = useState<string | null>(null);

  const categoryOptions = useMemo(() => categories, [categories]);

  function updateField<Key extends keyof ShopFormState>(key: Key, value: ShopFormState[Key]) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  function setShopFromDetail(detail: ShopDetail | null) {
    setShop(detail);
    setForm(toFormState(detail));
  }

  async function fetchShopDetail(currentShopId: string) {
    const shopResponse = await api.get(`/keeper/shop/${currentShopId}`);
    return unwrapApiData<ShopDetail>(shopResponse);
  }

  const handleAddTag = (tagName: string) => {
    const currentTags = form.tags.split(',').map((tag) => tag.trim()).filter(Boolean);
    if (!currentTags.some((tag) => tag.toLowerCase() === tagName.toLowerCase())) {
      updateField('tags', currentTags.length > 0 ? `${currentTags.join(', ')}, ${tagName}` : tagName);
    }
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

  const filteredModalTags = useMemo(
    () => availableTagsToDisplay.filter((tag) => tag.name.toLowerCase().includes(tagSearchQuery.toLowerCase())),
    [availableTagsToDisplay, tagSearchQuery],
  );

  const verificationStatusLabel = getShopVerificationStatusLabel(shop?.verifyStatus, shop?.isVerified);
  const listingStatusLabel = getShopListingStatusLabel(shop?.isActive ? 'Active' : 'Inactive', shop?.isActive);

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
          nextShop = await fetchShopDetail(shopId);
        }

        if (!active) {
          return;
        }

        setCategories(nextCategories);
        setAvailableTags(nextTags || []);
        setShopFromDetail(nextShop);
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

  async function handleCoverImageChange(event: ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files || []);
    event.target.value = '';

    if (files.length === 0) {
      return;
    }

    if (!hasOnlyImageFiles(files)) {
      setError('Only image files can be used for the shop cover.');
      return;
    }

    setUploadingCover(true);
    setError('');

    try {
      const [coverImage] = await readFilesAsDataUrls([files[0]]);
      updateField('imageUrl', coverImage || '');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to read the selected cover image.'));
    } finally {
      setUploadingCover(false);
    }
  }

  async function handleGalleryImagesChange(event: ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files || []);
    event.target.value = '';

    if (files.length === 0) {
      return;
    }

    if (!hasOnlyImageFiles(files)) {
      setError('Only image files can be added to the shop gallery.');
      return;
    }

    setUploadingGallery(true);
    setError('');

    try {
      const nextImages = await readFilesAsDataUrls(files);
      updateField('shopImages', [...form.shopImages, ...nextImages.filter(Boolean)]);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to read one or more selected gallery images.'));
    } finally {
      setUploadingGallery(false);
    }
  }

  function removeGalleryImage(indexToRemove: number) {
    updateField(
      'shopImages',
      form.shopImages.filter((_, index) => index !== indexToRemove),
    );
  }

  function clearCoverImage() {
    updateField('imageUrl', '');
  }

  function openImagePreview(image: string) {
    setActivePreviewImage(resolveMediaSource(image));
  }

  function closeImagePreview() {
    setActivePreviewImage(null);
  }

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

      const payload = {
        name: form.name.trim(),
        description: form.description.trim() || null,
        address: form.address.trim() || null,
        phoneNumber: form.phoneNumber.trim() || null,
        email: form.email.trim() || null,
        imageUrl: form.imageUrl || null,
        shopImages: form.shopImages,
        categoryId: form.categoryId || null,
        latitude: toNumberOrNull(form.latitude),
        longitude: toNumberOrNull(form.longitude),
        isOpen: form.isOpen,
        notificationRadius: toNumberOrNull(form.notificationRadius),
        amenities: form.amenities.split(',').map((item) => item.trim()).filter(Boolean),
        tags: form.tags.split(',').map((item) => item.trim()).filter(Boolean),
      };

      if (isEditing && shopId) {
        await api.put(`/keeper/shop/${shopId}`, payload);
        const refreshedShop = await fetchShopDetail(shopId);
        setShopFromDetail(refreshedShop);
        showToast(
          String(shop?.verifyStatus || '').toLowerCase() === 'rejected'
            ? 'Shop updated and sent back for review.'
            : 'Shop updated successfully.',
          'success',
        );
      } else {
        const response = await api.post('/keeper/shop', {
          ...payload,
          address: form.address.trim(),
        });

        const created = unwrapApiData<{ shopId: string }>(response);
        showToast('Shop created successfully.', 'success');
        router.replace(`/shops/${created.shopId}`);
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
      const refreshedShop = await fetchShopDetail(shopId);
      setShopFromDetail(refreshedShop);
      showToast('Google sync completed.', 'success');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to sync with Google Business Profile.'));
    } finally {
      setSyncing(false);
    }
  }

  async function handleReapply() {
    if (!shopId) {
      return;
    }

    setReapplying(true);
    setError('');

    try {
      await api.post(`/keeper/shop/${shopId}/reapply`);
      const refreshedShop = await fetchShopDetail(shopId);
      setShopFromDetail(refreshedShop);
      showToast('Shop sent back for verification review.', 'success');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to reapply this shop for review.'));
    } finally {
      setReapplying(false);
    }
  }

  return (
    <div className="field-stack">
      {error ? <InlineNotice tone="error" message={error} /> : null}

      {isEditing && shop ? (
        <SectionCard
          title="Current shop status"
          description="Verification, listing health, and review feedback for this location."
          action={
            <div className="button-row">
              {String(shop.verifyStatus || '').toLowerCase() === 'rejected' ? (
                <button type="button" className="button-secondary" onClick={() => void handleReapply()} disabled={reapplying || syncing}>
                  {reapplying ? 'Reapplying...' : 'Reapply'}
                </button>
              ) : null}
              <button type="button" className="button-ghost" onClick={() => void handleGoogleSync()} disabled={syncing || reapplying}>
                {syncing ? 'Syncing...' : 'Google sync'}
              </button>
            </div>
          }
        >
          <div className="field-stack">
            <div className="list-grid">
              <div className="list-item">
                <div className="inline-row" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
                  <strong>Listing status</strong>
                  <StatusPill status={listingStatusLabel} />
                </div>
                <p className="muted-text tiny-text" style={{ marginTop: '0.45rem' }}>
                  {shop.isActive ? 'Customers can discover this shop in the app.' : 'This shop is currently hidden from customers.'}
                </p>
              </div>
              <div className="list-item">
                <div className="inline-row" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
                  <strong>Verification</strong>
                  <StatusPill status={verificationStatusLabel} />
                </div>
                <p className="muted-text tiny-text" style={{ marginTop: '0.45rem' }}>
                  {verificationStatusLabel === 'Verified'
                    ? 'The current business details have passed review.'
                    : verificationStatusLabel === 'Rejected'
                      ? 'This shop needs updates before it can be approved again.'
                      : 'The latest shop details are waiting for review.'}
                </p>
              </div>
              <div className="list-item">
                <div className="inline-row" style={{ justifyContent: 'space-between', alignItems: 'center' }}>
                  <strong>Open state</strong>
                  <StatusPill status={shop.isOpen ? 'Open' : 'Closed'} />
                </div>
                <p className="muted-text tiny-text" style={{ marginTop: '0.45rem' }}>
                  Use the operational toggle below to reflect daily storefront availability.
                </p>
              </div>
            </div>

            {(shop.rejectionReason || shop.deactivateReason) ? (
              <div className="reason-stack">
                {shop.rejectionReason ? <InlineNotice tone="error" message={`Review feedback: ${shop.rejectionReason}`} /> : null}
                {shop.deactivateReason ? <InlineNotice tone="info" message={`Listing note: ${shop.deactivateReason}`} /> : null}
              </div>
            ) : null}
          </div>
        </SectionCard>
      ) : null}

      <SectionCard
        title={isEditing ? 'Edit shop' : 'Create shop'}
        description={
          isEditing
            ? 'Update listing content, storefront images, coordinates, and review metadata in one place.'
            : 'Create the public listing with the latest address, discovery tags, and storefront images.'
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
            <label htmlFor="shopCoverImage">Cover image</label>
            <div className="media-uploader">
              <label className="media-dropzone" htmlFor="shopCoverImage">
                <strong>{uploadingCover ? 'Preparing cover image...' : 'Upload a shop cover image'}</strong>
                <span className="muted-text tiny-text">JPG, PNG, and WebP work best. The image is stored directly with the shop.</span>
                <input id="shopCoverImage" type="file" accept="image/*" onChange={handleCoverImageChange} disabled={loading || saving || uploadingCover} />
              </label>

              {form.imageUrl ? (
                <div className="media-preview-grid">
                  <div className="media-preview-card media-preview-card-compact">
                    <button
                      type="button"
                      className="media-preview-frame media-preview-trigger"
                      onClick={() => openImagePreview(form.imageUrl)}
                    >
                      <img src={resolveMediaSource(form.imageUrl)} alt="Shop cover preview" />
                    </button>
                    <div className="media-preview-meta">
                      <strong>Primary cover image</strong>
                      <span className="muted-text tiny-text">This image is used as the main storefront thumbnail.</span>
                    </div>
                    <div className="media-preview-actions">
                      <button type="button" className="button-secondary" onClick={() => openImagePreview(form.imageUrl)} disabled={loading || saving}>
                        Preview full
                      </button>
                      <button type="button" className="button-ghost" onClick={clearCoverImage} disabled={loading || saving}>
                        Remove cover
                      </button>
                    </div>
                  </div>
                </div>
              ) : null}
            </div>
          </div>

          <div className="field">
            <label htmlFor="shopGalleryImages">Gallery images</label>
            <div className="media-uploader">
              <label className="media-dropzone" htmlFor="shopGalleryImages">
                <strong>{uploadingGallery ? 'Preparing gallery images...' : 'Upload additional shop images'}</strong>
                <span className="muted-text tiny-text">Add storefront, interior, shelf, or ambience photos to support review and discovery.</span>
                <input id="shopGalleryImages" type="file" accept="image/*" multiple onChange={handleGalleryImagesChange} disabled={loading || saving || uploadingGallery} />
              </label>

              {form.shopImages.length > 0 ? (
                <div className="media-preview-grid">
                  {form.shopImages.map((image, index) => (
                    <div key={`${image.slice(0, 32)}-${index}`} className="media-preview-card">
                      <button
                        type="button"
                        className="media-preview-frame media-preview-trigger"
                        onClick={() => openImagePreview(image)}
                      >
                        <img src={resolveMediaSource(image)} alt={`Shop gallery preview ${index + 1}`} />
                      </button>
                      <div className="media-preview-meta">
                        <strong>Gallery image {index + 1}</strong>
                        <span className="muted-text tiny-text">Additional storefront media saved with this shop.</span>
                      </div>
                      <div className="media-preview-actions">
                        <button type="button" className="button-secondary" onClick={() => openImagePreview(image)} disabled={loading || saving}>
                          Preview full
                        </button>
                        <button type="button" className="button-ghost" onClick={() => removeGalleryImage(index)} disabled={loading || saving}>
                          Remove image
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="muted-text tiny-text">No extra gallery images added yet.</p>
              )}
            </div>
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
                cursor: 'text',
              }}
              onClick={() => document.getElementById('shopTags')?.focus()}
            >
              {selectedTags.map((tag, index) => (
                <span
                  key={`${tag}-${index}`}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.3rem',
                    padding: '0.2rem 0.6rem',
                    fontSize: '0.85rem',
                    borderRadius: '999px',
                    background: 'var(--accent-soft)',
                    color: 'var(--accent-strong)',
                    fontWeight: 'bold',
                  }}
                >
                  {tag}
                  <button
                    type="button"
                    onClick={(clickEvent) => {
                      clickEvent.stopPropagation();
                      handleRemoveTag(tag);
                    }}
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
                onKeyDown={(keyEvent) => {
                  if (keyEvent.key === 'Enter' || keyEvent.key === ',') {
                    keyEvent.preventDefault();
                    if (tagInputValue.trim()) {
                      handleAddTag(tagInputValue.trim());
                      setTagInputValue('');
                    }
                  } else if (keyEvent.key === 'Backspace' && !tagInputValue && selectedTags.length > 0) {
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
                placeholder={selectedTags.length === 0 ? 'Type a tag and press Enter' : 'Add more...'}
                style={{
                  flex: 1,
                  minWidth: '120px',
                  border: 'none',
                  background: 'transparent',
                  color: 'var(--text)',
                  outline: 'none',
                  padding: '0.3rem',
                  fontSize: 'inherit',
                  boxShadow: 'none',
                }}
              />
            </div>
            {availableTagsToDisplay.length > 0 ? (
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
                {availableTagsToDisplay.length > 10 ? (
                  <button
                    type="button"
                    style={{ padding: '0.2rem 0.6rem', fontSize: '0.85rem', borderRadius: '1rem', border: '1px dashed var(--accent)', color: 'var(--accent)', background: 'transparent', cursor: 'pointer', fontWeight: 'bold' }}
                    onClick={() => setIsTagModalOpen(true)}
                  >
                    + {availableTagsToDisplay.length - 10} more...
                  </button>
                ) : null}
              </div>
            ) : null}
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

          <p className="muted-text tiny-text">
            Add both latitude and longitude together when you have them. Saving a rejected shop will submit the refreshed details for review again.
          </p>

          <button type="submit" className="button" disabled={loading || saving || uploadingCover || uploadingGallery}>
            {saving ? 'Saving shop...' : isEditing ? 'Save shop changes' : 'Create shop'}
          </button>
        </form>
      </SectionCard>

      {isTagModalOpen ? (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            zIndex: 1000,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <div
            style={{
              background: 'var(--surface)',
              padding: '2rem',
              borderRadius: 'var(--radius-xl)',
              width: '90%',
              maxWidth: '500px',
              maxHeight: '80vh',
              display: 'flex',
              flexDirection: 'column',
              boxShadow: 'var(--shadow)',
              border: '1px solid var(--border)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h3 style={{ margin: 0, color: 'var(--text)' }}>All Available Tags</h3>
              <button type="button" onClick={() => setIsTagModalOpen(false)} style={{ background: 'transparent', border: 'none', fontSize: '1.5rem', cursor: 'pointer', color: 'var(--text-muted)' }}>
                &times;
              </button>
            </div>
            <input
              type="text"
              placeholder="Search tags..."
              value={tagSearchQuery}
              onChange={(event) => setTagSearchQuery(event.target.value)}
              style={{ marginBottom: '1rem', padding: '0.6rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--field-border)', background: 'var(--field-bg)', color: 'var(--text)', width: '100%' }}
            />
            <div style={{ overflowY: 'auto', display: 'flex', gap: '0.5rem', flexWrap: 'wrap', paddingBottom: '1rem' }}>
              {filteredModalTags.length > 0 ? (
                filteredModalTags.map((tag) => (
                  <button
                    key={tag.tagId}
                    type="button"
                    style={{ padding: '0.3rem 0.8rem', fontSize: '0.9rem', borderRadius: '999px', border: '1px solid var(--border)', background: 'var(--surface-muted)', color: 'var(--text)', cursor: 'pointer' }}
                    onClick={() => handleAddTag(tag.name)}
                  >
                    + {tag.name}
                  </button>
                ))
              ) : (
                <p className="muted-text">No tags match your search.</p>
              )}
            </div>
            <div style={{ marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid var(--border)', textAlign: 'right' }}>
              <button type="button" className="button" onClick={() => setIsTagModalOpen(false)}>
                Done
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {activePreviewImage ? (
        <div className="media-lightbox" onClick={closeImagePreview} role="dialog" aria-modal="true" aria-label="Full image preview">
          <div className="media-lightbox-content" onClick={(event) => event.stopPropagation()}>
            <button type="button" className="media-lightbox-close" onClick={closeImagePreview} aria-label="Close image preview">
              &times;
            </button>
            <img src={activePreviewImage} alt="Full shop preview" className="media-lightbox-image" />
          </div>
        </div>
      ) : null}
    </div>
  );
}
