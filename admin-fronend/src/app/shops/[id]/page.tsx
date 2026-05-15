'use client';

import React, { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { 
  Store, MapPin, Phone, Mail, User, Tag, Calendar, 
  ChevronLeft, BadgeCheck, ShieldAlert, CheckCircle2, XCircle,
  ExternalLink, Info, Map as MapIcon, Image as ImageIcon
} from 'lucide-react';
import { motion } from 'framer-motion';
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
  keeperId: string;
  keeperBusinessName: string;
  categoryId: string;
  categoryName: string;
  latitude: number;
  longitude: number;
  imageUrl: string;
  isVerified: boolean;
  isActive: boolean;
  createdAt: string;
  recentOffers: Offer[];
}

export default function ShopDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const { hasPermission } = useAuth();
  const [shop, setShop] = useState<ShopDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

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

  const handleUpdateStatus = async (nextIsActive: boolean) => {
    try {
      await api.put(`/admin/shops/${params.id}/status`, { isActive: nextIsActive });
      setToast(`Shop ${nextIsActive ? 'activated' : 'deactivated'} successfully`);
      setTimeout(() => setToast(null), 3000);
      fetchShopDetails();
    } catch (err) {
      const message = getApiErrorMessage(err, 'Failed to update status.');
      setError(message);
      setToast(message);
      setTimeout(() => setToast(null), 3000);
    }
  };

  const handleVerify = async () => {
    try {
      await api.post(`/admin/shops/${params.id}/verify`);
      setToast('Shop verified successfully');
      setTimeout(() => setToast(null), 3000);
      fetchShopDetails();
    } catch (err) {
      const message = getApiErrorMessage(err, 'Failed to verify shop.');
      setError(message);
      setToast(message);
      setTimeout(() => setToast(null), 3000);
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex-center" style={{ height: '60vh' }}>
          <div className="loader"></div>
          <p style={{ marginTop: '1rem', color: 'hsl(var(--muted-foreground))' }}>Loading shop details...</p>
        </div>
      </DashboardLayout>
    );
  }

  if (!shop) {
    return (
      <DashboardLayout>
        <div className="flex-center" style={{ height: '60vh' }}>
          <ShieldAlert size={48} color="#ef4444" />
          <h2 style={{ marginTop: '1rem' }}>Shop Not Found</h2>
          <button 
            onClick={() => router.push('/shops')}
            className="btn-primary"
            style={{ marginTop: '1rem' }}
          >
            Back to Shops
          </button>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        {/* Toast */}
        {toast && (
          <div style={{
            position: 'fixed', top: '1.5rem', right: '1.5rem', zIndex: 100,
            padding: '0.75rem 1.25rem', borderRadius: 'var(--radius)',
            background: toast.includes('Failed') ? '#ef4444' : '#10b981',
            color: 'white', fontWeight: 600, fontSize: '0.875rem',
            boxShadow: '0 4px 12px rgba(0,0,0,0.3)'
          }}>
            {toast}
          </div>
        )}

        <div style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <button 
            onClick={() => router.push('/shops')}
            style={{ 
              padding: '0.5rem', borderRadius: '50%', background: 'hsl(var(--secondary))', 
              border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' 
            }}
          >
            <ChevronLeft size={20} />
          </button>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 700 }}>Shop Details</h1>
        </div>

        {error && (
          <div style={{ marginBottom: '1.5rem', padding: '0.875rem 1rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444', fontSize: '0.875rem', fontWeight: 600 }}>
            {error}
          </div>
        )}

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 350px', gap: '2rem' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            {/* Main Info Card */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="glass-card" 
              style={{ padding: '2rem' }}
            >
              <div style={{ display: 'flex', gap: '2rem' }}>
                <div style={{ 
                  width: '120px', height: '120px', borderRadius: '24px', 
                  background: 'hsl(var(--secondary))', display: 'flex', 
                  alignItems: 'center', justifyContent: 'center', overflow: 'hidden'
                }}>
                  {shop.imageUrl ? (
                    <img src={shop.imageUrl} alt={shop.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  ) : (
                    <Store size={48} color="hsl(var(--primary))" />
                  )}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                    <div>
                      <h2 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '0.5rem' }}>{shop.name}</h2>
                      <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                        <span style={{ 
                          padding: '0.25rem 0.75rem', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 700,
                          background: shop.isActive ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)',
                          color: shop.isActive ? '#10b981' : '#ef4444'
                        }}>
                          {shop.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </span>
                        {shop.isVerified && (
                          <span style={{ 
                            display: 'flex', alignItems: 'center', gap: '0.25rem',
                            color: '#10b981', fontSize: '0.875rem', fontWeight: 600
                          }}>
                            <BadgeCheck size={18} /> Verified Business
                          </span>
                        )}
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: '0.75rem' }}>
                      {!shop.isVerified && hasPermission(PERMISSIONS.shopsApprove) && (
                        <button onClick={handleVerify} className="btn-primary" style={{ background: '#f59e0b', borderColor: '#f59e0b' }}>
                          Verify Shop
                        </button>
                      )}
                      {shop.isActive ? (
                        hasPermission(PERMISSIONS.shopsApprove) && (
                          <button onClick={() => handleUpdateStatus(false)} className="btn-outline" style={{ color: '#ef4444', borderColor: '#ef4444' }}>
                            Deactivate
                          </button>
                        )
                      ) : (
                        hasPermission(PERMISSIONS.shopsApprove) && (
                          <button onClick={() => handleUpdateStatus(true)} className="btn-primary" style={{ background: '#10b981', borderColor: '#10b981' }}>
                            Activate
                          </button>
                        )
                      )}
                    </div>
                  </div>
                </div>
              </div>

              <div style={{ marginTop: '2.5rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ padding: '0.5rem', borderRadius: '10px', background: 'hsl(var(--secondary))' }}>
                    <MapPin size={18} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Address</p>
                    <p style={{ fontWeight: 600 }}>{shop.address || 'Not specified'}</p>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ padding: '0.5rem', borderRadius: '10px', background: 'hsl(var(--secondary))' }}>
                    <Phone size={18} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Phone</p>
                    <p style={{ fontWeight: 600 }}>{shop.phoneNumber || 'Not specified'}</p>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ padding: '0.5rem', borderRadius: '10px', background: 'hsl(var(--secondary))' }}>
                    <Mail size={18} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Email</p>
                    <p style={{ fontWeight: 600 }}>{shop.email || 'Not specified'}</p>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ padding: '0.5rem', borderRadius: '10px', background: 'hsl(var(--secondary))' }}>
                    <Tag size={18} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Category</p>
                    <p style={{ fontWeight: 600 }}>{shop.categoryName || 'General'}</p>
                  </div>
                </div>
              </div>
            </motion.div>

            {/* Description Card */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="glass-card" 
              style={{ padding: '1.5rem' }}
            >
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Info size={20} /> About Business
              </h3>
              <p style={{ lineHeight: 1.6, color: 'hsl(var(--foreground))', opacity: 0.9 }}>
                {shop.description || 'No description provided for this business.'}
              </p>
            </motion.div>

            {/* Offers Card */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="glass-card" 
              style={{ padding: '1.5rem' }}
            >
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Tag size={20} /> Active Offers ({shop.recentOffers?.length || 0})
              </h3>
              {shop.recentOffers && shop.recentOffers.length > 0 ? (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem' }}>
                  {shop.recentOffers.map(offer => (
                    <div key={offer.offerId} style={{ 
                      padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))',
                      background: 'rgba(255,255,255,0.02)'
                    }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                        <h4 style={{ fontWeight: 700 }}>{offer.title}</h4>
                        <span style={{ color: '#10b981', fontWeight: 700 }}>{offer.status}</span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>
                        <Calendar size={12} /> Expires: {new Date(offer.endDate).toLocaleDateString()}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ textAlign: 'center', padding: '2rem', background: 'hsl(var(--secondary))', borderRadius: 'var(--radius)' }}>
                  <p style={{ color: 'hsl(var(--muted-foreground))' }}>No active offers for this shop.</p>
                </div>
              )}
            </motion.div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            {/* Keeper Info */}
            <motion.div 
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              className="glass-card" 
              style={{ padding: '1.5rem' }}
            >
              <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1rem' }}>Shop Keeper</h3>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'hsl(var(--primary))', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
                  <User size={20} />
                </div>
                <div>
                  <p style={{ fontWeight: 700 }}>{shop.keeperBusinessName}</p>
                  <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>ID: {shop.keeperId.substring(0, 8)}...</p>
                </div>
              </div>
              <button 
                onClick={() => router.push(`/keepers/${shop.keeperId}`)}
                className="btn-outline" 
                style={{ width: '100%', marginTop: '1.25rem', fontSize: '0.875rem' }}
              >
                View Keeper Profile
              </button>
            </motion.div>

            {/* Location / Map Placeholder */}
            <motion.div 
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 }}
              className="glass-card" 
              style={{ padding: '1.5rem' }}
            >
              <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <MapIcon size={18} /> Location
              </h3>
              <div style={{ 
                height: '200px', borderRadius: 'var(--radius)', background: 'hsl(var(--secondary))',
                display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column',
                gap: '0.5rem', border: '1px solid hsl(var(--border))'
              }}>
                <MapPin size={32} color="hsl(var(--primary))" />
                <p style={{ fontSize: '0.8125rem', color: 'hsl(var(--muted-foreground))' }}>
                  {shop.latitude != null && shop.longitude != null
                    ? `${shop.latitude.toFixed(6)}, ${shop.longitude.toFixed(6)}`
                    : 'Coordinates not available'}
                </p>
                {shop.latitude != null && shop.longitude != null && (
                  <a 
                    href={`https://www.google.com/maps/search/?api=1&query=${shop.latitude},${shop.longitude}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{ fontSize: '0.75rem', color: 'hsl(var(--primary))', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.25rem', marginTop: '0.5rem' }}
                  >
                    Open in Google Maps <ExternalLink size={12} />
                  </a>
                )}
              </div>
            </motion.div>

            {/* Metadata */}
            <motion.div 
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2 }}
              className="glass-card" 
              style={{ padding: '1.5rem' }}
            >
              <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1rem' }}>System Info</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', fontSize: '0.8125rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'hsl(var(--muted-foreground))' }}>Date Created</span>
                  <span style={{ fontWeight: 600 }}>{new Date(shop.createdAt).toLocaleDateString()}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'hsl(var(--muted-foreground))' }}>Shop ID</span>
                  <span style={{ fontWeight: 600, fontFamily: 'monospace' }}>{shop.shopId.substring(0, 13)}...</span>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
