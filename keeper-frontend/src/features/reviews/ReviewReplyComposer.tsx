'use client';

import { FormEvent, useState } from 'react';

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
  const [expanded, setExpanded] = useState(() => !initialReply);
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
      <div className="review-composer-collapsed">
        <div className="review-composer-collapsed-copy">
          <strong>{initialReply ? 'Reply published' : 'Respond to this review'}</strong>
          <p className="muted-text tiny-text">
            {initialReply
              ? 'You can reopen this response and refine the message anytime.'
              : 'Post a short, helpful reply directly from your keeper workspace.'}
          </p>
        </div>
        <button type="button" className="button-secondary" disabled={disabled || busy} onClick={() => setExpanded(true)}>
          {initialReply ? 'Edit reply' : 'Respond'}
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
