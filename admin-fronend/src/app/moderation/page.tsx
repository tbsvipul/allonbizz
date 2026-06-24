'use client';

import React, { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { 
  AlertTriangle, 
  Check, 
  X, 
  MessageSquare, 
  Flag, 
  EyeOff, 
  ArrowUpCircle,
  Clock,
  User,
  ShieldAlert
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { unwrapPagedResponse } from '@/lib/api-response';
import { PERMISSIONS } from '@/lib/permissions';

interface ModerationItem {
  id: string;
  type: 'Offer' | 'Review' | 'Comment';
  content: string;
  reportedBy: string;
  reason: string;
  createdAt: string;
  status: 'Pending' | 'Flagged';
}

interface UserReportItem {
  reportId: string;
  reportedItemId: string;
  itemType: string;
  reportedBy: string;
  reason: string;
  comments: string;
  createdAt: string;
  status: string;
}

export default function ModerationPage() {
  const { hasPermission } = useAuth();
  const [items, setItems] = useState<ModerationItem[]>([]);
  const [reports, setReports] = useState<UserReportItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'queue' | 'reports'>('queue');

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'queue') {
        const response = await api.get('/moderation/queue');
        setItems(unwrapPagedResponse<ModerationItem>(response).data);
      } else {
        const response = await api.get('/moderation/reports');
        setReports(unwrapPagedResponse<UserReportItem>(response).data);
      }
    } catch (err) {
      console.error('Failed to fetch data', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const handleAction = async (id: string, action: 'approve' | 'reject' | 'hide' | 'escalate') => {
    try {
      let payload: any = {};
      
      if (action === 'reject' || action === 'escalate') {
        const reason = prompt(`Please provide a reason for ${action}:`);
        if (!reason) return; // Cancel if no reason provided for strict actions
        payload = { reason };
      }

      await api.post(`/moderation/${id}/${action}`, payload);
      setItems(prev => prev.filter(item => item.id !== id));
    } catch (err) {
      console.error(`Failed to ${action} item`, err);
      alert(`Error: Failed to ${action} item.`);
    }
  };

  const handleReportAction = async (reportId: string, type: 'dismiss' | 'action') => {
    try {
      let payload: any = {};
      if (type === 'dismiss') {
        const reason = prompt('Reason for dismissal (optional):');
        payload = { reason: reason || '' };
      } else {
        const action = prompt('What action was taken?');
        if (!action) return;
        payload = { action, notes: '' };
      }

      await api.post(`/moderation/reports/${reportId}/${type}`, payload);
      setReports(prev => prev.filter(report => report.reportId !== reportId));
    } catch (err) {
      console.error(`Failed to ${type} report`, err);
      alert(`Error: Failed to process report.`);
    }
  };

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ marginBottom: '2rem' }}>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Content Moderation</h1>
          <p style={{ color: 'hsl(var(--muted-foreground))' }}>Review and take action on reported content across the platform.</p>
        </div>

        <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem' }}>
          <button
            onClick={() => setActiveTab('queue')}
            style={{
              padding: '0.75rem 1.5rem',
              borderRadius: 'var(--radius)',
              fontWeight: 600,
              background: activeTab === 'queue' ? 'hsl(var(--primary))' : 'transparent',
              color: activeTab === 'queue' ? 'hsl(var(--primary-foreground))' : 'hsl(var(--muted-foreground))',
              border: 'none',
              cursor: 'pointer'
            }}
          >
            Content Queue
          </button>
          <button
            onClick={() => setActiveTab('reports')}
            style={{
              padding: '0.75rem 1.5rem',
              borderRadius: 'var(--radius)',
              fontWeight: 600,
              background: activeTab === 'reports' ? 'hsl(var(--primary))' : 'transparent',
              color: activeTab === 'reports' ? 'hsl(var(--primary-foreground))' : 'hsl(var(--muted-foreground))',
              border: 'none',
              cursor: 'pointer'
            }}
          >
            User Reports
          </button>
        </div>

        {activeTab === 'queue' && (
          <div style={{ display: 'grid', gap: '1.5rem' }}>
            {items.map((item, i) => (
              <motion.div 
                key={item.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
                className="glass-card" 
                style={{ padding: '1.5rem', display: 'flex', gap: '2rem', alignItems: 'flex-start' }}
              >
                <div style={{ 
                  width: '60px', 
                  height: '60px', 
                  borderRadius: '16px', 
                  background: item.type === 'Offer' ? 'rgba(99, 102, 241, 0.1)' : 'rgba(236, 72, 153, 0.1)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: item.type === 'Offer' ? '#6366f1' : '#ec4899'
                }}>
                  {item.type === 'Offer' ? <Flag size={28} /> : <MessageSquare size={28} />}
                </div>

                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                    <div>
                      <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>{item.type} Report</h3>
                      <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem', fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))' }}>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                          <User size={14} /> Reported by: {item.reportedBy}
                        </span>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                          <Clock size={14} /> {new Date(item.createdAt).toLocaleString()}
                        </span>
                      </div>
                    </div>
                    <div style={{ 
                      padding: '0.25rem 0.75rem', 
                      borderRadius: '20px', 
                      background: item.status === 'Flagged' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(245, 158, 11, 0.1)', 
                      color: item.status === 'Flagged' ? '#ef4444' : '#f59e0b',
                      fontSize: '0.75rem',
                      fontWeight: 600
                    }}>
                      {item.status} ({item.reason})
                    </div>
                  </div>

                  <div style={{ background: 'hsl(var(--secondary))', padding: '1.25rem', borderRadius: 'var(--radius)', borderLeft: '4px solid hsl(var(--primary))', marginBottom: '1.5rem' }}>
                     <p style={{ fontStyle: 'italic', fontSize: '0.9375rem', color: 'hsl(var(--foreground))' }}>"{item.content}"</p>
                  </div>

                  <div style={{ display: 'flex', gap: '0.75rem' }}>
                    {hasPermission(PERMISSIONS.moderationApprove) && (
                      <button 
                        onClick={() => handleAction(item.id, 'approve')}
                        style={{ 
                          display: 'flex', 
                          alignItems: 'center', 
                          gap: '0.5rem', 
                          padding: '0.6rem 1.25rem', 
                          background: 'rgba(16, 185, 129, 0.1)', 
                          color: '#10b981', 
                          border: 'none',
                          fontWeight: 600
                        }}
                      >
                        <Check size={18} /> Approve
                      </button>
                    )}
                    {hasPermission(PERMISSIONS.moderationReject) && (
                      <button 
                        onClick={() => handleAction(item.id, 'reject')}
                        style={{ 
                          display: 'flex', 
                          alignItems: 'center', 
                          gap: '0.5rem', 
                          padding: '0.6rem 1.25rem', 
                          background: 'rgba(239, 68, 68, 0.1)', 
                          color: '#ef4444', 
                          border: 'none',
                          fontWeight: 600
                        }}
                      >
                        <X size={18} /> Reject
                      </button>
                    )}
                    {hasPermission(PERMISSIONS.moderationEdit) && (
                      <button 
                        onClick={() => handleAction(item.id, 'hide')}
                        style={{ 
                          display: 'flex', 
                          alignItems: 'center', 
                          gap: '0.5rem', 
                          padding: '0.6rem 1.25rem', 
                          background: 'hsl(var(--secondary))', 
                          color: 'hsl(var(--foreground))', 
                          border: '1px solid hsl(var(--border))',
                          fontWeight: 600
                        }}
                      >
                        <EyeOff size={18} /> Hide
                      </button>
                    )}
                    {hasPermission(PERMISSIONS.moderationEscalate) && (
                      <button 
                        onClick={() => handleAction(item.id, 'escalate')}
                        style={{ 
                          display: 'flex', 
                          alignItems: 'center', 
                          gap: '0.5rem', 
                          padding: '0.6rem 1.25rem', 
                          background: 'hsl(var(--secondary))', 
                          color: 'hsl(var(--primary))', 
                          border: '1px solid hsl(var(--border))',
                          fontWeight: 600
                        }}
                      >
                        <ArrowUpCircle size={18} /> Escalate
                      </button>
                    )}
                  </div>
                </div>
              </motion.div>
            ))}
            {items.length === 0 && !loading && (
               <div className="flex-center glass-card" style={{ padding: '4rem', flexDirection: 'column', gap: '1rem' }}>
                  <AlertTriangle size={48} style={{ color: '#10b981' }} />
                  <p style={{ color: 'hsl(var(--muted-foreground))' }}>Moderation queue is empty. Good job!</p>
               </div>
            )}
          </div>
        )}

        {activeTab === 'reports' && (
          <div style={{ display: 'grid', gap: '1.5rem' }}>
            {reports.map((report, i) => (
              <motion.div 
                key={report.reportId}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
                className="glass-card" 
                style={{ padding: '1.5rem', display: 'flex', gap: '2rem', alignItems: 'flex-start' }}
              >
                <div style={{ 
                  width: '60px', 
                  height: '60px', 
                  borderRadius: '16px', 
                  background: 'rgba(245, 158, 11, 0.1)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#f59e0b'
                }}>
                  <ShieldAlert size={28} />
                </div>

                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                    <div>
                      <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>User Report: {report.itemType.toUpperCase()}</h3>
                      <div style={{ display: 'flex', gap: '1rem', marginTop: '0.25rem', fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))' }}>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                          <User size={14} /> Reported by: {report.reportedBy}
                        </span>
                        <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                          <Clock size={14} /> {new Date(report.createdAt).toLocaleString()}
                        </span>
                      </div>
                    </div>
                    <div style={{ 
                      padding: '0.25rem 0.75rem', 
                      borderRadius: '20px', 
                      background: report.status === 'pending' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)', 
                      color: report.status === 'pending' ? '#ef4444' : '#10b981',
                      fontSize: '0.75rem',
                      fontWeight: 600
                    }}>
                      {report.status.toUpperCase()}
                    </div>
                  </div>

                  <div style={{ background: 'hsl(var(--secondary))', padding: '1.25rem', borderRadius: 'var(--radius)', borderLeft: '4px solid hsl(var(--primary))', marginBottom: '1.5rem' }}>
                     <p style={{ fontWeight: 'bold', marginBottom: '0.5rem', color: 'hsl(var(--foreground))' }}>Reason: {report.reason}</p>
                     {report.comments && (
                       <p style={{ fontStyle: 'italic', fontSize: '0.9375rem', color: 'hsl(var(--muted-foreground))' }}>Comments: "{report.comments}"</p>
                     )}
                     <div style={{ marginTop: '0.75rem', fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))' }}>
                       Target Item ID: {report.reportedItemId}
                     </div>
                  </div>

                  {report.status === 'pending' && (
                    <div style={{ display: 'flex', gap: '0.75rem' }}>
                      {hasPermission(PERMISSIONS.moderationApprove) && (
                        <>
                          <button 
                            onClick={() => handleReportAction(report.reportId, 'action')}
                            style={{ 
                              display: 'flex', 
                              alignItems: 'center', 
                              gap: '0.5rem', 
                              padding: '0.6rem 1.25rem', 
                              background: 'rgba(16, 185, 129, 0.1)', 
                              color: '#10b981', 
                              border: 'none',
                              fontWeight: 600
                            }}
                          >
                            <Check size={18} /> Resolve & Take Action
                          </button>
                          <button 
                            onClick={() => handleReportAction(report.reportId, 'dismiss')}
                            style={{ 
                              display: 'flex', 
                              alignItems: 'center', 
                              gap: '0.5rem', 
                              padding: '0.6rem 1.25rem', 
                              background: 'hsl(var(--secondary))', 
                              color: 'hsl(var(--foreground))', 
                              border: '1px solid hsl(var(--border))',
                              fontWeight: 600
                            }}
                          >
                            <X size={18} /> Dismiss Report
                          </button>
                        </>
                      )}
                    </div>
                  )}
                </div>
              </motion.div>
            ))}
            {reports.length === 0 && !loading && (
               <div className="flex-center glass-card" style={{ padding: '4rem', flexDirection: 'column', gap: '1rem' }}>
                  <ShieldAlert size={48} style={{ color: '#10b981' }} />
                  <p style={{ color: 'hsl(var(--muted-foreground))' }}>No user reports found. All clear!</p>
               </div>
            )}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
