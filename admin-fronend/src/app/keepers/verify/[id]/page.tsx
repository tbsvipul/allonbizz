'use client';

/* eslint-disable @next/next/no-img-element */

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import {
  AlertCircle,
  ArrowLeft,
  BadgeCheck,
  CalendarClock,
  CheckCircle,
  ExternalLink,
  Eye,
  FileText,
  Image as ImageIcon,
  Info,
  Maximize2,
  PauseCircle,
  Send,
  Shield,
  Store,
  X,
  XCircle,
} from 'lucide-react';
import { AnimatePresence, motion } from 'framer-motion';
import api from '@/lib/api';
import { unwrapApiData } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';

interface KeeperDocument {
  id: string;
  name: string;
  type: string;
  url: string;
  status?: string;
  reviewNotes?: string | null;
  reviewedAt?: string | null;
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
  status: string;
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
  rejectionReason?: string | null;
  holdReason?: string | null;
  holdUntil?: string | null;
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
  verificationNotes?: string | null;
  isVerified?: boolean;
  deletedAt?: string | null;
}

type Notice = {
  tone: 'success' | 'error';
  message: string;
} | null;

type ImagePreview = {
  title: string;
  subtitle?: string;
  src: string;
} | null;

const getFullImageUrl = (path?: string | null) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:')) return path;

  if (path.length > 200 && !path.includes('.')) {
    try {
      const decodedStr = atob(path);
      if (decodedStr.startsWith('\\x')) {
        const hex = decodedStr.slice(2);
        let binary = '';
        for (let i = 0; i < hex.length; i += 2) {
          binary += String.fromCharCode(parseInt(hex.substring(i, i + 2), 16));
        }
        return `data:image/png;base64,${btoa(binary)}`;
      }
    } catch {
      // The value is still useful as a direct base64 payload below.
    }

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

function actionButtonStyle(background: string, color: string): React.CSSProperties {
  return {
    width: '100%',
    padding: '0.75rem 1rem',
    borderRadius: 'var(--radius)',
    border: 'none',
    background,
    color,
    fontWeight: 800,
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    gap: '0.45rem',
  };
}

function formatDateTime(value?: string | null) {
  if (!value) return 'Not provided';

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;

  return date.toLocaleString();
}

function statusStyle(status?: string): React.CSSProperties {
  const normalized = String(status || '').toLowerCase();
  if (normalized.includes('hold')) {
    return { background: 'rgba(245, 158, 11, 0.12)', color: '#d97706' };
  }
  if (normalized.includes('approved') || normalized.includes('active')) {
    return { background: 'rgba(16, 185, 129, 0.12)', color: '#10b981' };
  }
  if (normalized.includes('reject') || normalized.includes('suspend')) {
    return { background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444' };
  }
  return { background: 'rgba(59, 130, 246, 0.12)', color: '#3b82f6' };
}

function isImageDocument(doc: KeeperDocument) {
  const value = `${doc.type || ''} ${doc.name || ''} ${doc.url || ''}`.toLowerCase();
  return ['image', '.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'].some((token) => value.includes(token));
}

function DetailField({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div style={{ minWidth: 0 }}>
      <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', marginBottom: '0.25rem' }}>{label}</p>
      <p style={{ fontWeight: 700, overflowWrap: 'anywhere', lineHeight: 1.45 }}>{value || 'Not provided'}</p>
    </div>
  );
}

function Section({ title, icon, children }: { title: string; icon: React.ReactNode; children: React.ReactNode }) {
  return (
    <section className="glass-card" style={{ padding: '1.5rem' }}>
      <h2
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '0.5rem',
          fontSize: '0.8rem',
          fontWeight: 800,
          textTransform: 'uppercase',
          color: 'hsl(var(--muted-foreground))',
          marginBottom: '1rem',
        }}
      >
        {icon}
        {title}
      </h2>
      {children}
    </section>
  );
}

