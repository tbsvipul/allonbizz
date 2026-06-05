'use client';

/* eslint-disable @next/next/no-img-element */

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import {
  ArrowLeft,
  Mail,
  Phone,
  Shield,
  Clock,
  Star,
  Route,
  Ticket,
  Store,
  FileText,
  MapPin,
  ExternalLink,
  AlertTriangle,
} from 'lucide-react';
import { motion } from 'framer-motion';
import api from '@/lib/api';
import { unwrapApiData } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';

interface ActivityItem {
  type: string;
  description: string;
  timestamp: string;
}

interface UserSummary {
  userId: string;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  phone?: string | null;
  avatarUrl?: string | null;
  status: string;
  role: string;
  is2FAEnabled: boolean;
  createdAt: string;
  lastLoginAt?: string | null;
  lastLoginIp?: string | null;
  totalOrders: number;
  totalReviews: number;
  warningCount: number;
}

interface UserActivity {
  userId: string;
  recentActivities: ActivityItem[];
  totalReviews: number;
  totalOrders: number;
  totalReports: number;
  lastActiveAt?: string | null;
}

interface LoginHistoryItem {
  loginAt: string;
  ipAddress: string;
  userAgent?: string | null;
  location?: string | null;
  success: boolean;
}

interface JourneyHistoryItem {
  journeyId: string;
  type: string;
  startName?: string | null;
  endName?: string | null;
  startTime: string;
  endTime?: string | null;
  distance: number;
  duration: number;
  tags: string[];
  shopsEncountered: string[];
}

interface CustomerReview {
  reviewId: string;
  shopName: string;
  offerTitle?: string | null;
  rating: number;
  comment?: string | null;
  reply?: string | null;
  status: string;
  createdAt: string;
}

interface RedemptionSummary {
  redemptionId: string;
  offerId: string;
  shopId: string;
  offerTitle: string;
  shopName: string;
  status: string;
  savedAmount?: number | null;

  redeemedAt: string;
}

interface KeeperDocument {
  id: string;
  name: string;
  type: string;
  url: string;
}

interface ShopSummary {
  id: string;
  name: string;
  businessName: string;
  location: string;
  category: string;
  status: string;
  isVerified: boolean;
  latitude?: number | null;
  longitude?: number | null;
  shopProfileImage?: string | null;
}

interface OfferSummary {
  id: string;
  title: string;
  keeperName: string;
  shopName: string;
  status: string;
  redemptions: number;
  startDate: string;
  endDate: string;
  createdAt: string;
}

interface KeeperReview {
  reviewId: string;
  userName: string;
  userAvatarUrl?: string | null;
  shopName: string;
  rating: number;
  comment?: string | null;
  status: string;
  createdAt: string;
  reply?: string | null;
}

interface CustomerProfile {
  journeys: JourneyHistoryItem[];
  redemptions: RedemptionSummary[];
  reviews: CustomerReview[];
}

interface KeeperProfile {
  keeperId: string;
  businessName: string;
  businessLicense?: string | null;
  gstNumber?: string | null;
  panNumber?: string | null;
  status: string;
  rejectionReason?: string | null;
  approvedAt?: string | null;
  documents: KeeperDocument[];
  shops: ShopSummary[];
  offers: OfferSummary[];
  shopReviews: KeeperReview[];
  identityProofType?: string | null;
  identityProofNumber?: string | null;
  identityProofImage?: string | null;
  businessLicenseNumber?: string | null;
  businessLicenseImage?: string | null;
  gstCertificateImage?: string | null;
  panCardImage?: string | null;
  addressProofType?: string | null;
  addressProofImage?: string | null;
  shopFrontImage?: string | null;
  shopInsideImage?: string | null;
}

interface AdminUserProfile {
  summary: UserSummary;
  activity: UserActivity;
  loginHistory: LoginHistoryItem[];
  customer?: CustomerProfile | null;
  keeper?: KeeperProfile | null;
}

