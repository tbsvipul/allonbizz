'use client';

import { FormEvent, useState } from 'react';
import { CornerDownRight, Edit2 } from 'lucide-react';

export function ReviewReplyComposer({
  initialReply,
  disabled,
  busy,
  onSubmit,
}: {
  initialReply?: string | null;
  disabled?: boolean;
  busy?: boolean;
  onSubmit: (reply: string) => Promise<void>;
}) {
  const [reply, setReply] = useState(() => initialReply || '');
  const [expanded, setExpanded] = useState(false);
  const remainingCharacters = 500 - reply.length;

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await onSubmit(reply);
    setExpanded(false);
  }

  function handleCancel() {
    setReply(initialReply || '');
    setExpanded(false);
  }

  if (!expanded) {
    return (
      <div className="review-composer-collapsed" style={{ border: 'none', background: 'transparent', padding: 0, marginTop: '0.75rem' }}>
        <button
          type="button"
          disabled={disabled || busy}
          onClick={() => setExpanded(true)}
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.4rem',
            background: 'transparent',
            border: 'none',
            color: 'hsl(var(--primary))',
            fontSize: '0.875rem',
            fontWeight: 500,
            cursor: disabled || busy ? 'not-allowed' : 'pointer',
            padding: '0.25rem 0',
            opacity: disabled || busy ? 0.6 : 1,
          }}
        >
          {initialReply ? <Edit2 size={16} /> : <CornerDownRight size={16} />}
          {initialReply ? 'Edit reply' : 'Reply'}
        </button>
      </div>
    );
  }

  return (
    <form className="review-composer" onSubmit={handleSubmit}>
      <div className="review-composer-header">
        <div>
          <strong>{initialReply ? 'Update your reply' : 'Write a reply'}</strong>
          <p className="muted-text tiny-text">
            Keep it helpful, short, and specific to the customer&apos;s experience.
          </p>
        </div>
        <span className="mini-pill pill-muted">{remainingCharacters} chars left</span>
      </div>

      <div className="field">
        <textarea
          className="review-composer-textarea"
          value={reply}
          onChange={(event) => setReply(event.target.value)}
          disabled={disabled || busy}
          maxLength={500}
          placeholder="Write a thoughtful reply for this review"
        />
      </div>

      <div className="review-composer-footer">
        <p className="muted-text tiny-text">
          {disabled ? 'Approval is required before you can publish replies.' : 'Your response will be visible to customers after saving.'}
        </p>
        <div className="review-composer-actions">
          <button type="button" className="button-secondary" onClick={handleCancel} disabled={busy}>
            Cancel
          </button>
          <button type="submit" className="button" disabled={disabled || busy || !reply.trim()}>
            {busy ? 'Saving reply...' : initialReply ? 'Update reply' : 'Publish reply'}
          </button>
        </div>
      </div>
    </form>
  );
}
