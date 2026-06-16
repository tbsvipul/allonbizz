/* eslint-disable @next/next/no-img-element */
'use client';

import { ChangeEvent, FormEvent, useEffect, useMemo, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { readFilesAsDataUrls, resolveMediaSource } from '@/lib/media';
import { getShopListingStatusLabel, getShopVerificationStatusLabel } from '@/lib/shop-status';
import { CategoryTree, ShopDetail } from '@/lib/types';
import { useToast } from '@/context/ToastContext';
import { Store, MapPin, Image as ImageIcon, Tag, Settings, AlertCircle, Info, Send, Save, RefreshCw, Layers, Phone, Compass } from 'lucide-react';
import { InlineNotice } from '@/components/InlineNotice';
import { SectionCard } from '@/components/SectionCard';
import { StatusPill } from '@/components/StatusPill';
import CustomSelect from '@/components/CustomSelect';

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
  shopProfileImage: string;
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
    shopProfileImage: shop?.shopProfileImage || '',
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

const GOOGLE_MAP_SCRIPT_ID = 'navideals-google-maps-script';
const MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || '';

function loadGoogleMapsApi(apiKey: string) {
  if (typeof window === 'undefined') return Promise.resolve();
  const win = window as any;

  if (win.google?.maps) {
    return Promise.resolve();
  }

  if (win.__navidealsGoogleMapsPromise) {
    return win.__navidealsGoogleMapsPromise;
  }

  win.__navidealsGoogleMapsPromise = new Promise<void>((resolve, reject) => {
    const existingScript = document.getElementById(GOOGLE_MAP_SCRIPT_ID) as HTMLScriptElement | null;

    if (existingScript) {
      existingScript.addEventListener('load', () => resolve(), { once: true });
      existingScript.addEventListener('error', () => reject(new Error('Failed to load Google Maps.')), { once: true });
      return;
    }

    const script = document.createElement('script');
    script.id = GOOGLE_MAP_SCRIPT_ID;
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}`;
    script.async = true;
    script.defer = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error('Failed to load Google Maps.'));
    document.head.appendChild(script);
  });

  return win.__navidealsGoogleMapsPromise;
}

export function ShopEditor({ shopId }: { shopId?: string }) {
  const router = useRouter();
  const { showToast } = useToast();
  const isEditing = Boolean(shopId);

  // Real Map Integration References & State
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<any>(null);
  const [isMapReady, setIsMapReady] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [showDeactivateReason, setShowDeactivateReason] = useState(true);
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

  // Load Google Maps API Script
  useEffect(() => {
    if (typeof window === 'undefined') return;

    if (!MAPS_API_KEY) {
      console.warn('Google Maps API key is missing in environment configurations.');
      return;
    }

    loadGoogleMapsApi(MAPS_API_KEY)
      .then(() => {
        setIsMapReady(true);
      })
      .catch((err: any) => {
        console.error('Failed to load Google Maps library:', err);
      });
  }, []);

  // Initialize Map and bind custom animated Overlay
  useEffect(() => {
    const win = window as any;
    if (!isMapReady || !mapContainerRef.current || !win.google?.maps) {
      return;
    }

    const lat = parseFloat(form.latitude) || 0;
    const lng = parseFloat(form.longitude) || 0;

    if (lat !== 0 && lng !== 0) {
      const position = { lat, lng };

      if (!mapRef.current) {
        mapRef.current = new win.google.maps.Map(mapContainerRef.current, {
          center: position,
          zoom: 15,
          minZoom: 3,
          disableDefaultUI: true,
          zoomControl: false,
          gestureHandling: 'cooperative',
          styles: []
        });
      } else {
        mapRef.current.setCenter(position);
      }

      // Custom OverlayView class definition to position animated marker precisely over coordinate projection
      class GeofenceRadarOverlay extends win.google.maps.OverlayView {
        private container: HTMLDivElement | null = null;
        private pos: any;

        constructor(pos: any) {
          super();
          this.pos = pos;
        }

        onAdd() {
          const div = document.createElement('div');
          div.style.position = 'absolute';
          div.style.transform = 'translate(-50%, -50%)';
          div.style.display = 'flex';
          div.style.alignItems = 'center';
          div.style.justifyContent = 'center';
          div.style.pointerEvents = 'none';

          // Concentric animated circles and map pin
          div.innerHTML = `
            <!-- Double Expanding Purple Pulsing Radar Rings -->
            <div class="radar-ring" style="position: absolute; width: 110px; height: 110px; border-radius: 50%; border: 2px solid #a855f7; opacity: 0; animation: pulse-radar 2.8s cubic-bezier(0, 0, 0.2, 1) infinite;"></div>
            <div class="radar-ring-delayed" style="position: absolute; width: 110px; height: 110px; border-radius: 50%; border: 2px solid #a855f7; opacity: 0; animation: pulse-radar 2.8s cubic-bezier(0, 0, 0.2, 1) infinite; animation-delay: 1.4s;"></div>
            
            <!-- Dashed circular boundary ring -->
            <div style="position: absolute; width: 140px; height: 140px; border-radius: 50%; border: 1px dashed rgba(168, 85, 247, 0.25);"></div>
            
            <!-- Solid static accent rings -->
            <div style="position: absolute; width: 80px; height: 80px; border-radius: 50%; border: 1px solid rgba(168, 85, 247, 0.25);"></div>
            <div style="position: absolute; width: 180px; height: 180px; border-radius: 50%; border: 1px solid rgba(168, 85, 247, 0.12);"></div>

            <!-- Centered Floating Map Pin -->
            <div class="floating-pin" style="position: relative; z-index: 12; animation: subtle-float 2.5s ease-in-out infinite;">
              <svg xmlns="http://www.w3.org/2000/svg" width="38" height="38" viewBox="0 0 24 24" fill="rgba(168, 85, 247, 0.2)" stroke="#a855f7" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-map-pin"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
            </div>
            
            <style>
              @keyframes pulse-radar {
                0% { transform: scale(0.6); opacity: 0.8; }
                100% { transform: scale(2.5); opacity: 0; }
              }
              @keyframes subtle-float {
                0%, 100% { transform: translateY(0); }
                50% { transform: translateY(-5px); }
              }
            </style>
          `;

          this.container = div;
          const panes = this.getPanes();
          panes.overlayMouseTarget.appendChild(div);
        }

        draw() {
          if (!this.container) return;
          const projection = this.getProjection();
          if (!projection) return;
          const positionPixel = projection.fromLatLngToDivPixel(this.pos);
          if (!positionPixel) return;

          this.container.style.left = positionPixel.x + 'px';
          this.container.style.top = positionPixel.y + 'px';
        }

        onRemove() {
          if (this.container && this.container.parentNode) {
            this.container.parentNode.removeChild(this.container);
            this.container = null;
          }
        }
      }

      const activeOverlay = new GeofenceRadarOverlay(new win.google.maps.LatLng(lat, lng));
      activeOverlay.setMap(mapRef.current);

      // Clean up overlay when coords update or component unmounts
      return () => {
        activeOverlay.setMap(null);
      };
    }
  }, [isMapReady, form.latitude, form.longitude]);

  const handleRecenterMap = () => {
    const lat = parseFloat(form.latitude) || 0;
    const lng = parseFloat(form.longitude) || 0;
    if (mapRef.current && lat !== 0 && lng !== 0) {
      mapRef.current.panTo({ lat, lng });
      mapRef.current.setZoom(15);
    }
  };

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

  useEffect(() => {
    if (shop?.deactivateReason) {
      setShowDeactivateReason(true);
      const timer = setTimeout(() => setShowDeactivateReason(false), 10000);
      return () => clearTimeout(timer);
    }
  }, [shop?.deactivateReason]);

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
      updateField('shopProfileImage', coverImage || '');
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
    updateField('shopProfileImage', '');
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
      if (form.notificationRadius.trim()) {
        const radiusVal = Number(form.notificationRadius);
        if (Number.isNaN(radiusVal) || radiusVal <= 0) {
          throw new Error('Notification radius must be a valid number greater than zero.');
        }
      }

      const payload = {
        name: form.name.trim(),
        description: form.description.trim() || null,
        address: form.address.trim() || null,
        phoneNumber: form.phoneNumber.trim() || null,
        email: form.email.trim() || null,
        shopProfileImage: form.shopProfileImage || null,
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
    <div className="animate-fade-in" style={{ paddingBottom: '3rem' }}>
      
      {/* CSS Embedded Styles mimicking Admin Side */}
      <style dangerouslySetInnerHTML={{ __html: `
        @keyframes custom-ping {
          0% { transform: scale(1); opacity: 1; }
          100% { transform: scale(2.2); opacity: 0; }
        }
        .pulsing-dot-ring {
          animation: custom-ping 1.8s cubic-bezier(0, 0, 0.2, 1) infinite;
        }
        .gallery-thumbnail:hover img {
          transform: scale(1.06);
          filter: brightness(0.85);
        }
        .gallery-thumbnail:hover .gallery-overlay {
          opacity: 1 !important;
        }
        .chip-item:hover {
          transform: translateY(-2px);
          border-color: rgba(168, 85, 247, 0.4) !important;
          box-shadow: 0 4px 12px rgba(168, 85, 247, 0.06);
        }
        .tag-item:hover {
          transform: translateY(-2px);
          border-color: rgba(99, 102, 241, 0.4) !important;
          box-shadow: 0 4px 12px rgba(99, 102, 241, 0.06);
        }
        .keeper-input {
          width: 100%;
          padding: 0.85rem 1rem;
          border-radius: 12px;
          border: 1px solid rgba(148, 163, 184, 0.2);
          background: rgba(0, 0, 0, 0.15);
          color: hsl(var(--foreground));
          outline: none;
          font-weight: 500;
          font-size: 0.95rem;
          transition: all 0.2s ease;
          box-shadow: inset 0 2px 4px rgba(0,0,0,0.05);
        }
        .keeper-input:focus {
          border-color: hsl(var(--primary));
          background: rgba(0, 0, 0, 0.25);
          box-shadow: inset 0 2px 4px rgba(0,0,0,0.05), 0 0 0 3px rgba(99, 102, 241, 0.15);
        }
        .keeper-input:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }
        .metric-icon-box {
          padding: 0.7rem;
          border-radius: 12px;
          background: rgba(99, 102, 241, 0.1);
          color: hsl(var(--primary));
          display: flex;
          align-items: center;
          justify-content: center;
        }
      `}} />

      {error ? <InlineNotice tone="error" message={error} /> : null}
      {String(shop?.verifyStatus || '').toLowerCase() === 'rejected' && shop?.rejectionReason ? <InlineNotice tone="error" message={`Review feedback: ${shop.rejectionReason}`} /> : null}
      {String(shop?.verifyStatus || '').toLowerCase() === 'deactivated' && shop?.deactivateReason && showDeactivateReason ? <InlineNotice tone="info" message={`Listing note: ${shop.deactivateReason}`} /> : null}

      <form onSubmit={handleSubmit}>
        {/* Top Header Controls */}
        <div style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '1rem', marginTop: '1rem' }}>
          <div>
            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              {isEditing ? 'Shop Editor Workspace' : 'New Shop Creation'}
            </p>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 800, letterSpacing: '-0.02em' }}>
              {isEditing ? 'Manage Shop Details' : 'Create New Shop'}
            </h1>
          </div>
          
          <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
            {isEditing && (String(shop?.verifyStatus || '').toLowerCase() === 'rejected' || String(shop?.verifyStatus || '').toLowerCase() === 'deactivated') ? (
              <button type="button" className="button-secondary" onClick={() => void handleReapply()} disabled={reapplying || syncing}>
                <Send size={16} />
                {reapplying ? 'Reapplying...' : 'Reapply'}
              </button>
            ) : null}
            {isEditing && (
              <button type="button" className="button-ghost" onClick={() => void handleGoogleSync()} disabled={syncing || reapplying}>
                <RefreshCw size={16} />
                {syncing ? 'Syncing...' : 'Google sync'}
              </button>
            )}
            <button type="submit" className="button" disabled={loading || saving || uploadingCover || uploadingGallery} style={{ background: 'linear-gradient(135deg, hsl(var(--primary)) 0%, #a855f7 100%)', border: 'none', boxShadow: '0 4px 14px rgba(139, 92, 246, 0.3)' }}>
              <Save size={16} />
              {saving ? 'Saving...' : isEditing ? 'Save Changes' : 'Create Shop'}
            </button>
          </div>
        </div>

        {/* 2-Column Responsive Layout */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr minmax(320px, 360px)', gap: '2rem' }}>
          
          {/* Main Content Area */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            
            {/* Header Profile Glass Card */}
            <div className="glass-card" style={{ padding: '2rem', overflow: 'hidden', position: 'relative', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
              {/* Premium Gradient Hero Cover Banner */}
              <div style={{
                height: '140px',
                margin: '-2rem -2rem 0 -2rem',
                background: 'linear-gradient(135deg, hsl(var(--primary)) 0%, #a855f7 100%)',
                position: 'relative',
                overflow: 'hidden'
              }}>
                <div style={{ position: 'absolute', top: '-40px', right: '-40px', width: '220px', height: '220px', borderRadius: '50%', background: 'rgba(255, 255, 255, 0.08)', filter: 'blur(30px)' }}></div>
                <div style={{ position: 'absolute', bottom: '-70px', left: '15%', width: '160px', height: '160px', borderRadius: '50%', background: 'rgba(255, 255, 255, 0.12)', filter: 'blur(20px)' }}></div>
                
                <label htmlFor="shopCoverImage" style={{ position: 'absolute', right: '1.5rem', top: '1.5rem', background: 'rgba(0,0,0,0.6)', border: '1px solid rgba(255,255,255,0.2)', color: 'white', padding: '0.5rem 1rem', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem', fontWeight: 600, backdropFilter: 'blur(4px)', transition: 'background 0.2s' }}>
                  <ImageIcon size={16} /> {uploadingCover ? 'Uploading...' : 'Change Cover'}
                  <input id="shopCoverImage" type="file" accept="image/*" onChange={handleCoverImageChange} disabled={loading || saving || uploadingCover} style={{ display: 'none' }} />
                </label>
              </div>

              {/* Overlapping Profile Info Wrapper */}
              <div style={{ display: 'flex', flexDirection: 'column', marginTop: '-70px', position: 'relative', zIndex: 2, paddingBottom: '1.5rem', borderBottom: '1px solid rgba(148, 163, 184, 0.15)' }}>
                <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
                  <div style={{ 
                    width: '130px', height: '130px', borderRadius: '24px', background: 'hsl(var(--card))', 
                    border: '4px solid hsl(var(--card))', boxShadow: '0 12px 28px rgba(0, 0, 0, 0.16)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden', flexShrink: 0
                  }}>
                    {form.shopProfileImage ? (
                      <img src={resolveMediaSource(form.shopProfileImage)} alt="Cover" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    ) : (
                      <Store size={54} color="hsl(var(--primary))" />
                    )}
                  </div>
                  
                  <div style={{ flex: 1, minWidth: '250px', paddingTop: '4.5rem' }}>
                    <div style={{ background: 'rgba(0,0,0,0.15)', borderRadius: '12px', border: '1px solid rgba(148,163,184,0.2)', padding: '0.2rem 0.5rem', marginBottom: '1rem' }}>
                      <input 
                        value={form.name} 
                        onChange={(event) => updateField('name', event.target.value)} 
                        disabled={loading || saving} 
                        required 
                        placeholder="Shop Name" 
                        style={{ width: '100%', fontSize: '1.75rem', fontWeight: 800, padding: '0.5rem', background: 'transparent', border: 'none', color: 'hsl(var(--foreground))', outline: 'none' }} 
                      />
                    </div>
                    
                    <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center', flexWrap: 'wrap' }}>
                      <StatusPill status={verificationStatusLabel} />
                      <StatusPill status={listingStatusLabel} />

                      {/* Pulsing Open Now Toggle */}
                      <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', background: form.isOpen ? 'rgba(16, 185, 129, 0.08)' : 'rgba(245, 158, 11, 0.08)', padding: '0.4rem 0.85rem', borderRadius: '30px', border: form.isOpen ? '1px solid rgba(16, 185, 129, 0.2)' : '1px solid rgba(245, 158, 11, 0.2)', transition: 'all 0.2s' }}>
                        <input type="checkbox" checked={form.isOpen} onChange={(event) => updateField('isOpen', event.target.checked)} disabled={loading || saving} style={{ display: 'none' }} />
                        <span style={{ position: 'relative', display: 'flex', height: '8px', width: '8px' }}>
                          <span className={form.isOpen ? 'pulsing-dot-ring' : ''} style={{ position: 'absolute', display: 'inline-flex', height: '100%', width: '100%', borderRadius: '50%', backgroundColor: form.isOpen ? '#10b981' : '#f59e0b', opacity: 0.75 }}></span>
                          <span style={{ position: 'relative', display: 'inline-flex', borderRadius: '50%', height: '8px', width: '8px', backgroundColor: form.isOpen ? '#10b981' : '#f59e0b' }}></span>
                        </span>
                        <span style={{ fontSize: '0.75rem', fontWeight: 700, color: form.isOpen ? '#10b981' : '#f59e0b', textTransform: 'uppercase', letterSpacing: '0.03em' }}>
                          {form.isOpen ? 'Set Closed' : 'Set Open'}
                        </span>
                      </label>
                    </div>
                  </div>
                </div>
              </div>

              {/* Grid Contact Metrics Editable */}
              <div style={{ marginTop: '1.75rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1.5rem' }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.75rem' }}>
                  <div className="metric-icon-box"><MapPin size={20} /></div>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, display: 'block', marginBottom: '0.4rem' }}>
                      Location Address
                    </label>
                    <input value={form.address} onChange={(event) => updateField('address', event.target.value)} disabled={loading || saving} required placeholder="123 Main St..." className="keeper-input" />
                  </div>
                </div>
                
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.75rem' }}>
                  <div className="metric-icon-box"><Phone size={20} /></div>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, display: 'block', marginBottom: '0.4rem' }}>
                      Phone Number
                    </label>
                    <input value={form.phoneNumber} onChange={(event) => updateField('phoneNumber', event.target.value)} disabled={loading || saving} placeholder="+1 (555) 000-0000" className="keeper-input" />
                  </div>
                </div>
                
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.75rem' }}>
                  <div className="metric-icon-box"><Info size={20} /></div>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, display: 'block', marginBottom: '0.4rem' }}>
                      Email Address
                    </label>
                    <input type="email" value={form.email} onChange={(event) => updateField('email', event.target.value)} disabled={loading || saving} placeholder="hello@shop.com" className="keeper-input" />
                  </div>
                </div>
                
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.75rem' }}>
                  <div className="metric-icon-box"><Tag size={20} /></div>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, display: 'block', marginBottom: '0.4rem' }}>
                      Primary Category
                    </label>
                    <div style={{ position: 'relative' }}>
                      <CustomSelect
                        value={form.categoryId}
                        onChange={(val) => updateField('categoryId', val)}
                        options={[
                          { value: '', label: 'Select a category', icon: <Tag size={16} /> },
                          ...categoryOptions.map(category => ({
                            value: category.id,
                            label: category.label,
                            icon: <Tag size={16} />
                          }))
                        ]}
                        style={{ width: '100%' }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* About Business Card */}
            <div className="glass-card" style={{ padding: '2rem', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                <Info size={20} color="hsl(var(--primary))" /> About Business
              </h3>
              <textarea 
                value={form.description} 
                onChange={(event) => updateField('description', event.target.value)} 
                disabled={loading || saving} 
                placeholder="Describe your shop to attract customers... What makes it special?" 
                className="keeper-input" 
                style={{ minHeight: '140px', resize: 'vertical', lineHeight: 1.6 }} 
              />
            </div>

            {/* Amenities & Tags */}
            <div className="glass-card" style={{ padding: '2rem', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '2.5rem' }}>
                
                {/* Amenities Column */}
                <div>
                  <h3 style={{ fontSize: '1.125rem', fontWeight: 800, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                    <AlertCircle size={18} color="#10b981" /> Services & Amenities
                  </h3>
                  <input
                    value={form.amenities}
                    onChange={(event) => updateField('amenities', event.target.value)}
                    disabled={loading || saving}
                    placeholder="e.g. wifi, parking, seating..."
                    className="keeper-input"
                  />
                  <p className="muted-text" style={{ marginTop: '0.75rem', fontSize: '0.8rem' }}>Separate amenities with commas to display them as chips.</p>
                </div>

                {/* Search Tags Column */}
                <div>
                  <h3 style={{ fontSize: '1.125rem', fontWeight: 800, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                    <Tag size={18} color="hsl(var(--primary))" /> Search Tags
                  </h3>
                  <div className="keeper-input" style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem', padding: '0.75rem', cursor: 'text', minHeight: '100px', alignItems: 'flex-start', alignContent: 'flex-start' }} onClick={() => document.getElementById('shopTags')?.focus()}>
                    {selectedTags.map((tag, index) => (
                      <span key={`${tag}-${index}`} className="tag-item" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', background: 'rgba(99, 102, 241, 0.1)', border: '1px solid rgba(99, 102, 241, 0.2)', borderRadius: '30px', padding: '0.35rem 0.75rem', fontSize: '0.8rem', fontWeight: 600, color: 'hsl(var(--primary))' }}>
                        <span style={{ color: 'rgba(99, 102, 241, 0.7)' }}>#</span>{tag}
                        <button type="button" onClick={(e) => { e.stopPropagation(); handleRemoveTag(tag); }} style={{ background: 'none', border: 'none', color: 'inherit', cursor: 'pointer', fontSize: '1.1rem', lineHeight: 1 }}>&times;</button>
                      </span>
                    ))}
                    <input
                      id="shopTags"
                      value={tagInputValue}
                      onChange={(event) => setTagInputValue(event.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ',') { e.preventDefault(); if (tagInputValue.trim()) { handleAddTag(tagInputValue.trim()); setTagInputValue(''); } }
                        else if (e.key === 'Backspace' && !tagInputValue && selectedTags.length > 0) { handleRemoveTag(selectedTags[selectedTags.length - 1]); }
                      }}
                      onBlur={() => { if (tagInputValue.trim()) { handleAddTag(tagInputValue.trim()); setTagInputValue(''); } }}
                      disabled={loading || saving}
                      placeholder={selectedTags.length === 0 ? "Type and press Enter..." : ""}
                      style={{ flex: 1, minWidth: '120px', border: 'none', background: 'transparent', outline: 'none', color: 'hsl(var(--foreground))', fontSize: '0.9rem', marginTop: '0.2rem' }}
                    />
                  </div>
                  {availableTagsToDisplay.length > 0 ? (
                    <div style={{ marginTop: '1rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                      {availableTagsToDisplay.slice(0, 8).map((tag) => (
                        <button key={tag.tagId} type="button" onClick={() => handleAddTag(tag.name)} style={{ padding: '0.25rem 0.75rem', fontSize: '0.75rem', fontWeight: 600, borderRadius: '999px', border: '1px solid rgba(148, 163, 184, 0.3)', background: 'transparent', color: 'hsl(var(--muted-foreground))', cursor: 'pointer', transition: 'all 0.2s' }} className="tag-item">
                          + {tag.name}
                        </button>
                      ))}
                    </div>
                  ) : null}
                </div>
              </div>
            </div>

            {/* Shop Media Gallery Section */}
            <div className="glass-card" style={{ padding: '2rem', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '1rem' }}>
                <h3 style={{ fontSize: '1.25rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                  <ImageIcon size={20} color="hsl(var(--primary))" /> Shop Media Gallery ({form.shopImages.length})
                </h3>
                <label className="button-secondary" style={{ padding: '0.6rem 1.25rem', fontSize: '0.85rem', cursor: 'pointer', display: 'flex', gap: '0.5rem', alignItems: 'center', borderRadius: '12px' }}>
                  <ImageIcon size={16} /> {uploadingGallery ? 'Uploading...' : 'Add Photos'}
                  <input type="file" accept="image/*" multiple onChange={handleGalleryImagesChange} disabled={loading || saving || uploadingGallery} style={{ display: 'none' }} />
                </label>
              </div>
              
              {form.shopImages.length > 0 ? (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: '1.25rem' }}>
                  {form.shopImages.map((image, idx) => (
                    <div key={idx} className="gallery-thumbnail" style={{ position: 'relative', height: '140px', borderRadius: '16px', overflow: 'hidden', border: '1px solid hsl(var(--border))', background: 'rgba(0,0,0,0.2)', boxShadow: '0 4px 10px rgba(0,0,0,0.1)', transition: 'all 0.25s ease' }}>
                      <img src={resolveMediaSource(image)} alt={`Gallery ${idx}`} style={{ width: '100%', height: '100%', objectFit: 'cover', transition: 'transform 0.3s ease, filter 0.3s ease' }} />
                      <div className="gallery-overlay" style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0, 0, 0, 0.5)', backdropFilter: 'blur(3px)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '1rem', opacity: 0, transition: 'opacity 0.25s ease' }}>
                        <button type="button" onClick={() => openImagePreview(image)} style={{ background: 'rgba(255,255,255,0.2)', border: 'none', borderRadius: '50%', width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', cursor: 'pointer', backdropFilter: 'blur(4px)' }}><ImageIcon size={18} /></button>
                        <button type="button" onClick={() => removeGalleryImage(idx)} style={{ background: 'rgba(239,68,68,0.5)', border: 'none', borderRadius: '50%', width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', cursor: 'pointer', backdropFilter: 'blur(4px)' }}><AlertCircle size={18} /></button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ textAlign: 'center', padding: '4rem 2rem', border: '2px dashed rgba(148, 163, 184, 0.2)', borderRadius: '16px', background: 'rgba(0,0,0,0.05)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '1rem' }}>
                  <ImageIcon size={48} color="hsl(var(--muted-foreground))" style={{ opacity: 0.5 }} />
                  <div>
                    <h4 style={{ fontWeight: 800, fontSize: '1.05rem', color: 'hsl(var(--foreground))' }}>No Gallery Images</h4>
                    <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.85rem', marginTop: '0.25rem' }}>Upload storefront, interior, or product photos to attract customers.</p>
                  </div>
                </div>
              )}
            </div>

          </div>

          {/* Sidebar Area */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            
            {/* Styled Location & Geofence Card */}
            <div className="glass-card" style={{ padding: '2rem', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
              <h3 style={{ fontSize: '1.125rem', fontWeight: 800, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                <MapPin size={20} color="hsl(var(--primary))" /> Location & Geofence
              </h3>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>

                {/* Real Google Map with Overlaid Animated Radar Marker */}
                <div style={{ 
                  position: 'relative', 
                  height: '220px', 
                  width: '100%', 
                  marginBottom: '0.5rem', 
                  borderRadius: 'var(--radius)', 
                  overflow: 'hidden', 
                  border: '1px solid hsl(var(--border))',
                  background: 'hsl(var(--card))'
                }}>
                  {/* Google Map Div */}
                  <div 
                    ref={mapContainerRef} 
                    style={{ width: '100%', height: '100%' }}
                  />

                  {!isMapReady && (
                    <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'hsl(var(--muted-foreground))', fontSize: '0.85rem', fontWeight: 600, background: 'hsl(var(--card))' }}>
                      Loading Map View...
                    </div>
                  )}

                  {/* Recenter Control Button */}
                  {isMapReady && form.latitude && form.longitude && (
                    <button
                      type="button"
                      onClick={handleRecenterMap}
                      style={{
                        position: 'absolute', bottom: '0.75rem', right: '0.75rem',
                        background: 'rgba(15, 23, 42, 0.85)', border: '1px solid var(--glass-border)',
                        borderRadius: '8px', padding: '0.4rem 0.75rem', color: 'white',
                        fontSize: '0.75rem', fontWeight: 600, display: 'flex', alignItems: 'center',
                        gap: '0.25rem', backdropFilter: 'blur(4px)', cursor: 'pointer', zIndex: 15,
                        boxShadow: '0 4px 12px rgba(0,0,0,0.25)'
                      }}
                      className="copy-btn"
                    >
                      <Compass size={12} /> Recenter
                    </button>
                  )}
                </div>

                <div>
                  <label style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, display: 'block', marginBottom: '0.4rem' }}>Latitude</label>
                  <input value={form.latitude} onChange={(event) => updateField('latitude', event.target.value)} disabled={loading || saving} placeholder="e.g. 40.7128" className="keeper-input" style={{ fontFamily: 'monospace' }} />
                </div>
                <div>
                  <label style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, display: 'block', marginBottom: '0.4rem' }}>Longitude</label>
                  <input value={form.longitude} onChange={(event) => updateField('longitude', event.target.value)} disabled={loading || saving} placeholder="e.g. -74.0060" className="keeper-input" style={{ fontFamily: 'monospace' }} />
                </div>
                
                {/* Geofence Alert Radius */}
                <div style={{ background: 'rgba(168, 85, 247, 0.05)', border: '1px solid rgba(168, 85, 247, 0.15)', borderRadius: '16px', padding: '1.25rem', marginTop: '0.5rem' }}>
                  <label style={{ fontSize: '0.75rem', color: 'hsl(var(--primary))', fontWeight: 700, display: 'block', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.75rem' }}>Alert Radius (km)</label>
                  <input
                    type="number" min="0.1" step="0.1"
                    value={form.notificationRadius}
                    onChange={(event) => updateField('notificationRadius', event.target.value)}
                    disabled={loading || saving}
                    className="keeper-input"
                    style={{ background: 'rgba(0,0,0,0.2)', border: '1px solid rgba(168, 85, 247, 0.2)', fontWeight: 800, color: 'white', fontSize: '1.1rem' }}
                  />
                  <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.75rem', lineHeight: 1.4 }}>
                    Defines the circular geofence boundary around your shop. Users entering this zone will receive notifications about your active offers.
                  </p>
                </div>
              </div>
            </div>

          </div>
        </div>
      </form>

      {/* Lightbox / Modals */}
      {activePreviewImage ? (
        <div className="media-lightbox" onClick={closeImagePreview} style={{ zIndex: 9999 }}>
          <div className="media-lightbox-content" onClick={(e) => e.stopPropagation()}>
            <button type="button" className="media-lightbox-close" onClick={closeImagePreview}>&times;</button>
            <img src={activePreviewImage} alt="Enlarged preview" className="media-lightbox-image" />
          </div>
        </div>
      ) : null}
    </div>
  );
}
