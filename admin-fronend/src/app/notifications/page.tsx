'use client';

import React, { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { 
  Bell, Send, History, Users, UserCheck, Smartphone, 
  CheckCircle2, AlertCircle, RefreshCw, Clock, 
  Trash2, X, Eye, FileText, Check, Save
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';

interface NotificationSummary {
  notificationId: string;
  title: string;
  message: string;
  type: string;
  priority: string;
  targetAudience: string;
  status: string;
  scheduledAt: string | null;
  sentAt: string | null;
  createdAt: string;
  recipientCount: number;
}

export default function NotificationsPage() {
  const { hasPermission } = useAuth();
  const canSendNotifications = hasPermission(PERMISSIONS.notificationsSend);
  const [notifications, setNotifications] = useState<NotificationSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'all' | 'Draft' | 'Scheduled' | 'Queued' | 'Sent' | 'Failed'>('all');
  
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    message: '',
    type: 'SystemMessage',
    priority: 'Normal',
    targetAudience: 'all',
    sendImmediately: true,
    scheduledAt: ''
  });

  const [statusMsg, setStatusMsg] = useState<{ type: 'success' | 'error', text: string } | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const listRes = await api.get(`/admin/notifications?status=${activeTab === 'all' ? '' : activeTab}&pageNumber=1&pageSize=50`);
      setNotifications(unwrapPagedResponse<NotificationSummary>(listRes).data);
    } catch (err) {
      console.error('Failed to fetch data', err);
      setError(getApiErrorMessage(err, 'Failed to fetch notifications.'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setStatusMsg(null);

    try {
      const payload = {
        ...formData,
        scheduledAt: formData.sendImmediately || !formData.scheduledAt ? null : new Date(formData.scheduledAt).toISOString()
      };

      await api.post('/admin/notifications', payload);
      setStatusMsg({ type: 'success', text: formData.sendImmediately ? 'Broadcast dispatched successfully!' : 'Broadcast explicitly scheduled/saved!' });
      setTimeout(() => {
        setFormData({ title: '', message: '', type: 'SystemMessage', priority: 'Normal', targetAudience: 'all', sendImmediately: true, scheduledAt: '' });
        setStatusMsg(null);
        fetchData();
      }, 2000);
    } catch (err) {
      setStatusMsg({ type: 'error', text: getApiErrorMessage(err, 'Failed to process notification payload.') });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Permanently delete this item?')) return;
    try {
      await api.delete(`/admin/notifications/${id}`);
      fetchData();
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to delete notification.'));
    }
  };

  const handleSendDraft = async (id: string) => {
    if (!confirm('Force dispatch this draft globally?')) return;
    try {
      await api.post(`/admin/notifications/${id}/send`);
      fetchData();
    } catch (err) {
      setError(getApiErrorMessage(err, 'Failed to queue notification.'));
    }
  };

  const getTargetIcon = (role: string) => {
    switch (role?.toLowerCase()) {
      case 'keepers': return <UserCheck size={14} />;
      case 'customers': return <Smartphone size={14} />;
      default: return <Users size={14} />;
    }
  };

  const getStatusBadge = (status: string) => {
    switch(status.toLowerCase()) {
      case 'sent': return <span style={{ background: 'hsla(152, 69%, 31%, 0.1)', color: 'hsl(152, 69%, 31%)', padding: '0.2rem 0.6rem', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 700 }}><Check size={10} style={{ display: 'inline', marginRight: '4px' }}/>SENT</span>;
      case 'scheduled': return <span style={{ background: 'hsla(38, 92%, 50%, 0.1)', color: 'hsl(38, 92%, 50%)', padding: '0.2rem 0.6rem', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 700 }}><Clock size={10} style={{ display: 'inline', marginRight: '4px' }}/>SCHEDULED</span>;
      case 'queued': return <span style={{ background: 'hsla(221, 83%, 53%, 0.1)', color: '#2563eb', padding: '0.2rem 0.6rem', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 700 }}><Send size={10} style={{ display: 'inline', marginRight: '4px' }}/>QUEUED</span>;
      case 'failed': return <span style={{ background: 'hsla(0, 84%, 60%, 0.1)', color: '#ef4444', padding: '0.2rem 0.6rem', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 700 }}><AlertCircle size={10} style={{ display: 'inline', marginRight: '4px' }}/>FAILED</span>;
      default: return <span style={{ background: 'hsla(220, 9%, 46%, 0.1)', color: 'hsl(var(--muted-foreground))', padding: '0.2rem 0.6rem', borderRadius: '4px', fontSize: '0.7rem', fontWeight: 700 }}><FileText size={10} style={{ display: 'inline', marginRight: '4px' }}/>DRAFT</span>;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch(priority.toLowerCase()) {
      case 'critical': return 'hsl(0, 84%, 60%)';
      case 'high': return 'hsl(25, 95%, 53%)';
      case 'low': return 'hsl(220, 9%, 46%)';
      default: return 'hsl(var(--primary))';
    }
  };

  return (
    <DashboardLayout>
      <div className="animate-fade-in" style={{ paddingBottom: '3rem' }}>
        
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <div>
            <h1 style={{ fontSize: '1.85rem', fontWeight: 700, marginBottom: '0.25rem' }}>Broadcast Control</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))', fontSize: '0.95rem' }}>Compose and track system-wide push notifications effortlessly.</p>
          </div>
          <button 
            onClick={fetchData}
            style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1.25rem', borderRadius: '8px', border: '1px solid hsl(var(--border))', background: 'hsl(var(--card))', fontWeight: 600, color: 'hsl(var(--foreground))', cursor: 'pointer', transition: '0.2s' }}
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            Refresh Feed
          </button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: canSendNotifications ? 'minmax(350px, 1fr) 1.5fr' : '1fr', gap: '2rem', alignItems: 'start' }}>
          
          {/* Form Composer (Left Side) */}
          {canSendNotifications && (
          <div className="glass-card" style={{ padding: '2rem', borderTop: '4px solid hsl(var(--primary))' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <div style={{ background: 'hsla(var(--primary), 0.15)', color: 'hsl(var(--primary))', padding: '0.6rem', borderRadius: '10px' }}>
                <Send size={20} />
              </div>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0 }}>Compose Broadcast</h2>
            </div>
            
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              
              <div style={{ display: 'flex', gap: '1rem' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--foreground))' }}>Audience Segment</label>
                  <select 
                    value={formData.targetAudience} onChange={e => setFormData({...formData, targetAudience: e.target.value})}
                    style={{ width: '100%', padding: '0.8rem', borderRadius: '8px', background: 'hsl(var(--background))', border: '1px solid hsl(var(--border))', color: 'hsl(var(--foreground))', outline: 'none', transition: '0.2s' }}
                  >
                    <option value="all">Everyone</option>
                    <option value="customers">Customers</option>
                    <option value="keepers">Keepers</option>
                  </select>
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--foreground))' }}>Priority Layer</label>
                  <select 
                    value={formData.priority} onChange={e => setFormData({...formData, priority: e.target.value})}
                    style={{ width: '100%', padding: '0.8rem', borderRadius: '8px', background: 'hsl(var(--background))', border: '1px solid hsl(var(--border))', color: 'hsl(var(--foreground))', outline: 'none', transition: '0.2s' }}
                  >
                    <option value="Low">Low</option>
                    <option value="Normal">Normal</option>
                    <option value="High">High</option>
                    <option value="Critical">Critical</option>
                  </select>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--foreground))' }}>Header Title</label>
                <input 
                  required 
                  placeholder="e.g. Mega Weekend Sale Incoming!"
                  value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})}
                  style={{ width: '100%', padding: '0.8rem', borderRadius: '8px', background: 'hsl(var(--background))', border: '1px solid hsl(var(--border))', color: 'hsl(var(--foreground))', outline: 'none', transition: '0.2s' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--foreground))' }}>Primary Message Body</label>
                <textarea 
                  required 
                  rows={4}
                  placeholder="Main transmission text goes here..."
                  value={formData.message} onChange={e => setFormData({...formData, message: e.target.value})}
                  style={{ width: '100%', padding: '0.8rem', borderRadius: '8px', background: 'hsl(var(--background))', border: '1px solid hsl(var(--border))', color: 'hsl(var(--foreground))', outline: 'none', resize: 'none', transition: '0.2s' }}
                />
              </div>

              <div style={{ padding: '1.25rem', borderRadius: '10px', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div>
                    <h4 style={{ fontSize: '0.9rem', fontWeight: 600, color: 'hsl(var(--foreground))' }}>Execution Timing</h4>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Trigger immediately or batch for later</p>
                  </div>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', color: 'hsl(var(--foreground))' }}>
                    <input 
                      type="checkbox" 
                      checked={formData.sendImmediately} 
                      onChange={e => setFormData({...formData, sendImmediately: e.target.checked})} 
                      style={{ accentColor: 'hsl(var(--primary))', width: '1.25rem', height: '1.25rem', cursor: 'pointer' }}
                    /> 
                    <span style={{ fontSize: '0.9rem', fontWeight: 600 }}>Execute Now</span>
                  </label>
                </div>

                <AnimatePresence>
                  {!formData.sendImmediately && (
                    <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: 'auto', opacity: 1 }} exit={{ height: 0, opacity: 0 }} style={{ overflow: 'hidden' }}>
                      <div style={{ marginTop: '1.25rem', paddingTop: '1.25rem', borderTop: '1px solid hsl(var(--border))' }}>
                        <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--foreground))' }}>Target Schedule (UTC)</label>
                        <input 
                          type="datetime-local" 
                          required={!formData.sendImmediately}
                          value={formData.scheduledAt} onChange={e => setFormData({...formData, scheduledAt: e.target.value})}
                          style={{ padding: '0.8rem', borderRadius: '8px', background: 'hsl(var(--background))', border: '1px solid hsl(var(--border))', color: 'hsl(var(--foreground))', outline: 'none', width: '100%', transition: '0.2s' }}
                        />
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>

              <AnimatePresence>
                {statusMsg && (
                  <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }} style={{ padding: '0.8rem', borderRadius: '8px', background: statusMsg.type === 'success' ? 'hsla(152, 69%, 31%, 0.15)' : 'hsla(0, 84%, 60%, 0.15)', color: statusMsg.type === 'success' ? 'hsl(152, 69%, 31%)' : 'hsl(0, 84%, 60%)', display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem', fontWeight: 600 }}>
                    {statusMsg.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
                    {statusMsg.text}
                  </motion.div>
                )}
              </AnimatePresence>

              <button type="submit" disabled={saving} className="premium-gradient" style={{ width: '100%', padding: '1rem', borderRadius: '8px', border: 'none', color: 'white', fontWeight: 700, fontSize: '0.95rem', cursor: saving ? 'wait' : 'pointer', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '0.5rem', boxShadow: '0 8px 16px hsla(var(--primary), 0.3)', transition: 'transform 0.2s' }}>
                {saving ? 'Processing Matrix...' : formData.sendImmediately ? <><Send size={18} /> Dispatch Broadcast Orbit</> : <><Save size={18} /> Lock & Schedule Entry</>}
              </button>
            </form>
          </div>
          )}

          {/* Feed List (Right Side) */}
          <div className="glass-card" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column' }}>
            {error && (
              <div style={{ marginBottom: '1rem', padding: '0.875rem 1rem', borderRadius: 'var(--radius)', background: 'rgba(239, 68, 68, 0.12)', color: '#ef4444', fontSize: '0.875rem', fontWeight: 600 }}>
                {error}
              </div>
            )}
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1.5rem', borderBottom: '1px solid hsl(var(--border))', paddingBottom: '1rem' }}>
              <History size={18} color="hsl(var(--muted-foreground))" />
              <h3 style={{ fontWeight: 700, fontSize: '1.1rem' }}>Transmission Log Feed</h3>
            </div>

            <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1.5rem', flexWrap: 'wrap' }}>
              {['all', 'Sent', 'Scheduled', 'Queued', 'Draft', 'Failed'].map(tab => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab as any)}
                  style={{
                    background: activeTab === tab ? 'hsl(var(--foreground))' : 'hsl(var(--secondary))',
                    color: activeTab === tab ? 'hsl(var(--background))' : 'hsl(var(--muted-foreground))',
                    border: '1px solid',
                    borderColor: activeTab === tab ? 'hsl(var(--foreground))' : 'hsl(var(--border))',
                    padding: '0.4rem 1rem',
                    borderRadius: '20px',
                    fontWeight: 600,
                    fontSize: '0.8rem',
                    cursor: 'pointer',
                    transition: 'all 0.2s ease',
                    textTransform: 'capitalize'
                  }}
                >
                  {tab === 'all' ? 'All Filters' : tab}
                </button>
              ))}
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', maxHeight: '700px', overflowY: 'auto', paddingRight: '0.5rem' }}>
              {!loading && notifications.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '4rem 1rem', color: 'hsl(var(--muted-foreground))', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem' }}>
                  <Bell size={48} style={{ opacity: 0.15 }} />
                  <p style={{ fontWeight: 500 }}>No signals detected matching query.</p>
                </div>
              ) : notifications.map(item => (
                <motion.div 
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  key={item.notificationId} 
                  style={{ 
                    display: 'flex', alignItems: 'stretch', gap: '1.5rem', padding: '1.25rem',
                    borderRadius: '12px', background: 'hsl(var(--card))', border: '1px solid hsl(var(--border))',
                    boxShadow: '0 4px 12px hsla(0,0%,0%,0.02)'
                  }}
                >
                  {/* Decorative priority line */}
                  <div style={{ width: '4px', borderRadius: '4px', background: getPriorityColor(item.priority), flexShrink: 0 }} />

                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem', marginBottom: '0.5rem' }}>
                      {getStatusBadge(item.status)}
                      <span style={{ 
                        fontSize: '0.65rem', padding: '0.2rem 0.5rem', borderRadius: '4px', 
                        background: 'hsl(var(--secondary))', color: 'hsl(var(--foreground))', 
                        textTransform: 'uppercase', fontWeight: 700,
                        display: 'flex', alignItems: 'center', gap: '0.25rem', border: '1px solid hsl(var(--border))'
                      }}>
                        {getTargetIcon(item.targetAudience)} {item.targetAudience}
                      </span>
                      <span style={{ fontSize: '0.7rem', color: 'hsl(var(--muted-foreground))', display: 'flex', alignItems: 'center', gap: '0.25rem', fontWeight: 500 }}>
                        <Clock size={12} /> {new Date(item.createdAt).toLocaleString()}
                      </span>
                    </div>
                    <h4 style={{ fontWeight: 700, fontSize: '1rem', marginBottom: '0.35rem', color: 'hsl(var(--foreground))' }}>{item.title}</h4>
                    <p style={{ fontSize: '0.85rem', color: 'hsl(var(--muted-foreground))', lineHeight: '1.5', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                      {item.message}
                    </p>
                  </div>
                  
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', justifyContent: 'center' }}>
                    {item.status === 'Draft' && canSendNotifications && (
                      <button onClick={() => handleSendDraft(item.notificationId)} title="Force Launch Draft" style={{ width: '32px', height: '32px', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '8px', background: 'hsla(152, 69%, 31%, 0.1)', color: 'hsl(152, 69%, 31%)', border: 'none', cursor: 'pointer', transition: '0.2s' }}><Send size={14} /></button>
                    )}
                    {(item.status === 'Draft' || item.status === 'Scheduled') && canSendNotifications && (
                      <button onClick={() => handleDelete(item.notificationId)} title="Delete Matrix Entry" style={{ width: '32px', height: '32px', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '8px', background: 'hsla(0, 84%, 60%, 0.1)', color: 'hsl(0, 84%, 60%)', border: 'none', cursor: 'pointer', transition: '0.2s' }}><Trash2 size={14} /></button>
                    )}
                    <button title="Examine Data Logs" style={{ width: '32px', height: '32px', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '8px', background: 'hsl(var(--secondary))', color: 'hsl(var(--foreground))', border: '1px solid hsl(var(--border))', cursor: 'pointer', transition: '0.2s' }}><Eye size={14} /></button>
                  </div>
                </motion.div>
              ))}
            </div>
          </div>
        </div>

      </div>
    </DashboardLayout>
  );
}
