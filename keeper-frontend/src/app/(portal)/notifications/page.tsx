'use client';

import { useEffect, useState } from 'react';
import {
  Bell,
  Send,
  Users,
  Image as ImageIcon,
  Link2,
  Megaphone,
  Tag,
  Clock,
  Eye,
  ChevronRight,
  Sparkles,
  Radio,
  Calendar,
  Trash2,
  Power,
  PowerOff,
  Upload,
} from 'lucide-react';
import { PageHeader } from '@/components/PageHeader';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import { StatusPill } from '@/components/StatusPill';
import CustomSelect from '@/components/CustomSelect';
import api from '@/lib/api';
import { formatDateTime } from '@/lib/format';
import {
  KeeperNotification,
  OfferDetail,
  ShopSummary,
} from '@/lib/types';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { useAuth } from '@/context/AuthContext';

export default function NotificationsPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [notifications, setNotifications] = useState<KeeperNotification[]>([]);
  const [offers, setOffers] = useState<OfferDetail[]>([]);
  const [shops, setShops] = useState<ShopSummary[]>([]);

  // Compose form state
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [selectedOfferId, setSelectedOfferId] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  // We will collect available images from shops to let user select
  const availableImages = Array.from(new Set([
    ...shops.map(s => s.shopProfileImage).filter(Boolean)
  ])) as string[];

  const isCustomImage = imageUrl && !availableImages.includes(imageUrl);
  const imageOptions = [
    { value: '', label: 'No image' },
    ...availableImages.map(img => ({
      value: img,
      label: 'Shop Image',
      icon: <img src={img} alt="thumb" style={{ width: 16, height: 16, borderRadius: 4, objectFit: 'cover' }} />
    }))
  ];
  if (isCustomImage) {
    imageOptions.push({
      value: imageUrl,
      label: 'Custom Upload',
      icon: <img src={imageUrl} alt="custom" style={{ width: 16, height: 16, borderRadius: 4, objectFit: 'cover' }} />
    });
  }

  useEffect(() => {
    let active = true;

    async function load() {
      setLoading(true);
      setError('');

      try {
        const [notifRes, offersRes, shopsRes] = await Promise.all([
          api.get('/keeper/notifications/sent'),
          api.get('/keeper/offers'),
          api.get('/keeper/shops'),
        ]);

        if (active) {
          setNotifications(unwrapApiData<KeeperNotification[]>(notifRes) || []);
          setOffers(unwrapApiData<OfferDetail[]>(offersRes) || []);
          setShops(unwrapApiData<ShopSummary[]>(shopsRes) || []);
        }
      } catch (err) {
        if (active) {
          setError(getApiErrorMessage(err, 'Unable to load notifications.'));
        }
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    void load();

    return () => {
      active = false;
    };
  }, []);

  async function handleSend() {
    if (sending) return;
    if (!title.trim() || !message.trim()) {
      setError('Title and message are required.');
      return;
    }

    setSending(true);
    setError('');
    setSuccess('');

    try {
      const payload: Record<string, unknown> = {
        title: title.trim(),
        message: message.trim(),
      };

      if (selectedOfferId) {
        payload.offerId = selectedOfferId;
      }

      if (imageUrl.trim()) {
        payload.imageUrl = imageUrl.trim();
      }

      if (startDate) payload.startDate = new Date(startDate).toISOString();
      if (endDate) payload.endDate = new Date(endDate).toISOString();

      const response = await api.post('/keeper/notifications/send', payload);
      const result = unwrapApiData<{ recipientCount: number }>(response);
      const count = result?.recipientCount ?? 0;

      setSuccess(
        startDate && new Date(startDate) > new Date()
          ? `Notification scheduled successfully.`
          : `Notification sent to ${count} user(s) within your shop radius.`
      );
      setTitle('');
      setMessage('');
      setSelectedOfferId('');
      setImageUrl('');
      setStartDate('');
      setEndDate('');

      const refreshed = await api.get('/keeper/notifications/sent');
      setNotifications(unwrapApiData<KeeperNotification[]>(refreshed) || []);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Failed to send notification.'));
    } finally {
      setSending(false);
    }
  }

  async function toggleStatus(notifId: string, currentStatus: boolean) {
    try {
      await api.put(`/keeper/notifications/${notifId}/status`, { isActive: !currentStatus });
      setNotifications(prev => prev.map(n => n.notificationId === notifId ? { ...n, isActive: !currentStatus } : n));
    } catch (err) {
      alert('Failed to update status');
    }
  }

  async function deleteNotification(notifId: string) {
    if (!window.confirm('Are you sure you want to delete this notification?')) return;
    try {
      await api.delete(`/keeper/notifications/${notifId}`);
      setNotifications(prev => prev.filter(n => n.notificationId !== notifId));
    } catch (err) {
      alert('Failed to delete notification');
    }
  }

  const activeOffers = offers.filter(
    (o) => o.status.toLowerCase() === 'active',
  );

  const totalSent = notifications.length;
  const totalRecipients = notifications.reduce(
    (sum, n) => sum + (n.recipientCount || 0),
    0,
  );

  const canSend = user?.canManage && shops.length > 0;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.75rem', paddingBottom: '2.5rem' }}>
      <style dangerouslySetInnerHTML={{ __html: `
        @keyframes notif-ping {
          0% { transform: scale(1); opacity: 0.75; }
          100% { transform: scale(2.2); opacity: 0; }
        }
        @keyframes notif-fade-in {
          from { opacity: 0; transform: translateY(6px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes send-pulse {
          0%, 100% { box-shadow: 0 4px 20px rgba(99,102,241,0.3); }
          50% { box-shadow: 0 4px 30px rgba(99,102,241,0.55); }
        }
        .notif-ping { animation: notif-ping 1.8s cubic-bezier(0,0,0.2,1) infinite; }
        .notif-card-row {
          display: grid;
          grid-template-columns: auto 1fr auto auto auto;
          gap: 1rem;
          align-items: center;
          padding: 1rem 1.25rem;
          border-radius: 18px;
          border: 1px solid rgba(148,163,184,0.12);
          background: linear-gradient(180deg, rgba(255,255,255,0.04) 0%, rgba(255,255,255,0.015) 100%);
          transition: transform 0.18s ease, border-color 0.18s ease, box-shadow 0.18s ease;
          animation: notif-fade-in 0.35s ease;
        }
        .notif-card-row:hover {
          transform: translateY(-2px);
          border-color: rgba(99,102,241,0.22);
          box-shadow: 0 12px 28px rgba(15,23,42,0.07);
        }
        .notif-compose-field {
          display: flex;
          flex-direction: column;
          gap: 0.45rem;
        }
        .notif-compose-field label {
          display: flex;
          align-items: center;
          gap: 0.45rem;
          font-size: 0.8rem;
          font-weight: 700;
          color: hsl(var(--foreground));
          opacity: 0.75;
          letter-spacing: 0.02em;
        }
        .notif-input {
          padding: 0.75rem 1rem;
          border-radius: 14px;
          border: 1px solid hsl(var(--border));
          background: rgba(255,255,255,0.03);
          color: hsl(var(--foreground));
          font-size: 0.875rem;
          outline: none;
          transition: border-color 0.2s ease, box-shadow 0.2s ease;
          width: 100%;
          box-sizing: border-box;
          font-family: inherit;
        }
        .notif-input:focus {
          border-color: rgba(99,102,241,0.45);
          box-shadow: 0 0 0 3px rgba(99,102,241,0.08);
        }
        .notif-input::placeholder { color: rgba(100,116,139,0.7); }
        .notif-send-btn {
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
          padding: 0.75rem 1.5rem;
          border-radius: 14px;
          font-weight: 700;
          font-size: 0.875rem;
          cursor: pointer;
          border: none;
          background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
          color: #fff;
          transition: all 0.2s ease;
          animation: send-pulse 3s ease-in-out infinite;
        }
        .notif-send-btn:disabled {
          opacity: 0.55;
          cursor: not-allowed;
          animation: none;
          box-shadow: none;
        }
        .notif-send-btn:not(:disabled):hover {
          transform: translateY(-2px);
          box-shadow: 0 8px 24px rgba(99,102,241,0.45);
        }
        .stat-glass-card {
          padding: 1.25rem 1.4rem;
          border-radius: 20px;
          border: 1px solid rgba(148,163,184,0.13);
          background: linear-gradient(180deg, rgba(255,255,255,0.05) 0%, rgba(255,255,255,0.02) 100%);
          display: flex;
          align-items: center;
          gap: 1rem;
          transition: transform 0.2s ease;
        }
        .stat-glass-card:hover { transform: translateY(-2px); }
        @media (max-width: 900px) {
          .notif-card-row { grid-template-columns: auto 1fr; }
          .notif-card-row > :nth-child(3),
          .notif-card-row > :nth-child(4),
          .notif-card-row > :nth-child(5) { display: none; }
        }
        .upload-btn {
          display: inline-flex;
          align-items: center;
          gap: 0.35rem;
          padding: 0.4rem 0.8rem;
          border-radius: 8px;
          font-size: 0.75rem;
          font-weight: 700;
          cursor: pointer;
          background: rgba(99,102,241,0.1);
          color: #6366f1;
          border: 1px solid rgba(99,102,241,0.2);
          transition: all 0.2s ease;
        }
        .upload-btn:hover {
          background: rgba(99,102,241,0.2);
          border-color: rgba(99,102,241,0.4);
          transform: translateY(-1px);
        }
      `}} />

      <PageHeader
        title="Notifications"
        description="Send targeted alerts and promotions to users within your shop's notification radius."
      />

      {error ? <InlineNotice tone="error" message={error} /> : null}
      {success ? <InlineNotice tone="success" message={success} /> : null}

      {/* ── Stats Row ── */}
      {!loading && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(190px, 1fr))', gap: '1rem' }}>
          {/* Total Sent */}
          <div className="stat-glass-card">
            <div style={{
              width: 44, height: 44, borderRadius: 14, flexShrink: 0,
              background: 'linear-gradient(135deg, rgba(99,102,241,0.15), rgba(139,92,246,0.15))',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Megaphone size={20} style={{ color: '#8b5cf6' }} />
            </div>
            <div>
              <p style={{ margin: 0, fontSize: '0.72rem', color: 'hsl(var(--muted-foreground))', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 3 }}>
                Total Sent
              </p>
              <strong style={{ fontSize: '1.6rem', fontWeight: 800, lineHeight: 1 }}>{totalSent}</strong>
            </div>
          </div>

          {/* Total Reached */}
          <div className="stat-glass-card">
            <div style={{
              width: 44, height: 44, borderRadius: 14, flexShrink: 0,
              background: 'linear-gradient(135deg, rgba(16,185,129,0.15), rgba(5,150,105,0.15))',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Users size={20} style={{ color: '#10b981' }} />
            </div>
            <div>
              <p style={{ margin: 0, fontSize: '0.72rem', color: 'hsl(var(--muted-foreground))', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 3 }}>
                Total Reached
              </p>
              <strong style={{ fontSize: '1.6rem', fontWeight: 800, lineHeight: 1 }}>{totalRecipients}</strong>
            </div>
          </div>

          {/* Active Offers */}
          <div className="stat-glass-card">
            <div style={{
              width: 44, height: 44, borderRadius: 14, flexShrink: 0,
              background: 'linear-gradient(135deg, rgba(37,99,235,0.15), rgba(59,130,246,0.15))',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Tag size={20} style={{ color: '#2563eb' }} />
            </div>
            <div>
              <p style={{ margin: 0, fontSize: '0.72rem', color: 'hsl(var(--muted-foreground))', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 3 }}>
                Active Offers
              </p>
              <strong style={{ fontSize: '1.6rem', fontWeight: 800, lineHeight: 1 }}>{activeOffers.length}</strong>
            </div>
          </div>
        </div>
      )}

      {/* ── Compose Panel ── */}
      {canSend ? (
        <div
          className="glass-card"
          style={{
            borderRadius: '24px',
            background: 'linear-gradient(180deg, rgba(99,102,241,0.04) 0%, rgba(255,255,255,0.025) 100%)',
            border: '1px solid rgba(99,102,241,0.14)',
            overflow: 'hidden',
          }}
        >
          {/* Compose Header */}
          <div style={{
            padding: '1.25rem 1.75rem',
            borderBottom: '1px solid rgba(148,163,184,0.1)',
            background: 'linear-gradient(90deg, rgba(99,102,241,0.06) 0%, transparent 100%)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(99,102,241,0.3)',
            }}>
              <Radio size={16} color="#fff" />
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 800 }}>Broadcast Notification</h3>
              <p style={{ margin: 0, fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', fontWeight: 500 }}>
                Reaches all users currently inside your shop&apos;s radius
              </p>
            </div>
          </div>

          {/* Compose Form */}
          <div style={{ padding: '1.5rem 1.75rem', display: 'flex', flexDirection: 'column', gap: '1.1rem' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.1rem' }}>
              {/* Title */}
              <div className="notif-compose-field">
                <label htmlFor="notif-title">
                  <Bell size={13} />
                  Title <span style={{ color: '#ef4444', fontSize: '0.85em' }}>*</span>
                </label>
                <input
                  id="notif-title"
                  type="text"
                  className="notif-input"
                  placeholder="e.g. Flash Sale — 50% off today!"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  maxLength={100}
                />
              </div>

              {/* Attach Offer */}
              <div className="notif-compose-field">
                <label htmlFor="notif-offer">
                  <Link2 size={13} />
                  Attach Offer <span style={{ fontSize: '0.85em', opacity: 0.6 }}>(optional)</span>
                </label>
                <CustomSelect
                  value={selectedOfferId}
                  onChange={(val) => setSelectedOfferId(val)}
                  options={[
                    { value: '', label: 'No offer attached', icon: <Link2 size={16} /> },
                    ...activeOffers.map((offer) => ({
                      value: offer.offerId,
                      label: `${offer.title}${offer.discountPercentage ? ` (${offer.discountPercentage}% off)` : ''}`,
                      icon: <Tag size={16} />
                    }))
                  ]}
                  style={{ width: '100%' }}
                />
              </div>
            </div>

            {/* Message */}
            <div className="notif-compose-field">
              <label htmlFor="notif-message">
                <Send size={13} />
                Message <span style={{ color: '#ef4444', fontSize: '0.85em' }}>*</span>
              </label>
              <textarea
                id="notif-message"
                className="notif-input"
                placeholder="Write a compelling message for your customers..."
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={3}
                maxLength={500}
                style={{ resize: 'vertical', minHeight: 80 }}
              />
              <span style={{ fontSize: '0.72rem', color: 'hsl(var(--muted-foreground))', textAlign: 'right' }}>
                {message.length}/500
              </span>
            </div>

            {/* Dates & Image */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1.1rem' }}>
              <div className="notif-compose-field">
                <label htmlFor="notif-start">
                  <Calendar size={13} />
                  Start Date <span style={{ fontSize: '0.85em', opacity: 0.6 }}>(optional)</span>
                </label>
                <input
                  id="notif-start"
                  type="datetime-local"
                  className="notif-input"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                />
              </div>
              <div className="notif-compose-field">
                <label htmlFor="notif-end">
                  <Calendar size={13} />
                  End Date <span style={{ fontSize: '0.85em', opacity: 0.6 }}>(optional)</span>
                </label>
                <input
                  id="notif-end"
                  type="datetime-local"
                  className="notif-input"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  min={startDate || undefined}
                />
              </div>

              {/* Image Selection */}
              <div className="notif-compose-field">
                <label htmlFor="notif-image-select" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ display: 'flex', alignItems: 'center', gap: '0.45rem' }}>
                    <ImageIcon size={13} />
                    Attach Image <span style={{ fontSize: '0.85em', opacity: 0.6 }}>(optional)</span>
                  </span>
                  <label className="upload-btn">
                    <Upload size={12} />
                    Upload New
                    <input 
                      type="file" 
                      accept="image/*" 
                      style={{ display: 'none' }}
                      onChange={(e) => {
                        const file = e.target.files?.[0];
                        if (!file) return;
                        
                        // Enforce 1MB limit for notification images to keep payload small
                        if (file.size > 1024 * 1024) {
                          setError('Image size should be less than 1MB');
                          return;
                        }
                        
                        const reader = new FileReader();
                        reader.onload = (ev) => {
                          if (ev.target?.result) {
                            setImageUrl(ev.target.result as string);
                            setError('');
                          }
                        };
                        reader.readAsDataURL(file);
                      }}
                    />
                  </label>
                </label>
                <CustomSelect
                  value={imageUrl}
                  onChange={(val) => setImageUrl(val)}
                  options={imageOptions}
                  style={{ width: '100%' }}
                />
              </div>
            </div>

            {/* Live Preview */}
            {(title.trim() || message.trim()) && (
              <div style={{
                padding: '1rem 1.25rem',
                borderRadius: '16px',
                background: 'rgba(99,102,241,0.05)',
                border: '1px solid rgba(99,102,241,0.15)',
              }}>
                <p style={{ margin: '0 0 0.6rem', fontSize: '0.72rem', color: 'hsl(var(--muted-foreground))', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em', display: 'flex', alignItems: 'center', gap: 5 }}>
                  <Eye size={12} /> Preview
                </p>
                <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'flex-start' }}>
                  {imageUrl.trim() ? (
                    <img
                      src={imageUrl.trim()}
                      alt="Preview"
                      style={{ width: 48, height: 48, borderRadius: 10, objectFit: 'cover', flexShrink: 0, border: '1px solid rgba(0,0,0,0.08)' }}
                      onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                    />
                  ) : (
                    <div style={{ width: 48, height: 48, borderRadius: 10, background: 'rgba(99,102,241,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <Bell size={20} style={{ color: '#6366f1' }} />
                    </div>
                  )}
                  <div style={{ minWidth: 0, flex: 1 }}>
                    <strong style={{ fontSize: '0.9rem' }}>{title || 'Notification title'}</strong>
                    <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', marginTop: 3, marginBottom: 0 }}>
                      {message || 'Message body will appear here.'}
                    </p>
                    {selectedOfferId && (
                      <span style={{
                        display: 'inline-block', marginTop: 6, padding: '3px 10px',
                        borderRadius: 8, background: 'rgba(16,185,129,0.1)', color: '#059669',
                        fontSize: '0.72rem', fontWeight: 700,
                      }}>
                        📎 {activeOffers.find((o) => o.offerId === selectedOfferId)?.title || 'Offer attached'}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Send Button */}
            <div style={{ display: 'flex', justifyContent: 'flex-end', paddingTop: '0.25rem' }}>
              <button
                type="button"
                className="notif-send-btn"
                disabled={sending || !title.trim() || !message.trim()}
                onClick={() => void handleSend()}
              >
                {sending ? (
                  <>
                    <div style={{ width: 16, height: 16, borderRadius: '50%', border: '2px solid rgba(255,255,255,0.3)', borderTopColor: '#fff', animation: 'spin 0.7s linear infinite' }} />
                    Sending...
                  </>
                ) : (
                  <>
                    <Sparkles size={16} />
                    Send to nearby users
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      ) : !loading && shops.length === 0 ? (
        <div
          className="glass-card"
          style={{ padding: '2rem', borderRadius: '24px', textAlign: 'center' }}
        >
          <div style={{ width: 56, height: 56, borderRadius: 16, background: 'rgba(99,102,241,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1rem' }}>
            <Radio size={28} style={{ color: '#6366f1' }} />
          </div>
          <h3 style={{ fontWeight: 800, marginBottom: '0.5rem' }}>Set up a shop first</h3>
          <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.875rem', maxWidth: '360px', margin: '0 auto' }}>
            Create a shop with a notification radius, then return here to start broadcasting to nearby users.
          </p>
        </div>
      ) : null}

      {/* ── Sent History ── */}
      <div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginBottom: '1rem' }}>
          <Clock size={16} style={{ color: 'hsl(var(--muted-foreground))' }} />
          <h3 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 800 }}>Sent History</h3>
          {notifications.length > 0 && (
            <span style={{
              padding: '0.2rem 0.6rem', borderRadius: '999px', fontSize: '0.72rem', fontWeight: 700,
              background: 'rgba(99,102,241,0.1)', color: '#6366f1',
            }}>
              {notifications.length}
            </span>
          )}
        </div>

        {loading ? (
          <div style={{ padding: '2rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>
            <div style={{ width: 32, height: 32, borderRadius: '50%', border: '3px solid rgba(99,102,241,0.2)', borderTopColor: '#6366f1', animation: 'spin 0.8s linear infinite', margin: '0 auto 1rem' }} />
            Loading notifications...
          </div>
        ) : notifications.length === 0 ? (
          <EmptyState
            title="No notifications sent yet"
            message="Once you send your first notification, it will appear here with delivery details."
          />
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
            {notifications.map((notif) => (
              <div key={notif.notificationId} className="notif-card-row">
                {/* Icon / Image */}
                <div>
                  {notif.imageUrl ? (
                    <img
                      src={notif.imageUrl}
                      alt=""
                      style={{ width: 42, height: 42, borderRadius: 12, objectFit: 'cover', border: '1px solid rgba(148,163,184,0.15)', display: 'block' }}
                    />
                  ) : (
                    <div style={{
                      width: 42, height: 42, borderRadius: 12,
                      background: 'linear-gradient(135deg, rgba(99,102,241,0.12), rgba(139,92,246,0.12))',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      border: '1px solid rgba(99,102,241,0.12)',
                    }}>
                      <Bell size={18} style={{ color: '#8b5cf6' }} />
                    </div>
                  )}
                </div>

                {/* Title + Message */}
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontWeight: 700, fontSize: '0.9rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {notif.title}
                  </div>
                  <div style={{ fontSize: '0.78rem', color: 'hsl(var(--muted-foreground))', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', marginTop: 2 }}>
                    {notif.message}
                  </div>
                  {notif.offerTitle && (
                    <span style={{
                      display: 'inline-block', marginTop: 4, padding: '2px 8px',
                      borderRadius: 6, background: 'rgba(16,185,129,0.09)', color: '#059669',
                      fontSize: '0.68rem', fontWeight: 700,
                    }}>
                      📎 {notif.offerTitle}
                    </span>
                  )}
                </div>

                {/* Type */}
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <StatusPill status={notif.type} />
                </div>

                {/* Recipients */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', whiteSpace: 'nowrap' }}>
                  <div style={{
                    width: 28, height: 28, borderRadius: 8,
                    background: 'rgba(16,185,129,0.1)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <Users size={14} style={{ color: '#10b981' }} />
                  </div>
                  <strong style={{ fontSize: '0.875rem' }}>{notif.recipientCount}</strong>
                </div>

                {/* Date & Actions */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem', color: 'hsl(var(--muted-foreground))', whiteSpace: 'nowrap' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '2px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                      <Clock size={12} style={{ opacity: 0.6 }} />
                      <span style={{ fontSize: '0.7rem', fontWeight: 600 }}>
                        {notif.scheduledAt ? formatDateTime(notif.scheduledAt) : formatDateTime(notif.createdAt)}
                      </span>
                    </div>
                    {notif.expiresAt && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', color: '#ef4444' }}>
                        <Clock size={12} style={{ opacity: 0.6 }} />
                        <span style={{ fontSize: '0.7rem', fontWeight: 600 }}>
                          Ends: {formatDateTime(notif.expiresAt)}
                        </span>
                      </div>
                    )}
                  </div>
                  
                  <div style={{ width: '1px', height: '24px', background: 'rgba(148,163,184,0.2)', margin: '0 0.25rem' }} />

                  <button
                    onClick={() => void toggleStatus(notif.notificationId, notif.isActive)}
                    title={notif.isActive ? "Deactivate" : "Activate"}
                    style={{
                      border: 'none', cursor: 'pointer', padding: '6px', borderRadius: '8px',
                      color: notif.isActive ? '#10b981' : 'hsl(var(--muted-foreground))',
                      background: notif.isActive ? 'rgba(16,185,129,0.1)' : 'rgba(148,163,184,0.1)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center'
                    }}
                  >
                    {notif.isActive ? <Power size={16} /> : <PowerOff size={16} />}
                  </button>

                  <button
                    onClick={() => void deleteNotification(notif.notificationId)}
                    title="Delete"
                    style={{
                      background: 'rgba(239,68,68,0.1)', border: 'none', cursor: 'pointer', padding: '6px', borderRadius: '8px',
                      color: '#ef4444', display: 'flex', alignItems: 'center', justifyContent: 'center'
                    }}
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}
