'use client';

/* eslint-disable @next/next/no-img-element */

import React, { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  BadgeCheck,
  Building,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Clock,
  Eye,
  Filter,
  Layers,
  MapPin,
  RefreshCw,
  Search,
  ShieldCheck,
  Store,
  X,
  XCircle,
} from 'lucide-react';
import { AnimatePresence, motion } from 'framer-motion';
import api from '@/lib/api';
import { unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';
import CustomSelect from '@/components/CustomSelect';

interface Shop {
  id: string;
  name: string;
  businessName: string;
  category: string;
  location: string;
  status: string;
  isVerified: boolean;
  verifyStatus: string;
  isOpen?: boolean;
  shopProfileImage?: string | null;
  rejectionReason?: string | null;
  deactivateReason?: string | null;
}

type StatusFilter = 'all' | 'active' | 'inactive';
type VerifyFilter = 'all' | 'Pending' | 'Verified' | 'Rejected' | 'Deactivated';
type ActionType = 'verify' | 'reject' | 'activate' | 'deactivate' | null;
type Toast = { tone: 'success' | 'error'; message: string };
type Tone = { background: string; color: string; border: string };

const PAGE_SIZE = 10;

const statusTabs: Array<{ value: StatusFilter; label: string }> = [
  { value: 'all', label: 'All Shops' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
];

const verifyOptions: Array<{ value: VerifyFilter; label: string }> = [
  { value: 'all', label: 'All Verification States' },
  { value: 'Pending', label: 'Pending Review' },
  { value: 'Verified', label: 'Verified' },
  { value: 'Rejected', label: 'Rejected' },
  { value: 'Deactivated', label: 'Deactivated' },
];

function SummaryCard({
  label,
  value,
  helper,
  accent,
  icon,
}: {
  label: string;
  value: string;
  helper: string;
  accent: string;
  icon: React.ReactNode;
}) {
  return (
    <div
      style={{
        padding: '1rem',
        borderRadius: '18px',
        border: `1px solid ${accent}22`,
        background: `linear-gradient(180deg, ${accent}14 0%, rgba(255, 255, 255, 0.02) 100%)`,
        minHeight: '118px',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
      }}
    >
      <div
        style={{
          width: '42px',
          height: '42px',
          borderRadius: '14px',
          background: `${accent}20`,
          color: accent,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {icon}
      </div>
      <div>
        <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 700, letterSpacing: '0.03em', textTransform: 'uppercase' }}>
          {label}
        </p>
        <p style={{ fontSize: '1.55rem', fontWeight: 800, marginTop: '0.2rem', letterSpacing: '-0.02em' }}>{value}</p>
        <p style={{ fontSize: '0.78rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.3rem', lineHeight: 1.45 }}>{helper}</p>
      </div>
    </div>
  );
}

function getOperationalTone(status: string): Tone {
  switch (status.toLowerCase()) {
    case 'active':
      return {
        background: 'rgba(16, 185, 129, 0.12)',
        color: '#10b981',
        border: 'rgba(16, 185, 129, 0.22)',
      };
    case 'inactive':
      return {
        background: 'rgba(239, 68, 68, 0.12)',
        color: '#ef4444',
        border: 'rgba(239, 68, 68, 0.22)',
      };
    case 'flagged':
      return {
        background: 'rgba(245, 158, 11, 0.12)',
        color: '#f59e0b',
        border: 'rgba(245, 158, 11, 0.22)',
      };
    default:
      return {
        background: 'rgba(107, 114, 128, 0.12)',
        color: '#6b7280',
        border: 'rgba(107, 114, 128, 0.2)',
      };
  }
}

function getVerificationTone(status: string): Tone {
  switch (status.toLowerCase()) {
    case 'verified':
      return {
        background: 'rgba(16, 185, 129, 0.12)',
        color: '#10b981',
        border: 'rgba(16, 185, 129, 0.22)',
      };
    case 'rejected':
    case 'deactivated':
      return {
        background: 'rgba(239, 68, 68, 0.12)',
        color: '#ef4444',
        border: 'rgba(239, 68, 68, 0.22)',
      };
    default:
      return {
        background: 'rgba(245, 158, 11, 0.12)',
        color: '#f59e0b',
        border: 'rgba(245, 158, 11, 0.22)',
      };
  }
}

function getAttentionNote(shop: Shop) {
  if (shop.verifyStatus.toLowerCase() === 'rejected' && shop.rejectionReason?.trim()) {
    return {
      label: 'Rejection note',
      value: shop.rejectionReason.trim(),
      tone: {
        background: 'rgba(239, 68, 68, 0.08)',
        color: '#ef4444',
        border: 'rgba(239, 68, 68, 0.18)',
      },
    };
  }

  if (shop.status.toLowerCase() === 'inactive' && shop.deactivateReason?.trim()) {
    return {
      label: 'Deactivation note',
      value: shop.deactivateReason.trim(),
      tone: {
        background: 'rgba(245, 158, 11, 0.08)',
        color: '#d97706',
        border: 'rgba(245, 158, 11, 0.18)',
      },
    };
  }

  return null;
}

function getActionDetails(type: Exclude<ActionType, null>) {
  switch (type) {
    case 'verify':
      return {
        title: 'Approve Verification',
        description: 'This shop will be marked as verified. You can optionally leave an internal approval note.',
        confirmLabel: 'Approve Shop',
        tone: '#10b981',
        requiresReason: false,
      };
    case 'reject':
      return {
        title: 'Reject Verification',
        description: 'Add a clear rejection reason. This message helps the team understand what blocked approval.',
        confirmLabel: 'Reject Shop',
        tone: '#ef4444',
        requiresReason: true,
      };
    case 'activate':
      return {
        title: 'Activate Shop',
        description: 'Re-enable this shop for admin operations and restore its active status.',
        confirmLabel: 'Activate Shop',
        tone: '#10b981',
        requiresReason: false,
      };
    case 'deactivate':
      return {
        title: 'Deactivate Shop',
        description: 'Add the reason for deactivation so future reviewers can understand the decision.',
        confirmLabel: 'Deactivate Shop',
        tone: '#ef4444',
        requiresReason: true,
      };
    default:
      return null;
  }
}

function formatShortId(id: string) {
  return id.slice(0, 8).toUpperCase();
}

function buildActionButtonStyle(background: string, color: string, border?: string): React.CSSProperties {
  return {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '0.4rem',
    padding: '0.62rem 0.9rem',
    borderRadius: '12px',
    border: border ? `1px solid ${border}` : '1px solid transparent',
    background,
    color,
    fontWeight: 700,
    fontSize: '0.8rem',
    lineHeight: 1,
    minHeight: '40px',
  };
}

export default function ShopsPage() {
  const router = useRouter();
  const { hasPermission } = useAuth();
  const canApproveShops = hasPermission(PERMISSIONS.shopsApprove);

  const [shops, setShops] = useState<Shop[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [verifyFilter, setVerifyFilter] = useState<VerifyFilter>('all');
  const [toast, setToast] = useState<Toast | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalShops, setTotalShops] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [activeAction, setActiveAction] = useState<{ type: ActionType; shopId: string }>({ type: null, shopId: '' });
  const [actionReason, setActionReason] = useState('');
  const [submittingAction, setSubmittingAction] = useState(false);

  const showToast = (tone: Toast['tone'], message: string) => {
    setToast({ tone, message });
    window.setTimeout(() => setToast(null), 3200);
  };

  const fetchShops = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const response = await api.get('/admin/shops', {
        params: {
          search: search.trim() || undefined,
          isActive: statusFilter === 'all' ? undefined : statusFilter === 'active',
          verifyStatus: verifyFilter === 'all' ? undefined : verifyFilter,
          pageNumber: page,
          pageSize: PAGE_SIZE,
        },
      });

      const { data, pagination } = unwrapPagedResponse<Shop>(response);
      const nextTotalPages = pagination?.totalPages || 1;

      setShops(data || []);
      setTotalPages(nextTotalPages);
      setTotalShops(pagination?.totalCount || 0);

      if (page > nextTotalPages) {
        setPage(nextTotalPages);
      }
    } catch (err) {
      console.error('Failed to fetch shops', err);
      setError(getApiErrorMessage(err, 'Failed to fetch shops.'));
    } finally {
      setLoading(false);
    }
  }, [page, search, statusFilter, verifyFilter]);

  const handleUpdateStatus = async (id: string, nextIsActive: boolean, reason?: string) => {
    setSubmittingAction(true);

    try {
      await api.put(`/admin/shops/${id}/status`, {
        isActive: nextIsActive,
        reason: reason?.trim() || undefined,
      });

      setActiveAction({ type: null, shopId: '' });
      setActionReason('');
      showToast('success', `Shop ${nextIsActive ? 'activated' : 'deactivated'} successfully.`);
      await fetchShops();
    } catch (err) {
      console.error('Status update failed', err);
      const message = getApiErrorMessage(err, 'Failed to update status.');
      setError(message);
      showToast('error', message);
    } finally {
      setSubmittingAction(false);
    }
  };

  const handleVerifyAction = async (id: string, isVerify: boolean, reason?: string) => {
    setSubmittingAction(true);

    try {
      if (isVerify) {
        await api.post(`/admin/shops/${id}/verify`, { reason: reason?.trim() || undefined });
        showToast('success', 'Shop verified successfully.');
      } else {
        await api.post(`/admin/shops/${id}/reject`, { reason: reason?.trim() || '' });
        showToast('success', 'Shop rejected successfully.');
      }

      setActiveAction({ type: null, shopId: '' });
      setActionReason('');
      await fetchShops();
    } catch (err) {
      console.error('Verification failed', err);
      const message = getApiErrorMessage(err, `Failed to ${isVerify ? 'verify' : 'reject'} shop.`);
      setError(message);
      showToast('error', message);
    } finally {
      setSubmittingAction(false);
    }
  };

  useEffect(() => {
    const debounce = window.setTimeout(() => {
      void fetchShops();
    }, 250);

    return () => window.clearTimeout(debounce);
  }, [fetchShops]);

  const activeOnPage = shops.filter((shop) => shop.status.toLowerCase() === 'active').length;
  const inactiveOnPage = shops.filter((shop) => shop.status.toLowerCase() === 'inactive').length;
  const pendingOnPage = shops.filter((shop) => shop.verifyStatus.toLowerCase() === 'pending').length;
  const verifiedOnPage = shops.filter((shop) => shop.verifyStatus.toLowerCase() === 'verified').length;
  const hasFilters = search.trim().length > 0 || statusFilter !== 'all' || verifyFilter !== 'all';
  const rangeStart = totalShops === 0 ? 0 : (page - 1) * PAGE_SIZE + 1;
  const rangeEnd = totalShops === 0 ? 0 : Math.min(totalShops, (page - 1) * PAGE_SIZE + shops.length);
  const selectedShop = shops.find((shop) => shop.id === activeAction.shopId) || null;
  const actionDetails = activeAction.type ? getActionDetails(activeAction.type) : null;

  return (
    <DashboardLayout>
      <div className="animate-fade-in" style={{ display: 'grid', gap: '1.5rem', paddingBottom: '2rem' }}>
        <style
          dangerouslySetInnerHTML={{
            __html: `
              .shops-hero-grid {
                display: grid;
                grid-template-columns: minmax(0, 1.5fr) repeat(3, minmax(150px, 1fr));
                gap: 1rem;
                align-items: stretch;
              }

              .shops-toolbar-grid {
                display: grid;
                grid-template-columns: minmax(280px, 1.6fr) minmax(210px, 0.8fr) auto auto;
                gap: 0.85rem;
                align-items: center;
              }

              .shops-filter-row,
              .shops-pill-row {
                display: flex;
                align-items: center;
                gap: 0.75rem;
                flex-wrap: wrap;
              }

              .shop-list {
                display: flex;
                flex-direction: column;
                gap: 0.95rem;
              }

              .shop-row {
                display: grid;
                grid-template-columns: minmax(0, 1.6fr) minmax(240px, 0.95fr) auto;
                gap: 1rem;
                align-items: center;
                padding: 1.1rem;
                border-radius: 22px;
                border: 1px solid rgba(148, 163, 184, 0.18);
                background:
                  linear-gradient(180deg, rgba(255, 255, 255, 0.045) 0%, rgba(255, 255, 255, 0.02) 100%);
                transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
                cursor: pointer;
              }

              .shop-row:hover {
                transform: translateY(-2px);
                border-color: rgba(99, 102, 241, 0.28);
                box-shadow: 0 18px 36px rgba(15, 23, 42, 0.08);
              }

              .shop-primary {
                display: flex;
                align-items: flex-start;
                gap: 1rem;
                min-width: 0;
              }

              .shop-avatar {
                width: 58px;
                height: 58px;
                border-radius: 18px;
                overflow: hidden;
                flex: 0 0 auto;
                display: flex;
                align-items: center;
                justify-content: center;
                background: linear-gradient(135deg, rgba(99, 102, 241, 0.18) 0%, rgba(16, 185, 129, 0.12) 100%);
                border: 1px solid rgba(99, 102, 241, 0.18);
                color: hsl(var(--primary));
              }

              .shop-inline-meta {
                display: flex;
                align-items: center;
                gap: 0.75rem;
                flex-wrap: wrap;
                margin-top: 0.55rem;
              }

              .shop-meta-chip {
                display: inline-flex;
                align-items: center;
                gap: 0.42rem;
                padding: 0.42rem 0.65rem;
                border-radius: 999px;
                background: rgba(148, 163, 184, 0.1);
                border: 1px solid rgba(148, 163, 184, 0.15);
                color: hsl(var(--muted-foreground));
                font-size: 0.76rem;
                font-weight: 700;
                max-width: 100%;
              }

              .shop-meta-chip span {
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
              }

              .shop-side {
                display: flex;
                flex-direction: column;
                gap: 0.7rem;
              }

              .shop-actions {
                display: flex;
                flex-wrap: wrap;
                justify-content: flex-end;
                gap: 0.6rem;
                align-items: center;
                min-width: 0;
              }

              .shop-note {
                margin-top: 0.8rem;
                padding: 0.75rem 0.9rem;
                border-radius: 14px;
                font-size: 0.8rem;
                line-height: 1.45;
              }

              .shop-skeleton {
                height: 0.95rem;
                border-radius: 999px;
                background: linear-gradient(90deg, rgba(148, 163, 184, 0.08), rgba(148, 163, 184, 0.18), rgba(148, 163, 184, 0.08));
                background-size: 200% 100%;
                animation: shopSkeleton 1.4s linear infinite;
              }

              @keyframes shopSkeleton {
                0% { background-position: 200% 0; }
                100% { background-position: -200% 0; }
              }

              @media (max-width: 1200px) {
                .shops-hero-grid {
                  grid-template-columns: repeat(2, minmax(0, 1fr));
                }

                .shops-toolbar-grid {
                  grid-template-columns: repeat(2, minmax(0, 1fr));
                }

                .shop-row {
                  grid-template-columns: minmax(0, 1fr);
                }

                .shop-actions {
                  justify-content: flex-start;
                }
              }

              @media (max-width: 720px) {
                .shops-hero-grid,
                .shops-toolbar-grid {
                  grid-template-columns: 1fr;
                }

                .shop-primary {
                  flex-direction: column;
                }

                .shop-avatar {
                  width: 64px;
                  height: 64px;
                }
              }
            `,
          }}
        />

        <AnimatePresence>
          {toast && (
            <motion.div
              initial={{ opacity: 0, y: -14, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -14, scale: 0.96 }}
              style={{
                position: 'fixed',
                top: '1.5rem',
                right: '1.5rem',
                zIndex: 1200,
                padding: '0.85rem 1.2rem',
                borderRadius: '16px',
                background:
                  toast.tone === 'error'
                    ? 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)'
                    : 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                color: 'white',
                fontWeight: 700,
                fontSize: '0.875rem',
                boxShadow: '0 18px 38px rgba(15, 23, 42, 0.2)',
                display: 'flex',
                alignItems: 'center',
                gap: '0.55rem',
              }}
            >
              {toast.tone === 'error' ? <XCircle size={18} /> : <CheckCircle2 size={18} />}
              {toast.message}
            </motion.div>
          )}
        </AnimatePresence>

        <motion.section
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass-card"
          style={{
            padding: '1.5rem',
            position: 'relative',
            overflow: 'hidden',
            background:
              'radial-gradient(circle at top left, rgba(99, 102, 241, 0.12) 0%, transparent 35%), radial-gradient(circle at bottom right, rgba(16, 185, 129, 0.1) 0%, transparent 32%)',
          }}
        >
          <div
            style={{
              position: 'absolute',
              top: '-70px',
              right: '-70px',
              width: '180px',
              height: '180px',
              borderRadius: '50%',
              background: 'rgba(99, 102, 241, 0.12)',
              filter: 'blur(20px)',
            }}
          />

          <div className="shops-hero-grid" style={{ position: 'relative' }}>
            

            <SummaryCard
              label="Matching Shops"
              value={totalShops.toLocaleString()}
              helper="Total rows matching the current filters."
              accent="#6366f1"
              icon={<Store size={19} />}
            />
            <SummaryCard
              label="Pending Review"
              value={pendingOnPage.toLocaleString()}
              helper="Pending verification shops on this page."
              accent="#f59e0b"
              icon={<Clock size={19} />}
            />
            <SummaryCard
              label="Verified On Page"
              value={verifiedOnPage.toLocaleString()}
              helper="Visible listings already approved."
              accent="#10b981"
              icon={<BadgeCheck size={19} />}
            />
          </div>
        </motion.section>

        <section className="glass-card" style={{ padding: '1rem' }}>
          {error && (
            <div
              style={{
                marginBottom: '1rem',
                padding: '0.875rem 1rem',
                borderRadius: '16px',
                background: 'rgba(239, 68, 68, 0.12)',
                color: '#ef4444',
                fontSize: '0.875rem',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                gap: '0.55rem',
              }}
            >
              <AlertTriangle size={18} />
              {error}
            </div>
          )}

          <div className="shops-toolbar-grid">
            <div style={{ position: 'relative' }}>
              <Search size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
              <input
                placeholder="Search by shop name, business, location, or ID..."
                value={search}
                onChange={(event) => {
                  setSearch(event.target.value);
                  setPage(1);
                }}
                style={{
                  width: '100%',
                  padding: '0.85rem 1rem 0.85rem 2.75rem',
                  borderRadius: '16px',
                  border: '1px solid hsl(var(--border))',
                  background: 'hsl(var(--secondary))',
                  color: 'hsl(var(--foreground))',
                  outline: 'none',
                  fontWeight: 500,
                }}
              />
            </div>

              <CustomSelect
                value={verifyFilter}
                onChange={(val) => {
                  setVerifyFilter(val as VerifyFilter);
                  setPage(1);
                }}
                options={[
                  { value: 'all', label: 'All Verification States', icon: <Filter size={16} /> },
                  { value: 'Pending', label: 'Pending Review', icon: <Clock size={16} />, color: '#f59e0b' },
                  { value: 'Verified', label: 'Verified', icon: <ShieldCheck size={16} />, color: '#10b981' },
                  { value: 'Rejected', label: 'Rejected', icon: <XCircle size={16} />, color: '#ef4444' },
                  { value: 'Deactivated', label: 'Deactivated', icon: <XCircle size={16} />, color: '#ef4444' },
                ]}
                style={{ width: '100%', minWidth: '220px' }}
                className="shops-verify-select"
              />

            <button
              onClick={() => void fetchShops()}
              disabled={loading}
              style={{
                ...buildActionButtonStyle('hsl(var(--secondary))', 'hsl(var(--foreground))', 'hsl(var(--border))'),
                minWidth: '120px',
                opacity: loading ? 0.75 : 1,
              }}
            >
              <RefreshCw size={15} />
              Refresh
            </button>

            <button
              onClick={() => {
                setSearch('');
                setStatusFilter('all');
                setVerifyFilter('all');
                setPage(1);
              }}
              disabled={!hasFilters}
              style={{
                ...buildActionButtonStyle('transparent', 'hsl(var(--muted-foreground))', 'hsl(var(--border))'),
                minWidth: '120px',
                opacity: hasFilters ? 1 : 0.55,
              }}
            >
              <X size={15} />
              Clear
            </button>
          </div>

          <div style={{ marginTop: '1rem', display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap', alignItems: 'center' }}>
            <div className="shops-filter-row">
              {statusTabs.map((tab) => {
                const active = statusFilter === tab.value;

                return (
                  <button
                    key={tab.value}
                    onClick={() => {
                      setStatusFilter(tab.value);
                      setPage(1);
                    }}
                    style={{
                      padding: '0.62rem 0.95rem',
                      borderRadius: '999px',
                      border: active ? '1px solid transparent' : '1px solid hsl(var(--border))',
                      background:
                        active && tab.value === 'active'
                          ? 'linear-gradient(135deg, #10b981 0%, #059669 100%)'
                          : active && tab.value === 'inactive'
                            ? 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)'
                            : active
                              ? 'linear-gradient(135deg, hsl(var(--primary)) 0%, #8b5cf6 100%)'
                              : 'hsl(var(--secondary))',
                      color: active ? 'white' : 'hsl(var(--foreground))',
                      fontWeight: 800,
                      fontSize: '0.8rem',
                    }}
                  >
                    {tab.label}
                  </button>
                );
              })}
            </div>

            <div className="shops-filter-row" style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.83rem', fontWeight: 700 }}>
              <span>
                Showing <span style={{ color: 'hsl(var(--foreground))' }}>{rangeStart}-{rangeEnd}</span> of{' '}
                <span style={{ color: 'hsl(var(--foreground))' }}>{totalShops}</span>
              </span>
              <span
                style={{
                  width: '6px',
                  height: '6px',
                  borderRadius: '50%',
                  background: 'rgba(148, 163, 184, 0.5)',
                }}
              />
              <span>{activeOnPage} active on this page</span>
              <span
                style={{
                  width: '6px',
                  height: '6px',
                  borderRadius: '50%',
                  background: 'rgba(148, 163, 184, 0.5)',
                }}
              />
              <span>{inactiveOnPage} inactive on this page</span>
            </div>
          </div>
        </section>

        <section className="glass-card" style={{ padding: '1rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap', alignItems: 'center', marginBottom: '1rem' }}>
            <div>
              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Operational Queue
              </p>
              <h2 style={{ fontSize: '1.2rem', fontWeight: 800, marginTop: '0.2rem' }}>Review, approve, and manage shops faster</h2>
            </div>

            <div className="shops-pill-row">
              <span style={{ ...buildActionButtonStyle('rgba(16, 185, 129, 0.08)', '#10b981', 'rgba(16, 185, 129, 0.18)'), minWidth: 'unset', padding: '0.45rem 0.75rem' }}>
                <BadgeCheck size={14} />
                Verified
              </span>
              <span style={{ ...buildActionButtonStyle('rgba(245, 158, 11, 0.08)', '#f59e0b', 'rgba(245, 158, 11, 0.18)'), minWidth: 'unset', padding: '0.45rem 0.75rem' }}>
                <Clock size={14} />
                Pending
              </span>
              <span style={{ ...buildActionButtonStyle('rgba(239, 68, 68, 0.08)', '#ef4444', 'rgba(239, 68, 68, 0.18)'), minWidth: 'unset', padding: '0.45rem 0.75rem' }}>
                <AlertTriangle size={14} />
                Needs attention
              </span>
            </div>
          </div>

          {loading && shops.length === 0 ? (
            <div className="shop-list">
              {Array.from({ length: 4 }).map((_, index) => (
                <div key={index} className="shop-row" style={{ cursor: 'default' }}>
                  <div className="shop-primary">
                    <div className="shop-avatar" style={{ background: 'rgba(148, 163, 184, 0.08)', borderColor: 'rgba(148, 163, 184, 0.16)' }}>
                      <Store size={22} color="rgba(148, 163, 184, 0.65)" />
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div className="shop-skeleton" style={{ width: '42%', marginBottom: '0.6rem' }} />
                      <div className="shop-skeleton" style={{ width: '65%', marginBottom: '0.7rem' }} />
                      <div className="shop-inline-meta">
                        <div className="shop-skeleton" style={{ width: '120px', height: '32px' }} />
                        <div className="shop-skeleton" style={{ width: '150px', height: '32px' }} />
                      </div>
                    </div>
                  </div>
                  <div className="shop-side">
                    <div className="shop-skeleton" style={{ height: '36px' }} />
                    <div className="shop-skeleton" style={{ height: '36px' }} />
                  </div>
                  <div className="shop-actions">
                    <div className="shop-skeleton" style={{ width: '110px', height: '40px' }} />
                    <div className="shop-skeleton" style={{ width: '110px', height: '40px' }} />
                  </div>
                </div>
              ))}
            </div>
          ) : shops.length === 0 ? (
            <div
              style={{
                padding: '3.25rem 1.5rem',
                borderRadius: '22px',
                border: '1px dashed hsl(var(--border))',
                background: 'rgba(255, 255, 255, 0.03)',
                textAlign: 'center',
              }}
            >
              <div
                style={{
                  width: '64px',
                  height: '64px',
                  borderRadius: '20px',
                  background: 'rgba(99, 102, 241, 0.08)',
                  color: 'hsl(var(--primary))',
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginBottom: '1rem',
                }}
              >
                <Store size={28} />
              </div>
              <h3 style={{ fontSize: '1.15rem', fontWeight: 800 }}>No shops match the current view</h3>
              <p style={{ marginTop: '0.45rem', color: 'hsl(var(--muted-foreground))', lineHeight: 1.6, maxWidth: '560px', marginInline: 'auto' }}>
                Try widening the search or clearing filters to bring more shops back into the directory.
              </p>
              {hasFilters && (
                <button
                  onClick={() => {
                    setSearch('');
                    setStatusFilter('all');
                    setVerifyFilter('all');
                    setPage(1);
                  }}
                  style={{
                    ...buildActionButtonStyle('hsl(var(--secondary))', 'hsl(var(--foreground))', 'hsl(var(--border))'),
                    marginTop: '1.2rem',
                    minWidth: '140px',
                  }}
                >
                  Reset Filters
                </button>
              )}
            </div>
          ) : (
            <div className="shop-list">
              <AnimatePresence mode="popLayout">
                {shops.map((shop, index) => {
                  const operationalTone = getOperationalTone(shop.status);
                  const verificationTone = getVerificationTone(shop.verifyStatus);
                  const attentionNote = getAttentionNote(shop);

                  return (
                    <motion.article
                      key={shop.id}
                      layout
                      initial={{ opacity: 0, y: 12 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -12 }}
                      transition={{ delay: index * 0.03 }}
                      className="shop-row"
                      onClick={() => router.push(`/shops/${shop.id}`)}
                    >
                      <div className="shop-primary">
                        <div className="shop-avatar">
                          {shop.shopProfileImage ? (
                            <img src={shop.shopProfileImage} alt={shop.name} style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                          ) : (
                            <Store size={24} />
                          )}
                        </div>

                        <div style={{ minWidth: 0, flex: 1 }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', flexWrap: 'wrap' }}>
                            <h3 style={{ fontSize: '1.06rem', fontWeight: 800, letterSpacing: '-0.02em', overflowWrap: 'anywhere' }}>{shop.name}</h3>
                            {shop.isVerified && (
                              <span
                                style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: '0.35rem',
                                  padding: '0.32rem 0.58rem',
                                  borderRadius: '999px',
                                  background: 'rgba(16, 185, 129, 0.12)',
                                  color: '#10b981',
                                  fontSize: '0.72rem',
                                  fontWeight: 800,
                                }}
                              >
                                <BadgeCheck size={13} />
                                Trusted
                              </span>
                            )}
                          </div>

                          <p style={{ marginTop: '0.35rem', color: 'hsl(var(--muted-foreground))', fontSize: '0.88rem', display: 'flex', alignItems: 'center', gap: '0.42rem', overflowWrap: 'anywhere' }}>
                            <Building size={14} />
                            {shop.businessName || 'Business details not added yet'}
                          </p>

                          <div className="shop-inline-meta">
                            <span className="shop-meta-chip">
                              <Store size={13} />
                              <span>#{formatShortId(shop.id)}</span>
                            </span>
                            <span className="shop-meta-chip">
                              <Layers size={13} />
                              <span>{shop.category || 'Uncategorized'}</span>
                            </span>
                            <span className="shop-meta-chip">
                              <MapPin size={13} />
                              <span>{shop.location || 'Location not recorded'}</span>
                            </span>
                          </div>

                          {attentionNote && (
                            <div
                              className="shop-note"
                              style={{
                                background: attentionNote.tone.background,
                                border: `1px solid ${attentionNote.tone.border}`,
                                color: attentionNote.tone.color,
                              }}
                            >
                              <strong>{attentionNote.label}:</strong> {attentionNote.value}
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="shop-side">
                        <div className="shop-meta-chip" style={{ background: operationalTone.background, borderColor: operationalTone.border, color: operationalTone.color, justifyContent: 'center' }}>
                          <Activity size={13} />
                          <span>{shop.status}</span>
                        </div>
                        <div className="shop-meta-chip" style={{ background: verificationTone.background, borderColor: verificationTone.border, color: verificationTone.color, justifyContent: 'center' }}>
                          {shop.verifyStatus.toLowerCase() === 'verified' ? <ShieldCheck size={13} /> : (shop.verifyStatus.toLowerCase() === 'rejected' || shop.verifyStatus.toLowerCase() === 'deactivated') ? <XCircle size={13} /> : <Clock size={13} />}
                          <span>{shop.verifyStatus}</span>
                        </div>
                        {/* Open / Closed indicator */}
                        <div
                          className="shop-meta-chip"
                          style={{
                            background: shop.isOpen ? 'rgba(16,185,129,0.1)' : 'rgba(245,158,11,0.1)',
                            borderColor: shop.isOpen ? 'rgba(16,185,129,0.22)' : 'rgba(245,158,11,0.22)',
                            color: shop.isOpen ? '#10b981' : '#f59e0b',
                            justifyContent: 'center',
                          }}
                        >
                          <span style={{ position: 'relative', display: 'inline-flex', height: '7px', width: '7px' }}>
                            <span style={{ position: 'absolute', display: 'inline-flex', height: '100%', width: '100%', borderRadius: '50%', backgroundColor: shop.isOpen ? '#10b981' : '#f59e0b', opacity: 0.75 }} />
                            <span style={{ position: 'relative', display: 'inline-flex', borderRadius: '50%', height: '7px', width: '7px', backgroundColor: shop.isOpen ? '#10b981' : '#f59e0b' }} />
                          </span>
                          <span>{shop.isOpen !== false ? 'Open' : 'Closed'}</span>
                        </div>
                      </div>

                      <div className="shop-actions">
                        {shop.status.toLowerCase() !== 'active' && canApproveShops && (
                          <button
                            onClick={(event) => {
                              event.stopPropagation();
                              setActiveAction({ type: 'activate', shopId: shop.id });
                            }}
                            style={buildActionButtonStyle('rgba(16, 185, 129, 0.1)', '#10b981')}
                          >
                            <CheckCircle2 size={15} />
                            Activate
                          </button>
                        )}

                        {shop.status.toLowerCase() !== 'inactive' && canApproveShops && (
                          <button
                            onClick={(event) => {
                              event.stopPropagation();
                              setActiveAction({ type: 'deactivate', shopId: shop.id });
                            }}
                            style={buildActionButtonStyle('rgba(239, 68, 68, 0.1)', '#ef4444')}
                          >
                            <XCircle size={15} />
                            Deactivate
                          </button>
                        )}

                        {shop.verifyStatus === 'Pending' && canApproveShops && (
                          <>
                            <button
                              onClick={(event) => {
                                event.stopPropagation();
                                setActiveAction({ type: 'verify', shopId: shop.id });
                              }}
                              style={buildActionButtonStyle('rgba(16, 185, 129, 0.1)', '#10b981')}
                            >
                              <BadgeCheck size={15} />
                              Approve
                            </button>
                            <button
                              onClick={(event) => {
                                event.stopPropagation();
                                setActiveAction({ type: 'reject', shopId: shop.id });
                              }}
                              style={buildActionButtonStyle('rgba(239, 68, 68, 0.1)', '#ef4444')}
                            >
                              <XCircle size={15} />
                              Reject
                            </button>
                          </>
                        )}

                        <button
                          onClick={(event) => {
                            event.stopPropagation();
                            router.push(`/shops/${shop.id}`);
                          }}
                          style={buildActionButtonStyle('hsl(var(--secondary))', 'hsl(var(--foreground))', 'hsl(var(--border))')}
                        >
                          <Eye size={15} />
                          Details
                          <ArrowRight size={14} />
                        </button>
                      </div>
                    </motion.article>
                  );
                })}
              </AnimatePresence>
            </div>
          )}

          {!loading && shops.length > 0 && (
            <div
              style={{
                marginTop: '1.25rem',
                paddingTop: '1rem',
                borderTop: '1px solid hsl(var(--border))',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                gap: '1rem',
                flexWrap: 'wrap',
              }}
            >
              <div>
                <p style={{ fontSize: '0.9rem', fontWeight: 700 }}>
                  Showing {rangeStart}-{rangeEnd} of {totalShops} shops
                </p>
                <p style={{ marginTop: '0.25rem', fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                  Use the list to jump into details or resolve verification and status actions in place.
                </p>
              </div>

              <div style={{ display: 'flex', gap: '0.55rem', alignItems: 'center' }}>
                <button
                  onClick={() => setPage((current) => Math.max(1, current - 1))}
                  disabled={page === 1}
                  style={{
                    ...buildActionButtonStyle('hsl(var(--secondary))', 'hsl(var(--foreground))', 'hsl(var(--border))'),
                    opacity: page === 1 ? 0.55 : 1,
                    minWidth: '110px',
                  }}
                >
                  <ChevronLeft size={15} />
                  Previous
                </button>

                <div
                  style={{
                    padding: '0.65rem 0.95rem',
                    borderRadius: '14px',
                    background: 'hsl(var(--secondary))',
                    border: '1px solid hsl(var(--border))',
                    fontSize: '0.82rem',
                    fontWeight: 800,
                    color: 'hsl(var(--muted-foreground))',
                  }}
                >
                  Page {page} / {totalPages}
                </div>

                <button
                  onClick={() => setPage((current) => Math.min(totalPages, current + 1))}
                  disabled={page === totalPages}
                  style={{
                    ...buildActionButtonStyle('hsl(var(--secondary))', 'hsl(var(--foreground))', 'hsl(var(--border))'),
                    opacity: page === totalPages ? 0.55 : 1,
                    minWidth: '96px',
                  }}
                >
                  Next
                  <ChevronRight size={15} />
                </button>
              </div>
            </div>
          )}
        </section>

        <AnimatePresence>
          {activeAction.type && actionDetails && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => {
                setActiveAction({ type: null, shopId: '' });
                setActionReason('');
              }}
              style={{
                position: 'fixed',
                inset: 0,
                zIndex: 2000,
                background: 'rgba(2, 6, 23, 0.72)',
                backdropFilter: 'blur(10px)',
                WebkitBackdropFilter: 'blur(10px)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '1.5rem',
              }}
            >
              <motion.div
                initial={{ opacity: 0, scale: 0.96, y: 14 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.96, y: 14 }}
                onClick={(event) => event.stopPropagation()}
                style={{
                  width: 'min(520px, 100%)',
                  borderRadius: '24px',
                  overflow: 'hidden',
                  border: '1px solid rgba(148, 163, 184, 0.16)',
                  background: 'hsl(var(--card))',
                  boxShadow: '0 28px 70px rgba(15, 23, 42, 0.32)',
                }}
              >
                <div
                  style={{
                    padding: '1.35rem 1.5rem',
                    borderBottom: '1px solid hsl(var(--border))',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'flex-start',
                    gap: '1rem',
                  }}
                >
                  <div>
                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: '0.45rem', padding: '0.38rem 0.7rem', borderRadius: '999px', background: `${actionDetails.tone}12`, color: actionDetails.tone, fontSize: '0.75rem', fontWeight: 800, marginBottom: '0.75rem' }}>
                      {actionDetails.tone === '#10b981' ? <CheckCircle2 size={14} /> : <AlertTriangle size={14} />}
                      Shop action
                    </div>
                    <h3 style={{ fontSize: '1.15rem', fontWeight: 800 }}>{actionDetails.title}</h3>
                    <p style={{ marginTop: '0.35rem', color: 'hsl(var(--muted-foreground))', fontSize: '0.88rem', lineHeight: 1.55 }}>
                      {selectedShop ? `${selectedShop.name} (${selectedShop.businessName || 'Business profile'})` : 'Selected shop'}
                    </p>
                  </div>

                  <button
                    onClick={() => {
                      setActiveAction({ type: null, shopId: '' });
                      setActionReason('');
                    }}
                    style={{ background: 'none', border: 'none', color: 'hsl(var(--muted-foreground))', padding: '0.2rem' }}
                  >
                    <X size={18} />
                  </button>
                </div>

                <div style={{ padding: '1.5rem' }}>
                  <p style={{ color: 'hsl(var(--muted-foreground))', lineHeight: 1.65, fontSize: '0.9rem' }}>{actionDetails.description}</p>

                  <div
                    style={{
                      marginTop: '1rem',
                      padding: '0.9rem 1rem',
                      borderRadius: '16px',
                      background: 'hsl(var(--secondary))',
                      border: '1px solid hsl(var(--border))',
                    }}
                  >
                    <p style={{ fontSize: '0.76rem', color: 'hsl(var(--muted-foreground))', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                      Reference
                    </p>
                    <p style={{ marginTop: '0.35rem', fontWeight: 700 }}>#{selectedShop ? formatShortId(selectedShop.id) : 'N/A'}</p>
                  </div>

                  <textarea
                    value={actionReason}
                    onChange={(event) => setActionReason(event.target.value)}
                    rows={5}
                    placeholder={actionDetails.requiresReason ? 'Add the reason for this action...' : 'Optional note for this action...'}
                    style={{
                      width: '100%',
                      marginTop: '1rem',
                      padding: '0.9rem 1rem',
                      borderRadius: '16px',
                      border: '1px solid hsl(var(--border))',
                      background: 'hsl(var(--secondary))',
                      color: 'hsl(var(--foreground))',
                      outline: 'none',
                      resize: 'none',
                      fontSize: '0.9rem',
                      lineHeight: 1.6,
                    }}
                  />
                </div>

                <div
                  style={{
                    padding: '1rem 1.5rem',
                    background: 'rgba(148, 163, 184, 0.06)',
                    borderTop: '1px solid hsl(var(--border))',
                    display: 'flex',
                    justifyContent: 'flex-end',
                    gap: '0.75rem',
                    flexWrap: 'wrap',
                  }}
                >
                  <button
                    onClick={() => {
                      setActiveAction({ type: null, shopId: '' });
                      setActionReason('');
                    }}
                    style={buildActionButtonStyle('transparent', 'hsl(var(--muted-foreground))', 'hsl(var(--border))')}
                  >
                    Cancel
                  </button>

                  <button
                    onClick={() => {
                      if (activeAction.type === 'verify') {
                        void handleVerifyAction(activeAction.shopId, true, actionReason);
                      }

                      if (activeAction.type === 'reject') {
                        void handleVerifyAction(activeAction.shopId, false, actionReason);
                      }

                      if (activeAction.type === 'activate') {
                        void handleUpdateStatus(activeAction.shopId, true, actionReason);
                      }

                      if (activeAction.type === 'deactivate') {
                        void handleUpdateStatus(activeAction.shopId, false, actionReason);
                      }
                    }}
                    disabled={submittingAction || (actionDetails.requiresReason && !actionReason.trim())}
                    style={{
                      ...buildActionButtonStyle(actionDetails.tone, 'white'),
                      opacity: submittingAction || (actionDetails.requiresReason && !actionReason.trim()) ? 0.6 : 1,
                    }}
                  >
                    {submittingAction ? 'Processing...' : actionDetails.confirmLabel}
                  </button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </DashboardLayout>
  );
}
