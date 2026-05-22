'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import DashboardLayout from '@/components/DashboardLayout';
import {
  AlertCircle,
  ArrowRight,
  CheckCircle,
  Clock,
  FileText,
  MapPin,
  RefreshCw,
  Search,
  ShieldCheck,
  Store,
} from 'lucide-react';
import { motion } from 'framer-motion';
import api from '@/lib/api';
import { unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';

interface KeeperDocument {
  id: string;
  name: string;
  type: string;
  url: string;
}

interface KeeperApplicationListItem {
  id: string;
  businessName: string;
  ownerName: string;
  email: string;
  category: string;
  location: string;
  appliedDate: string;
  documents: KeeperDocument[];
}

type Notice = {
  tone: 'success' | 'error';
  message: string;
} | null;

function bannerStyle(tone: 'success' | 'error'): React.CSSProperties {
  return {
    marginBottom: '1rem',
    padding: '0.875rem 1rem',
    borderRadius: 'var(--radius)',
    background: tone === 'error' ? 'rgba(239, 68, 68, 0.12)' : 'rgba(16, 185, 129, 0.12)',
    color: tone === 'error' ? '#ef4444' : '#10b981',
    fontSize: '0.875rem',
    fontWeight: 600,
    display: 'flex',
    alignItems: 'center',
    gap: '0.5rem',
  };
}

export default function KeeperVerificationPage() {
  const [applications, setApplications] = useState<KeeperApplicationListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [notice, setNotice] = useState<Notice>(null);
  const [searchTerm, setSearchTerm] = useState('');

  const fetchApplications = async () => {
    setLoading(true);
    try {
      const response = await api.get('/keepers/pending', {
        params: { pageNumber: 1, pageSize: 100 },
      });
      setApplications(unwrapPagedResponse<KeeperApplicationListItem>(response).data);
      setNotice(null);
    } catch (err) {
      console.error('Failed to fetch applications', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to fetch keeper applications.') });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchApplications();
  }, []);

  const filteredApplications = applications.filter((app) => {
    const haystack = `${app.businessName} ${app.ownerName} ${app.email} ${app.category} ${app.location}`.toLowerCase();
    return haystack.includes(searchTerm.trim().toLowerCase());
  });

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div
          style={{
            marginBottom: '1.5rem',
            display: 'flex',
            justifyContent: 'space-between',
            gap: '1rem',
            alignItems: 'flex-start',
            flexWrap: 'wrap',
          }}
        >
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Keeper Verification</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))', maxWidth: '680px', lineHeight: 1.6 }}>
              Review pending keeper applications. Select a keeper to open the full verification workspace on a dedicated page.
            </p>
          </div>

          <button
            onClick={() => void fetchApplications()}
            disabled={loading}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.5rem',
              padding: '0.7rem 1rem',
              borderRadius: 'var(--radius)',
              border: '1px solid hsl(var(--border))',
              background: 'hsl(var(--card))',
              color: 'hsl(var(--foreground))',
              fontWeight: 700,
              opacity: loading ? 0.7 : 1,
            }}
          >
            <RefreshCw size={16} />
            Refresh
          </button>
        </div>

        {notice && (
          <div style={bannerStyle(notice.tone)}>
            <AlertCircle size={18} />
            {notice.message}
          </div>
        )}

        <div
          className="glass-card"
          style={{
            padding: '1rem',
            marginBottom: '1.5rem',
            display: 'grid',
            gridTemplateColumns: 'minmax(220px, 1fr) auto',
            gap: '1rem',
            alignItems: 'center',
          }}
        >
          <div style={{ position: 'relative' }}>
            <Search
              size={18}
              style={{
                position: 'absolute',
                left: '0.9rem',
                top: '50%',
                transform: 'translateY(-50%)',
                color: 'hsl(var(--muted-foreground))',
              }}
            />
            <input
              value={searchTerm}
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="Search business, owner, email, category, or location"
              style={{
                width: '100%',
                padding: '0.8rem 1rem 0.8rem 2.65rem',
                borderRadius: 'var(--radius)',
                border: '1px solid hsl(var(--border))',
                background: 'hsl(var(--secondary))',
                color: 'hsl(var(--foreground))',
                outline: 'none',
                fontSize: '0.9rem',
              }}
            />
          </div>

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.75rem',
              padding: '0.75rem 1rem',
              borderRadius: 'var(--radius)',
              background: 'rgba(245, 158, 11, 0.1)',
              color: '#d97706',
              fontWeight: 800,
              whiteSpace: 'nowrap',
            }}
          >
            <ShieldCheck size={18} />
            {applications.length} Pending
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(330px, 1fr))', gap: '1.25rem' }}>
          {filteredApplications.map((app, index) => (
            <Link key={app.id} href={`/keepers/verify/${app.id}`} style={{ textDecoration: 'none', color: 'inherit' }}>
              <motion.article
                initial={{ opacity: 0, y: 14 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.03 }}
                className="glass-card"
                style={{
                  padding: '1.35rem',
                  minHeight: '230px',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  border: '1px solid var(--glass-border)',
                }}
              >
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', alignItems: 'flex-start' }}>
                    <div style={{ display: 'flex', gap: '0.85rem', minWidth: 0 }}>
                      <div
                        style={{
                          width: '44px',
                          height: '44px',
                          borderRadius: '10px',
                          background: 'hsl(var(--secondary))',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          flex: '0 0 auto',
                          color: 'hsl(var(--primary))',
                        }}
                      >
                        <Store size={21} />
                      </div>
                      <div style={{ minWidth: 0 }}>
                        <h3 style={{ fontSize: '1.05rem', fontWeight: 800, overflowWrap: 'anywhere' }}>{app.businessName}</h3>
                        <p style={{ fontSize: '0.86rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.2rem', overflowWrap: 'anywhere' }}>
                          {app.ownerName}
                        </p>
                      </div>
                    </div>
                    <span
                      style={{
                        padding: '0.25rem 0.7rem',
                        borderRadius: '999px',
                        background: 'rgba(245, 158, 11, 0.1)',
                        color: '#d97706',
                        fontSize: '0.72rem',
                        fontWeight: 800,
                        whiteSpace: 'nowrap',
                      }}
                    >
                      Pending
                    </span>
                  </div>

                  <div style={{ marginTop: '1.25rem', display: 'grid', gap: '0.75rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.55rem', fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                      <Clock size={15} />
                      Applied {new Date(app.appliedDate).toLocaleDateString()}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.55rem', fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', overflowWrap: 'anywhere' }}>
                      <MapPin size={15} />
                      {app.location || 'Location not provided'}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.55rem', fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                      <FileText size={15} />
                      {app.documents.length} Submitted documents
                    </div>
                  </div>
                </div>

                <div
                  style={{
                    marginTop: '1.1rem',
                    paddingTop: '1rem',
                    borderTop: '1px solid hsl(var(--border))',
                    display: 'flex',
                    justifyContent: 'space-between',
                    gap: '1rem',
                    alignItems: 'center',
                  }}
                >
                  <div style={{ minWidth: 0 }}>
                    <p style={{ fontSize: '0.8rem', fontWeight: 700, color: 'hsl(var(--foreground))', overflowWrap: 'anywhere' }}>
                      {app.category || 'Uncategorized'}
                    </p>
                    <p style={{ fontSize: '0.76rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.2rem', overflowWrap: 'anywhere' }}>
                      {app.email}
                    </p>
                  </div>
                  <span
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.35rem',
                      color: 'hsl(var(--primary))',
                      fontSize: '0.82rem',
                      fontWeight: 800,
                      whiteSpace: 'nowrap',
                    }}
                  >
                    Details
                    <ArrowRight size={16} />
                  </span>
                </div>
              </motion.article>
            </Link>
          ))}

          {filteredApplications.length === 0 && !loading && (
            <div className="flex-center glass-card" style={{ padding: '4rem', flexDirection: 'column', gap: '1rem', gridColumn: '1 / -1' }}>
              <CheckCircle size={48} style={{ color: '#10b981' }} />
              <p style={{ color: 'hsl(var(--muted-foreground))' }}>
                {applications.length === 0 ? 'All caught up. No pending keeper applications.' : 'No keeper applications match your search.'}
              </p>
            </div>
          )}

          {loading && (
            <div className="glass-card" style={{ padding: '3rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))', gridColumn: '1 / -1' }}>
              Loading keeper applications...
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
