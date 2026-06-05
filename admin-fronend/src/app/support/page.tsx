'use client';

import { useState, useEffect } from 'react';
import { Mail, Search, Clock, CheckCircle, AlertCircle, Loader, MessageCircle, Send, Check } from 'lucide-react';
import api from '@/lib/api';
import { unwrapApiData, unwrapPagedResponse } from '@/lib/api-response';
import { formatDateTime } from '@/lib/format';
import DashboardLayout from '@/components/DashboardLayout';

interface TicketSummary {
  ticketId: string;
  userId: string;
  role: string;
  userName: string;
  subject: string;
  status: string;
  priority: string;
  updatedAt: string;
}

interface TicketMessage {
  messageId: string;
  senderRole: string;
  message: string;
  createdAt: string;
}

interface TicketDetail extends TicketSummary {
  messages: TicketMessage[];
}

export default function AdminSupportPage() {
  const [tickets, setTickets] = useState<TicketSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTicket, setSelectedTicket] = useState<TicketDetail | null>(null);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [replyText, setReplyText] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  useEffect(() => {
    fetchTickets();
  }, [statusFilter]);

  async function fetchTickets() {
    try {
      setLoading(true);
      const params: any = { pageNumber: 1, pageSize: 50 };
      if (statusFilter) params.status = statusFilter;
      const res = await api.get('/admin/support', { params });
      setTickets(unwrapPagedResponse<TicketSummary>(res).data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }

  async function openTicket(id: string) {
    try {
      setLoadingDetail(true);
      const res = await api.get(`/admin/support/${id}`);
      setSelectedTicket(unwrapApiData<TicketDetail>(res));
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingDetail(false);
    }
  }

  async function handleReply(e: React.FormEvent) {
    e.preventDefault();
    if (!replyText.trim() || !selectedTicket) return;
    
    try {
      const res = await api.post(`/admin/support/${selectedTicket.ticketId}/reply`, { message: replyText });
      const newMsg = unwrapApiData<TicketMessage>(res);
      if (newMsg) {
        setSelectedTicket({
          ...selectedTicket,
          status: 'InProgress',
          messages: [...selectedTicket.messages, newMsg]
        });
        setTickets(tickets.map(t => t.ticketId === selectedTicket.ticketId ? { ...t, status: 'InProgress' } : t));
        setReplyText('');
      }
    } catch (e) {
      console.error(e);
    }
  }

  async function changeStatus(status: string) {
    if (!selectedTicket) return;
    try {
      await api.put(`/admin/support/${selectedTicket.ticketId}/status`, `"${status}"`, { headers: { 'Content-Type': 'application/json' } });
      setSelectedTicket({ ...selectedTicket, status });
      setTickets(tickets.map(t => t.ticketId === selectedTicket.ticketId ? { ...t, status } : t));
    } catch (e) {
      console.error(e);
    }
  }

  const getStatusBadge = (status: string) => {
    if (status === 'Open') return <span className="mini-pill pill-danger"><AlertCircle size={12}/> Open</span>;
    if (status === 'InProgress') return <span className="mini-pill pill-warning"><Clock size={12}/> In Progress</span>;
    return <span className="mini-pill pill-success"><CheckCircle size={12}/> Closed</span>;
  };

  return (
    <DashboardLayout>
      <div style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Support Tickets</h1>
          <p style={{ color: 'hsl(var(--muted-foreground))' }}>Manage and respond to user inquiries</p>
        </div>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} style={{ padding: '0.5rem 1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'transparent', color: 'hsl(var(--foreground))' }}>
            <option value="">All Statuses</option>
            <option value="Open">Open</option>
            <option value="InProgress">In Progress</option>
            <option value="Closed">Closed</option>
          </select>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '350px 1fr', gap: '1.5rem', height: 'calc(100vh - 200px)', minHeight: '600px' }}>
        {/* Left List */}
        <div className="glass-card" style={{ display: 'flex', flexDirection: 'column', padding: 0, overflow: 'hidden', height: '100%' }}>
          <div style={{ padding: '1.25rem', borderBottom: '1px solid hsl(var(--border))' }}>
            <h3 style={{ fontSize: '1.125rem', fontWeight: 700 }}>Inbox</h3>
          </div>
          <div style={{ flex: 1, overflowY: 'auto' }}>
            {loading ? (
              <div style={{ padding: '2rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}><Loader className="spin" size={24} /></div>
            ) : tickets.length === 0 ? (
              <div style={{ padding: '3rem 1rem', textAlign: 'center' }}>
                <CheckCircle size={32} style={{ opacity: 0.5, margin: '0 auto 1rem', color: '#10b981' }} />
                <p style={{ color: 'hsl(var(--muted-foreground))' }}>No support tickets found.</p>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column' }}>
                {tickets.map(t => (
                  <div 
                    key={t.ticketId} 
                    onClick={() => openTicket(t.ticketId)}
                    style={{ 
                      padding: '1rem 1.25rem', 
                      borderBottom: '1px solid hsl(var(--border))',
                      borderLeft: t.status === 'Open' ? '3px solid hsl(var(--destructive))' : '3px solid transparent',
                      cursor: 'pointer',
                      background: selectedTicket?.ticketId === t.ticketId 
                        ? 'hsl(var(--secondary))' 
                        : (t.status === 'Open' ? 'rgba(239, 68, 68, 0.05)' : 'transparent'),
                      transition: 'all 0.2s ease'
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                      <strong style={{ color: 'hsl(var(--foreground))', fontSize: '0.9rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        {t.subject}
                        {t.status === 'Open' && <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'hsl(var(--destructive))' }} title="Needs Attention" />}
                      </strong>
                      {getStatusBadge(t.status)}
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>
                      <span>{t.userName || 'Unknown'} ({t.role})</span>
                      <span>{formatDateTime(t.updatedAt).split(',')[0]}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Detail */}
        <div className="glass-card" style={{ display: 'flex', flexDirection: 'column', padding: 0, overflow: 'hidden', height: '100%' }}>
          {selectedTicket ? (
            <>
              <div style={{ padding: '1.5rem', borderBottom: '1px solid hsl(var(--border))' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem' }}>{selectedTicket.subject}</h3>
                    <div style={{ display: 'flex', gap: '1rem', fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))' }}>
                      <span>From: {selectedTicket.userName || 'Unknown'} ({selectedTicket.role})</span>
                      <span>Priority: {selectedTicket.priority}</span>
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                    {getStatusBadge(selectedTicket.status)}
                    {selectedTicket.status !== 'Closed' && (
                      <button onClick={() => changeStatus('Closed')} style={{ padding: '0.4rem 0.8rem', fontSize: '0.8rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'transparent', color: 'hsl(var(--foreground))', display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer' }}>
                        <Check size={14} /> Close Ticket
                      </button>
                    )}
                  </div>
                </div>
              </div>
              
              <div style={{ flex: 1, overflowY: 'auto', padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                {loadingDetail ? (
                  <div style={{ textAlign: 'center', color: 'hsl(var(--muted-foreground))', padding: '2rem' }}><Loader className="spin" size={24} /></div>
                ) : (
                  selectedTicket.messages.map(m => {
                    const isAdmin = m.senderRole === 'Admin';
                    return (
                      <div key={m.messageId} style={{
                        alignSelf: isAdmin ? 'flex-end' : 'flex-start',
                        maxWidth: '80%',
                        background: isAdmin ? '#6366f1' : 'hsl(var(--secondary))',
                        color: isAdmin ? '#fff' : 'hsl(var(--foreground))',
                        border: isAdmin ? 'none' : '1px solid hsl(var(--border))',
                        padding: '1rem',
                        borderRadius: 'var(--radius)',
                        borderBottomRightRadius: isAdmin ? 4 : 'var(--radius)',
                        borderBottomLeftRadius: !isAdmin ? 4 : 'var(--radius)',
                      }}>
                        <div style={{ fontSize: '0.75rem', opacity: 0.8, marginBottom: '0.4rem', display: 'flex', gap: '0.5rem' }}>
                          <strong>{isAdmin ? 'You (Admin)' : selectedTicket.userName || 'User'}</strong>
                          <span>{formatDateTime(m.createdAt)}</span>
                        </div>
                        <div style={{ lineHeight: 1.5, whiteSpace: 'pre-wrap', fontSize: '0.9rem' }}>
                          {m.message}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>

              {selectedTicket.status !== 'Closed' && (
                <form onSubmit={handleReply} style={{ padding: '1.25rem', borderTop: '1px solid hsl(var(--border))', display: 'flex', gap: '1rem', background: 'hsl(var(--secondary))' }}>
                  <input
                    value={replyText}
                    onChange={e => setReplyText(e.target.value)}
                    placeholder="Type your reply to the user..."
                    style={{ flex: 1, padding: '0.75rem 1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'transparent', color: 'hsl(var(--foreground))' }}
                  />
                  <button type="submit" disabled={!replyText.trim()} style={{ borderRadius: 'var(--radius)', padding: '0.75rem 1.5rem', background: '#6366f1', color: 'white', border: 'none', display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 600, cursor: replyText.trim() ? 'pointer' : 'not-allowed', opacity: replyText.trim() ? 1 : 0.5 }}>
                    <Send size={18} /> Send
                  </button>
                </form>
              )}
            </>
          ) : (
            <div style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', color: 'hsl(var(--muted-foreground))' }}>
              <MessageCircle size={48} style={{ opacity: 0.2, marginBottom: '1rem' }} />
              <p>Select a ticket from the left to view the conversation.</p>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