function MediaProofCard({
  title,
  subtitle,
  src,
  onOpen,
}: {
  title: string;
  subtitle?: string;
  src: string;
  onOpen: () => void;
}) {
  return (
    <div
      style={{
        border: '1px solid hsl(var(--border))',
        borderRadius: 'var(--radius)',
        overflow: 'hidden',
        background: 'hsl(var(--card))',
      }}
    >
      <button
        type="button"
        onClick={onOpen}
        style={{
          position: 'relative',
          width: '100%',
          height: '170px',
          border: 'none',
          borderRadius: 0,
          overflow: 'hidden',
          background: 'hsl(var(--secondary))',
          display: 'block',
          padding: 0,
        }}
        aria-label={`Open ${title}`}
      >
        <img src={src} alt={title} style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
        <span
          style={{
            position: 'absolute',
            inset: 0,
            background: 'rgba(15, 23, 42, 0.52)',
            color: 'white',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '0.45rem',
            fontWeight: 800,
            opacity: 0,
            transition: 'opacity 0.2s ease',
          }}
          className="keeper-image-overlay"
        >
          <Maximize2 size={16} />
          View full image
        </span>
      </button>
      <div style={{ padding: '0.9rem 1rem' }}>
        <p style={{ fontSize: '0.88rem', fontWeight: 800, overflowWrap: 'anywhere' }}>{title}</p>
        {subtitle && (
          <p style={{ fontSize: '0.78rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem', overflowWrap: 'anywhere' }}>
            {subtitle}
          </p>
        )}
      </div>
    </div>
  );
}

function ImagePreviewModal({ image, onClose }: { image: ImagePreview; onClose: () => void }) {
  if (!image) return null;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
        role="dialog"
        aria-modal="true"
        aria-label={image.title}
        style={{
          position: 'fixed',
          inset: 0,
          zIndex: 9999,
          background: 'rgba(0, 0, 0, 0.95)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          padding: '1.5rem 2rem',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          background: 'linear-gradient(to bottom, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0) 100%)',
          zIndex: 10000,
          pointerEvents: 'none',
        }}>
          <div style={{ pointerEvents: 'auto' }}>
            <p style={{ fontWeight: 800, color: 'white', fontSize: '1.25rem', overflowWrap: 'anywhere' }}>{image.title}</p>
            {image.subtitle && (
              <p style={{ color: 'rgba(255,255,255,0.7)', fontSize: '0.9rem', marginTop: '0.2rem', overflowWrap: 'anywhere' }}>
                {image.subtitle}
              </p>
            )}
          </div>
          <button
            type="button"
            onClick={onClose}
            style={{
              width: '44px',
              height: '44px',
              borderRadius: '50%',
              border: 'none',
              background: 'rgba(255,255,255,0.15)',
              color: 'white',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              pointerEvents: 'auto',
              backdropFilter: 'blur(4px)',
            }}
            aria-label="Close full image"
          >
            <X size={22} />
          </button>
        </div>

        <motion.div
          initial={{ scale: 0.96 }}
          animate={{ scale: 1 }}
          exit={{ scale: 0.96 }}
          onClick={(event) => event.stopPropagation()}
          style={{
            width: '100%',
            height: '100%',
            padding: '5rem 2rem 2rem 2rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <img
            src={image.src}
            alt={image.title}
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
    </AnimatePresence>
  );
}

