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
      const res = await api.get('/admin/notifications/inbox/unread-count');
      setUnreadCount(unwrapApiData<number>(res) || 0);
    } catch (e) {
      // Ignore
    }
  }

  async function fetchNotifications() {
    setLoading(true);
    try {
      const res = await api.get('/admin/notifications/inbox', { params: { pageSize: 10, pageNumber: 1 } });
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
      await api.put(`/admin/notifications/inbox/${id}/read`);
      setNotifications(prev => prev.map(n => n.notificationId === id ? { ...n, isRead: true } : n));
      setUnreadCount(prev => Math.max(0, prev - 1));
    } catch (e) {}
  }

  async function deleteNotification(id: string) {
    try {
      await api.delete(`/admin/notifications/inbox/${id}`);
      setNotifications(prev => prev.filter(n => n.notificationId !== id));
    } catch (e) {}
  }

  const getIcon = (type: string) => {
    switch (type) {
      case 'SystemMessage': return <ShieldAlert size={16} color="hsl(var(--primary))" />;
      case 'Promotion': return <Sparkles size={16} color="hsl(var(--secondary))" />;
      case 'Alert': return <Megaphone size={16} color="hsl(var(--destructive))" />;
      default: return <Info size={16} color="hsl(var(--muted-foreground))" />;
    }
  };

  return (
    <div ref={ref} style={{ position: 'relative' }}>
      <button
        type="button"
        onClick={() => setOpen(!open)}
        title="Notifications"
        style={{ background: 'none', border: 'none', color: 'hsl(var(--foreground))', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative', cursor: 'pointer' }}
      >
        <Bell size={20} />
        {unreadCount > 0 && (
          <span style={{
            position: 'absolute',
            top: -6,
            right: -6,
            minWidth: '16px',
            height: '16px',
            backgroundColor: 'hsl(var(--destructive))',
            color: 'white',
            borderRadius: '10px',
            fontSize: '0.65rem',
            padding: '0 4px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 'bold',
            border: '2px solid hsl(var(--card))'
          }}>{unreadCount}</span>
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
          background: 'hsl(var(--card))',
          border: '1px solid hsl(var(--border))',
          borderRadius: 'var(--radius)',
          boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
        }}>
          <div style={{ padding: '1rem', borderBottom: '1px solid hsl(var(--border))', display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'sticky', top: 0, background: 'hsl(var(--card))', zIndex: 10 }}>
            <h3 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 700, color: 'hsl(var(--foreground))' }}>Inbox</h3>
            {unreadCount > 0 && (
              <span style={{ fontSize: '0.7rem', padding: '0.2rem 0.6rem', background: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6', borderRadius: '999px', fontWeight: 700 }}>
                {unreadCount} unread
              </span>
            )}
          </div>

          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {loading && notifications.length === 0 ? (
              <div style={{ padding: '2rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))', fontSize: '0.8rem' }}>Loading...</div>
            ) : notifications.length === 0 ? (
              <div style={{ padding: '2rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))', fontSize: '0.8rem' }}>No notifications yet</div>
            ) : (
              notifications.map((notif) => (
                <div key={notif.notificationId} style={{
                  padding: '1rem',
                  borderBottom: '1px solid hsl(var(--border))',
                  background: notif.isRead ? 'transparent' : 'rgba(59, 130, 246, 0.05)',
                  display: 'flex',
                  gap: '0.75rem',
                  alignItems: 'flex-start'
                }}>
                  <div style={{
                    width: 32, height: 32, borderRadius: '50%',
                    background: 'hsl(var(--secondary))',
                    border: '1px solid hsl(var(--border))',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0
                  }}>
                    {getIcon(notif.type)}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <strong style={{ fontSize: '0.85rem', fontWeight: notif.isRead ? 600 : 700, color: 'hsl(var(--foreground))' }}>{notif.title}</strong>
                      <span style={{ fontSize: '0.65rem', color: 'hsl(var(--muted-foreground))' }}>{formatDateTime(notif.createdAt).split(',')[0]}</span>
                    </div>
                    <p style={{ margin: '4px 0 0', fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))', lineHeight: 1.4 }}>
                      {notif.message}
                    </p>
                    <div style={{ display: 'flex', gap: '0.75rem', marginTop: '0.75rem' }}>
                      {!notif.isRead && (
                        <button onClick={() => void markAsRead(notif.notificationId)} style={{ background: 'none', border: 'none', color: 'hsl(var(--primary))', fontSize: '0.75rem', padding: 0, cursor: 'pointer', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
                          <Check size={12} /> Mark read
                        </button>
                      )}
                      <button onClick={() => void deleteNotification(notif.notificationId)} style={{ background: 'none', border: 'none', color: 'hsl(var(--destructive))', fontSize: '0.75rem', padding: 0, cursor: 'pointer', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
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