const getFullImageUrl = (path?: string | null) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:')) return path;
  
  if (path.length > 200 && !path.includes('.')) {
    try {
      // The backend may have serialized the ASCII bytes of a PostgreSQL hex string 
      // instead of the raw binary data. We decode the base64 to check.
      const decodedStr = atob(path);
      if (decodedStr.startsWith('\\x')) {
        // It is a hex string (e.g. \x89504e47...), parse it into binary
        const hex = decodedStr.slice(2);
        let binary = '';
        for (let i = 0; i < hex.length; i += 2) {
          binary += String.fromCharCode(parseInt(hex.substring(i, i + 2), 16));
        }
        // Encode the true binary back to base64
        const realBase64 = btoa(binary);
        return `data:image/png;base64,${realBase64}`;
      }
    } catch {
      // Ignore if it's not a valid base64 string or decode fails
    }
    // If it's a raw base64 string from a byte[] property
    return `data:image/png;base64,${path}`;
  }
  
  try {
    const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5247/api/v1';
    const origin = new URL(apiBaseUrl).origin;
    return `${origin}${path.startsWith('/') ? '' : '/'}${path}`;
  } catch {
    return `http://localhost:5247${path.startsWith('/') ? '' : '/'}${path}`;
  }
};

function formatDate(value?: string | null) {
  if (!value) {
    return 'Not available';
  }

  return new Date(value).toLocaleDateString();
}

function formatDateTime(value?: string | null) {
  if (!value) {
    return 'Not available';
  }

  return new Date(value).toLocaleString();
}

function formatDistance(value: number) {
  return `${value.toFixed(2)} km`;
}

function formatDuration(value: number) {
  const totalMinutes = Math.max(0, Math.round(value / 60));
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;

  if (hours === 0) {
    return `${minutes} min`;
  }

  return `${hours}h ${minutes}m`;
}

function formatCurrency(value?: number | null) {
  if (value == null) {
    return 'Not recorded';
  }

  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 2,
  }).format(value);
}

