'use client';

import React, { useEffect, useMemo, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import {
  CheckCircle,
  XCircle,
  FileText,
  Clock,
  MapPin,
  ExternalLink,
  Info,
  Shield,
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { unwrapApiData, unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';

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

interface KeeperReviewMessage {
  messageId: string;
  messageType: string;
  message: string;
  adminName: string;
  isReadByKeeper: boolean;
  createdAt: string;
}

interface KeeperApplicationDetail extends KeeperApplicationListItem {
  userId: string;
  businessLicense?: string | null;
  gstNumber?: string | null;
  panNumber?: string | null;
  socialLinksJson?: string | null;
  status: string;
  rejectionReason?: string | null;
  approvedAt?: string | null;
  reviewMessages: KeeperReviewMessage[];
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
    } catch (e) {
      // Ignore if it's not a valid base64 string or decode fails
    }
    // If it's a raw base64 string from a byte[] property
    return `data:image/png;base64,${path}`;
  }
  
  try {
    const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5247/api/v1';
    const origin = new URL(apiBaseUrl).origin;
    return `${origin}${path.startsWith('/') ? '' : '/'}${path}`;
  } catch (e) {
    return `http://localhost:5247${path.startsWith('/') ? '' : '/'}${path}`;
  }
};


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
  };
}

function actionButtonStyle(background: string, color: string): React.CSSProperties {
  return {
    width: '100%',
    padding: '0.75rem 1rem',
    borderRadius: 'var(--radius)',
    border: 'none',
    background,
    color,
    fontWeight: 700,
    cursor: 'pointer',
  };
}

