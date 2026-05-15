'use client';

import React, { useEffect, useMemo, useRef, useState } from 'react';
import { MapPin } from 'lucide-react';
import api from '@/lib/api';
import { unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';

interface DashboardMapShop {
  id: string;
  name: string;
  businessName: string;
  category: string;
  location: string;
  status: string;
  isVerified: boolean;
  latitude?: number | null;
  longitude?: number | null;
  imageUrl?: string | null;
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
const GEOCODING_ENABLED = process.env.NEXT_PUBLIC_GOOGLE_MAPS_GEOCODING_ENABLED === 'true';
const GEOCODE_CACHE_KEY = 'navideals-dashboard-shop-geocodes-v1';

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

function buildGeocodeQuery(shop: DashboardMapShop) {
  return [shop.location, shop.businessName, shop.name]
    .map((value) => value?.trim())
    .filter((value) => value && value.toLowerCase() !== 'unknown')
    .join(', ');
}

function geocodeAddress(geocoder: any, address: string): Promise<{ latitude: number; longitude: number } | null> {
  return new Promise((resolve) => {
    geocoder.geocode({ address }, (results: any, status: string) => {
      if (status === 'OK' && results?.[0]?.geometry?.location) {
        resolve({
          latitude: results[0].geometry.location.lat(),
          longitude: results[0].geometry.location.lng(),
        });
        return;
      }

      resolve(null);
    });
  });
}

function createMarkerIcon(googleMaps: any, status: string, isSelected: boolean) {
  const isActive = status.toLowerCase() === 'active';

  return {
    path: googleMaps.SymbolPath.CIRCLE,
    scale: isSelected ? 10 : 8,
    fillColor: isActive ? '#10b981' : '#ef4444',
    fillOpacity: 1,
    strokeColor: isSelected ? '#111827' : '#ffffff',
    strokeWeight: isSelected ? 3 : 2,
  };
}

function escapeHtml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function buildInfoWindowContent(shop: DashboardMapShop) {
  const statusIsActive = shop.status.toLowerCase() === 'active';
  const statusBg = statusIsActive ? 'rgba(16, 185, 129, 0.12)' : 'rgba(239, 68, 68, 0.12)';
  const statusColor = statusIsActive ? '#10b981' : '#ef4444';
  const latitude = typeof shop.latitude === 'number' ? shop.latitude.toFixed(4) : 'N/A';
  const longitude = typeof shop.longitude === 'number' ? shop.longitude.toFixed(4) : 'N/A';
  const image = shop.imageUrl
    ? `<img src="${escapeHtml(shop.imageUrl)}" alt="${escapeHtml(shop.name)}" style="width:52px;height:52px;border-radius:14px;object-fit:cover;display:block;" />`
    : '<div style="width:52px;height:52px;border-radius:14px;background:#1f2937;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:800;font-size:18px;">S</div>';

  return `
    <div style="max-width:280px;padding:4px 2px 2px;font-family:Inter,system-ui,sans-serif;color:#0f172a;">
      <div style="display:flex;gap:12px;align-items:flex-start;">
        ${image}
        <div style="min-width:0;">
          <div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap;">
            <h4 style="margin:0;font-size:16px;line-height:1.2;font-weight:800;">${escapeHtml(shop.name)}</h4>
            ${shop.isVerified ? '<span style="color:#10b981;font-size:14px;">●</span>' : ''}
          </div>
          <p style="margin:4px 0 0;color:#475569;font-size:13px;line-height:1.35;">${escapeHtml(shop.businessName || 'Business')}</p>
        </div>
      </div>

      <div style="margin-top:12px;display:grid;gap:8px;">
        <div>
          <div style="font-size:11px;text-transform:uppercase;letter-spacing:.08em;color:#64748b;margin-bottom:3px;">Category</div>
          <div style="font-size:13px;font-weight:700;">${escapeHtml(shop.category || 'General')}</div>
        </div>
        <div>
          <div style="font-size:11px;text-transform:uppercase;letter-spacing:.08em;color:#64748b;margin-bottom:3px;">Address</div>
          <div style="font-size:13px;font-weight:700;">${escapeHtml(shop.location || 'Unknown')}</div>
        </div>
      </div>

      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:12px;">
        <span style="padding:6px 10px;border-radius:999px;background:${statusBg};color:${statusColor};font-size:12px;font-weight:800;">
          ${escapeHtml(shop.status)}
        </span>
        <span style="padding:6px 10px;border-radius:999px;background:rgba(37,99,235,.12);color:#2563eb;font-size:12px;font-weight:800;">
          ${latitude}, ${longitude}
        </span>
      </div>

      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:14px;">
        <a href="/shops/${encodeURIComponent(shop.id)}" style="padding:9px 12px;border-radius:12px;background:#2563eb;color:#fff;text-decoration:none;font-size:12px;font-weight:800;">
          View shop details
        </a>
        <a href="https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${shop.latitude},${shop.longitude}`)}" target="_blank" rel="noopener noreferrer" style="padding:9px 12px;border-radius:12px;background:rgba(37,99,235,.1);color:#2563eb;text-decoration:none;font-size:12px;font-weight:800;">
          Open in Google Maps
        </a>
      </div>
    </div>
  `;
}

export default function DashboardShopMap() {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<any>(null);
  const infoWindowRef = useRef<any>(null);
  const markersRef = useRef<Array<{ shopId: string; marker: any }>>([]);
  const geocodeAttemptedRef = useRef<Set<string>>(new Set());
  const [shops, setShops] = useState<DashboardMapShop[]>([]);
  const [resolvedCoordinates, setResolvedCoordinates] = useState<Record<string, ResolvedCoordinate>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedShopId, setSelectedShopId] = useState<string | null>(null);
  const [isMapReady, setIsMapReady] = useState(false);

  const resolvedShops = useMemo(
    () =>
      shops.map((shop) => {
        if (hasValidCoordinates(shop.latitude, shop.longitude)) {
          return shop;
        }

        const cached = resolvedCoordinates[shop.id];
        if (!cached) {
          return shop;
        }

        return {
          ...shop,
          latitude: cached.latitude,
          longitude: cached.longitude,
        };
      }),
    [resolvedCoordinates, shops]
  );

  const mappableShops = useMemo(
    () => resolvedShops.filter((shop) => hasValidCoordinates(shop.latitude, shop.longitude)),
    [resolvedShops]
  );

  const activeCount = useMemo(
    () => mappableShops.filter((shop) => shop.status.toLowerCase() === 'active').length,
    [mappableShops]
  );

  const inactiveCount = useMemo(
    () => mappableShops.filter((shop) => shop.status.toLowerCase() !== 'active').length,
    [mappableShops]
  );

  const selectedShop = useMemo(
    () => mappableShops.find((shop) => shop.id === selectedShopId) ?? null,
    [mappableShops, selectedShopId]
  );

  useEffect(() => {
    if (!GEOCODING_ENABLED || typeof window === 'undefined') {
      return;
    }

    try {
      const raw = window.localStorage.getItem(GEOCODE_CACHE_KEY);
      if (!raw) {
        return;
      }

      const parsed = JSON.parse(raw) as Record<string, ResolvedCoordinate>;
      setResolvedCoordinates(parsed);
      Object.keys(parsed).forEach((shopId) => geocodeAttemptedRef.current.add(shopId));
    } catch {
      // Ignore corrupt cache.
    }
  }, []);

  useEffect(() => {
    let isMounted = true;

    const fetchAllShops = async () => {
      setLoading(true);
      setError(null);

      try {
        const pageSize = 100;
        const firstResponse = await api.get('/admin/shops', {
          params: { pageNumber: 1, pageSize },
        });
        const firstPage = unwrapPagedResponse<DashboardMapShop>(firstResponse);
        const totalPages = Math.max(
          1,
          firstPage.pagination.totalPages ||
            Math.ceil((firstPage.pagination.totalCount || firstPage.data.length) / pageSize)
        );

        let allShops = firstPage.data;

        if (totalPages > 1) {
          const remainingResponses = await Promise.all(
            Array.from({ length: totalPages - 1 }, (_, index) =>
              api.get('/admin/shops', {
                params: { pageNumber: index + 2, pageSize },
              })
            )
          );

          allShops = [
            ...allShops,
            ...remainingResponses.flatMap((response) => unwrapPagedResponse<DashboardMapShop>(response).data),
          ];
        }

        if (!isMounted) {
          return;
        }

        setShops(allShops);
      } catch (err) {
        if (!isMounted) {
          return;
        }

        setError(getApiErrorMessage(err, 'Failed to load shop map data.'));
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    fetchAllShops();

    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    let isMounted = true;

    if (!MAPS_API_KEY) {
      setError('Google Maps API key is missing. Add NEXT_PUBLIC_GOOGLE_MAPS_API_KEY to admin-fronend/.env.local.');
      setLoading(false);
      return () => {
        isMounted = false;
      };
    }

    loadGoogleMapsApi(MAPS_API_KEY)
      .then(() => {
        if (isMounted) {
          setIsMapReady(true);
        }
      })
      .catch((err: Error) => {
        if (isMounted) {
          setError(err.message);
        }
      });

    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    const win = window as GoogleMapsWindow;

    if (!GEOCODING_ENABLED || !isMapReady || !win.google?.maps || shops.length === 0) {
      return;
    }

    const pendingShops = shops.filter((shop) => {
      if (hasValidCoordinates(shop.latitude, shop.longitude)) {
        return false;
      }

      if (resolvedCoordinates[shop.id]) {
        return false;
      }

      if (geocodeAttemptedRef.current.has(shop.id)) {
        return false;
      }

      return buildGeocodeQuery(shop).length > 0;
    });

    if (pendingShops.length === 0) {
      return;
    }

    let cancelled = false;

    const geocodeMissingShops = async () => {
      const geocoder = new win.google.maps.Geocoder();
      const discoveredCoordinates: Record<string, ResolvedCoordinate> = {};

      for (const shop of pendingShops) {
        if (cancelled) {
          return;
        }

        geocodeAttemptedRef.current.add(shop.id);
        const coordinate = await geocodeAddress(geocoder, buildGeocodeQuery(shop));
        if (coordinate) {
          discoveredCoordinates[shop.id] = coordinate;
        }

        await new Promise((resolve) => setTimeout(resolve, 120));
      }

      if (cancelled || Object.keys(discoveredCoordinates).length === 0) {
        return;
      }

      setResolvedCoordinates((previous) => {
        const next = { ...previous, ...discoveredCoordinates };
        try {
          window.localStorage.setItem(GEOCODE_CACHE_KEY, JSON.stringify(next));
        } catch {
          // Ignore cache write issues.
        }
        return next;
      });
    };

    geocodeMissingShops().catch(() => {
      // Ignore geocoding failures when the fallback is enabled explicitly.
    });

    return () => {
      cancelled = true;
    };
  }, [isMapReady, resolvedCoordinates, shops]);

  useEffect(() => {
    const win = window as GoogleMapsWindow;

    if (!isMapReady || !mapContainerRef.current || !win.google?.maps) {
      return;
    }

    if (!mapRef.current) {
      mapRef.current = new win.google.maps.Map(mapContainerRef.current, {
        center: { lat: 23.0375, lng: 72.566 },
        zoom: 11,
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: false,
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

    mappableShops.forEach((shop) => {
      const marker = new googleMaps.Marker({
        map,
        position: { lat: shop.latitude, lng: shop.longitude },
        title: shop.name,
        icon: createMarkerIcon(googleMaps, shop.status, shop.id === selectedShopId),
      });

      marker.addListener('click', () => {
        setSelectedShopId(shop.id);
      });

      bounds.extend(marker.getPosition());
      markersRef.current.push({ shopId: shop.id, marker });
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

    const markerEntry = markersRef.current.find((entry) => entry.shopId === selectedShop.id);
    if (!markerEntry) {
      return;
    }

    infoWindowRef.current.setContent(buildInfoWindowContent(selectedShop));
    infoWindowRef.current.open({
      map: mapRef.current,
      anchor: markerEntry.marker,
      shouldFocus: false,
    });
  }, [selectedShop]);

  return (
    <div className="glass-card" style={{ padding: '1.5rem', height: '100%' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap' }}>
        <div>
          <h3 style={{ fontSize: '1.125rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.35rem' }}>
            <MapPin size={18} color="#2563eb" /> Shop Map
          </h3>
          <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
            Click a marker to open the shop details popup inside the map.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#10b981' }}>{activeCount} active</span>
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#ef4444' }}>{inactiveCount} inactive</span>
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#2563eb' }}>{mappableShops.length} plotted</span>
        </div>
      </div>

      {error && (
        <div style={{ marginBottom: '1rem', padding: '0.875rem 1rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444', fontSize: '0.875rem', fontWeight: 600 }}>
          {error}
        </div>
      )}

      <div
        ref={mapContainerRef}
        style={{
          minHeight: '520px',
          width: '100%',
          borderRadius: '18px',
          overflow: 'hidden',
          background: 'linear-gradient(135deg, rgba(37, 99, 235, 0.14), rgba(16, 185, 129, 0.14))',
          border: '1px solid hsl(var(--border))',
          position: 'relative',
        }}
      >
        {!isMapReady && (
          <div style={{ width: '100%', height: '100%', minHeight: '520px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>
            Loading map...
          </div>
        )}

        {isMapReady && !loading && mappableShops.length === 0 && (
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'hsl(var(--muted-foreground))', fontWeight: 600, background: 'rgba(10, 15, 28, 0.45)', textAlign: 'center', padding: '1.5rem' }}>
            Shop markers appear here when shops have saved latitude and longitude values.
          </div>
        )}
      </div>
    </div>
  );
}
