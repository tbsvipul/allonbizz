'use client';

import { FormEvent, Suspense, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import api from '@/lib/api';
import { getApiErrorMessage } from '@/lib/api-response';
import { useToast } from '@/context/ToastContext';
import { AuthHero } from '@/components/AuthHero';
import { InlineNotice } from '@/components/InlineNotice';

function ResetPasswordContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { showToast } = useToast();
  const resetToken = searchParams.get('token') || '';
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError('');

    if (!resetToken) {
      setError('Missing reset token. Restart the recovery flow.');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('The password confirmation does not match.');
      return;
    }

    setLoading(true);

    try {
      await api.post('/auth/reset-password', {
        token: resetToken,
        newPassword,
      });

      showToast('Password updated. Sign in with the new password.', 'success');
      router.replace('/login');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to reset the password.'));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-grid">
      <AuthHero
        eyebrow="Final Step"
        title="Set the new password and get back to work."
        description="Choose a secure password for the keeper account. Once it is saved, the portal sign-in will use the new credentials right away."
        points={[
          'Use at least 8 characters so the API accepts the new password.',
          'If the token expires, restart the recovery flow from the OTP step.',
          'Changing the password will not reset your shops, offers, or approval state.',
        ]}
      />

      <section className="auth-card">
        <div style={{ display: 'grid', gap: '0.45rem' }}>
          <h2>Reset password</h2>
          <p className="muted-text">Finish the reset with a new password for your keeper account.</p>
        </div>

        {error ? <InlineNotice tone="error" message={error} /> : null}

        <form className="form-stack" onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="newPassword">New password</label>
            <input
              id="newPassword"
              type="password"
              value={newPassword}
              onChange={(event) => setNewPassword(event.target.value)}
              required
              minLength={8}
            />
          </div>

          <div className="field">
            <label htmlFor="confirmPassword">Confirm password</label>
            <input
              id="confirmPassword"
              type="password"
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              required
              minLength={8}
            />
          </div>

          <button type="submit" className="button" disabled={loading}>
            {loading ? 'Saving...' : 'Save new password'}
          </button>
        </form>

        <Link className="button-ghost" href="/login">
          Back to sign in
        </Link>
      </section>
    </div>
  );
}

function ResetPasswordFallback() {
  return (
    <div className="auth-grid">
      <AuthHero
        eyebrow="Final Step"
        title="Set the new password and get back to work."
        description="Choose a secure password for the keeper account to finish recovery."
        points={[
          'Use a strong password with at least 8 characters.',
          'If the token expires, restart the recovery flow.',
          'Your account data will stay intact after the reset.',
        ]}
      />

      <section className="auth-card">
        <div style={{ display: 'grid', gap: '0.45rem' }}>
          <h2>Reset password</h2>
          <p className="muted-text">Loading reset details...</p>
        </div>
      </section>
    </div>
  );
}

export default function ResetPasswordPage() {
  return (
    <Suspense fallback={<ResetPasswordFallback />}>
      <ResetPasswordContent />
    </Suspense>
  );
}
