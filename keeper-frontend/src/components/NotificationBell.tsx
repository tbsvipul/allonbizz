'use client';

import { useEffect, useState, useRef } from 'react';
import { Bell, Check, Trash2, ShieldAlert, Sparkles, Megaphone, Info } from 'lucide-react';
import api from '@/lib/api';
import { unwrapApiData, unwrapPagedResponse } from '@/lib/api-response';
import { formatDateTime } from '@/lib/format';

interface UserNotification {
  notificationId: string;
  title: string;
  message: string;
  imageUrl?: string;
  type: string;
  priority: string;
  isRead: boolean;
  createdAt: string;
}

export function NotificationBell() {
  const [open, setOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const [notifications, setNotifications] = useState<UserNotification[]>([]);
  const [loading, setLoading] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchUnreadCount();
    const interval = setInterval(fetchUnreadCount, 60000); // Check every minute
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (ref.current && !ref.current.contains(event.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    if (open) {
      fetchNotifications();
    }
  }, [open]);

  async function fetchUnreadCount() {
    try {
      const res = await api.get('/user/notifications/unread-count');
      setUnreadCount(unwrapApiData<number>(res) || 0);
    } catch (e) {
      // Ignore
    }
  }

  async function fetchNotifications() {
    setLoading(true);
    try {
      const res = await api.get('/user/notifications', { params: { pageSize: 10, pageNumber: 1 } });
      const items = unwrapPagedResponse<UserNotification>(res).data || [];
      setNotifications(items);
    } catch (e) {
      // Ignore
    } finally {
      setLoading(false);
    }
  }

  async function markAsRead(id: string) {
    try {
      await api.put(`/user/notifications/${id}/read`);
      setNotifications(prev => prev.map(n => n.notificationId === id ? { ...n, isRead: true } : n));
      setUnreadCount(prev => Math.max(0, prev - 1));
    } catch (e) {}
  }

  async function deleteNotification(id: string) {
    try {
      await api.delete(`/user/notifications/${id}`);
      setNotifications(prev => prev.filter(n => n.notificationId !== id));
    } catch (e) {}
  }

  const getIcon = (type: string) => {
    switch (type) {
      case 'SystemMessage': return <ShieldAlert size={16} color="var(--accent)" />;
      case 'Promotion': return <Sparkles size={16} color="var(--accent-alt)" />;
      case 'Alert': return <Megaphone size={16} color="var(--danger)" />;
      default: return <Info size={16} color="var(--text-muted)" />;
    }
  };

  return (
    <div ref={ref} style={{ position: 'relative' }}>
      <button
        type="button"
        className="portal-icon-button"
        onClick={() => setOpen(!open)}
        title="Notifications"
        style={{ position: 'relative' }}
      >
        <Bell size={18} />
        {unreadCount > 0 && (
          <span style={{
            position: 'absolute',
            top: 4,
            right: 4,
            width: 8,
            height: 8,
            backgroundColor: 'var(--danger)',
            borderRadius: '50%',
            boxShadow: '0 0 0 2px var(--background)'
          }} />
        )}
      </button>

      {open && (
        <div style={{
          position: 'absolute',
          top: '100%',
          right: 0,
          marginTop: '0.5rem',
          width: '320px',
          maxHeight: '400px',
          overflowY: 'auto',
          zIndex: 50,
          display: 'flex',
          flexDirection: 'column',
          background: 'var(--surface)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--shadow)'
        }}>
          <div style={{ padding: '1rem', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'sticky', top: 0, background: 'var(--surface)', zIndex: 10 }}>
            <h3 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 700, color: 'var(--text)' }}>Inbox</h3>
            {unreadCount > 0 && (
              <span style={{ fontSize: '0.7rem', padding: '0.2rem 0.6rem', background: 'var(--accent-soft)', color: 'var(--accent-strong)', borderRadius: '999px', fontWeight: 700 }}>
                {unreadCount} unread
              </span>
            )}
          </div>

          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {loading && notifications.length === 0 ? (
              <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--text-muted)', fontSize: '0.8rem' }}>Loading...</div>
            ) : notifications.length === 0 ? (
              <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--text-muted)', fontSize: '0.8rem' }}>No notifications yet</div>
            ) : (
              notifications.map((notif) => (
                <div key={notif.notificationId} style={{
                  padding: '1rem',
                  borderBottom: '1px solid var(--border)',
                  background: notif.isRead ? 'transparent' : 'var(--accent-soft)',
                  display: 'flex',
                  gap: '0.75rem',
                  alignItems: 'flex-start'
                }}>
                  <div style={{
                    width: 32, height: 32, borderRadius: '50%',
                    background: 'var(--surface-muted)',
                    border: '1px solid var(--border)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0
                  }}>
                    {getIcon(notif.type)}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <strong style={{ fontSize: '0.85rem', fontWeight: notif.isRead ? 600 : 700, color: 'var(--text)' }}>{notif.title}</strong>
                      <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)' }}>{formatDateTime(notif.createdAt).split(',')[0]}</span>
                    </div>
                    <p style={{ margin: '4px 0 0', fontSize: '0.75rem', color: 'var(--text-muted)', lineHeight: 1.4 }}>
                      {notif.message}
                    </p>
                    <div style={{ display: 'flex', gap: '0.75rem', marginTop: '0.75rem' }}>
                      {!notif.isRead && (
                        <button onClick={() => void markAsRead(notif.notificationId)} style={{ background: 'none', border: 'none', color: 'var(--accent)', fontSize: '0.75rem', padding: 0, cursor: 'pointer', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
                          <Check size={12} /> Mark read
                        </button>
                      )}
                      <button onClick={() => void deleteNotification(notif.notificationId)} style={{ background: 'none', border: 'none', color: 'var(--danger)', fontSize: '0.75rem', padding: 0, cursor: 'pointer', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Trash2 size={12} /> Delete
                      </button>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}
