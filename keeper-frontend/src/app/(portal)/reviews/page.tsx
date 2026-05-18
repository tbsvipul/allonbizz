'use client';

import { Star, Store } from 'lucide-react';
import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import { ReviewReplyComposer } from '@/features/reviews/ReviewReplyComposer';
import api from '@/lib/api';
import { formatDateTime } from '@/lib/format';
import { PaginationMeta, getApiErrorMessage, unwrapApiData, unwrapPagedResponse } from '@/lib/api-response';
import { ReviewItem, ShopSummary } from '@/lib/types';
import { useAuth } from '@/context/AuthContext';
import { StatusPill } from '@/components/StatusPill';

function renderStars(rating: number) {
  return Array.from({ length: 5 }, (_, index) => (
    <Star
      key={`${rating}-${index}`}
      size={15}
      className={index < rating ? 'review-star review-star-filled' : 'review-star'}
      fill={index < rating ? 'currentColor' : 'none'}
    />
  ));
}

function getInitials(name: string) {
  const segments = name.trim().split(/\s+/).filter(Boolean);
  return segments.slice(0, 2).map((segment) => segment[0]?.toUpperCase() || '').join('') || 'CU';
}

export default function ReviewsPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [busyReviewId, setBusyReviewId] = useState('');
  const [error, setError] = useState('');
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [reviews, setReviews] = useState<ReviewItem[]>([]);
  const [pagination, setPagination] = useState<PaginationMeta | null>(null);
  const [shopId, setShopId] = useState('');
  const [page, setPage] = useState(1);

  useEffect(() => {
    let active = true;

    async function load() {
      setLoading(true);
      setError('');

      try {
        const [shopsResponse, reviewsResponse] = await Promise.all([
          api.get('/keeper/shops'),
          api.get('/keeper/reviews', {
            params: {
              shopId: shopId || undefined,
              pageNumber: page,
              pageSize: 10,
            },
          }),
        ]);

        if (!active) {
          return;
        }

        setShops(unwrapApiData<ShopSummary[]>(shopsResponse));
        const paged = unwrapPagedResponse<ReviewItem>(reviewsResponse);
        setReviews(paged.data);
        setPagination(paged.pagination);
      } catch (err) {
        if (active) {
          setError(getApiErrorMessage(err, 'Unable to load reviews.'));
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
  }, [page, shopId]);

  async function handleReply(reviewId: string, reply: string) {
    setBusyReviewId(reviewId);
    setError('');

    try {
      await api.post(`/keeper/review/${reviewId}/reply`, {
        reply,
      });

      const refreshed = await api.get('/keeper/reviews', {
        params: {
          shopId: shopId || undefined,
          pageNumber: page,
          pageSize: 10,
        },
      });

      const paged = unwrapPagedResponse<ReviewItem>(refreshed);
      setReviews(paged.data);
      setPagination(paged.pagination);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to save the review reply.'));
    } finally {
      setBusyReviewId('');
    }
  }

  return (
    <div className="reviews-page">
      <PageHeader
        title="Reviews"
        description="See what customers are saying and answer reviews directly from the keeper workspace."
        actions={
          <div className="reviews-filter-card">
            <div className="field">
              <label htmlFor="reviewShopFilter">Filter by shop</label>
              <select
                id="reviewShopFilter"
                value={shopId}
                onChange={(event) => {
                  setShopId(event.target.value);
                  setPage(1);
                }}
              >
                <option value="">All shops</option>
                {shops.map((shop) => (
                  <option key={shop.id} value={shop.id}>
                    {shop.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
        }
      />

      {error ? <InlineNotice tone="error" message={error} /> : null}

      {loading ? (
        <p className="muted-text">Loading reviews...</p>
      ) : reviews.length === 0 ? (
        <EmptyState title="No reviews yet" message="Customer reviews for your shops and offers will appear here once they start coming in." />
      ) : (
        <div className="reviews-list">
          {reviews.map((review) => (
            <section key={review.reviewId} className="review-shell">
              <div className="review-shell-header">
                <div className="review-customer">
                  <div className="review-avatar">{getInitials(review.userFullName)}</div>
                  <div className="review-customer-copy">
                    <h3>{review.userFullName}</h3>
                    <div className="review-meta-row">
                      <span className="review-date">{formatDateTime(review.createdAt)}</span>
                      <span className="review-chip">
                        <Store size={14} />
                        {review.shopName}
                      </span>
                      {review.offerTitle ? <span className="review-chip review-chip-subtle">{review.offerTitle}</span> : null}
                    </div>
                  </div>
                </div>

                <div className="review-rating-side">
                  <div className="review-stars">{renderStars(review.rating)}</div>
                  <div className="review-rating-meta">
                    <span className="review-rating-label">{review.rating}/5</span>
                    <StatusPill status={review.status} />
                  </div>
                </div>
              </div>

              <p className="review-comment">{review.comment || 'No written comment was left with this rating.'}</p>

              {review.reply ? (
                <div className="review-inline-response">
                  <div className="review-inline-response-header">
                    <strong>Your reply</strong>
                    <span className="muted-text tiny-text">{review.repliedAt ? formatDateTime(review.repliedAt) : 'Published'}</span>
                  </div>
                  <p className="review-response-text">{review.reply}</p>
                </div>
              ) : null}

              <ReviewReplyComposer
                key={`${review.reviewId}:${review.reply || ''}`}
                initialReply={review.reply}
                busy={busyReviewId === review.reviewId}
                disabled={!user?.canManage}
                onSubmit={(reply) => handleReply(review.reviewId, reply)}
              />
            </section>
          ))}
        </div>
      )}

      {pagination ? (
        <div className="reviews-pagination">
          <button type="button" className="button-secondary" onClick={() => setPage((current) => Math.max(1, current - 1))} disabled={page <= 1}>
            Previous page
          </button>
          <span className="muted-text tiny-text">
            Page {pagination.page} of {pagination.totalPages || 1}
          </span>
          <button
            type="button"
            className="button-secondary"
            onClick={() => setPage((current) => current + 1)}
            disabled={!pagination.hasNextPage}
          >
            Next page
          </button>
        </div>
      ) : null}
    </div>
  );
}