function getStatusStyle(status?: string | null) {
  const normalized = (status || '').toLowerCase();

  if (normalized.includes('active') || normalized.includes('published') || normalized.includes('approved')) {
    return { background: 'rgba(16, 185, 129, 0.12)', color: '#10b981' };
  }

  if (normalized.includes('pending') || normalized.includes('hold')) {
    return { background: 'rgba(245, 158, 11, 0.12)', color: '#f59e0b' };
  }

  if (normalized.includes('hidden') || normalized.includes('reject') || normalized.includes('ban') || normalized.includes('suspend')) {
    return { background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444' };
  }

  return { background: 'rgba(99, 102, 241, 0.12)', color: '#818cf8' };
}

function EmptyState({ message }: { message: string }) {
  return (
    <div
      style={{
        padding: '1.25rem',
        borderRadius: 'var(--radius)',
        background: 'rgba(255,255,255,0.03)',
        border: '1px solid hsl(var(--border))',
        color: 'hsl(var(--muted-foreground))',
        fontSize: '0.875rem',
      }}
    >
      {message}
    </div>
  );
}

export default function UserProfilePage() {
  const params = useParams();
  const router = useRouter();
  const userId = useMemo(() => {
    const value = params.id;
    return Array.isArray(value) ? value[0] : value;
  }, [params.id]);
  const [profile, setProfile] = useState<AdminUserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProfile = useCallback(async () => {
    if (!userId) {
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const response = await api.get(`/users/${userId}/profile`);
      setProfile(unwrapApiData<AdminUserProfile>(response));
    } catch (err) {
      console.error('Failed to load user profile', err);
      setError(getApiErrorMessage(err, 'Failed to load user profile.'));
      setProfile(null);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    void fetchProfile();
  }, [fetchProfile]);

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex-center" style={{ height: '60vh', flexDirection: 'column', gap: '1rem' }}>
          <div className="loader"></div>
          <p style={{ color: 'hsl(var(--muted-foreground))' }}>Loading user profile...</p>
        </div>
      </DashboardLayout>
    );
  }

  if (!profile) {
    return (
      <DashboardLayout>
        <div className="flex-center" style={{ height: '60vh', flexDirection: 'column', gap: '1rem' }}>
          <AlertTriangle size={44} color="#ef4444" />
          <h2 style={{ fontSize: '1.5rem', fontWeight: 700 }}>User profile unavailable</h2>
          <p style={{ color: 'hsl(var(--muted-foreground))' }}>{error || 'The requested user could not be loaded.'}</p>
          <button
            onClick={() => router.push('/users')}
            style={{ padding: '0.75rem 1.25rem', borderRadius: 'var(--radius)', border: 'none' }}
            className="premium-gradient"
          >
            Back to Users
          </button>
        </div>
      </DashboardLayout>
    );
  }

  const { summary, activity, loginHistory, customer, keeper } = profile;

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem' }}>
          <button
            onClick={() => router.push('/users')}
            style={{
              width: '42px',
              height: '42px',
              borderRadius: '50%',
              background: 'hsl(var(--secondary))',
              border: '1px solid hsl(var(--border))',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
            }}
          >
            <ArrowLeft size={18} />
          </button>
          <div style={{ flex: 1 }}>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.35rem' }}>User Profile</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))' }}>
              Full account context for {summary.fullName} with role-specific related data.
            </p>
          </div>
          <span
            style={{
              padding: '0.4rem 0.85rem',
              borderRadius: '999px',
              fontSize: '0.8rem',
              fontWeight: 700,
              textTransform: 'capitalize',
              ...getStatusStyle(summary.status),
            }}
          >
            {summary.status}
          </span>
        </div>

        {error && (
          <div
            style={{
              marginBottom: '1.5rem',
              padding: '0.875rem 1rem',
              borderRadius: 'var(--radius)',
              background: 'rgba(239, 68, 68, 0.12)',
              color: '#ef4444',
              fontSize: '0.875rem',
              fontWeight: 600,
            }}
          >
            {error}
          </div>
        )}

        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 2fr) minmax(300px, 1fr)', gap: '2rem' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="glass-card" style={{ padding: '2rem' }}>
              <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
                <div
                  style={{
                    width: '88px',
                    height: '88px',
                    borderRadius: '24px',
                    background: 'hsl(var(--secondary))',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '2rem',
                    fontWeight: 700,
                    overflow: 'hidden',
                  }}
                >
                  {summary.avatarUrl ? (
                    <img src={summary.avatarUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                  ) : (
                    summary.firstName?.[0] || summary.email?.[0] || '?'
                  )}
                </div>

                <div style={{ flex: 1, minWidth: '220px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                    <div>
                      <h2 style={{ fontSize: '1.8rem', fontWeight: 800, marginBottom: '0.5rem' }}>{summary.fullName}</h2>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.75rem' }}>
                        <span
                          style={{
                            padding: '0.35rem 0.75rem',
                            borderRadius: '999px',
                            background: 'rgba(129, 140, 248, 0.12)',
                            color: '#818cf8',
                            fontSize: '0.8rem',
                            fontWeight: 700,
                            textTransform: 'capitalize',
                          }}
                        >
                          {summary.role}
                        </span>
                        <span
                          style={{
                            padding: '0.35rem 0.75rem',
                            borderRadius: '999px',
                            background: summary.is2FAEnabled ? 'rgba(16, 185, 129, 0.12)' : 'rgba(245, 158, 11, 0.12)',
                            color: summary.is2FAEnabled ? '#10b981' : '#f59e0b',
                            fontSize: '0.8rem',
                            fontWeight: 700,
                          }}
                        >
                          {summary.is2FAEnabled ? '2FA enabled' : '2FA disabled'}
                        </span>
                      </div>
                    </div>
                    <div style={{ textAlign: 'right', minWidth: '200px' }}>
                      <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>Joined</p>
                      <p style={{ fontWeight: 700 }}>{formatDate(summary.createdAt)}</p>
                      <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.75rem' }}>Last login</p>
                      <p style={{ fontWeight: 700 }}>{formatDateTime(summary.lastLoginAt)}</p>
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(190px, 1fr))', gap: '1rem', marginTop: '1.5rem' }}>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                        <Mail size={14} /> Email
                      </p>
                      <p style={{ marginTop: '0.45rem', fontWeight: 700 }}>{summary.email}</p>
                    </div>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                        <Phone size={14} /> Phone
                      </p>
                      <p style={{ marginTop: '0.45rem', fontWeight: 700 }}>{summary.phone || 'Not provided'}</p>
                    </div>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                        <Shield size={14} /> Last login IP
                      </p>
                      <p style={{ marginTop: '0.45rem', fontWeight: 700 }}>{summary.lastLoginIp || 'Not recorded'}</p>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.05 }}
              style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem' }}
            >
              {[
                { label: 'Orders', value: activity.totalOrders, icon: Ticket },
                { label: 'Reviews', value: activity.totalReviews, icon: Star },
                { label: 'Reports', value: activity.totalReports, icon: AlertTriangle },
                { label: 'Warnings', value: summary.warningCount, icon: Shield },
              ].map((item) => (
                <div key={item.label} className="glass-card" style={{ padding: '1.25rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>{item.label}</p>
                    <item.icon size={18} color="hsl(var(--primary))" />
                  </div>
                  <p style={{ fontSize: '1.9rem', fontWeight: 800, marginTop: '0.75rem' }}>{item.value}</p>
                </div>
              ))}
            </motion.div>

            <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="glass-card" style={{ padding: '1.5rem' }}>
              <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem' }}>Recent Activity</h3>
              {activity.recentActivities.length === 0 ? (
                <EmptyState message="No recent activity recorded for this account." />
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                  {activity.recentActivities.map((item, index) => (
                    <div
                      key={`${item.type}-${item.timestamp}-${index}`}
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        gap: '1rem',
                        padding: '1rem',
                        borderRadius: 'var(--radius)',
                        background: 'rgba(255,255,255,0.03)',
                        border: '1px solid hsl(var(--border))',
                      }}
                    >
                      <div>
                        <p style={{ fontWeight: 700, textTransform: 'capitalize' }}>{item.type.replace(/_/g, ' ')}</p>
                        <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.35rem' }}>{item.description}</p>
                      </div>
                      <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', whiteSpace: 'nowrap' }}>
                        {formatDateTime(item.timestamp)}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </motion.div>

            {customer && (
              <>
                <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.15 }} className="glass-card" style={{ padding: '1.5rem' }}>
                  <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Route size={18} /> Journey History
                  </h3>
                  {customer.journeys.length === 0 ? (
                    <EmptyState message="No journeys found for this customer." />
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                      {customer.journeys.map((journey) => (
                        <div key={journey.journeyId} style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                            <div>
                              <p style={{ fontWeight: 700, textTransform: 'capitalize' }}>{journey.type}</p>
                              <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>
                                {journey.startName || 'Start not recorded'} to {journey.endName || 'In progress'}
                              </p>
                            </div>
                            <span style={{ padding: '0.3rem 0.7rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700, ...getStatusStyle(journey.endTime ? 'completed' : 'pending') }}>
                              {journey.endTime ? 'Completed' : 'In progress'}
                            </span>
                          </div>
                          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))', gap: '0.75rem', marginTop: '1rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Started</p>
                              <p style={{ fontWeight: 600 }}>{formatDateTime(journey.startTime)}</p>
                            </div>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Duration</p>
                              <p style={{ fontWeight: 600 }}>{formatDuration(journey.duration)}</p>
                            </div>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Distance</p>
                              <p style={{ fontWeight: 600 }}>{formatDistance(journey.distance)}</p>
                            </div>
                          </div>
                          {(journey.tags.length > 0 || journey.shopsEncountered.length > 0) && (
                            <div style={{ marginTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                              {journey.tags.length > 0 && (
                                <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                                  Tags: <span style={{ color: 'hsl(var(--foreground))' }}>{journey.tags.join(', ')}</span>
                                </p>
                              )}
                              {journey.shopsEncountered.length > 0 && (
                                <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                                  Shops encountered: <span style={{ color: 'hsl(var(--foreground))' }}>{journey.shopsEncountered.join(', ')}</span>
                                </p>
                              )}
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </motion.div>

                <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="glass-card" style={{ padding: '1.5rem' }}>
                  <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Ticket size={18} /> Redemptions
                  </h3>
                  {customer.redemptions.length === 0 ? (
                    <EmptyState message="No offer redemptions recorded." />
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                      {customer.redemptions.map((redemption) => (
                        <div key={redemption.redemptionId} style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                            <div>
                              <p style={{ fontWeight: 700 }}>{redemption.offerTitle}</p>
                              <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>{redemption.shopName}</p>
                            </div>
                            <span style={{ padding: '0.3rem 0.7rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700, ...getStatusStyle(redemption.status) }}>
                              {redemption.status}
                            </span>
                          </div>
                          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))', gap: '0.75rem', marginTop: '1rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Redeemed at</p>
                              <p style={{ fontWeight: 600 }}>{formatDateTime(redemption.redeemedAt)}</p>
                            </div>

                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </motion.div>

                <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.25 }} className="glass-card" style={{ padding: '1.5rem' }}>
                  <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Star size={18} /> Customer Reviews
                  </h3>
                  {customer.reviews.length === 0 ? (
                    <EmptyState message="This customer has not submitted any reviews." />
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                      {customer.reviews.map((review) => (
                        <div key={review.reviewId} style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                            <div>
                              <p style={{ fontWeight: 700 }}>{review.shopName}</p>
                              <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>
                                {review.offerTitle || 'Shop review'} | Rating {review.rating}/5
                              </p>
                            </div>
                            <span style={{ padding: '0.3rem 0.7rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700, ...getStatusStyle(review.status) }}>
                              {review.status}
                            </span>
                          </div>
                          <p style={{ marginTop: '0.85rem', lineHeight: 1.6 }}>{review.comment || 'No comment provided.'}</p>
                          {review.reply && (
                            <div style={{ marginTop: '0.85rem', padding: '0.85rem', borderRadius: 'var(--radius)', background: 'rgba(99, 102, 241, 0.08)', borderLeft: '3px solid #818cf8' }}>
                              <p style={{ fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.35rem' }}>Keeper reply</p>
                              <p style={{ fontSize: '0.875rem' }}>{review.reply}</p>
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </motion.div>
              </>
            )}

            {keeper && (
              <>
                <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.15 }} className="glass-card" style={{ padding: '1.5rem' }}>
                  <style dangerouslySetInnerHTML={{ __html: `
                    .hover-overlay {
                      opacity: 0 !important;
                      transition: opacity 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
                    }
                    .hover-overlay:hover {
                      opacity: 1 !important;
                    }
                  ` }} />
                  <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem' }}>Keeper Business Details</h3>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(190px, 1fr))', gap: '1rem' }}>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Business name</p>
                      <p style={{ marginTop: '0.4rem', fontWeight: 700 }}>{keeper.businessName}</p>
                    </div>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Status</p>
                      <p style={{ marginTop: '0.4rem', fontWeight: 700 }}>{keeper.status}</p>
                    </div>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Approved at</p>
                      <p style={{ marginTop: '0.4rem', fontWeight: 700 }}>{formatDateTime(keeper.approvedAt)}</p>
                    </div>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>GST number</p>
                      <p style={{ marginTop: '0.4rem', fontWeight: 700 }}>{keeper.gstNumber || 'Not provided'}</p>
                    </div>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>PAN number</p>
                      <p style={{ marginTop: '0.4rem', fontWeight: 700 }}>{keeper.panNumber || 'Not provided'}</p>
                    </div>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Business license</p>
                      <p style={{ marginTop: '0.4rem', fontWeight: 700 }}>
                        {keeper.businessLicense || 'Not provided'}
                        {keeper.businessLicenseNumber ? ` (${keeper.businessLicenseNumber})` : ''}
                      </p>
                    </div>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Identity proof</p>
                      <p style={{ marginTop: '0.4rem', fontWeight: 700 }}>
                        {keeper.identityProofType || 'Not provided'}
                        {keeper.identityProofNumber ? ` (${keeper.identityProofNumber})` : ''}
                      </p>
                    </div>
                    <div style={{ padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Address proof</p>
                      <p style={{ marginTop: '0.4rem', fontWeight: 700 }}>{keeper.addressProofType || 'Not provided'}</p>
                    </div>
                  </div>

                  {/* Verification Media Proofs */}
                  <div style={{ marginTop: '1.5rem', paddingTop: '1.5rem', borderTop: '1px solid hsl(var(--border))' }}>
                    <p style={{ fontSize: '0.875rem', fontWeight: 700, color: 'hsl(var(--muted-foreground))', textTransform: 'uppercase', marginBottom: '1rem' }}>Verification Credentials & Media Proofs</p>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: '1.25rem' }}>
                      {keeper.identityProofImage && (
                        <div style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem', background: 'rgba(255,255,255,0.01)' }}>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Identity Proof ({keeper.identityProofType || 'National ID'})</p>
                            <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>{keeper.identityProofNumber || 'N/A'}</p>
                          </div>
                          <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                            <img src={getFullImageUrl(keeper.identityProofImage)} alt="Identity Proof" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            <a href={getFullImageUrl(keeper.identityProofImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                              View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                            </a>
                          </div>
                        </div>
                      )}

                      {keeper.businessLicenseImage && (
                        <div style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem', background: 'rgba(255,255,255,0.01)' }}>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Business License</p>
                            <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>{keeper.businessLicenseNumber || 'N/A'}</p>
                          </div>
                          <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                            <img src={getFullImageUrl(keeper.businessLicenseImage)} alt="Business License" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            <a href={getFullImageUrl(keeper.businessLicenseImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                              View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                            </a>
                          </div>
                        </div>
                      )}

                      {keeper.gstCertificateImage && (
                        <div style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem', background: 'rgba(255,255,255,0.01)' }}>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>GST Certificate</p>
                            <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>{keeper.gstNumber || 'N/A'}</p>
                          </div>
                          <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                            <img src={getFullImageUrl(keeper.gstCertificateImage)} alt="GST Certificate" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            <a href={getFullImageUrl(keeper.gstCertificateImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                              View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                            </a>
                          </div>
                        </div>
                      )}

                      {keeper.panCardImage && (
                        <div style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem', background: 'rgba(255,255,255,0.01)' }}>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>PAN Card</p>
                            <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>{keeper.panNumber || 'N/A'}</p>
                          </div>
                          <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                            <img src={getFullImageUrl(keeper.panCardImage)} alt="PAN Card" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            <a href={getFullImageUrl(keeper.panCardImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                              View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                            </a>
                          </div>
                        </div>
                      )}

                      {keeper.addressProofImage && (
                        <div style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem', background: 'rgba(255,255,255,0.01)' }}>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Address Proof ({keeper.addressProofType || 'Utility Bill'})</p>
                            <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>Verified Address Proof</p>
                          </div>
                          <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                            <img src={getFullImageUrl(keeper.addressProofImage)} alt="Address Proof" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            <a href={getFullImageUrl(keeper.addressProofImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                              View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                            </a>
                          </div>
                        </div>
                      )}

                      {keeper.shopFrontImage && (
                        <div style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem', background: 'rgba(255,255,255,0.01)' }}>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Shop Front View</p>
                            <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>Exterior Storefront Image</p>
                          </div>
                          <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                            <img src={getFullImageUrl(keeper.shopFrontImage)} alt="Shop Front View" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            <a href={getFullImageUrl(keeper.shopFrontImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                              View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                            </a>
                          </div>
                        </div>
                      )}

                      {keeper.shopInsideImage && (
                        <div style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem', background: 'rgba(255,255,255,0.01)' }}>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Shop Inside View</p>
                            <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>Interior Store Image</p>
                          </div>
                          <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                            <img src={getFullImageUrl(keeper.shopInsideImage)} alt="Shop Inside View" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            <a href={getFullImageUrl(keeper.shopInsideImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                              View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                            </a>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>

                  {keeper.rejectionReason && (
                    <div style={{ marginTop: '1rem', padding: '1rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.2)', color: '#fca5a5' }}>
                      <p style={{ fontWeight: 700, marginBottom: '0.35rem' }}>Rejection reason</p>
                      <p>{keeper.rejectionReason}</p>
                    </div>
                  )}
                </motion.div>

                <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="glass-card" style={{ padding: '1.5rem' }}>
                  <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <FileText size={18} /> Keeper Documents
                  </h3>
                  {keeper.documents.length === 0 ? (
                    <EmptyState message="No keeper documents are attached." />
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                      {keeper.documents.map((document) => (
                        <div key={document.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '1rem', padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)' }}>
                          <div>
                            <p style={{ fontWeight: 700 }}>{document.name}</p>
                            <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>{document.type}</p>
                          </div>
                          <a href={document.url} target="_blank" rel="noreferrer" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem', color: 'hsl(var(--primary))', fontWeight: 700 }}>
                            Open <ExternalLink size={14} />
                          </a>
                        </div>
                      ))}
                    </div>
                  )}
                </motion.div>

                <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.25 }} className="glass-card" style={{ padding: '1.5rem' }}>
                  <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Store size={18} /> Shops
                  </h3>
                  {keeper.shops.length === 0 ? (
                    <EmptyState message="No shops are linked to this keeper." />
                  ) : (
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem' }}>
                      {keeper.shops.map((shop) => (
                        <div key={shop.id} style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.75rem' }}>
                            <div>
                              <p style={{ fontWeight: 700 }}>{shop.name}</p>
                              <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>{shop.category || 'General'}</p>
                            </div>
                            <span style={{ padding: '0.3rem 0.65rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700, ...getStatusStyle(shop.status) }}>
                              {shop.status}
                            </span>
                          </div>
                          <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                            <MapPin size={14} /> {shop.location || 'Location not recorded'}
                          </p>
                          <p style={{ marginTop: '0.75rem', fontSize: '0.8rem', color: shop.isVerified ? '#10b981' : '#f59e0b', fontWeight: 700 }}>
                            {shop.isVerified ? 'Verified shop' : 'Verification pending'}
                          </p>
                        </div>
                      ))}
                    </div>
                  )}
                </motion.div>

                <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="glass-card" style={{ padding: '1.5rem' }}>
                  <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem' }}>Offers</h3>
                  {keeper.offers.length === 0 ? (
                    <EmptyState message="No offers found for this keeper." />
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                      {keeper.offers.map((offer) => (
                        <div key={offer.id} style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                            <div>
                              <p style={{ fontWeight: 700 }}>{offer.title}</p>
                              <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>{offer.shopName}</p>
                            </div>
                            <span style={{ padding: '0.3rem 0.7rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700, ...getStatusStyle(offer.status) }}>
                              {offer.status}
                            </span>
                          </div>
                          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))', gap: '0.75rem', marginTop: '1rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Start date</p>
                              <p style={{ fontWeight: 600 }}>{formatDate(offer.startDate)}</p>
                            </div>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>End date</p>
                              <p style={{ fontWeight: 600 }}>{formatDate(offer.endDate)}</p>
                            </div>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Redemptions</p>
                              <p style={{ fontWeight: 600 }}>{offer.redemptions}</p>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </motion.div>

                <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.35 }} className="glass-card" style={{ padding: '1.5rem' }}>
                  <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Star size={18} /> Shop Reviews
                  </h3>
                  {keeper.shopReviews.length === 0 ? (
                    <EmptyState message="No shop reviews are linked to this keeper." />
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                      {keeper.shopReviews.map((review) => (
                        <div key={review.reviewId} style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', minWidth: 0 }}>
                              <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'hsl(var(--secondary))', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, overflow: 'hidden', flex: '0 0 auto' }}>
                                {review.userAvatarUrl ? (
                                  <img src={review.userAvatarUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                                ) : (
                                  review.userName?.[0] || '?'
                                )}
                              </div>
                              <div style={{ minWidth: 0 }}>
                                <p style={{ fontWeight: 700 }}>{review.userName}</p>
                                <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>
                                  {review.shopName} | Rating {review.rating}/5
                                </p>
                              </div>
                            </div>
                            <span style={{ padding: '0.3rem 0.7rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700, ...getStatusStyle(review.status) }}>
                              {review.status}
                            </span>
                          </div>
                          <p style={{ marginTop: '0.85rem', lineHeight: 1.6 }}>{review.comment || 'No comment provided.'}</p>
                          {review.reply && (
                            <div style={{ marginTop: '0.85rem', padding: '0.85rem', borderRadius: 'var(--radius)', background: 'rgba(99, 102, 241, 0.08)', borderLeft: '3px solid #818cf8' }}>
                              <p style={{ fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.35rem' }}>Keeper reply</p>
                              <p style={{ fontSize: '0.875rem' }}>{review.reply}</p>
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </motion.div>
              </>
            )}
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <motion.div initial={{ opacity: 0, x: 16 }} animate={{ opacity: 1, x: 0 }} className="glass-card" style={{ padding: '1.5rem' }}>
              <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1rem' }}>Account Snapshot</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem' }}>
                  <span style={{ color: 'hsl(var(--muted-foreground))' }}>User ID</span>
                  <span style={{ fontWeight: 700, fontFamily: 'monospace' }}>{summary.userId.slice(0, 12)}...</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem' }}>
                  <span style={{ color: 'hsl(var(--muted-foreground))' }}>Created</span>
                  <span style={{ fontWeight: 700 }}>{formatDateTime(summary.createdAt)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem' }}>
                  <span style={{ color: 'hsl(var(--muted-foreground))' }}>Last active</span>
                  <span style={{ fontWeight: 700 }}>{formatDateTime(activity.lastActiveAt)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem' }}>
                  <span style={{ color: 'hsl(var(--muted-foreground))' }}>Total reviews</span>
                  <span style={{ fontWeight: 700 }}>{summary.totalReviews}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem' }}>
                  <span style={{ color: 'hsl(var(--muted-foreground))' }}>Total orders</span>
                  <span style={{ fontWeight: 700 }}>{summary.totalOrders}</span>
                </div>
              </div>
            </motion.div>

            <motion.div initial={{ opacity: 0, x: 16 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.08 }} className="glass-card" style={{ padding: '1.5rem' }}>
              <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Clock size={18} /> Login History
              </h3>
              {loginHistory.length === 0 ? (
                <EmptyState message="No login history entries are available." />
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                  {loginHistory.map((entry, index) => (
                    <div key={`${entry.loginAt}-${entry.ipAddress}-${index}`} style={{ padding: '0.95rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                        <p style={{ fontWeight: 700 }}>{formatDateTime(entry.loginAt)}</p>
                        <span style={{ padding: '0.25rem 0.65rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700, ...getStatusStyle(entry.success ? 'active' : 'hidden') }}>
                          {entry.success ? 'Success' : 'Failed'}
                        </span>
                      </div>
                      <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.45rem' }}>IP: {entry.ipAddress || 'Unknown'}</p>
                      {entry.location && (
                        <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>Location: {entry.location}</p>
                      )}
                      {entry.userAgent && (
                        <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>{entry.userAgent}</p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </motion.div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
