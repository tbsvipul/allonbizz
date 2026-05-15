'use client';

import React, { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { 
  Tag, 
  Search, 
  Calendar, 
  Clock, 
  AlertCircle,
  CheckCircle2,
  XCircle,
  MoreVertical,
  ArrowUpRight
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';

interface Offer {
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

export default function OffersPage() {
  const { hasPermission } = useAuth();
  const [offers, setOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalOffers, setTotalOffers] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const fetchOffers = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/admin/offers', {
        params: { search, status: statusFilter, pageNumber: page, pageSize: 10 }
      });
      const { data, pagination } = unwrapPagedResponse<Offer>(response);
      setOffers(data || []);
      setTotalPages(pagination?.totalPages || 1);
      setTotalOffers(pagination?.totalCount || 0);
    } catch (err) {
      console.error('Failed to fetch offers', err);
      setError(getApiErrorMessage(err, 'Failed to fetch offers.'));
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStatus = async (id: string, status: string) => {
    try {
      await api.put(`/admin/offers/${id}/status`, { status });
      fetchOffers();
    } catch (err) {
      console.error('Update failed', err);
      setError(getApiErrorMessage(err, 'Failed to update offer status.'));
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this offer permanently?')) return;
    try {
      await api.delete(`/admin/offers/${id}`);
      fetchOffers();
    } catch (err) {
      console.error('Delete failed', err);
      setError(getApiErrorMessage(err, 'Failed to delete offer.'));
    }
  };

  useEffect(() => {
    fetchOffers();
  }, [search, statusFilter, page]);

  const getStatusIcon = (status: string) => {
    switch (status.toLowerCase()) {
      case 'active': return <CheckCircle2 size={16} color="#10b981" />;
      case 'expired': return <Clock size={16} color="#ef4444" />;
      case 'pending': return <AlertCircle size={16} color="#f59e0b" />;
      default: return <XCircle size={16} color="#6b7280" />;
    }
  };

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Global Offers Overview</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))' }}>Monitor and moderate all active promotions across the platform.</p>
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1.5rem', marginBottom: '2rem' }}>
          {error && (
            <div style={{ marginBottom: '1rem', padding: '0.875rem 1rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444', fontSize: '0.875rem', fontWeight: 600 }}>
              {error}
            </div>
          )}
          <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem' }}>
            <div style={{ position: 'relative', flex: 1 }}>
              <Search size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
              <input 
                placeholder="Search offers or businesses…" 
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1); }}
                style={{ 
                  width: '100%', 
                  padding: '0.75rem 1rem 0.75rem 2.75rem', 
                  borderRadius: 'var(--radius)', 
                  border: '1px solid hsl(var(--border))',
                  background: 'hsl(var(--secondary))',
                  outline: 'none',
                }} 
              />
            </div>
            <select 
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
              style={{ background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', padding: '0.75rem 1.25rem', borderRadius: 'var(--radius)', fontWeight: 500, outline: 'none' }}
            >
              <option value="">All Status</option>
            <option value="Active">Active</option>
            <option value="Expired">Expired</option>
          </select>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem' }}>
          <AnimatePresence>
            {offers.map((offer) => (
              <motion.div 
                key={offer.id}
                layout
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="glass-card"
                style={{ padding: '1.5rem', border: '1px solid rgba(255,255,255,0.05)' }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '1rem' }}>
                  <div style={{ display: 'flex', gap: '0.75rem' }}>
                    <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Tag size={20} />
                    </div>
                    <div>
                      <h3 style={{ fontWeight: 700 }}>{offer.title}</h3>
                      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>{offer.keeperName} • {offer.shopName}</p>
                    </div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.75rem', fontWeight: 600 }}>
                    {getStatusIcon(offer.status)}
                    <span style={{ color: 'hsl(var(--foreground))' }}>{offer.status}</span>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.25rem' }}>
                  <div style={{ flex: 1, padding: '0.75rem', borderRadius: '8px', background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.05)' }}>
                     <p style={{ fontSize: '0.7rem', color: 'hsl(var(--muted-foreground))', textTransform: 'uppercase', letterSpacing: '0.025em', marginBottom: '0.25rem' }}>Redemptions</p>
                     <p style={{ fontWeight: 700, fontSize: '1.125rem' }}>{offer.redemptions}</p>
                  </div>
                  <div style={{ flex: 1, padding: '0.75rem', borderRadius: '8px', background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.05)' }}>
                     <p style={{ fontSize: '0.7rem', color: 'hsl(var(--muted-foreground))', textTransform: 'uppercase', letterSpacing: '0.025em', marginBottom: '0.25rem' }}>Expires In</p>
                     <p style={{ fontWeight: 700, fontSize: '1.125rem' }}>{Math.ceil((new Date(offer.endDate).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))}d</p>
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'hsl(var(--muted-foreground))', fontSize: '0.75rem', marginBottom: '1.25rem' }}>
                  <Calendar size={14} />
                  {new Date(offer.startDate).toLocaleDateString()} - {new Date(offer.endDate).toLocaleDateString()}
                </div>

                <div style={{ display: 'flex', gap: '0.75rem' }}>
                  {hasPermission(PERMISSIONS.offersEdit) && (offer.status.toLowerCase() === 'active' ? (
                    <button 
                      onClick={() => handleUpdateStatus(offer.id, 'Expired')}
                      style={{ 
                        flex: 1, padding: '0.5rem', borderRadius: 'var(--radius)', 
                        background: 'rgba(239, 68, 68, 0.1)', border: 'none', color: '#ef4444', 
                        fontSize: '0.875rem', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' 
                      }}
                    >
                      <Clock size={16} /> Expire Now
                    </button>
                  ) : (
                    <button 
                      onClick={() => handleUpdateStatus(offer.id, 'Active')}
                      style={{ 
                        flex: 1, padding: '0.5rem', borderRadius: 'var(--radius)', 
                        background: 'rgba(16, 185, 129, 0.1)', border: 'none', color: '#10b981', 
                        fontSize: '0.875rem', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' 
                      }}
                    >
                      <CheckCircle2 size={16} /> Activate
                    </button>
                  ))}
                   <div style={{ position: 'relative' }}>
                    <button 
                      onClick={() => {
                        const menu = document.getElementById(`menu-${offer.id}`);
                        if (menu) menu.style.display = menu.style.display === 'none' ? 'block' : 'none';
                      }}
                      style={{ 
                        padding: '0.5rem', borderRadius: 'var(--radius)', 
                        background: 'hsl(var(--secondary))', border: 'none', color: 'hsl(var(--foreground))',
                        cursor: 'pointer'
                      }}
                    >
                      <MoreVertical size={16} />
                    </button>
                    <div 
                      id={`menu-${offer.id}`}
                      style={{ 
                        display: 'none', position: 'absolute', bottom: '100%', right: 0, 
                        background: 'hsl(var(--background))', border: '1px solid hsl(var(--border))', 
                        borderRadius: 'var(--radius)', minWidth: '120px', zIndex: 10, boxShadow: 'var(--shadow-lg)',
                        marginBottom: '0.5rem'
                      }}
                    >
                      <button 
                        onClick={() => {
                          alert('Analytics view implementation in progress');
                          document.getElementById(`menu-${offer.id}`)!.style.display = 'none';
                        }}
                        style={{ width: '100%', padding: '0.6rem 1rem', textAlign: 'left', background: 'none', border: 'none', color: 'inherit', fontSize: '0.8rem', cursor: 'pointer', borderBottom: '1px solid hsl(var(--border))' }}
                      >
                        Analytics
                      </button>
                      {hasPermission(PERMISSIONS.offersDelete) && (
                        <button 
                          onClick={() => handleDelete(offer.id)}
                          style={{ width: '100%', padding: '0.6rem 1rem', textAlign: 'left', background: 'none', border: 'none', color: '#ef4444', fontSize: '0.8rem', cursor: 'pointer' }}
                        >
                          Delete
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              </motion.div>
              ))}
            </AnimatePresence>
          </div>

          {/* Pagination */}
          {!loading && offers.length > 0 && (
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '2rem', padding: '1rem', borderTop: '1px solid hsl(var(--border))' }}>
              <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))' }}>
                Showing {offers.length} of {totalOffers} offers
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