export default function KeeperVerificationPage() {
  const { hasPermission } = useAuth();
  const [applications, setApplications] = useState<KeeperApplicationListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [selectedAppId, setSelectedAppId] = useState<string | null>(null);
  const [selectedApp, setSelectedApp] = useState<KeeperApplicationDetail | null>(null);
  const [notice, setNotice] = useState<Notice>(null);
  const [submittingAction, setSubmittingAction] = useState<string | null>(null);
  const [approveNotes, setApproveNotes] = useState('');
  const [rejectReason, setRejectReason] = useState('');
  const [requestMessage, setRequestMessage] = useState('');
  const [holdReason, setHoldReason] = useState('');
  const [holdUntil, setHoldUntil] = useState('');

  const canModerate = useMemo(
    () =>
      hasPermission(PERMISSIONS.keepersApprove) ||
      hasPermission(PERMISSIONS.keepersReject) ||
      hasPermission(PERMISSIONS.keepersView),
    [hasPermission]
  );

  const fetchApplications = async () => {
    setLoading(true);
    try {
      const response = await api.get('/keepers/pending', {
        params: { pageNumber: 1, pageSize: 100 },
      });
      const items = unwrapPagedResponse<KeeperApplicationListItem>(response).data;
      setApplications(items);
      return items;
    } catch (err) {
      console.error('Failed to fetch applications', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to fetch keeper applications.') });
      return [] as KeeperApplicationListItem[];
    } finally {
      setLoading(false);
    }
  };

  const fetchApplicationDetail = async (id: string) => {
    setDetailLoading(true);
    try {
      const response = await api.get(`/keepers/pending/${id}`);
      setSelectedApp(unwrapApiData<KeeperApplicationDetail>(response));
    } catch (err) {
      console.error('Failed to fetch keeper detail', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to load keeper application details.') });
      setSelectedApp(null);
    } finally {
      setDetailLoading(false);
    }
  };

  const resetActionForms = () => {
    setApproveNotes('');
    setRejectReason('');
    setRequestMessage('');
    setHoldReason('');
    setHoldUntil('');
  };

  useEffect(() => {
    void fetchApplications();
  }, []);

  const selectApplication = async (id: string) => {
    setSelectedAppId(id);
    setSelectedApp(null);
    resetActionForms();
    await fetchApplicationDetail(id);
  };

  const refreshAfterAction = async (id: string, clearSelection: boolean) => {
    const items = await fetchApplications();

    if (clearSelection) {
      setSelectedAppId(null);
      setSelectedApp(null);
      return;
    }

    const stillPresent = items.some((item) => item.id === id);
    if (!stillPresent) {
      setSelectedAppId(null);
      setSelectedApp(null);
      return;
    }

    await fetchApplicationDetail(id);
  };

  const handleApprove = async () => {
    if (!selectedApp) {
      return;
    }

    setSubmittingAction('approve');
    try {
      await api.post(`/keepers/${selectedApp.id}/approve`, {
        notes: approveNotes.trim() || undefined,
      });
      setNotice({ tone: 'success', message: 'Keeper approved successfully.' });
      resetActionForms();
      await refreshAfterAction(selectedApp.id, true);
    } catch (err) {
      console.error('Failed to approve keeper', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to approve keeper.') });
    } finally {
      setSubmittingAction(null);
    }
  };

  const handleReject = async () => {
    if (!selectedApp) {
      return;
    }

    if (!rejectReason.trim()) {
      setNotice({ tone: 'error', message: 'Rejection reason is required.' });
      return;
    }

    setSubmittingAction('reject');
    try {
      await api.post(`/keepers/${selectedApp.id}/reject`, {
        reason: rejectReason.trim(),
      });
      setNotice({ tone: 'success', message: 'Keeper rejected successfully.' });
      resetActionForms();
      await refreshAfterAction(selectedApp.id, true);
    } catch (err) {
      console.error('Failed to reject keeper', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to reject keeper.') });
    } finally {
      setSubmittingAction(null);
    }
  };

  const handleRequestInfo = async () => {
    if (!selectedApp) {
      return;
    }

    if (!requestMessage.trim()) {
      setNotice({ tone: 'error', message: 'A message is required when requesting more information.' });
      return;
    }

    setSubmittingAction('request-info');
    try {
      await api.post(`/keepers/${selectedApp.id}/request-info`, {
        message: requestMessage.trim(),
      });
      setNotice({ tone: 'success', message: 'Information request sent to keeper.' });
      setRequestMessage('');
      await refreshAfterAction(selectedApp.id, false);
    } catch (err) {
      console.error('Failed to request keeper info', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to request more information.') });
    } finally {
      setSubmittingAction(null);
    }
  };

  const handleHold = async () => {
    if (!selectedApp) {
      return;
    }

    setSubmittingAction('hold');
    try {
      await api.post(`/keepers/${selectedApp.id}/hold`, {
        reason: holdReason.trim() || undefined,
        holdUntil: holdUntil ? new Date(holdUntil).toISOString() : undefined,
      });
      setNotice({ tone: 'success', message: 'Keeper application placed on hold.' });
      setHoldReason('');
      setHoldUntil('');
      await refreshAfterAction(selectedApp.id, false);
    } catch (err) {
      console.error('Failed to hold keeper application', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to hold keeper application.') });
    } finally {
      setSubmittingAction(null);
    }
  };

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ marginBottom: '2rem' }}>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Keeper Verification</h1>
          <p style={{ color: 'hsl(var(--muted-foreground))' }}>
            Review pending keeper registrations, inspect full submissions, and send structured approval decisions with message history.
          </p>
        </div>

        {notice && <div style={bannerStyle(notice.tone)}>{notice.message}</div>}

        <div style={{ display: 'grid', gridTemplateColumns: selectedAppId ? 'minmax(340px, 1fr) minmax(420px, 1.2fr)' : '1fr', gap: '2rem' }}>
          <div style={{ display: 'grid', gridTemplateColumns: selectedAppId ? '1fr' : 'repeat(auto-fill, minmax(360px, 1fr))', gap: '1.5rem' }}>
            {applications.map((app) => (
              <motion.div
                key={app.id}
                layout
                onClick={() => void selectApplication(app.id)}
                className="glass-card"
                style={{
                  padding: '1.5rem',
                  cursor: 'pointer',
                  border: selectedAppId === app.id ? '2px solid hsl(var(--primary))' : '1px solid var(--glass-border)',
                  boxShadow: selectedAppId === app.id ? '0 0 20px rgba(59, 130, 246, 0.18)' : 'var(--glass-shadow)',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '1rem' }}>
                  <div>
                    <h3 style={{ fontSize: '1.125rem', fontWeight: 700 }}>{app.businessName}</h3>
                    <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>{app.ownerName}</p>
                  </div>
                  <div style={{ padding: '0.25rem 0.75rem', borderRadius: '20px', background: 'rgba(245, 158, 11, 0.1)', color: '#f59e0b', fontSize: '0.75rem', fontWeight: 700 }}>
                    Pending Review
                  </div>
                </div>

                <div style={{ marginTop: '1.25rem', display: 'flex', flexWrap: 'wrap', gap: '1rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>
                    <Clock size={14} /> {new Date(app.appliedDate).toLocaleDateString()}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>
                    <MapPin size={14} /> {app.location}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>
                    <FileText size={14} /> {app.documents.length} Documents
                  </div>
                </div>

                <div style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '1px solid hsl(var(--border))', fontSize: '0.8125rem', color: 'hsl(var(--muted-foreground))' }}>
                  {app.category} | {app.email}
                </div>
              </motion.div>
            ))}

            {applications.length === 0 && !loading && (
              <div className="flex-center glass-card" style={{ padding: '4rem', flexDirection: 'column', gap: '1rem' }}>
                <CheckCircle size={48} style={{ color: '#10b981' }} />
                <p style={{ color: 'hsl(var(--muted-foreground))' }}>All caught up. No pending keeper applications.</p>
              </div>
            )}

            {loading && (
              <div className="glass-card" style={{ padding: '3rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))', gridColumn: '1 / -1' }}>
                Loading applications...
              </div>
            )}
          </div>

          <AnimatePresence>
            {selectedAppId && (
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                className="glass-card"
                style={{ padding: '2rem', height: 'fit-content', position: 'sticky', top: '2rem' }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                  <div>
                    <h2 style={{ fontSize: '1.5rem', fontWeight: 700 }}>Application Details</h2>
                    <p style={{ color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>Full pending submission with review actions and message history.</p>
                  </div>
                  <button onClick={() => { setSelectedAppId(null); setSelectedApp(null); }} style={{ background: 'none', border: 'none', color: 'hsl(var(--muted-foreground))', cursor: 'pointer' }}>
                    <XCircle size={24} />
                  </button>
                </div>

                {detailLoading || !selectedApp ? (
                  <div style={{ padding: '2rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>Loading full application details...</div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                    <style dangerouslySetInnerHTML={{ __html: `
                      .hover-overlay {
                        opacity: 0 !important;
                        transition: opacity 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
                      }
                      .hover-overlay:hover {
                        opacity: 1 !important;
                      }
                    ` }} />
                    <section>
                      <h4 style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'hsl(var(--muted-foreground))', marginBottom: '0.75rem' }}>
                        Business Information
                      </h4>
                      <div style={{ background: 'hsl(var(--secondary))', padding: '1rem', borderRadius: 'var(--radius)', display: 'grid', gap: '0.75rem' }}>
                        <div>
                          <p style={{ fontWeight: 700 }}>{selectedApp.businessName}</p>
                          <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>
                            {selectedApp.category} | {selectedApp.location}
                          </p>
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))', gap: '0.75rem' }}>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Owner</p>
                            <p style={{ fontWeight: 600 }}>{selectedApp.ownerName}</p>
                          </div>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Email</p>
                            <p style={{ fontWeight: 600 }}>{selectedApp.email}</p>
                          </div>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Status</p>
                            <p style={{ fontWeight: 600 }}>{selectedApp.status}</p>
                          </div>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Applied</p>
                            <p style={{ fontWeight: 600 }}>{new Date(selectedApp.appliedDate).toLocaleString()}</p>
                          </div>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>GST Number</p>
                            <p style={{ fontWeight: 600 }}>{selectedApp.gstNumber || 'Not provided'}</p>
                          </div>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>PAN Number</p>
                            <p style={{ fontWeight: 600 }}>{selectedApp.panNumber || 'Not provided'}</p>
                          </div>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Business License</p>
                            <p style={{ fontWeight: 600 }}>
                              {selectedApp.businessLicense || 'Not provided'}
                              {selectedApp.businessLicenseNumber ? ` (${selectedApp.businessLicenseNumber})` : ''}
                            </p>
                          </div>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Identity Proof</p>
                            <p style={{ fontWeight: 600 }}>
                              {selectedApp.identityProofType || 'Not provided'}
                              {selectedApp.identityProofNumber ? ` (${selectedApp.identityProofNumber})` : ''}
                            </p>
                          </div>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Address Proof</p>
                            <p style={{ fontWeight: 600 }}>{selectedApp.addressProofType || 'Not provided'}</p>
                          </div>
                          <div>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Approved at</p>
                            <p style={{ fontWeight: 600 }}>{selectedApp.approvedAt ? new Date(selectedApp.approvedAt).toLocaleString() : 'Not approved yet'}</p>
                          </div>
                        </div>
                      </div>
                      {selectedApp.rejectionReason && (
                        <div style={{ marginTop: '0.75rem', padding: '0.9rem 1rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', color: '#ef4444' }}>
                          <strong>Rejection reason:</strong> {selectedApp.rejectionReason}
                        </div>
                      )}
                    </section>

                    <section>
                      <h4 style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'hsl(var(--muted-foreground))', marginBottom: '0.75rem' }}>
                        Verification Credentials & Media Proofs
                      </h4>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1.25rem' }}>
                        {selectedApp.identityProofImage && (
                          <div className="glass-card" style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Identity Proof ({selectedApp.identityProofType || 'National ID'})</p>
                              <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>{selectedApp.identityProofNumber || 'N/A'}</p>
                            </div>
                            <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                              <img src={getFullImageUrl(selectedApp.identityProofImage)} alt="Identity Proof" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                              <a href={getFullImageUrl(selectedApp.identityProofImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                                View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                              </a>
                            </div>
                          </div>
                        )}

                        {selectedApp.businessLicenseImage && (
                          <div className="glass-card" style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Business License</p>
                              <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>{selectedApp.businessLicenseNumber || 'N/A'}</p>
                            </div>
                            <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                              <img src={getFullImageUrl(selectedApp.businessLicenseImage)} alt="Business License" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                              <a href={getFullImageUrl(selectedApp.businessLicenseImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                                View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                              </a>
                            </div>
                          </div>
                        )}

                        {selectedApp.gstCertificateImage && (
                          <div className="glass-card" style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>GST Certificate</p>
                              <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>{selectedApp.gstNumber || 'N/A'}</p>
                            </div>
                            <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                              <img src={getFullImageUrl(selectedApp.gstCertificateImage)} alt="GST Certificate" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                              <a href={getFullImageUrl(selectedApp.gstCertificateImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                                View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                              </a>
                            </div>
                          </div>
                        )}

                        {selectedApp.panCardImage && (
                          <div className="glass-card" style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>PAN Card</p>
                              <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>{selectedApp.panNumber || 'N/A'}</p>
                            </div>
                            <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                              <img src={getFullImageUrl(selectedApp.panCardImage)} alt="PAN Card" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                              <a href={getFullImageUrl(selectedApp.panCardImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                                View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                              </a>
                            </div>
                          </div>
                        )}

                        {selectedApp.addressProofImage && (
                          <div className="glass-card" style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Address Proof ({selectedApp.addressProofType || 'Utility Bill'})</p>
                              <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>Verified Address Proof</p>
                            </div>
                            <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                              <img src={getFullImageUrl(selectedApp.addressProofImage)} alt="Address Proof" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                              <a href={getFullImageUrl(selectedApp.addressProofImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                                View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                              </a>
                            </div>
                          </div>
                        )}

                        {selectedApp.shopFrontImage && (
                          <div className="glass-card" style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Shop Front View</p>
                              <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>Exterior Storefront Image</p>
                            </div>
                            <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                              <img src={getFullImageUrl(selectedApp.shopFrontImage)} alt="Shop Front View" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                              <a href={getFullImageUrl(selectedApp.shopFrontImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                                View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                              </a>
                            </div>
                          </div>
                        )}

                        {selectedApp.shopInsideImage && (
                          <div className="glass-card" style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                            <div>
                              <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 600 }}>Shop Inside View</p>
                              <p style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '0.15rem' }}>Interior Store Image</p>
                            </div>
                            <div style={{ position: 'relative', width: '100%', height: '140px', borderRadius: '8px', overflow: 'hidden', border: '1px solid hsl(var(--border))' }}>
                              <img src={getFullImageUrl(selectedApp.shopInsideImage)} alt="Shop Inside View" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                              <a href={getFullImageUrl(selectedApp.shopInsideImage)} target="_blank" rel="noreferrer" style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 0, transition: 'opacity 0.2s', color: 'white', fontWeight: 600 }} className="hover-overlay">
                                View Full Image <ExternalLink size={14} style={{ marginLeft: '4px' }} />
                              </a>
                            </div>
                          </div>
                        )}
                      </div>
                    </section>

                    <section>
                      <h4 style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'hsl(var(--muted-foreground))', marginBottom: '0.75rem' }}>
                        Submitted Documents
                      </h4>

                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                        {selectedApp.documents.map((doc) => (
                          <div key={doc.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', padding: '0.75rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                              <FileText size={20} style={{ color: 'hsl(var(--primary))' }} />
                              <div>
                                <p style={{ fontSize: '0.875rem', fontWeight: 600 }}>{doc.name}</p>
                                <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>{doc.type}</p>
                              </div>
                            </div>
                            <a href={doc.url} style={{ color: 'hsl(var(--primary))' }} target="_blank" rel="noreferrer">
                              <ExternalLink size={18} />
                            </a>
                          </div>
                        ))}
                      </div>
                    </section>

                    {canModerate && (
                      <section>
                        <h4 style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'hsl(var(--muted-foreground))', marginBottom: '0.75rem' }}>
                          Review Actions
                        </h4>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                          {hasPermission(PERMISSIONS.keepersApprove) && (
                            <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(16, 185, 129, 0.05)' }}>
                              <p style={{ fontWeight: 700, marginBottom: '0.65rem' }}>Approve keeper</p>
                              <textarea
                                value={approveNotes}
                                onChange={(event) => setApproveNotes(event.target.value)}
                                rows={4}
                                placeholder="Optional approval notes"
                                style={{ width: '100%', resize: 'vertical', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none', marginBottom: '0.75rem' }}
                              />
                              <button onClick={() => void handleApprove()} disabled={submittingAction === 'approve'} style={{ ...actionButtonStyle('linear-gradient(135deg, #16a34a, #22c55e)', 'white'), opacity: submittingAction === 'approve' ? 0.7 : 1 }}>
                                Approve
                              </button>
                            </div>
                          )}

                          {hasPermission(PERMISSIONS.keepersReject) && (
                            <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(239, 68, 68, 0.05)' }}>
                              <p style={{ fontWeight: 700, marginBottom: '0.65rem' }}>Reject keeper</p>
                              <textarea
                                value={rejectReason}
                                onChange={(event) => setRejectReason(event.target.value)}
                                rows={4}
                                placeholder="Required rejection reason"
                                style={{ width: '100%', resize: 'vertical', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none', marginBottom: '0.75rem' }}
                              />
                              <button onClick={() => void handleReject()} disabled={submittingAction === 'reject'} style={{ ...actionButtonStyle('rgba(239, 68, 68, 0.16)', '#ef4444'), opacity: submittingAction === 'reject' ? 0.7 : 1 }}>
                                Reject
                              </button>
                            </div>
                          )}

                          {hasPermission(PERMISSIONS.keepersView) && (
                            <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(59, 130, 246, 0.05)' }}>
                              <p style={{ fontWeight: 700, marginBottom: '0.65rem' }}>Request more information</p>
                              <textarea
                                value={requestMessage}
                                onChange={(event) => setRequestMessage(event.target.value)}
                                rows={4}
                                placeholder="Required message for the keeper"
                                style={{ width: '100%', resize: 'vertical', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none', marginBottom: '0.75rem' }}
                              />
                              <button onClick={() => void handleRequestInfo()} disabled={submittingAction === 'request-info'} style={{ ...actionButtonStyle('rgba(59, 130, 246, 0.14)', '#60a5fa'), opacity: submittingAction === 'request-info' ? 0.7 : 1 }}>
                                Send Request
                              </button>
                            </div>
                          )}

                          {hasPermission(PERMISSIONS.keepersApprove) && (
                            <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(245, 158, 11, 0.05)' }}>
                              <p style={{ fontWeight: 700, marginBottom: '0.65rem' }}>Place on hold</p>
                              <textarea
                                value={holdReason}
                                onChange={(event) => setHoldReason(event.target.value)}
                                rows={3}
                                placeholder="Optional hold reason"
                                style={{ width: '100%', resize: 'vertical', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none', marginBottom: '0.75rem' }}
                              />
                              <input
                                type="datetime-local"
                                value={holdUntil}
                                onChange={(event) => setHoldUntil(event.target.value)}
                                style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none', marginBottom: '0.75rem' }}
                              />
                              <button onClick={() => void handleHold()} disabled={submittingAction === 'hold'} style={{ ...actionButtonStyle('rgba(245, 158, 11, 0.14)', '#f59e0b'), opacity: submittingAction === 'hold' ? 0.7 : 1 }}>
                                Hold Application
                              </button>
                            </div>
                          )}
                        </div>
                      </section>
                    )}

                    <section>
                      <h4 style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'hsl(var(--muted-foreground))', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                        <Info size={14} /> Review Message History
                      </h4>
                      {selectedApp.reviewMessages.length === 0 ? (
                        <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)', color: 'hsl(var(--muted-foreground))' }}>
                          No review messages have been recorded for this application yet.
                        </div>
                      ) : (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                          {selectedApp.reviewMessages.map((message) => (
                            <div key={message.messageId} style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)' }}>
                              <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                                <div>
                                  <p style={{ fontWeight: 700, textTransform: 'capitalize' }}>{message.messageType.replace(/-/g, ' ')}</p>
                                  <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>
                                    {message.adminName} | {new Date(message.createdAt).toLocaleString()}
                                  </p>
                                </div>
                                <span style={{ fontSize: '0.75rem', color: message.isReadByKeeper ? '#10b981' : '#f59e0b', fontWeight: 700 }}>
                                  {message.isReadByKeeper ? 'Read by keeper' : 'Unread'}
                                </span>
                              </div>
                              <p style={{ marginTop: '0.75rem', lineHeight: 1.6 }}>{message.message}</p>
                            </div>
                          ))}
                        </div>
                      )}
                    </section>

                    <section>
                      <h4 style={{ fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', color: 'hsl(var(--muted-foreground))', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                        <Shield size={14} /> Submission Metadata
                      </h4>
                      <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.03)', display: 'grid', gap: '0.5rem' }}>
                        <p style={{ fontSize: '0.85rem' }}><strong>User ID:</strong> {selectedApp.userId}</p>
                        <p style={{ fontSize: '0.85rem' }}><strong>Keeper ID:</strong> {selectedApp.id}</p>
                        <p style={{ fontSize: '0.85rem' }}><strong>Social links payload:</strong> {selectedApp.socialLinksJson || 'Not provided'}</p>
                      </div>
                    </section>
                  </div>
                )}
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </DashboardLayout>
  );
}
