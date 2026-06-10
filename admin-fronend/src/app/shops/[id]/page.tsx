'use client';

import React, { useEffect, useState, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { 
  Store, MapPin, Phone, Mail, User, Tag, Calendar, 
  ChevronLeft, BadgeCheck, ShieldAlert, CheckCircle2, XCircle,
  ExternalLink, Info, Map as MapIcon, Image as ImageIcon,
  Clock, Check, Copy, Compass, X
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';

interface Offer {
  offerId: string;
  title: string;
  status: string;
  endDate: string;
}

interface ShopDetails {
  shopId: string;
  name: string;
  description: string;
  address: string;
  phoneNumber: string;
  email: string;
  categoryId?: string | null;
  keeperBusinessName?: string | null;
  keeperName?: string | null;
  keeperId: string;
  keeperUserId: string;
  latitude: number;
  longitude: number;
  shopProfileImage: string;
  shopImages: string[];
  tags: string[];
  amenities: string[];
  categoryName: string;
  isOpen: boolean;
  notificationRadius: number;
  isVerified: boolean;
  verifyStatus: string;
  isActive: boolean;
  createdAt: string;
  recentOffers: Offer[];
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

// Sleek dark-indigo style array for a futuristic premium mapping display matching the admin visual design
const darkMapStyle = [
  { elementType: "geometry", stylers: [{ color: "#0b0f19" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#0b0f19" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#4b5563" }] },
  {
    featureType: "administrative.locality",
    elementType: "labels.text.fill",
    stylers: [{ color: "#a855f7" }]
  },
  {
    featureType: "poi",
    elementType: "labels.text.fill",
    stylers: [{ color: "#9ca3af" }]
  },
  {
    featureType: "poi.park",
    elementType: "geometry",
    stylers: [{ color: "#111827" }]
  },
  {
    featureType: "poi.park",
    elementType: "labels.text.fill",
    stylers: [{ color: "#374151" }]
  },
  {
    featureType: "road",
    elementType: "geometry",
    stylers: [{ color: "#1f2937" }]
  },
  {
    featureType: "road",
    elementType: "geometry.stroke",
    stylers: [{ color: "#374151" }]
  },
  {
    featureType: "road",
    elementType: "labels.text.fill",
    stylers: [{ color: "#4b5563" }]
  },
  {
    featureType: "road.highway",
    elementType: "geometry",
    stylers: [{ color: "#312e81" }]
  },
  {
    featureType: "road.highway",
    elementType: "geometry.stroke",
    stylers: [{ color: "#4338ca" }]
  },
  {
    featureType: "road.highway",
    elementType: "labels.text.fill",
    stylers: [{ color: "#9ca3af" }]
  },
  {
    featureType: "transit",
    elementType: "geometry",
    stylers: [{ color: "#111827" }]
  },
  {
    featureType: "transit.station",
    elementType: "labels.text.fill",
    stylers: [{ color: "#a855f7" }]
  },
  {
    featureType: "water",
    elementType: "geometry",
    stylers: [{ color: "#030712" }]
  },
  {
    featureType: "water",
    elementType: "labels.text.fill",
    stylers: [{ color: "#1f2937" }]
  },
  {
    featureType: "water",
    elementType: "labels.text.stroke",
    stylers: [{ color: "#030712" }]
  }
];

export default function ShopDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const { hasPermission } = useAuth();
  const [shop, setShop] = useState<ShopDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeLightboxImage, setActiveLightboxImage] = useState<string | null>(null);
  const [copiedCoords, setCopiedCoords] = useState(false);
  type ActionType = 'verify' | 'reject' | 'activate' | 'deactivate' | null;
  const [activeAction, setActiveAction] = useState<ActionType>(null);
  const [actionReason, setActionReason] = useState('');
  const [submittingAction, setSubmittingAction] = useState(false);
  
  // Real Map Integration References & State
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<any>(null);
  const [isMapReady, setIsMapReady] = useState(false);

  const fetchShopDetails = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get(`/admin/shops/${params.id}`);
      setShop(response.data.data);
    } catch (err) {
      console.error('Failed to fetch shop details', err);
      const message = getApiErrorMessage(err, 'Failed to load shop details.');
      setError(message);
      setToast(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (params.id) {
      fetchShopDetails();
    }
  }, [params.id]);

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
        const win = window as any;
        win.gm_authFailure = () => {
          setToast('Google Maps API quota exceeded. Please upgrade your API key.');
        };
      })
      .catch((err: any) => {
        console.error('Failed to load Google Maps library:', err);
      });
  }, []);

  // Initialize Map and bind custom animated Overlay
  useEffect(() => {
    const win = window as any;
    if (!isMapReady || !mapContainerRef.current || !win.google?.maps || !shop) {
      return;
    }

    if (shop.latitude != null && shop.longitude != null) {
      const position = { lat: shop.latitude, lng: shop.longitude };

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
            <div class="radar-ring" style="position: absolute; width: 110px; height: 110px; border-radius: 50%; border: 2px solid #a855f7; opacity: 0;"></div>
            <div class="radar-ring-delayed" style="position: absolute; width: 110px; height: 110px; border-radius: 50%; border: 2px solid #a855f7; opacity: 0;"></div>
            
            <!-- Dashed circular boundary ring -->
            <div style="position: absolute; width: 140px; height: 140px; border-radius: 50%; border: 1px dashed rgba(168, 85, 247, 0.25);"></div>
            
            <!-- Solid static accent rings -->
            <div style="position: absolute; width: 80px; height: 80px; border-radius: 50%; border: 1px solid rgba(168, 85, 247, 0.25);"></div>
            <div style="position: absolute; width: 180px; height: 180px; border-radius: 50%; border: 1px solid rgba(168, 85, 247, 0.12);"></div>

            <!-- Centered Floating Map Pin -->
            <div class="floating-pin" style="position: relative; z-index: 12;">
              <svg xmlns="http://www.w3.org/2000/svg" width="38" height="38" viewBox="0 0 24 24" fill="rgba(168, 85, 247, 0.2)" stroke="#a855f7" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-map-pin"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
            </div>
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

      const activeOverlay = new GeofenceRadarOverlay(new win.google.maps.LatLng(shop.latitude, shop.longitude));
      activeOverlay.setMap(mapRef.current);

      // Clean up overlay when coords update or component unmounts
      return () => {
        activeOverlay.setMap(null);
      };
    }
  }, [isMapReady, shop?.latitude, shop?.longitude]);

  const handleRecenterMap = () => {
    if (mapRef.current && shop?.latitude != null && shop?.longitude != null) {
      mapRef.current.panTo({ lat: shop.latitude, lng: shop.longitude });
      mapRef.current.setZoom(15);
    }
  };

  const handleUpdateStatus = async (nextIsActive: boolean, reason?: string) => {
    setSubmittingAction(true);
    try {
      await api.put(`/admin/shops/${params.id}/status`, { 
        isActive: nextIsActive,
        reason: reason?.trim() || undefined
      });
      setToast(`Shop ${nextIsActive ? 'activated' : 'deactivated'} successfully`);
      setTimeout(() => setToast(null), 3000);
      setActiveAction(null);
      setActionReason('');
      fetchShopDetails();
    } catch (err) {
      const message = getApiErrorMessage(err, 'Failed to update status.');
      setError(message);
      setToast(message);
      setTimeout(() => setToast(null), 3000);
    } finally {
      setSubmittingAction(false);
    }
  };

  const handleVerifyAction = async (isVerify: boolean, reason?: string) => {
    setSubmittingAction(true);
    try {
      if (isVerify) {
        await api.post(`/admin/shops/${params.id}/verify`, { reason: reason?.trim() || undefined });
        setToast('Shop verified successfully');
      } else {
        await api.post(`/admin/shops/${params.id}/reject`, { reason: reason?.trim() || '' });
        setToast('Shop rejected successfully');
      }
      setTimeout(() => setToast(null), 3000);
      setActiveAction(null);
      setActionReason('');
      fetchShopDetails();
    } catch (err) {
      const message = getApiErrorMessage(err, `Failed to ${isVerify ? 'verify' : 'reject'} shop.`);
      setError(message);
      setToast(message);
      setTimeout(() => setToast(null), 3000);
    } finally {
      setSubmittingAction(false);
    }
  };

  const handleCopyCoords = () => {
    if (shop?.latitude != null && shop?.longitude != null) {
      const coords = `${shop.latitude}, ${shop.longitude}`;
      navigator.clipboard.writeText(coords);
      setCopiedCoords(true);
      setToast('Coordinates copied to clipboard!');
      setTimeout(() => {
        setCopiedCoords(false);
        setToast(null);
      }, 2000);
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex-center" style={{ height: '60vh', flexDirection: 'column' }}>
          <div className="loader"></div>
          <p style={{ marginTop: '1rem', color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>
            Loading shop details...
          </p>
        </div>
      </DashboardLayout>
    );
  }

  if (!shop) {
    return (
      <DashboardLayout>
        <div className="flex-center" style={{ height: '60vh', flexDirection: 'column', gap: '1rem' }}>
          <ShieldAlert size={56} color="#ef4444" />
          <h2 style={{ fontSize: '1.5rem', fontWeight: 700 }}>Shop Not Found</h2>
          <p style={{ color: 'hsl(var(--muted-foreground))' }}>The requested shop listing does not exist or has been removed.</p>
          <button 
            onClick={() => router.push('/shops')}
            className="btn-primary"
            style={{ marginTop: '0.5rem', padding: '0.625rem 1.25rem' }}
          >
            Back to Shops
          </button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <>
      <DashboardLayout>
      <div className="animate-fade-in" style={{ paddingBottom: '3rem' }}>
        
        {/* CSS Embedded Styles */}
        <style dangerouslySetInnerHTML={{ __html: `
          @keyframes custom-ping {
            0% { transform: scale(1); opacity: 1; }
            100% { transform: scale(2.2); opacity: 0; }
          }
          @keyframes pulse-radar {
            0% { transform: scale(0.6); opacity: 0.8; }
            100% { transform: scale(2.5); opacity: 0; }
          }
          @keyframes subtle-float {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-5px); }
          }
          .pulsing-dot-ring {
            animation: custom-ping 1.8s cubic-bezier(0, 0, 0.2, 1) infinite;
          }
          .radar-ring {
            animation: pulse-radar 2.8s cubic-bezier(0, 0, 0.2, 1) infinite;
          }
          .radar-ring-delayed {
            animation: pulse-radar 2.8s cubic-bezier(0, 0, 0.2, 1) infinite;
            animation-delay: 1.4s;
          }
          .floating-pin {
            animation: subtle-float 2.5s ease-in-out infinite;
          }
          .gallery-thumbnail:hover img {
            transform: scale(1.06);
            filter: brightness(0.85);
          }
          .gallery-thumbnail:hover .gallery-overlay {
            opacity: 1 !important;
          }
          .copy-btn:hover {
            background: rgba(255, 255, 255, 0.08) !important;
            color: hsl(var(--primary)) !important;
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
        `}} />

        {/* Toast */}
        <AnimatePresence>
          {toast && (
            <motion.div 
              initial={{ opacity: 0, y: -20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -20, scale: 0.95 }}
              style={{
                position: 'fixed', top: '1.5rem', right: '1.5rem', zIndex: 1100,
                padding: '0.85rem 1.5rem', borderRadius: 'var(--radius)',
                background: toast.includes('Failed') ? 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)' : 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                color: 'white', fontWeight: 600, fontSize: '0.875rem',
                boxShadow: '0 10px 25px rgba(0,0,0,0.25)',
                display: 'flex', alignItems: 'center', gap: '0.5rem',
                border: '1px solid rgba(255, 255, 255, 0.1)'
              }}
            >
              {toast.includes('Failed') ? <XCircle size={18} /> : <CheckCircle2 size={18} />}
              {toast}
            </motion.div>
          )}
        </AnimatePresence>

        {/* Top Header Controls */}
        <div style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <button 
              onClick={() => router.push('/shops')}
              style={{ 
                padding: '0.6rem', borderRadius: '50%', background: 'var(--glass)', 
                border: '1px solid var(--glass-border)', cursor: 'pointer', display: 'flex', 
                alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--glass-shadow)'
              }}
            >
              <ChevronLeft size={20} />
            </button>
            <div>
              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Directory Listing</p>
              <h1 style={{ fontSize: '1.75rem', fontWeight: 800, letterSpacing: '-0.02em' }}>Shop Details</h1>
            </div>
          </div>
          <button 
            onClick={() => router.push('/shops')}
            className="btn-outline"
            style={{ fontSize: '0.875rem', padding: '0.5rem 1rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}
          >
            Back to Directory
          </button>
        </div>

        {error && (
          <div style={{ marginBottom: '1.5rem', padding: '1rem 1.25rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', color: '#ef4444', fontSize: '0.875rem', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <ShieldAlert size={18} />
            {error}
          </div>
        )}

        {/* 2-Column Responsive Layout */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 360px', gap: '2rem' }}>
          
          {/* Main Content Area */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            
            {/* Header Profile Glass Card */}
            <motion.div 
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              className="glass-card" 
              style={{ padding: '2rem', overflow: 'hidden', position: 'relative' }}
            >
              {/* Premium Gradient Hero Cover Banner */}
              <div style={{
                height: '140px',
                margin: '-2rem -2rem 0 -2rem',
                background: 'linear-gradient(135deg, hsl(var(--primary)) 0%, #a855f7 100%)',
                borderRadius: 'var(--radius) var(--radius) 0 0',
                position: 'relative',
                overflow: 'hidden'
              }}>
                <div style={{ position: 'absolute', top: '-40px', right: '-40px', width: '220px', height: '220px', borderRadius: '50%', background: 'rgba(255, 255, 255, 0.08)', filter: 'blur(30px)' }}></div>
                <div style={{ position: 'absolute', bottom: '-70px', left: '15%', width: '160px', height: '160px', borderRadius: '50%', background: 'rgba(255, 255, 255, 0.12)', filter: 'blur(20px)' }}></div>
              </div>

              {/* Overlapping Profile Info Wrapper */}
              <div style={{ 
                display: 'flex', 
                flexDirection: 'column', 
                marginTop: '-70px', 
                position: 'relative', 
                zIndex: 2, 
                paddingBottom: '1.5rem',
                borderBottom: '1px solid hsl(var(--border))'
              }}>
                <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
                  <div style={{ 
                    width: '130px', 
                    height: '130px', 
                    borderRadius: '24px', 
                    background: 'hsl(var(--card))', 
                    border: '4px solid hsl(var(--card))',
                    boxShadow: '0 12px 28px rgba(0, 0, 0, 0.16)',
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'center', 
                    overflow: 'hidden',
                    flexShrink: 0
                  }}>
                    {shop.shopProfileImage ? (
                      <img src={shop.shopProfileImage} alt={shop.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    ) : (
                      <Store size={54} color="hsl(var(--primary))" />
                    )}
                  </div>
                  
                  <div style={{ flex: 1, minWidth: '250px', paddingTop: '5rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1.5rem' }}>
                      <div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap', marginBottom: '0.5rem' }}>
                          <h2 style={{ fontSize: '2.25rem', fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1.1 }}>{shop.name}</h2>
                          {shop.verifyStatus === 'Verified' && (
                            <span style={{ 
                              display: 'inline-flex', alignItems: 'center', gap: '0.25rem',
                              background: 'linear-gradient(135deg, rgba(16, 185, 129, 0.08) 0%, rgba(5, 150, 105, 0.08) 100%)',
                              color: '#10b981', fontSize: '0.75rem', fontWeight: 700, padding: '0.35rem 0.75rem', borderRadius: '30px',
                              border: '1px solid rgba(16, 185, 129, 0.2)'
                            }}>
                              <BadgeCheck size={14} /> VERIFIED PARTNER
                            </span>
                          )}
                        </div>
                        
                        <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center', flexWrap: 'wrap' }}>
                          <span style={{ 
                            padding: '0.35rem 0.75rem', borderRadius: '30px', fontSize: '0.725rem', fontWeight: 700,
                            background: shop.isActive ? 'rgba(16, 185, 129, 0.08)' : 'rgba(239, 68, 68, 0.08)',
                            color: shop.isActive ? '#10b981' : '#ef4444',
                            border: shop.isActive ? '1px solid rgba(16, 185, 129, 0.15)' : '1px solid rgba(239, 68, 68, 0.15)',
                            letterSpacing: '0.05em'
                          }}>
                            {shop.isActive ? 'ACTIVE IN DIRECTORY' : 'DEACTIVATED'}
                          </span>
                          
                          {/* Pulsing Open Now Indicator */}
                          {shop.isOpen ? (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', background: 'rgba(16, 185, 129, 0.08)', padding: '0.35rem 0.75rem', borderRadius: '30px', border: '1px solid rgba(16, 185, 129, 0.15)' }}>
                              <span style={{ position: 'relative', display: 'flex', height: '8px', width: '8px' }}>
                                <span className="pulsing-dot-ring" style={{ position: 'absolute', display: 'inline-flex', height: '100%', width: '100%', borderRadius: '50%', backgroundColor: '#10b981', opacity: 0.75 }}></span>
                                <span style={{ position: 'relative', display: 'inline-flex', borderRadius: '50%', height: '8px', width: '8px', backgroundColor: '#10b981' }}></span>
                              </span>
                              <span style={{ fontSize: '0.725rem', fontWeight: 700, color: '#10b981', textTransform: 'uppercase', letterSpacing: '0.03em' }}>Open Now</span>
                            </div>
                          ) : (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', background: 'rgba(245, 158, 11, 0.08)', padding: '0.35rem 0.75rem', borderRadius: '30px', border: '1px solid rgba(245, 158, 11, 0.15)' }}>
                              <span style={{ position: 'relative', display: 'flex', height: '8px', width: '8px' }}>
                                <span className="pulsing-dot-ring" style={{ position: 'absolute', display: 'inline-flex', height: '100%', width: '100%', borderRadius: '50%', backgroundColor: '#f59e0b', opacity: 0.75 }}></span>
                                <span style={{ position: 'relative', display: 'inline-flex', borderRadius: '50%', height: '8px', width: '8px', backgroundColor: '#f59e0b' }}></span>
                              </span>
                              <span style={{ fontSize: '0.725rem', fontWeight: 700, color: '#f59e0b', textTransform: 'uppercase', letterSpacing: '0.03em' }}>Closed</span>
                            </div>
                          )}
                        </div>
                      </div>
                      
                      {/* Action buttons */}
                      <div style={{ display: 'flex', gap: '1rem', marginBottom: '0.25rem', flexWrap: 'wrap' }}>
                        
                        {shop.verifyStatus === 'Pending' && hasPermission(PERMISSIONS.shopsApprove) && (
                          <div style={{ display: 'flex', gap: '0.5rem', background: 'rgba(255,255,255,0.03)', padding: '0.35rem', borderRadius: '12px', border: '1px solid hsl(var(--border))' }}>
                            <button 
                              onClick={() => setActiveAction('verify')} 
                              className="btn-primary" 
                              style={{ 
                                display: 'flex', alignItems: 'center', gap: '0.35rem',
                                background: '#10b981', borderColor: '#10b981', 
                                boxShadow: '0 4px 14px rgba(16, 185, 129, 0.25)', 
                                padding: '0.5rem 1rem', fontWeight: 600, fontSize: '0.875rem' 
                              }}
                            >
                              <BadgeCheck size={16} /> Approve
                            </button>
                            <button 
                              onClick={() => setActiveAction('reject')} 
                              className="btn-outline" 
                              style={{ 
                                display: 'flex', alignItems: 'center', gap: '0.35rem',
                                color: '#ef4444', borderColor: '#ef4444', background: 'transparent',
                                padding: '0.5rem 1rem', fontWeight: 600, fontSize: '0.875rem' 
                              }}
                            >
                              <XCircle size={16} /> Reject
                            </button>
                          </div>
                        )}

                        <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                          {shop.isActive ? (
                            hasPermission(PERMISSIONS.shopsApprove) && (
                              <button 
                                onClick={() => setActiveAction('deactivate')} 
                                className="btn-outline" 
                                style={{ 
                                  display: 'flex', alignItems: 'center', gap: '0.35rem',
                                  color: '#f59e0b', borderColor: '#f59e0b', 
                                  background: 'transparent', padding: '0.625rem 1.25rem', 
                                  fontWeight: 600, fontSize: '0.875rem' 
                                }}
                              >
                                <XCircle size={16} /> Deactivate Shop
                              </button>
                            )
                          ) : (
                            hasPermission(PERMISSIONS.shopsApprove) && (
                              <button 
                                onClick={() => setActiveAction('activate')} 
                                className="btn-primary" 
                                style={{ 
                                  display: 'flex', alignItems: 'center', gap: '0.35rem',
                                  background: '#3b82f6', borderColor: '#3b82f6', 
                                  boxShadow: '0 4px 14px rgba(59, 130, 246, 0.25)', 
                                  padding: '0.625rem 1.25rem', fontWeight: 600, fontSize: '0.875rem' 
                                }}
                              >
                                <CheckCircle2 size={16} /> Activate Shop
                              </button>
                            )
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Grid Contact Metrics */}
              <div style={{ marginTop: '1.75rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ padding: '0.6rem', borderRadius: '12px', background: 'hsl(var(--secondary))', color: 'hsl(var(--primary))' }}>
                    <MapPin size={20} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>Location Address</p>
                    <p style={{ fontWeight: 600, fontSize: '0.925rem', opacity: 0.95 }}>{shop.address || 'Not specified'}</p>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ padding: '0.6rem', borderRadius: '12px', background: 'hsl(var(--secondary))', color: 'hsl(var(--primary))' }}>
                    <Phone size={20} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>Phone Number</p>
                    <p style={{ fontWeight: 600, fontSize: '0.925rem', opacity: 0.95 }}>{shop.phoneNumber || 'Not specified'}</p>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ padding: '0.6rem', borderRadius: '12px', background: 'hsl(var(--secondary))', color: 'hsl(var(--primary))' }}>
                    <Mail size={20} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>Email Address</p>
                    <p style={{ fontWeight: 600, fontSize: '0.925rem', opacity: 0.95 }}>{shop.email || 'Not specified'}</p>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ padding: '0.6rem', borderRadius: '12px', background: 'hsl(var(--secondary))', color: 'hsl(var(--primary))' }}>
                    <Tag size={20} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>Primary Category</p>
                    <p style={{ fontWeight: 600, fontSize: '0.925rem', opacity: 0.95 }}>{shop.categoryName || 'General Store'}</p>
                  </div>
                </div>
              </div>
            </motion.div>

            {/* About Business Card */}
            <motion.div 
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.08 }}
              className="glass-card" 
              style={{ padding: '1.75rem' }}
            >
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                <Info size={20} color="hsl(var(--primary))" /> About Business
              </h3>
              <p style={{ lineHeight: 1.6, color: 'hsl(var(--foreground))', opacity: 0.85, fontSize: '0.975rem' }}>
                {shop.description || 'No description provided for this business listing yet.'}
              </p>
            </motion.div>

            {/* Amenities & Tags (Dynamic Visual Chips) */}
            <motion.div 
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.15 }}
              className="glass-card" 
              style={{ padding: '1.75rem' }}
            >
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', flexWrap: 'wrap' }}>
                
                {/* Amenities Column */}
                <div>
                  <h3 style={{ fontSize: '1.125rem', fontWeight: 850, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                    <CheckCircle2 size={18} color="#10b981" /> Services & Amenities
                  </h3>
                  {shop.amenities && shop.amenities.length > 0 ? (
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                      {shop.amenities.map((amenity, idx) => (
                        <div 
                          key={idx} 
                          className="chip-item"
                          style={{
                            display: 'flex', alignItems: 'center', gap: '0.35rem',
                            background: 'rgba(255, 255, 255, 0.03)',
                            border: '1px solid hsl(var(--border))',
                            borderRadius: '30px', padding: '0.45rem 0.9rem',
                            fontSize: '0.85rem', fontWeight: 600, color: 'hsl(var(--foreground))',
                            transition: 'all 0.2s ease'
                          }}
                        >
                          <Check size={14} color="#10b981" strokeWidth={3} />
                          {amenity}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.875rem', fontStyle: 'italic' }}>
                      No amenities specified for this shop.
                    </p>
                  )}
                </div>

                {/* Search Tags Column */}
                <div>
                  <h3 style={{ fontSize: '1.125rem', fontWeight: 850, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                    <Tag size={18} color="hsl(var(--primary))" /> Search Tags & Keywords
                  </h3>
                  {shop.tags && shop.tags.length > 0 ? (
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                      {shop.tags.map((tag, idx) => (
                        <div 
                          key={idx} 
                          className="tag-item"
                          style={{
                            display: 'flex', alignItems: 'center', gap: '0.35rem',
                            background: 'rgba(99, 102, 241, 0.05)',
                            border: '1px solid rgba(99, 102, 241, 0.15)',
                            borderRadius: '30px', padding: '0.45rem 0.9rem',
                            fontSize: '0.85rem', fontWeight: 600, color: 'hsl(var(--primary))',
                            transition: 'all 0.2s ease'
                          }}
                        >
                          <span style={{ color: 'rgba(99, 102, 241, 0.7)' }}>#</span>
                          {tag}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.875rem', fontStyle: 'italic' }}>
                      No custom search tags defined for this shop.
                    </p>
                  )}
                </div>
              </div>
            </motion.div>

            {/* Shop Media Gallery Section */}
            <motion.div 
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="glass-card" 
              style={{ padding: '1.75rem' }}
            >
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                <ImageIcon size={20} color="hsl(var(--primary))" /> Shop Media Gallery ({shop.shopImages?.length || 0})
              </h3>
              
              {shop.shopImages && shop.shopImages.length > 0 ? (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(130px, 1fr))', gap: '1.25rem' }}>
                  {shop.shopImages.map((imgBase64, idx) => (
                    <div 
                      key={idx}
                      onClick={() => setActiveLightboxImage(imgBase64)}
                      className="gallery-thumbnail"
                      style={{
                        position: 'relative',
                        height: '110px',
                        borderRadius: 'var(--radius)',
                        overflow: 'hidden',
                        cursor: 'zoom-in',
                        border: '1px solid hsl(var(--border))',
                        background: 'hsl(var(--secondary))',
                        boxShadow: '0 4px 10px rgba(0,0,0,0.05)',
                        transition: 'all 0.25s ease'
                      }}
                    >
                      <img 
                        src={imgBase64} 
                        alt={`Shop Gallery ${idx + 1}`} 
                        style={{ 
                          width: '100%', 
                          height: '100%', 
                          objectFit: 'cover',
                          transition: 'transform 0.3s ease, filter 0.3s ease'
                        }} 
                      />
                      {/* Glass Hover Overlay */}
                      <div 
                        className="gallery-overlay"
                        style={{
                          position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
                          background: 'rgba(0, 0, 0, 0.45)',
                          backdropFilter: 'blur(3px)',
                          WebkitBackdropFilter: 'blur(3px)',
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          opacity: 0, transition: 'opacity 0.25s ease'
                        }}
                      >
                        <motion.div
                          whileHover={{ scale: 1.1 }}
                          style={{
                            background: 'rgba(255, 255, 255, 0.2)',
                            borderRadius: '50%', padding: '0.45rem',
                            border: '1px solid rgba(255, 255, 255, 0.3)',
                            color: 'white'
                          }}
                        >
                          <ImageIcon size={18} />
                        </motion.div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ 
                  textAlign: 'center', padding: '3rem 2rem', 
                  border: '2px dashed hsl(var(--border))', borderRadius: 'var(--radius)',
                  background: 'rgba(0,0,0,0.01)', display: 'flex', flexDirection: 'column', 
                  alignItems: 'center', justifyContent: 'center', gap: '0.75rem'
                }}>
                  <ImageIcon size={36} color="hsl(var(--muted-foreground))" style={{ opacity: 0.6 }} />
                  <div>
                    <h4 style={{ fontWeight: 700, fontSize: '0.95rem' }}>No Additional Gallery Images</h4>
                    <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.8125rem', marginTop: '0.15rem' }}>The shopkeeper has not uploaded any gallery photos for their business front or products.</p>
                  </div>
                </div>
              )}
            </motion.div>

            {/* Offers Card */}
            <motion.div 
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.24 }}
              className="glass-card" 
              style={{ padding: '1.75rem' }}
            >
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                <Calendar size={20} color="hsl(var(--primary))" /> Active Broadcast Offers ({shop.recentOffers?.length || 0})
              </h3>
              {shop.recentOffers && shop.recentOffers.length > 0 ? (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1.25rem' }}>
                  {shop.recentOffers.map(offer => (
                    <div key={offer.offerId} style={{ 
                      padding: '1.25rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))',
                      background: 'rgba(255,255,255,0.015)', boxShadow: '0 4px 12px rgba(0,0,0,0.02)',
                      display: 'flex', flexDirection: 'column', gap: '0.75rem'
                    }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                        <h4 style={{ fontWeight: 700, fontSize: '1rem', flex: 1, paddingRight: '0.5rem' }}>{offer.title}</h4>
                        <span style={{ 
                          fontSize: '0.675rem', fontWeight: 800, letterSpacing: '0.05em',
                          color: '#10b981', background: 'rgba(16, 185, 129, 0.08)',
                          padding: '0.25rem 0.5rem', borderRadius: '20px', border: '1px solid rgba(16, 185, 129, 0.15)'
                        }}>
                          {offer.status.toUpperCase()}
                        </span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.775rem', color: 'hsl(var(--muted-foreground))', marginTop: 'auto' }}>
                        <Clock size={14} /> <span>Expires: {new Date(offer.endDate).toLocaleDateString(undefined, { dateStyle: 'medium' })}</span>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ textAlign: 'center', padding: '2.5rem 2rem', background: 'hsl(var(--secondary))', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))' }}>
                  <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.875rem', fontWeight: 500 }}>No promotional offers are currently active for this shop.</p>
                </div>
              )}
            </motion.div>
          </div>

          {/* Sidebar Area */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            
            {/* Keeper Profile Card */}
            <motion.div 
              initial={{ opacity: 0, x: 15 }}
              animate={{ opacity: 1, x: 0 }}
              className="glass-card" 
              style={{ padding: '1.5rem' }}
            >
              <h3 style={{ fontSize: '1.125rem', fontWeight: 800, marginBottom: '1.25rem', letterSpacing: '-0.01em' }}>Shop Keeper</h3>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', paddingBottom: '1rem', borderBottom: '1px solid hsl(var(--border))' }}>
                <div style={{ width: '48px', height: '48px', borderRadius: '14px', background: 'hsl(var(--primary))', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', boxShadow: '0 4px 12px rgba(139, 92, 246, 0.25)' }}>
                  <User size={22} />
                </div>
                <div>
                  <p style={{ fontWeight: 700, fontSize: '0.95rem' }}>{shop.keeperName || shop.keeperBusinessName || 'N/A'}</p>
                  {shop.keeperName && shop.keeperBusinessName && (
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.1rem' }}>
                      {shop.keeperBusinessName}
                    </p>
                  )}
                  <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.1rem' }}>ID: {shop.keeperId.substring(0, 8)}...</p>
                </div>
              </div>
              <button 
                onClick={() => router.push(`/users/${shop.keeperUserId}`)}
                className="btn-outline" 
                style={{ width: '100%', marginTop: '1.25rem', fontSize: '0.85rem', padding: '0.625rem', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.35rem' }}
              >
                View Keeper Profile <ExternalLink size={14} />
              </button>
            </motion.div>

            {/* Styled Geofence Radar & Maps Card */}
            <motion.div 
              initial={{ opacity: 0, x: 15 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.08 }}
              className="glass-card" 
              style={{ padding: '1.5rem' }}
            >
              <h3 style={{ fontSize: '1.125rem', fontWeight: 800, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.01em' }}>
                <Compass size={18} color="hsl(var(--primary))" /> Location & Geofence
              </h3>

              {/* Real Google Map with Overlaid Animated Radar Marker */}
              <div style={{ 
                position: 'relative', 
                height: '220px', 
                width: '100%', 
                margin: '1.25rem 0', 
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
                {isMapReady && shop.latitude != null && shop.longitude != null && (
                  <button
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

              {/* Coordinates Monospace Display */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                
                {/* Geofence Alert Radius */}
                <div style={{ 
                  background: 'rgba(168, 85, 247, 0.05)', 
                  border: '1px solid rgba(168, 85, 247, 0.12)', 
                  borderRadius: '12px', padding: '0.75rem 1rem',
                  display: 'flex', justifyContent: 'space-between', alignItems: 'center'
                }}>
                  <div>
                    <span style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 550, display: 'block', textTransform: 'uppercase', letterSpacing: '0.02em' }}>Alert Radius</span>
                    <span style={{ fontWeight: 800, fontSize: '1.05rem', color: 'hsl(var(--primary))' }}>
                      {shop.notificationRadius ? `${shop.notificationRadius} Meters` : 'Default 500m'}
                    </span>
                  </div>
                  <Compass size={22} color="hsl(var(--primary))" style={{ opacity: 0.8 }} />
                </div>

                {/* GPS Coordinates & Copy Action */}
                <div style={{ 
                  background: 'hsl(var(--secondary))', borderRadius: '12px', 
                  padding: '0.75rem 1rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center'
                }}>
                  <div>
                    <p style={{ fontSize: '0.725rem', color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>GPS Coordinates</p>
                    <p style={{ fontFamily: 'monospace', fontWeight: 700, fontSize: '0.85rem', marginTop: '0.1rem', opacity: 0.95 }}>
                      {shop.latitude != null && shop.longitude != null
                        ? `${shop.latitude.toFixed(6)}, ${shop.longitude.toFixed(6)}`
                        : 'Coordinates N/A'}
                    </p>
                  </div>
                  {shop.latitude != null && shop.longitude != null && (
                    <button 
                      onClick={handleCopyCoords}
                      className="copy-btn"
                      style={{
                        padding: '0.45rem', borderRadius: '8px', background: 'transparent',
                        border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', 
                        justifyContent: 'center', color: 'hsl(var(--muted-foreground))', transition: 'all 0.2s'
                      }}
                      title="Copy GPS coordinates"
                    >
                      <Copy size={16} />
                    </button>
                  )}
                </div>

                {/* Google Maps Button Link */}
                {shop.latitude != null && shop.longitude != null && (
                  <a 
                    href={`https://www.google.com/maps/search/?api=1&query=${shop.latitude},${shop.longitude}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn-outline"
                    style={{ 
                      width: '100%', fontSize: '0.85rem', padding: '0.625rem', 
                      fontWeight: 600, display: 'flex', alignItems: 'center', 
                      justifyContent: 'center', gap: '0.35rem', textDecoration: 'none',
                      boxShadow: '0 4px 12px rgba(0,0,0,0.02)'
                    }}
                  >
                    Open in Google Maps <ExternalLink size={14} />
                  </a>
                )}
              </div>
            </motion.div>

            {/* System Info / Metadata Card */}
            <motion.div 
              initial={{ opacity: 0, x: 15 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.16 }}
              className="glass-card" 
              style={{ padding: '1.5rem' }}
            >
              <h3 style={{ fontSize: '1.125rem', fontWeight: 800, marginBottom: '1.25rem', letterSpacing: '-0.01em' }}>System Registry</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem', fontSize: '0.8125rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '0.65rem', borderBottom: '1px solid hsl(var(--border))' }}>
                  <span style={{ color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>Date Created</span>
                  <span style={{ fontWeight: 700, opacity: 0.9 }}>{new Date(shop.createdAt).toLocaleDateString(undefined, { dateStyle: 'medium' })}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>System Identifier</span>
                  <span 
                    style={{ 
                      fontWeight: 700, fontFamily: 'monospace', opacity: 0.85, 
                      background: 'hsl(var(--secondary))', padding: '0.15rem 0.45rem', borderRadius: '4px' 
                    }}
                  >
                    {shop.shopId.substring(0, 13)}...
                  </span>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </DashboardLayout>

        {/* Fullscreen Base64 Gallery Lightbox Modal */}
        <AnimatePresence>
          {activeLightboxImage && (
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setActiveLightboxImage(null)}
              style={{
                position: 'fixed', inset: 0, 
                zIndex: 9999, background: 'rgba(0, 0, 0, 0.95)', 
                display: 'flex', flexDirection: 'column', 
                alignItems: 'center', justifyContent: 'center',
                cursor: 'zoom-out'
              }}
            >
              <div style={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                padding: '1.5rem 2rem',
                display: 'flex',
                justifyContent: 'flex-end',
                alignItems: 'flex-start',
                background: 'linear-gradient(to bottom, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0) 100%)',
                zIndex: 10000,
                pointerEvents: 'none',
              }}>
                <button 
                  onClick={(e) => { e.stopPropagation(); setActiveLightboxImage(null); }}
                  style={{
                    width: '44px', height: '44px',
                    borderRadius: '50%', border: 'none',
                    background: 'rgba(255,255,255,0.15)',
                    color: 'white', display: 'flex',
                    alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
                    pointerEvents: 'auto', backdropFilter: 'blur(4px)'
                  }}
                >
                  <X size={22} />
                </button>
              </div>
              
              <motion.div 
                initial={{ scale: 0.96 }}
                animate={{ scale: 1 }}
                exit={{ scale: 0.96 }}
                transition={{ type: 'spring', damping: 25, stiffness: 300 }}
                style={{ 
                  width: '100%', 
                  height: '100%', 
                  padding: '2rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <img 
                  onClick={(e) => e.stopPropagation()}
                  src={activeLightboxImage} 
                  alt="Shop Preview Panel" 
                  style={{ 
                    maxWidth: '100%', 
                    maxHeight: '100%', 
                    objectFit: 'contain', 
                    display: 'block',
                    borderRadius: '8px',
                    boxShadow: '0 28px 80px rgba(0,0,0,0.5)',
                  }} 
                />
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Glassmorphic Action Modal */}
        <AnimatePresence>
          {activeAction && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => { setActiveAction(null); setActionReason(''); }}
              style={{
                position: 'fixed', inset: 0,
                zIndex: 2000, background: 'rgba(10, 15, 30, 0.75)',
                backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                padding: '2rem'
              }}
            >
              <motion.div
                initial={{ scale: 0.95, y: 15 }}
                animate={{ scale: 1, y: 0 }}
                exit={{ scale: 0.95, y: 15 }}
                onClick={(e) => e.stopPropagation()}
                style={{
                  width: 'min(480px, 100%)',
                  background: 'hsl(var(--card))',
                  border: '1px solid hsl(var(--border))',
                  borderRadius: '16px',
                  boxShadow: '0 20px 50px rgba(0,0,0,0.3)',
                  overflow: 'hidden'
                }}
              >
                <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid hsl(var(--border))', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <h3 style={{ fontWeight: 800, fontSize: '1.1rem', textTransform: 'capitalize' }}>
                    {activeAction} Shop
                  </h3>
                  <button 
                    onClick={() => { setActiveAction(null); setActionReason(''); }}
                    style={{ background: 'none', border: 'none', color: 'hsl(var(--muted-foreground))', cursor: 'pointer' }}
                  >
                    <X size={18} />
                  </button>
                </div>
                
                <div style={{ padding: '1.5rem' }}>
                  <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginBottom: '1rem', lineHeight: 1.5 }}>
                    {activeAction === 'verify' && 'Please provide an optional approval note.'}
                    {activeAction === 'reject' && 'Please provide a required reason for rejection.'}
                    {activeAction === 'activate' && 'Please provide an optional activation note.'}
                    {activeAction === 'deactivate' && 'Please provide a required reason for deactivating this shop.'}
                  </p>
                  
                  <textarea
                    value={actionReason}
                    onChange={(e) => setActionReason(e.target.value)}
                    rows={4}
                    placeholder={`Reason for ${activeAction}...`}
                    style={{
                      width: '100%',
                      padding: '0.75rem',
                      borderRadius: '8px',
                      border: '1px solid hsl(var(--border))',
                      background: 'hsl(var(--secondary))',
                      color: 'hsl(var(--foreground))',
                      outline: 'none',
                      fontSize: '0.9rem',
                      resize: 'none'
                    }}
                  />
                </div>
                
                <div style={{ padding: '1rem 1.5rem', background: 'hsl(var(--secondary))', borderTop: '1px solid hsl(var(--border))', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
                  <button
                    onClick={() => { setActiveAction(null); setActionReason(''); }}
                    className="btn-outline"
                    style={{ padding: '0.5rem 1rem', fontSize: '0.85rem', fontWeight: 600 }}
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => {
                      if (activeAction === 'verify') handleVerifyAction(true, actionReason);
                      if (activeAction === 'reject') handleVerifyAction(false, actionReason);
                      if (activeAction === 'activate') handleUpdateStatus(true, actionReason);
                      if (activeAction === 'deactivate') handleUpdateStatus(false, actionReason);
                    }}
                    disabled={submittingAction || ((activeAction === 'reject' || activeAction === 'deactivate') && !actionReason.trim())}
                    className="btn-primary"
                    style={{ 
                      background: activeAction === 'verify' || activeAction === 'activate' ? '#10b981' : '#ef4444', 
                      borderColor: activeAction === 'verify' || activeAction === 'activate' ? '#10b981' : '#ef4444', 
                      color: 'white', 
                      padding: '0.5rem 1rem', 
                      fontSize: '0.85rem', 
                      fontWeight: 600,
                      opacity: (submittingAction || ((activeAction === 'reject' || activeAction === 'deactivate') && !actionReason.trim())) ? 0.6 : 1,
                      cursor: (submittingAction || ((activeAction === 'reject' || activeAction === 'deactivate') && !actionReason.trim())) ? 'not-allowed' : 'pointer'
                    }}
                  >
                    {submittingAction ? 'Processing...' : 'Confirm'}
                  </button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
    </>
  );
}
