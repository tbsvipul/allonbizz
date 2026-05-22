'use client';

/* eslint-disable @next/next/no-img-element */

import React, { useCallback, useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { Star, XCircle, CheckCircle2, User, Store } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';

interface Review {
  reviewId: string;
  userName: string;
  userAvatarUrl?: string | null;
  shopName: string;
  rating: number;
  comment: string;
  status: string;
  createdAt: string;
  reply?: string | null;
}

type Notice = {
  tone: 'success' | 'error';
  message: string;
} | null;

function statusColor(status: string) {
  const normalized = status.toLowerCase();

  if (normalized === 'published') {
    return '#10b981';
  }

  if (normalized === 'hidden') {
    return '#ef4444';
  }

  return '#f59e0b';
}

export default function ReviewsPage() {
  const { hasPermission } = useAuth();
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [notice, setNotice] = useState<Notice>(null);
  const [updatingReviewId, setUpdatingReviewId] = useState<string | null>(null);

  const fetchReviews = useCallback(async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/reviews', {
        params: { status: statusFilter || undefined, pageNumber: 1, pageSize: 100 },
      });
      setReviews(unwrapPagedResponse<Review>(response).data);
    } catch (err) {
      console.error('Failed to fetch reviews', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to fetch reviews.') });
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  const handleUpdateStatus = async (id: string, status: 'Hidden' | 'Published') => {
    setUpdatingReviewId(id);
    try {
      await api.put(`/admin/reviews/${id}/status`, { status });
      setNotice({
        tone: 'success',
        message: status === 'Hidden' ? 'Review hidden successfully.' : 'Review is visible again.',
      });
      await fetchReviews();
    } catch (err) {
      console.error('Update failed', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to update review status.') });
    } finally {
      setUpdatingReviewId(null);
    }
  };

  useEffect(() => {
    void fetchReviews();
  }, [fetchReviews]);

  const renderStars = (rating: number) =>
    Array.from({ length: 5 }).map((_, index) => (
      <Star
        key={index}
        size={14}
        fill={index < rating ? '#f59e0b' : 'transparent'}
        color={index < rating ? '#f59e0b' : '#6b7280'}
      />
    ));

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem', gap: '1rem', flexWrap: 'wrap' }}>
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Review Moderation</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))' }}>
              Reviews publish immediately. Use this page to hide or restore visibility when moderation is needed.
            </p>
          </div>
          <select
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value)}
            className="glass-card"
            style={{ padding: '0.75rem 1.25rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', fontWeight: 600, outline: 'none' }}
          >
            <option value="">All Reviews</option>
            <option value="Published">Published</option>
            <option value="Hidden">Hidden</option>
          </select>
        </div>

        {notice && (
          <div
            style={{
              marginBottom: '1rem',
              padding: '0.875rem 1rem',
              borderRadius: 'var(--radius)',
              background: notice.tone === 'error' ? 'rgba(239, 68, 68, 0.12)' : 'rgba(16, 185, 129, 0.12)',
              color: notice.tone === 'error' ? '#ef4444' : '#10b981',
              fontSize: '0.875rem',
              fontWeight: 600,
            }}
          >
            {notice.message}
          </div>
        )}

        {loading ? (
          <div className="glass-card" style={{ padding: '3rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>
            Loading reviews...
          </div>
        ) : reviews.length === 0 ? (
          <div className="glass-card" style={{ padding: '3rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>
            No reviews matched the current filter.
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <AnimatePresence mode="popLayout">
              {reviews.map((review) => {
                const isHidden = review.status.toLowerCase() === 'hidden';
                const isUpdating = updatingReviewId === review.reviewId;

                return (
                  <motion.div
                    key={review.reviewId}
                    layout
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 20 }}
                    className="glass-card"
                    style={{ padding: '1.5rem' }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem', gap: '1rem', flexWrap: 'wrap' }}>
                      <div style={{ display: 'flex', gap: '1rem' }}>
                        <div style={{ width: '48px', height: '48px', borderRadius: '50%', background: 'hsl(var(--secondary))', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
                          {review.userAvatarUrl ? (
                            <img src={review.userAvatarUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                          ) : (
                            <User size={20} />
                          )}
                        </div>
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
                            <h4 style={{ fontWeight: 600 }}>{review.userName}</h4>
                            <div style={{ display: 'flex', gap: '0.1rem' }}>{renderStars(review.rating)}</div>
                          </div>
                          <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                            <Store size={14} /> Reviewed <span style={{ color: 'hsl(var(--foreground))', fontWeight: 600 }}>{review.shopName}</span>
                          </p>
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>{new Date(review.createdAt).toLocaleDateString()}</p>
                        <span style={{ fontSize: '0.75rem', fontWeight: 700, color: statusColor(review.status) }}>{review.status}</span>
                      </div>
                    </div>

                    <p style={{ fontSize: '0.9375rem', lineHeight: 1.6, marginBottom: '1rem', color: 'rgba(255,255,255,0.8)' }}>
                      &quot;{review.comment || 'No comment provided.'}&quot;
                    </p>

                    {review.reply && (
                      <div style={{ padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '8px', borderLeft: '3px solid hsl(var(--primary))', marginBottom: '1rem' }}>
                        <p style={{ fontSize: '0.75rem', fontWeight: 600, marginBottom: '0.25rem' }}>Keeper Response:</p>
                        <p style={{ fontSize: '0.875rem', fontStyle: 'italic' }}>{review.reply}</p>
                      </div>
                    )}

                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
                      {hasPermission(PERMISSIONS.moderationEdit) && !isHidden && (
                        <button
                          onClick={() => void handleUpdateStatus(review.reviewId, 'Hidden')}
                          disabled={isUpdating}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            background: 'rgba(239, 68, 68, 0.1)',
                            border: 'none',
                            color: '#ef4444',
                            padding: '0.5rem 1rem',
                            borderRadius: 'var(--radius)',
                            fontSize: '0.875rem',
                            opacity: isUpdating ? 0.7 : 1,
                          }}
                        >
                          <XCircle size={16} /> Hide Review
                        </button>
                      )}
                      {hasPermission(PERMISSIONS.moderationEdit) && isHidden && (
                        <button
                          onClick={() => void handleUpdateStatus(review.reviewId, 'Published')}
                          disabled={isUpdating}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            background: 'rgba(16, 185, 129, 0.1)',
                            border: 'none',
                            color: '#10b981',
                            padding: '0.5rem 1rem',
                            borderRadius: 'var(--radius)',
                            fontSize: '0.875rem',
                            opacity: isUpdating ? 0.7 : 1,
                          }}
                        >
                          <CheckCircle2 size={16} /> Unhide Review
                        </button>
                      )}
                    </div>
                  </motion.div>
                );
              })}
            </AnimatePresence>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