export default function KeeperVerificationDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { hasPermission } = useAuth();
  const keeperId = typeof params.id === 'string' ? params.id : Array.isArray(params.id) ? params.id[0] : '';

  const [application, setApplication] = useState<KeeperApplicationDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [notice, setNotice] = useState<Notice>(null);
  const [submittingAction, setSubmittingAction] = useState<string | null>(null);
  const [approveNotes, setApproveNotes] = useState('');
  const [rejectReason, setRejectReason] = useState('');
  const [requestMessage, setRequestMessage] = useState('');
  const [holdReason, setHoldReason] = useState('');
  const [holdUntil, setHoldUntil] = useState('');
  const [selectedImage, setSelectedImage] = useState<ImagePreview>(null);

  const canApprove = hasPermission(PERMISSIONS.keepersApprove);
  const canReject = hasPermission(PERMISSIONS.keepersReject);
  const canModerate = canApprove || canReject;

  const fetchApplicationDetail = useCallback(async () => {
    if (!keeperId) return;

    setLoading(true);
    try {
      const response = await api.get(`/keepers/pending/${keeperId}`);
      setApplication(unwrapApiData<KeeperApplicationDetail>(response));
      setNotice(null);
    } catch (err) {
      console.error('Failed to fetch keeper detail', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to load keeper application details.') });
      setApplication(null);
    } finally {
      setLoading(false);
    }
  }, [keeperId]);

  const resetActionForms = () => {
    setApproveNotes('');
    setRejectReason('');
    setRequestMessage('');
    setHoldReason('');
    setHoldUntil('');
  };

  useEffect(() => {
    void fetchApplicationDetail();
  }, [fetchApplicationDetail]);

  useEffect(() => {
    if (!selectedImage) return;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setSelectedImage(null);
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [selectedImage]);

  const mediaProofs = useMemo(() => {
    if (!application) return [];

    return [
      {
        title: `Identity Proof${application.identityProofType ? ` (${application.identityProofType})` : ''}`,
        subtitle: application.identityProofNumber || 'Identity document',
        value: application.identityProofImage,
      },
      {
        title: 'Business License',
        subtitle: application.businessLicenseNumber || application.businessLicense || 'Business registration proof',
        value: application.businessLicenseImage,
      },
      {
        title: 'GST Certificate',
        subtitle: application.gstNumber || 'GST proof',
        value: application.gstCertificateImage,
      },
      {
        title: 'PAN Card',
        subtitle: application.panNumber || 'PAN proof',
        value: application.panCardImage,
      },
      {
        title: `Address Proof${application.addressProofType ? ` (${application.addressProofType})` : ''}`,
        subtitle: 'Registered address proof',
        value: application.addressProofImage,
      },
      {
        title: 'Shop Front View',
        subtitle: 'Exterior storefront image',
        value: application.shopFrontImage,
      },
      {
        title: 'Shop Inside View',
        subtitle: 'Interior store image',
        value: application.shopInsideImage,
      },
    ].filter((item) => Boolean(item.value));
  }, [application]);

  const handleApprove = async () => {
    if (!application) return;

    setSubmittingAction('approve');
    try {
      await api.post(`/keepers/${application.id}/approve`, {
        notes: approveNotes.trim() || undefined,
      });
      resetActionForms();
      router.push('/keepers/verify');
    } catch (err) {
      console.error('Failed to approve keeper', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to approve keeper.') });
    } finally {
      setSubmittingAction(null);
    }
  };

  const handleReject = async () => {
    if (!application) return;

    if (!rejectReason.trim()) {
      setNotice({ tone: 'error', message: 'Rejection reason is required.' });
      return;
    }

    setSubmittingAction('reject');
    try {
      await api.post(`/keepers/${application.id}/reject`, {
        reason: rejectReason.trim(),
      });
      resetActionForms();
      router.push('/keepers/verify');
    } catch (err) {
      console.error('Failed to reject keeper', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to reject keeper.') });
    } finally {
      setSubmittingAction(null);
    }
  };

  const handleRequestInfo = async () => {
    if (!application) return;

    if (!requestMessage.trim()) {
      setNotice({ tone: 'error', message: 'A message is required when requesting more information.' });
      return;
    }

    setSubmittingAction('request-info');
    try {
      await api.post(`/keepers/${application.id}/request-info`, {
        message: requestMessage.trim(),
      });
      setNotice({ tone: 'success', message: 'Information request sent to keeper.' });
      setRequestMessage('');
      await fetchApplicationDetail();
    } catch (err) {
      console.error('Failed to request keeper info', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to request more information.') });
    } finally {
      setSubmittingAction(null);
    }
  };

  const handleHold = async () => {
    if (!application) return;

    setSubmittingAction('hold');
    try {
      await api.post(`/keepers/${application.id}/hold`, {
        reason: holdReason.trim() || undefined,
        holdUntil: holdUntil ? new Date(holdUntil).toISOString() : undefined,
      });
      setNotice({ tone: 'success', message: 'Keeper application placed on hold.' });
      setHoldReason('');
      setHoldUntil('');
      await fetchApplicationDetail();
    } catch (err) {
      console.error('Failed to hold keeper application', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to hold keeper application.') });
    } finally {
      setSubmittingAction(null);
    }
  };

  return (
    <DashboardLayout>
      <style dangerouslySetInnerHTML={{ __html: '.keeper-image-overlay:hover, button:hover .keeper-image-overlay { opacity: 1 !important; }' }} />

      <div className="animate-fade-in">
        <div
          style={{
            marginBottom: '1.5rem',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'flex-start',
            gap: '1rem',
            flexWrap: 'wrap',
          }}
        >
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'flex-start', minWidth: 0 }}>
            <button
              type="button"
              onClick={() => router.push('/keepers/verify')}
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '999px',
                border: '1px solid hsl(var(--border))',
                background: 'hsl(var(--secondary))',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'hsl(var(--foreground))',
                flex: '0 0 auto',
              }}
              aria-label="Back to keeper verification"
            >
              <ArrowLeft size={20} />
            </button>
            <div style={{ minWidth: 0 }}>
              <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.85rem', fontWeight: 700, marginBottom: '0.35rem' }}>
                Keeper Application
              </p>
              <h1 style={{ fontSize: '1.75rem', fontWeight: 800, overflowWrap: 'anywhere' }}>
                {application?.businessName || 'Keeper details'}
              </h1>
              {application && (
                <p style={{ color: 'hsl(var(--muted-foreground))', marginTop: '0.35rem', overflowWrap: 'anywhere' }}>
                  {application.ownerName} | {application.email}
                </p>
              )}
            </div>
          </div>

          {application && (
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.45rem',
                padding: '0.55rem 0.9rem',
                borderRadius: '999px',
                fontWeight: 800,
                ...statusStyle(application.status),
              }}
            >
              <BadgeCheck size={16} />
              {application.status}
            </div>
          )}
        </div>

        {notice && (
          <div style={bannerStyle(notice.tone)}>
            <AlertCircle size={18} />
            {notice.message}
          </div>
        )}

        {loading && (
          <div className="glass-card" style={{ padding: '3rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>
            Loading full keeper application...
          </div>
        )}

        {!loading && !application && (
          <div className="flex-center glass-card" style={{ padding: '4rem', flexDirection: 'column', gap: '1rem' }}>
            <XCircle size={48} style={{ color: '#ef4444' }} />
            <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Keeper application not found</h2>
            <p style={{ color: 'hsl(var(--muted-foreground))' }}>The application may have already moved out of pending review.</p>
            <button
              type="button"
              onClick={() => router.push('/keepers/verify')}
              style={actionButtonStyle('hsl(var(--primary))', 'white')}
            >
              Back to keeper list
            </button>
          </div>
        )}

        {!loading && application && (
          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) 360px', gap: '1.5rem', alignItems: 'start' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', minWidth: 0 }}>
              <Section title="Business Profile" icon={<Store size={15} />}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(190px, 1fr))', gap: '1rem 1.25rem' }}>
                  <DetailField label="Business Name" value={application.businessName} />
                  <DetailField label="Owner" value={application.ownerName} />
                  <DetailField label="Email" value={application.email} />
                  <DetailField label="Category" value={application.category} />
                  <DetailField label="Location" value={application.location} />
                  <DetailField label="Applied" value={formatDateTime(application.appliedDate)} />
                  <DetailField label="GST Number" value={application.gstNumber} />
                  <DetailField label="PAN Number" value={application.panNumber} />
                  <DetailField
                    label="Business License"
                    value={
                      <>
                        {application.businessLicense || 'Not provided'}
                        {application.businessLicenseNumber ? ` (${application.businessLicenseNumber})` : ''}
                      </>
                    }
                  />
                  <DetailField
                    label="Identity Proof"
                    value={
                      <>
                        {application.identityProofType || 'Not provided'}
                        {application.identityProofNumber ? ` (${application.identityProofNumber})` : ''}
                      </>
                    }
                  />
                  <DetailField label="Address Proof" value={application.addressProofType} />
                  <DetailField label="Approved At" value={formatDateTime(application.approvedAt)} />
                </div>

                {(application.holdReason || application.rejectionReason) && (
                  <div style={{ marginTop: '1rem', display: 'grid', gap: '0.75rem' }}>
                    {application.holdReason && (
                      <div
                        style={{
                          padding: '0.9rem 1rem',
                          borderRadius: 'var(--radius)',
                          background: 'rgba(245, 158, 11, 0.1)',
                          color: '#d97706',
                          border: '1px solid rgba(245, 158, 11, 0.2)',
                          lineHeight: 1.55,
                        }}
                      >
                        <strong>Hold reason:</strong> {application.holdReason}
                        {application.holdUntil ? ` | Until ${formatDateTime(application.holdUntil)}` : ''}
                      </div>
                    )}
                    {application.rejectionReason && (
                      <div
                        style={{
                          padding: '0.9rem 1rem',
                          borderRadius: 'var(--radius)',
                          background: 'rgba(239, 68, 68, 0.1)',
                          color: '#ef4444',
                          border: '1px solid rgba(239, 68, 68, 0.2)',
                          lineHeight: 1.55,
                        }}
                      >
                        <strong>Rejection reason:</strong> {application.rejectionReason}
                      </div>
                    )}
                  </div>
                )}
              </Section>

              <Section title="Verification Credentials & Media Proofs" icon={<ImageIcon size={15} />}>
                {mediaProofs.length === 0 ? (
                  <div style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', color: 'hsl(var(--muted-foreground))' }}>
                    No verification images were attached to this application.
                  </div>
                ) : (
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
                    {mediaProofs.map((proof) => {
                      const src = getFullImageUrl(proof.value);
                      return (
                        <MediaProofCard
                          key={proof.title}
                          title={proof.title}
                          subtitle={proof.subtitle}
                          src={src}
                          onOpen={() => setSelectedImage({ title: proof.title, subtitle: proof.subtitle, src })}
                        />
                      );
                    })}
                  </div>
                )}
              </Section>

              <Section title="Submitted Documents" icon={<FileText size={15} />}>
                {application.documents.length === 0 ? (
                  <div style={{ padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', color: 'hsl(var(--muted-foreground))' }}>
                    No separate documents were submitted.
                  </div>
                ) : (
                  <div style={{ display: 'grid', gap: '0.75rem' }}>
                    {application.documents.map((doc) => {
                      const documentUrl = getFullImageUrl(doc.url);
                      const imageDoc = isImageDocument(doc);
                      return (
                        <div
                          key={doc.id}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            gap: '1rem',
                            padding: '0.85rem',
                            border: '1px solid hsl(var(--border))',
                            borderRadius: 'var(--radius)',
                            background: 'hsl(var(--card))',
                          }}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', minWidth: 0 }}>
                            <div
                              style={{
                                width: '40px',
                                height: '40px',
                                borderRadius: '10px',
                                background: 'hsl(var(--secondary))',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                color: 'hsl(var(--primary))',
                                flex: '0 0 auto',
                              }}
                            >
                              {imageDoc ? <ImageIcon size={18} /> : <FileText size={18} />}
                            </div>
                            <div style={{ minWidth: 0 }}>
                              <p style={{ fontSize: '0.9rem', fontWeight: 800, overflowWrap: 'anywhere' }}>{doc.name}</p>
                              <p style={{ fontSize: '0.76rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.2rem', overflowWrap: 'anywhere' }}>
                                {doc.type || 'Document'} {doc.status ? `| ${doc.status}` : ''}
                              </p>
                            </div>
                          </div>

                          {doc.url && imageDoc ? (
                            <button
                              type="button"
                              onClick={() => setSelectedImage({ title: doc.name, subtitle: doc.type, src: documentUrl })}
                              style={{
                                border: '1px solid hsl(var(--border))',
                                background: 'hsl(var(--secondary))',
                                color: 'hsl(var(--foreground))',
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: '0.4rem',
                                padding: '0.5rem 0.75rem',
                                fontWeight: 800,
                                whiteSpace: 'nowrap',
                              }}
                            >
                              <Eye size={16} />
                              Preview
                            </button>
                          ) : doc.url ? (
                            <a
                              href={documentUrl}
                              style={{
                                color: 'hsl(var(--primary))',
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: '0.35rem',
                                fontWeight: 800,
                                textDecoration: 'none',
                              }}
                              target="_blank"
                              rel="noreferrer"
                            >
                              Open
                              <ExternalLink size={16} />
                            </a>
                          ) : null}
                        </div>
                      );
                    })}
                  </div>
                )}
              </Section>

              <Section title="Review Message History" icon={<Info size={15} />}>
                {application.reviewMessages.length === 0 ? (
                  <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', color: 'hsl(var(--muted-foreground))' }}>
                    No review messages have been recorded for this application yet.
                  </div>
                ) : (
                  <div style={{ display: 'grid', gap: '0.75rem' }}>
                    {application.reviewMessages.map((message) => (
                      <div
                        key={message.messageId}
                        style={{
                          padding: '1rem',
                          borderRadius: 'var(--radius)',
                          border: '1px solid hsl(var(--border))',
                          background: 'hsl(var(--card))',
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                          <div>
                            <p style={{ fontWeight: 800, textTransform: 'capitalize' }}>{message.messageType.replace(/-/g, ' ')}</p>
                            <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', marginTop: '0.25rem' }}>
                              {message.adminName} | {formatDateTime(message.createdAt)}
                            </p>
                          </div>
                          <span style={{ fontSize: '0.75rem', color: message.isReadByKeeper ? '#10b981' : '#d97706', fontWeight: 800 }}>
                            {message.isReadByKeeper ? 'Read by keeper' : 'Unread'}
                          </span>
                        </div>
                        <p style={{ marginTop: '0.75rem', lineHeight: 1.6, overflowWrap: 'anywhere' }}>{message.message}</p>
                      </div>
                    ))}
                  </div>
                )}
              </Section>
            </div>

            <aside style={{ display: 'flex', flexDirection: 'column', gap: '1rem', position: 'sticky', top: '1rem' }}>
              {canModerate ? (
                <section className="glass-card" style={{ padding: '1.25rem' }}>
                  <h2
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      fontSize: '0.85rem',
                      fontWeight: 800,
                      textTransform: 'uppercase',
                      color: 'hsl(var(--muted-foreground))',
                      marginBottom: '1rem',
                    }}
                  >
                    <Shield size={15} />
                    Review Actions
                  </h2>

                  <div style={{ display: 'grid', gap: '1rem' }}>
                    {canApprove && (
                      <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid rgba(16, 185, 129, 0.25)', background: 'rgba(16, 185, 129, 0.05)' }}>
                        <p style={{ fontWeight: 800, marginBottom: '0.65rem' }}>Approve keeper</p>
                        <textarea
                          value={approveNotes}
                          onChange={(event) => setApproveNotes(event.target.value)}
                          rows={3}
                          placeholder="Optional approval notes"
                          style={{ width: '100%', resize: 'vertical', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'hsl(var(--foreground))', outline: 'none', marginBottom: '0.75rem' }}
                        />
                        <button
                          type="button"
                          onClick={() => void handleApprove()}
                          disabled={submittingAction === 'approve'}
                          style={{ ...actionButtonStyle('linear-gradient(135deg, #16a34a, #22c55e)', 'white'), opacity: submittingAction === 'approve' ? 0.7 : 1 }}
                        >
                          <CheckCircle size={17} />
                          Approve
                        </button>
                      </div>
                    )}

                    {canReject && (
                      <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid rgba(239, 68, 68, 0.25)', background: 'rgba(239, 68, 68, 0.05)' }}>
                        <p style={{ fontWeight: 800, marginBottom: '0.65rem' }}>Reject keeper</p>
                        <textarea
                          value={rejectReason}
                          onChange={(event) => setRejectReason(event.target.value)}
                          rows={3}
                          placeholder="Required rejection reason"
                          style={{ width: '100%', resize: 'vertical', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'hsl(var(--foreground))', outline: 'none', marginBottom: '0.75rem' }}
                        />
                        <button
                          type="button"
                          onClick={() => void handleReject()}
                          disabled={submittingAction === 'reject'}
                          style={{ ...actionButtonStyle('rgba(239, 68, 68, 0.16)', '#ef4444'), opacity: submittingAction === 'reject' ? 0.7 : 1 }}
                        >
                          <XCircle size={17} />
                          Reject
                        </button>
                      </div>
                    )}

                    {canApprove && (
                      <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid rgba(59, 130, 246, 0.25)', background: 'rgba(59, 130, 246, 0.05)' }}>
                        <p style={{ fontWeight: 800, marginBottom: '0.65rem' }}>Request information</p>
                        <textarea
                          value={requestMessage}
                          onChange={(event) => setRequestMessage(event.target.value)}
                          rows={3}
                          placeholder="Required message for the keeper"
                          style={{ width: '100%', resize: 'vertical', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'hsl(var(--foreground))', outline: 'none', marginBottom: '0.75rem' }}
                        />
                        <button
                          type="button"
                          onClick={() => void handleRequestInfo()}
                          disabled={submittingAction === 'request-info'}
                          style={{ ...actionButtonStyle('rgba(59, 130, 246, 0.14)', '#3b82f6'), opacity: submittingAction === 'request-info' ? 0.7 : 1 }}
                        >
                          <Send size={17} />
                          Send Request
                        </button>
                      </div>
                    )}

                    {canApprove && (
                      <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid rgba(245, 158, 11, 0.25)', background: 'rgba(245, 158, 11, 0.05)' }}>
                        <p style={{ fontWeight: 800, marginBottom: '0.65rem' }}>Place on hold</p>
                        <textarea
                          value={holdReason}
                          onChange={(event) => setHoldReason(event.target.value)}
                          rows={3}
                          placeholder="Optional hold reason"
                          style={{ width: '100%', resize: 'vertical', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'hsl(var(--foreground))', outline: 'none', marginBottom: '0.75rem' }}
                        />
                        <input
                          type="datetime-local"
                          value={holdUntil}
                          onChange={(event) => setHoldUntil(event.target.value)}
                          style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'hsl(var(--foreground))', outline: 'none', marginBottom: '0.75rem' }}
                        />
                        <button
                          type="button"
                          onClick={() => void handleHold()}
                          disabled={submittingAction === 'hold'}
                          style={{ ...actionButtonStyle('rgba(245, 158, 11, 0.14)', '#d97706'), opacity: submittingAction === 'hold' ? 0.7 : 1 }}
                        >
                          <PauseCircle size={17} />
                          Hold Application
                        </button>
                      </div>
                    )}
                  </div>
                </section>
              ) : (
                <section className="glass-card" style={{ padding: '1.25rem', color: 'hsl(var(--muted-foreground))', lineHeight: 1.6 }}>
                  You have view access to this application. Approval actions require keeper moderation permissions.
                </section>
              )}

              <section className="glass-card" style={{ padding: '1.25rem' }}>
                <h2
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    fontSize: '0.85rem',
                    fontWeight: 800,
                    textTransform: 'uppercase',
                    color: 'hsl(var(--muted-foreground))',
                    marginBottom: '1rem',
                  }}
                >
                  <CalendarClock size={15} />
                  Metadata
                </h2>
                <div style={{ display: 'grid', gap: '0.75rem' }}>
                  <DetailField label="Keeper ID" value={application.id} />
                  <DetailField label="User ID" value={application.userId} />
                  <DetailField label="Verified Flag" value={application.isVerified ? 'Yes' : 'No'} />
                  <DetailField label="Verification Notes" value={application.verificationNotes} />
                  <DetailField label="Social Links Payload" value={application.socialLinksJson} />
                </div>
              </section>
            </aside>
          </div>
        )}
      </div>

      <ImagePreviewModal image={selectedImage} onClose={() => setSelectedImage(null)} />
    </DashboardLayout>
  );
}
