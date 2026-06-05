'use client';

import { useState, useEffect } from 'react';
import { Mail, Search, Clock, CheckCircle, AlertCircle, Loader, MessageCircle, Send, Plus } from 'lucide-react';
import api from '@/lib/api';
import { unwrapApiData, unwrapPagedResponse } from '@/lib/api-response';
import { formatDateTime } from '@/lib/format';

interface TicketSummary {
  ticketId: string;
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

export default function KeeperSupportPage() {
  const [tickets, setTickets] = useState<TicketSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTicket, setSelectedTicket] = useState<TicketDetail | null>(null);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [replyText, setReplyText] = useState('');
  
  // New ticket form
  const [showNew, setShowNew] = useState(false);
  const [newSubject, setNewSubject] = useState('');
  const [newMessage, setNewMessage] = useState('');
  const [newPriority, setNewPriority] = useState('Normal');

  useEffect(() => {
    fetchTickets();
  }, []);

  async function fetchTickets() {
    try {
      setLoading(true);
      const res = await api.get('/keeper/support', { params: { pageNumber: 1, pageSize: 50 } });
      setTickets(unwrapPagedResponse<TicketSummary>(res).data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }

  async function openTicket(id: string) {
    try {
      setShowNew(false);
      setLoadingDetail(true);
      const res = await api.get(`/keeper/support/${id}`);
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
      const res = await api.post(`/keeper/support/${selectedTicket.ticketId}/reply`, { message: replyText });
      const newMsg = unwrapApiData<TicketMessage>(res);
      if (newMsg) {
        setSelectedTicket({
          ...selectedTicket,
          messages: [...selectedTicket.messages, newMsg]
        });
        setReplyText('');
      }
    } catch (e) {
      console.error(e);
    }
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!newSubject.trim() || !newMessage.trim()) return;

    try {
      const res = await api.post('/keeper/support', {
        subject: newSubject,
        message: newMessage,
        priority: newPriority
      });
      const ticket = unwrapApiData<TicketDetail>(res);
      if (ticket) {
        setTickets([ticket, ...tickets]);
        setSelectedTicket(ticket);
        setShowNew(false);
        setNewSubject('');
        setNewMessage('');
      }
    } catch (e) {
      console.error(e);
    }
  }

  const getStatusBadge = (status: string) => {
    if (status === 'Open') return <span className="mini-pill pill-info"><AlertCircle size={12}/> Open</span>;
    if (status === 'InProgress') return <span className="mini-pill pill-warning"><Clock size={12}/> In Progress</span>;
    return <span className="mini-pill pill-success"><CheckCircle size={12}/> Closed</span>;
  };

  return (
    <div className="shell-main">
      <div className="shell-header">
        <div>
          <h1 style={{ color: 'var(--text)' }}>Support Center</h1>
          <p style={{ color: 'var(--text-muted)' }}>Contact NaviDeals administrators for help</p>
        </div>
        <button className="button" onClick={() => { setShowNew(true); setSelectedTicket(null); }}>
          <Plus size={16} /> New Ticket
        </button>
      </div>

      <div className="split-grid" style={{ height: 'calc(100vh - 200px)', minHeight: '600px' }}>
        {/* Left List */}
        <div className="panel-card" style={{ display: 'flex', flexDirection: 'column', padding: 0, overflow: 'hidden', height: '100%' }}>
          <div style={{ padding: '1rem', borderBottom: '1px solid var(--border)' }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 600 }}>Your Tickets</h3>
          </div>
          <div style={{ flex: 1, overflowY: 'auto' }}>
            {loading ? (
              <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--text-muted)' }}><Loader className="spin" size={24} /></div>
            ) : tickets.length === 0 ? (
              <div className="empty-state" style={{ margin: '1rem' }}>
                <Mail size={32} style={{ opacity: 0.5, margin: '0 auto' }} />
                <p>No support tickets yet.</p>
              </div>
            ) : (
              <div className="list-grid" style={{ gridTemplateColumns: '1fr', gap: 0 }}>
                {tickets.map(t => (
                  <div 
                    key={t.ticketId} 
                    onClick={() => openTicket(t.ticketId)}
                    style={{ 
                      padding: '1rem', 
                      borderBottom: '1px solid var(--border)',
                      cursor: 'pointer',
                      background: selectedTicket?.ticketId === t.ticketId ? 'var(--accent-soft)' : 'transparent',
                      transition: 'background 0.2s ease'
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                      <strong style={{ color: 'var(--text)' }}>{t.subject}</strong>
                      {getStatusBadge(t.status)}
                    </div>
                    <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      Updated: {formatDateTime(t.updatedAt)}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Detail */}
        <div className="panel-card" style={{ display: 'flex', flexDirection: 'column', padding: 0, overflow: 'hidden', height: '100%' }}>
          {showNew ? (
            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <h3 style={{ fontSize: '1.2rem' }}>Create New Ticket</h3>
              <form onSubmit={handleCreate} className="form-stack">
                <div className="field">
                  <label>Subject</label>
                  <input required value={newSubject} onChange={e => setNewSubject(e.target.value)} placeholder="Brief summary of your issue" />
                </div>
                <div className="field">
                  <label>Priority</label>
                  <select value={newPriority} onChange={e => setNewPriority(e.target.value)}>
                    <option value="Low">Low</option>
                    <option value="Normal">Normal</option>
                    <option value="High">High</option>
                  </select>
                </div>
                <div className="field">
                  <label>Message</label>
                  <textarea required value={newMessage} onChange={e => setNewMessage(e.target.value)} placeholder="Describe your problem in detail..." />
                </div>
                <div className="button-row">
                  <button type="submit" className="button">Submit Ticket</button>
                  <button type="button" className="button-ghost" onClick={() => setShowNew(false)}>Cancel</button>
                </div>
              </form>
            </div>
          ) : selectedTicket ? (
            <>
              <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h3 style={{ fontSize: '1.3rem', marginBottom: '0.5rem' }}>{selectedTicket.subject}</h3>
                    <div style={{ display: 'flex', gap: '1rem', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                      <span>Ticket ID: {selectedTicket.ticketId.split('-')[0]}</span>
                      <span>Priority: {selectedTicket.priority}</span>
                    </div>
                  </div>
                  {getStatusBadge(selectedTicket.status)}
                </div>
              </div>
              
              <div style={{ flex: 1, overflowY: 'auto', padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                {loadingDetail ? (
                  <div style={{ textAlign: 'center', color: 'var(--text-muted)' }}><Loader className="spin" size={24} /></div>
                ) : (
                  selectedTicket.messages.map(m => {
                    const isUser = m.senderRole === 'User';
                    return (
                      <div key={m.messageId} style={{
                        alignSelf: isUser ? 'flex-end' : 'flex-start',
                        maxWidth: '80%',
                        background: isUser ? 'var(--accent)' : 'var(--surface-muted)',
                        color: isUser ? '#fff' : 'var(--text)',
                        border: isUser ? 'none' : '1px solid var(--border)',
                        padding: '1rem',
                        borderRadius: 'var(--radius-lg)',
                        borderBottomRightRadius: isUser ? 4 : 'var(--radius-lg)',
                        borderBottomLeftRadius: !isUser ? 4 : 'var(--radius-lg)',
                      }}>
                        <div style={{ fontSize: '0.75rem', opacity: 0.8, marginBottom: '0.4rem', display: 'flex', gap: '0.5rem' }}>
                          <strong>{isUser ? 'You' : 'NaviDeals Support'}</strong>
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
                <form onSubmit={handleReply} style={{ padding: '1.25rem', borderTop: '1px solid var(--border)', display: 'flex', gap: '1rem', background: 'var(--surface-muted)' }}>
                  <input
                    value={replyText}
                    onChange={e => setReplyText(e.target.value)}
                    placeholder="Type your reply..."
                    style={{ flex: 1, padding: '0.75rem 1rem', borderRadius: 'var(--radius-lg)', border: '1px solid var(--border)' }}
                  />
                  <button type="submit" className="button" disabled={!replyText.trim()} style={{ borderRadius: 'var(--radius-lg)' }}>
                    <Send size={18} /> Send
                  </button>
                </form>
              )}
            </>
          ) : (
            <div className="empty-state" style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
              <MessageCircle size={48} style={{ opacity: 0.2, margin: '0 auto' }} />
              <p>Select a ticket to view conversation or create a new one.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
