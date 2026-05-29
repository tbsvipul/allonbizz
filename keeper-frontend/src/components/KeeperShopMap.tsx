'use client';

import React, { useEffect, useMemo, useRef, useState } from 'react';
import { MapPin } from 'lucide-react';
import { ShopSummary } from '@/lib/types';

interface KeeperShopMapProps {
  shops: ShopSummary[];
}

interface ResolvedCoordinate {
  latitude: number;
  longitude: number;
}

type GoogleMapsWindow = Window & {
  google?: any;
  __navidealsGoogleMapsPromise?: Promise<void>;
};

const GOOGLE_MAP_SCRIPT_ID = 'navideals-google-maps-script';
const MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || '';
const GEOLOCATION_PERMISSION_DENIED = 1;
const GEOLOCATION_POSITION_UNAVAILABLE = 2;
const GEOLOCATION_TIMEOUT = 3;

function loadGoogleMapsApi(apiKey: string) {
  const win = window as GoogleMapsWindow;

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

    (win as any).__navidealsGoogleMapsCallback = () => {
      resolve();
    };

    const script = document.createElement('script');
    script.id = GOOGLE_MAP_SCRIPT_ID;
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&loading=async&callback=__navidealsGoogleMapsCallback`;
    script.async = true;
    script.defer = true;
    script.onerror = () => reject(new Error('Failed to load Google Maps.'));
    document.head.appendChild(script);
  });

  return win.__navidealsGoogleMapsPromise;
}

function hasValidCoordinates(latitude?: number | null, longitude?: number | null) {
  return (
    typeof latitude === 'number' &&
    Number.isFinite(latitude) &&
    typeof longitude === 'number' &&
    Number.isFinite(longitude) &&
    Math.abs(latitude) <= 90 &&
    Math.abs(longitude) <= 180 &&
    !(latitude === 0 && longitude === 0)
  );
}

function getGeolocationErrorMessage(error?: GeolocationPositionError | null) {
  if (typeof window !== 'undefined' && !window.isSecureContext) {
    return `Current location only works on HTTPS or localhost. This page is running on ${window.location.origin}.`;
  }

  switch (error?.code) {
    case GEOLOCATION_PERMISSION_DENIED:
      return 'Location access was blocked. Allow location permission for this site and try again.';
    case GEOLOCATION_POSITION_UNAVAILABLE:
      return "Your browser couldn't determine the current location. Check GPS or network access and try again.";
    case GEOLOCATION_TIMEOUT:
      return 'Getting the current location timed out. Please try again.';
    default:
      return error?.message || 'Unable to get the current location right now.';
  }
}

function escapeHtml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function buildInfoWindowContent(shop: ShopSummary) {
  const statusIsActive = shop.status.toLowerCase() === 'active';
  const statusBg = statusIsActive ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)';
  const statusColor = statusIsActive ? '#059669' : '#dc2626';
  const openBg = shop.isOpen ? 'rgba(16,185,129,0.1)' : 'rgba(245,158,11,0.1)';
  const openColor = shop.isOpen ? '#059669' : '#d97706';
  const openLabel = shop.isOpen ? 'Open' : 'Closed';
  const latitude = typeof shop.latitude === 'number' ? shop.latitude.toFixed(4) : 'N/A';
  const longitude = typeof shop.longitude === 'number' ? shop.longitude.toFixed(4) : 'N/A';
  
  const image = shop.shopProfileImage
    ? `<img src="${escapeHtml(shop.shopProfileImage)}" alt="${escapeHtml(shop.name)}" style="width: 48px; height: 48px; border-radius: 12px; object-fit: cover; border: 1px solid rgba(0,0,0,0.08); display: block; flex-shrink: 0;" />`
    : `<div style="width: 48px; height: 48px; border-radius: 12px; background: linear-gradient(135deg, #1e293b, #0f172a); display: flex; align-items: center; justify-content: center; color: #fff; font-weight: 700; font-size: 18px; border: 1px solid rgba(0,0,0,0.08); flex-shrink: 0;">${escapeHtml(shop.name.charAt(0).toUpperCase())}</div>`;

  return `
    <div style="min-width: 250px; max-width: 280px; padding: 4px; font-family: Inter, system-ui, sans-serif; color: #0f172a;">
      <div style="display: flex; gap: 12px; align-items: center; padding-bottom: 12px; border-bottom: 1px solid rgba(0,0,0,0.06);">
        ${image}
        <div style="min-width: 0; flex: 1;">
          <div style="display: flex; align-items: center; gap: 6px;">
            <h4 style="margin: 0; font-size: 15px; line-height: 1.2; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${escapeHtml(shop.name)}</h4>
            ${shop.isVerified ? '<svg width="14" height="14" viewBox="0 0 24 24" fill="#10b981" stroke="#fff" stroke-width="2"><circle cx="12" cy="12" r="10"></circle></svg>' : ''}
          </div>
          <p style="margin: 3px 0 0; color: #64748b; font-size: 13px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${escapeHtml(shop.businessName || shop.category || 'Business')}</p>
        </div>
      </div>
      <div style="padding: 12px 0; display: flex; flex-direction: column; gap: 10px;">
        <div style="display: flex; align-items: flex-start; gap: 8px;">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-top:2px; flex-shrink:0;"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg>
          <div style="font-size: 13px; font-weight: 500; color: #334155; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">${escapeHtml(shop.location || 'Unknown location')}</div>
        </div>
        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
          <span style="padding: 4px 8px; border-radius: 6px; background: ${statusBg}; color: ${statusColor}; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;">
            ${escapeHtml(shop.status)}
          </span>
          <span style="padding: 4px 8px; border-radius: 6px; background: ${openBg}; color: ${openColor}; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;">
            ${openLabel}
          </span>
          <span style="padding: 4px 8px; border-radius: 6px; background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 600;">
            <span style="opacity: 0.6; margin-right: 2px;">GPS:</span> ${latitude}, ${longitude}
          </span>
        </div>
      </div>
      <div style="display: flex; gap: 8px; margin-top: 4px;">
        <a href="/shops/${encodeURIComponent(shop.id)}" style="flex: 1; text-align: center; padding: 8px; border-radius: 8px; background: #2563eb; color: #fff; text-decoration: none; font-size: 13px; font-weight: 600; box-shadow: 0 2px 4px rgba(37,99,235,0.2);">
          Details
        </a>
      </div>
    </div>
  `;
}

export function KeeperShopMap({ shops }: KeeperShopMapProps) {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<any>(null);
  const infoWindowRef = useRef<any>(null);
  const markersRef = useRef<Array<{ shopId: string; marker: any }>>([]);
  const currentLocationMarkerRef = useRef<any>(null);
  const [error, setError] = useState<string | null>(null);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [selectedShopId, setSelectedShopId] = useState<string | null>(null);
  const [isMapReady, setIsMapReady] = useState(false);
  const [hasCurrentLocation, setHasCurrentLocation] = useState(false);

  const mappableShops = useMemo(
    () => shops.filter((shop) => hasValidCoordinates(shop.latitude, shop.longitude)),
    [shops]
  );

  const openCount = useMemo(
    () => mappableShops.filter((shop) => shop.isOpen).length,
    [mappableShops]
  );

  const closedCount = useMemo(
    () => mappableShops.filter((shop) => !shop.isOpen).length,
    [mappableShops]
  );

  const selectedShop = useMemo(
    () => mappableShops.find((shop) => shop.id === selectedShopId) ?? null,
    [mappableShops, selectedShopId]
  );

  useEffect(() => {
    let isMounted = true;
    if (!MAPS_API_KEY) {
      setError('Google Maps API key is missing.');
      return () => { isMounted = false; };
    }

    loadGoogleMapsApi(MAPS_API_KEY)
      .then(() => {
        if (isMounted) {
          setIsMapReady(true);
          const win = window as any;
          win.gm_authFailure = () => {
            setError('Google Maps API quota exceeded. Please upgrade your API key.');
          };
        }
      })
      .catch((err: Error) => {
        if (isMounted) setError(err.message);
      });

    return () => { isMounted = false; };
  }, []);

  useEffect(() => {
    const win = window as GoogleMapsWindow;

    if (!isMapReady || !mapContainerRef.current || !win.google?.maps) {
      return;
    }

    if (!mapRef.current) {
      mapRef.current = new win.google.maps.Map(mapContainerRef.current, {
        center: { lat: 23.0375, lng: 72.566 },
        zoom: 11,
        minZoom: 3,
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: true,
        gestureHandling: 'cooperative',
      });

      // Add Current Location Button
      const locationButton = document.createElement('button');
      locationButton.type = 'button';
      locationButton.title = 'Pan to Current Location';
      locationButton.style.backgroundColor = '#fff';
      locationButton.style.border = 'none';
      locationButton.style.outline = 'none';
      locationButton.style.width = '40px';
      locationButton.style.height = '40px';
      locationButton.style.borderRadius = '2px';
      locationButton.style.boxShadow = 'rgba(0, 0, 0, 0.3) 0px 1px 4px -1px';
      locationButton.style.cursor = 'pointer';
      locationButton.style.marginRight = '10px';
      locationButton.style.padding = '0';
      locationButton.style.display = 'flex';
      locationButton.style.alignItems = 'center';
      locationButton.style.justifyContent = 'center';

      const locationIcon = document.createElement('div');
      locationIcon.style.width = '18px';
      locationIcon.style.height = '18px';
      locationIcon.style.backgroundImage = 'url(https://maps.gstatic.com/tactile/mylocation/mylocation-sprite-1x.png)';
      locationIcon.style.backgroundSize = '180px 18px';
      locationIcon.style.backgroundPosition = '0px 0px';
      locationIcon.style.backgroundRepeat = 'no-repeat';
      locationButton.appendChild(locationIcon);

      mapRef.current.controls[win.google.maps.ControlPosition.RIGHT_BOTTOM].push(locationButton);

      // Ensure the ripple style is added to the document once
      if (!document.getElementById('map-ripple-style')) {
        const style = document.createElement('style');
        style.id = 'map-ripple-style';
        style.innerHTML = `@keyframes map-ripple { 0% { transform: scale(0.5); opacity: 0.8; } 100% { transform: scale(2.5); opacity: 0; } }`;
        document.head.appendChild(style);
      }

      class CurrentLocationOverlay extends win.google.maps.OverlayView {
        private container: HTMLDivElement | null = null;
        private position: { lat: number; lng: number };

        constructor(position: { lat: number; lng: number }) {
          super();
          this.position = position;
        }

        onAdd() {
          const div = document.createElement('div');
          div.style.position = 'absolute';
          div.style.transform = 'translate(-50%, -50%)';
          div.style.pointerEvents = 'none';
          div.style.zIndex = '1000';
          div.innerHTML = `
            <div style="position: relative; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center;">
              <div style="position: absolute; width: 100%; height: 100%; background-color: #3b82f6; border-radius: 50%; opacity: 0.4; animation: map-ripple 2s infinite ease-out;"></div>
              <div style="position: absolute; width: 16px; height: 16px; background-color: #2563eb; border: 3px solid #ffffff; border-radius: 50%; box-shadow: 0 2px 4px rgba(0,0,0,0.3); z-index: 2;"></div>
            </div>
          `;
          this.container = div;
          const panes = this.getPanes();
          if (panes && panes.floatPane) {
            panes.floatPane.appendChild(div);
          }
        }

        draw() {
          if (!this.container) return;
          const projection = this.getProjection();
          if (!projection) return;
          const latLng = new win.google.maps.LatLng(this.position.lat, this.position.lng);
          const pixel = projection.fromLatLngToDivPixel(latLng);
          if (!pixel) return;
          this.container.style.left = pixel.x + 'px';
          this.container.style.top = pixel.y + 'px';
        }

        onRemove() {
          if (this.container && this.container.parentNode) {
            this.container.parentNode.removeChild(this.container);
            this.container = null;
          }
        }
        
        updatePosition(pos: {lat: number; lng: number}) {
          this.position = pos;
          this.draw();
        }
      }

      locationButton.addEventListener('click', () => {
        if (!navigator.geolocation) {
          setLocationError('Current location is not supported in this browser.');
          return;
        }

        setLocationError(null);
        locationIcon.style.backgroundPosition = '-18px 0px';
        navigator.geolocation.getCurrentPosition(
          (position) => {
            locationIcon.style.backgroundPosition = '0px 0px';
            setLocationError(null);
            const pos = { lat: position.coords.latitude, lng: position.coords.longitude };
            setHasCurrentLocation(true);
            mapRef.current.panTo(pos);
            mapRef.current.setZoom(15);

            if (currentLocationMarkerRef.current) {
              currentLocationMarkerRef.current.updatePosition(pos);
            } else {
              currentLocationMarkerRef.current = new CurrentLocationOverlay(pos);
              currentLocationMarkerRef.current.setMap(mapRef.current);
            }
          },
          (geoError) => {
            locationIcon.style.backgroundPosition = '0px 0px';
            const message = getGeolocationErrorMessage(geoError);
            setLocationError(message);
            console.warn('Geolocation request failed.', {
              code: geoError.code,
              message: geoError.message,
              secureContext: window.isSecureContext,
              origin: window.location.origin,
            });
          },
          {
            enableHighAccuracy: true,
            timeout: 10000,
            maximumAge: 60000,
          }
        );
      });

      mapRef.current.addListener('click', () => {
        setSelectedShopId(null);
      });
    }

    if (!infoWindowRef.current) {
      infoWindowRef.current = new win.google.maps.InfoWindow();
    }

    const googleMaps = win.google.maps;
    const map = mapRef.current;

    markersRef.current.forEach((entry) => entry.marker.setMap(null));
    markersRef.current = [];

    if (mappableShops.length === 0) {
      infoWindowRef.current.close();
      return;
    }

    const bounds = new googleMaps.LatLngBounds();

    class ShopMarkerOverlay extends googleMaps.OverlayView {
      private container: HTMLDivElement | null = null;
      private shop: ShopSummary;
      private isSelected: boolean;
      private onClick: () => void;

      constructor(shop: ShopSummary, isSelected: boolean, onClick: () => void) {
        super();
        this.shop = shop;
        this.isSelected = isSelected;
        this.onClick = onClick;
      }

      onAdd() {
        const div = document.createElement('div');
        div.style.position = 'absolute';
        const tipOffset = this.isSelected ? 38 : 32.5; 
        div.style.transform = `translate(-50%, calc(-50% - ${tipOffset}px))`;
        div.style.cursor = 'pointer';
        div.style.zIndex = this.isSelected ? '100' : '10';
        div.onclick = (e) => {
          e.stopPropagation();
          this.onClick();
        };

        const pinColor = this.shop.isOpen ? '#10b981' : '#f59e0b';
        const size = this.isSelected ? 54 : 46;
        const innerSize = this.isSelected ? 44 : 38;
        const iconSize = this.isSelected ? 24 : 20;

        const imageHtml = this.shop.shopProfileImage 
          ? `<img src="${escapeHtml(this.shop.shopProfileImage)}" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%;" />`
          : `<svg xmlns="http://www.w3.org/2000/svg" width="${iconSize}" height="${iconSize}" viewBox="0 0 24 24" fill="none" stroke="${pinColor}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>`;

        div.innerHTML = `
          <div style="position: relative; width: ${size}px; height: ${size}px; display: flex; align-items: center; justify-content: center; transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);">
            <div style="
              position: absolute;
              width: 100%;
              height: 100%;
              background-color: ${pinColor};
              border-radius: 50% 50% 4px 50%;
              transform: rotate(45deg);
              box-shadow: 2px 4px 12px rgba(0,0,0,0.3);
              ${this.isSelected ? `border: 2px solid #fff; box-shadow: 0 0 0 3px rgba(37,99,235,0.4), 2px 4px 16px rgba(0,0,0,0.4);` : ''}
            "></div>
            <div style="
              position: absolute;
              width: ${innerSize}px;
              height: ${innerSize}px;
              background-color: #ffffff;
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              overflow: hidden;
              z-index: 2;
            ">
              ${imageHtml}
            </div>
          </div>
        `;

        this.container = div;
        const panes = this.getPanes();
        if (panes && panes.overlayMouseTarget) {
          panes.overlayMouseTarget.appendChild(div);
        }
      }

      draw() {
        if (!this.container) return;
        const projection = this.getProjection();
        if (!projection) return;
        const pos = new win.google.maps.LatLng(this.shop.latitude!, this.shop.longitude!);
        const positionPixel = projection.fromLatLngToDivPixel(pos);
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

    mappableShops.forEach((shop) => {
      const isSelected = shop.id === selectedShopId;
      const markerOverlay = new ShopMarkerOverlay(shop, isSelected, () => {
        setSelectedShopId(shop.id);
      });
      
      markerOverlay.setMap(map);
      bounds.extend(new googleMaps.LatLng(shop.latitude!, shop.longitude!));
      markersRef.current.push({ shopId: shop.id, marker: markerOverlay });
    });

    if (selectedShop) {
      map.panTo({ lat: selectedShop.latitude, lng: selectedShop.longitude });
      map.setZoom(Math.max(map.getZoom() || 13, 13));
      return;
    }

    if (mappableShops.length === 1) {
      map.setCenter({ lat: mappableShops[0].latitude, lng: mappableShops[0].longitude });
      map.setZoom(13);
      return;
    }

    map.fitBounds(bounds, 48);
  }, [isMapReady, mappableShops, selectedShop, selectedShopId]);

  useEffect(() => {
    if (!infoWindowRef.current || !mapRef.current) {
      return;
    }

    if (!selectedShop) {
      infoWindowRef.current.close();
      return;
    }

    const win = window as GoogleMapsWindow;
    if (!win.google?.maps) {
      return;
    }

    const pos = new win.google.maps.LatLng(selectedShop.latitude!, selectedShop.longitude!);
    infoWindowRef.current.setContent(buildInfoWindowContent(selectedShop));
    infoWindowRef.current.setPosition(pos);
    infoWindowRef.current.setOptions({ pixelOffset: new win.google.maps.Size(0, -35) });

    infoWindowRef.current.open({
      map: mapRef.current,
      shouldFocus: false,
    });
  }, [selectedShop]);

  return (
    <div className="glass-card" style={{ padding: '2rem', height: '100%', width: '100%', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-xl)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap' }}>
        <div>
          <h3 style={{ fontSize: '1.125rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.35rem', color: 'hsl(var(--foreground))' }}>
            <MapPin size={18} color="#2563eb" /> Your Shops on Map
          </h3>
          <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
            Click a marker to view shop details.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#10b981' }}>{openCount} open</span>
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#f59e0b' }}>{closedCount} closed</span>
        </div>
      </div>

      {error && (
        <div style={{ marginBottom: '1rem', padding: '0.875rem 1rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444', fontSize: '0.875rem', fontWeight: 600 }}>
          {error}
        </div>
      )}

      {locationError && (
        <div style={{ marginBottom: '1rem', padding: '0.875rem 1rem', borderRadius: 'var(--radius)', background: 'rgba(245, 158, 11, 0.14)', color: '#d97706', fontSize: '0.875rem', fontWeight: 600 }}>
          {locationError}
        </div>
      )}

      <div style={{ position: 'relative', minHeight: '520px', width: '100%', borderRadius: '18px', overflow: 'hidden', background: 'linear-gradient(135deg, rgba(37, 99, 235, 0.14), rgba(16, 185, 129, 0.14))', border: '1px solid hsl(var(--border))' }}>
        <div ref={mapContainerRef} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }} />

        {!isMapReady && (
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'hsl(var(--muted-foreground))', fontWeight: 600, zIndex: 10 }}>
            Loading map...
          </div>
        )}

        {isMapReady && mappableShops.length === 0 && !hasCurrentLocation && (
          <div
            style={{
              position: 'absolute',
              top: '1rem',
              left: '50%',
              transform: 'translateX(-50%)',
              maxWidth: 'min(420px, calc(100% - 2rem))',
              padding: '0.875rem 1rem',
              borderRadius: '14px',
              background: 'rgba(10, 15, 28, 0.78)',
              border: '1px solid rgba(148, 163, 184, 0.25)',
              boxShadow: '0 12px 40px rgba(15, 23, 42, 0.22)',
              color: '#e2e8f0',
              fontSize: '0.875rem',
              fontWeight: 600,
              textAlign: 'center',
              pointerEvents: 'none',
              zIndex: 10,
            }}
          >
            Shop markers appear here when shops have saved latitude and longitude values. You can still use the current location button.
          </div>
        )}
      </div>
    </div>
  );
}
