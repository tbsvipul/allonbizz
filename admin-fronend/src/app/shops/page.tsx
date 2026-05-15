'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { 
  Store, Plus, Search, Trash2, BadgeCheck, Clock, AlertTriangle,
  MapPin, Building, Filter, X, CheckCircle2, XCircle, Eye
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';

interface Shop {
  id: string;
  name: string;
  businessName: string;
  category: string;
  location: string;
  status: string;
  isVerified: boolean;
  imageUrl?: string;
}

export default function ShopsPage() {
  const router = useRouter();
  const { hasPermission } = useAuth();
  const [shops, setShops] = useState<Shop[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [toast, setToast] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalShops, setTotalShops] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const fetchShops = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/admin/shops', {
        params: {
          search,
          isActive: statusFilter === 'all' ? undefined : (statusFilter === 'active'),
          pageNumber: page,
          pageSize: 10
        }
      });
      const { data, pagination } = unwrapPagedResponse<Shop>(response);
      setShops(data || []);
      setTotalPages(pagination?.totalPages || 1);
      setTotalShops(pagination?.totalCount || 0);
    } catch (err) {
      console.error('Failed to fetch shops', err);
      setError(getApiErrorMessage(err, 'Failed to fetch shops.'));
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStatus = async (id: string, nextIsActive: boolean) => {
    try {
      await api.put(`/admin/shops/${id}/status`, { isActive: nextIsActive });
      setToast(`Shop ${nextIsActive ? 'activated' : 'deactivated'} successfully`);
      setTimeout(() => setToast(null), 3000);
      fetchShops();
    } catch (err) {
      console.error('Status update failed', err);
      const message = getApiErrorMessage(err, 'Failed to update status.');
      setError(message);
      setToast(message);
      setTimeout(() => setToast(null), 3000);
    }
  };

  const handleVerify = async (id: string) => {
    try {
      await api.post(`/admin/shops/${id}/verify`);
      setToast('Shop verified successfully');
      setTimeout(() => setToast(null), 3000);
      fetchShops();
    } catch (err) {
      console.error('Verification failed', err);
      const message = getApiErrorMessage(err, 'Failed to verify shop.');
      setError(message);
      setToast(message);
      setTimeout(() => setToast(null), 3000);
    }
  };

  useEffect(() => {
    const debounce = setTimeout(() => fetchShops(), 300);
    return () => clearTimeout(debounce);
  }, [search, statusFilter, page]);

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'active': return { bg: 'rgba(16, 185, 129, 0.1)', text: '#10b981' };
      case 'inactive': return { bg: 'rgba(239, 68, 68, 0.1)', text: '#ef4444' };
      case 'flagged': return { bg: 'rgba(245, 158, 11, 0.1)', text: '#f59e0b' };
      default: return { bg: 'rgba(107, 114, 128, 0.1)', text: '#6b7280' };
    }
  };

  const statusCounts = {
    all: totalShops,
    active: shops.filter(s => s.status.toLowerCase() === 'active').length,
    inactive: shops.filter(s => s.status.toLowerCase() === 'inactive').length,
  };

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        {/* Toast */}
        <AnimatePresence>
          {toast && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              style={{
                position: 'fixed', top: '1.5rem', right: '1.5rem', zIndex: 100,
                padding: '0.75rem 1.25rem', borderRadius: 'var(--radius)',
                background: toast.includes('Failed') ? '#ef4444' : '#10b981',
                color: 'white', fontWeight: 600, fontSize: '0.875rem',
                boxShadow: '0 4px 12px rgba(0,0,0,0.3)'
              }}
            >
              {toast}
            </motion.div>
          )}
        </AnimatePresence>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Shop Management</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))' }}>Oversee business locations and their operational status.</p>
          </div>
        </div>

        {/* Status filter tabs */}
        <div style={{ display: 'flex', gap: '0.75rem', marginBottom: '1.5rem' }}>
          {(['all', 'active', 'inactive'] as const).map(st => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              style={{
                padding: '0.5rem 1.25rem', borderRadius: '20px', fontWeight: 600,
                fontSize: '0.875rem', textTransform: 'capitalize', border: 'none', cursor: 'pointer',
                background: statusFilter === st ? (st === 'active' ? '#10b981' : st === 'inactive' ? '#ef4444' : 'hsl(var(--primary))') : 'hsl(var(--secondary))',
                color: statusFilter === st ? 'white' : 'inherit',
                transition: '0.2s'
              }}
            >
              {st}
            </button>
          ))}
        </div>

        <div className="glass-card" style={{ padding: '1.5rem', marginBottom: '2rem' }}>
          {error && (
            <div style={{ marginBottom: '1rem', padding: '0.875rem 1rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444', fontSize: '0.875rem', fontWeight: 600 }}>
              {error}
            </div>
          )}
          <div style={{ position: 'relative', marginBottom: '1.5rem' }}>
            <Search size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
            <input 
              placeholder="Search shops by name or ID…" 
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              style={{ 
                width: '100%', padding: '0.75rem 1rem 0.75rem 2.75rem', 
                borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))',
                background: 'hsl(var(--secondary))', outline: 'none',
              }} 
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.5rem' }}>
            <AnimatePresence>
              {shops.map((shop) => (
                <motion.div 
                  key={shop.id}
                  layout
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="glass-card"
                  style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                    <div style={{ display: 'flex', gap: '1rem' }}>
                      <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'hsl(var(--secondary))', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'hsl(var(--primary))', overflow: 'hidden' }}>
                        {shop.imageUrl ? (
                          <img src={shop.imageUrl} alt={shop.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        ) : (
                          <Store size={24} />
                        )}
                      </div>
                      <div>
                        <h3 style={{ fontWeight: 700, fontSize: '1.125rem' }}>{shop.name}</h3>
                        <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                          <Building size={14} /> {shop.businessName}
                        </p>
                      </div>
                    </div>
                    {shop.isVerified && <BadgeCheck size={20} style={{ color: '#10b981' }} />}
                  </div>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.875rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'hsl(var(--muted-foreground))' }}>
                      <MapPin size={14} /> {shop.location}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'hsl(var(--muted-foreground))' }}>
                      <Filter size={14} /> {shop.category}
                    </div>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid hsl(var(--border))' }}>
                    <span style={{ 
                      padding: '0.25rem 0.75rem', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 600,
                      background: getStatusColor(shop.status).bg, color: getStatusColor(shop.status).text
                    }}>
                      {shop.status}
                    </span>
                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      {shop.status.toLowerCase() !== 'active' && hasPermission(PERMISSIONS.shopsApprove) && (
                        <button 
                          onClick={() => handleUpdateStatus(shop.id, true)}
                          style={{ padding: '0.4rem 0.75rem', borderRadius: 'var(--radius)', background: 'rgba(16, 185, 129, 0.1)', border: 'none', color: '#10b981', cursor: 'pointer', fontSize: '0.75rem', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.25rem' }}
                          title="Activate"
                        >
                          <CheckCircle2 size={14} /> Activate
                        </button>
                      )}
                      {shop.status.toLowerCase() !== 'inactive' && hasPermission(PERMISSIONS.shopsApprove) && (
                        <button 
                          onClick={() => handleUpdateStatus(shop.id, false)}
                          style={{ padding: '0.4rem 0.75rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.1)', border: 'none', color: '#ef4444', cursor: 'pointer', fontSize: '0.75rem', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.25rem' }}
                          title="Deactivate"
                        >
                          <XCircle size={14} /> Deactivate
                        </button>
                      )}
                      {!shop.isVerified && hasPermission(PERMISSIONS.shopsApprove) && (
                        <button 
                          onClick={() => handleVerify(shop.id)}
                          style={{ padding: '0.4rem 0.75rem', borderRadius: 'var(--radius)', background: 'rgba(245, 158, 11, 0.1)', border: 'none', color: '#f59e0b', cursor: 'pointer', fontSize: '0.75rem', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.25rem' }}
                          title="Verify Shop"
                        >
                          <BadgeCheck size={14} /> Verify
                        </button>
                      )}
                      <button 
                        onClick={() => router.push(`/shops/${shop.id}`)}
                        style={{ padding: '0.4rem 0.75rem', borderRadius: 'var(--radius)', background: 'rgba(59, 130, 246, 0.1)', border: 'none', color: '#3b82f6', cursor: 'pointer', fontSize: '0.75rem', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.25rem' }}
                        title="View Details"
                      >
                        <Eye size={14} /> Details
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>

          {!loading && shops.length === 0 && (
            <div className="flex-center" style={{ padding: '4rem' }}>
              <p style={{ color: 'hsl(var(--muted-foreground))' }}>No shops found matching your criteria.</p>
            </div>
          )}

          {/* Pagination */}
          {!loading && shops.length > 0 && (
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '2rem', padding: '1rem', borderTop: '1px solid hsl(var(--border))' }}>
              <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))' }}>
                Showing {shops.length} of {totalShops} shops
              </p>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button 
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="glass-card"
                  style={{ padding: '0.5rem 1rem', display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 600, opacity: page === 1 ? 0.5 : 1 }}
                >
                  Previous
                </button>
                <div style={{ display: 'flex', alignItems: 'center', padding: '0 1rem', fontWeight: 600, fontSize: '0.875rem' }}>
                  Page {page} of {totalPages}
                </div>
                <button 
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="glass-card"
                  style={{ padding: '0.5rem 1rem', display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 600, opacity: page === totalPages ? 0.5 : 1 }}
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
