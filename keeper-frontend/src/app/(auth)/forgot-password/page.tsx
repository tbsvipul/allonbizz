'use client';

import { FormEvent, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { useToast } from '@/context/ToastContext';
import { AuthHero } from '@/components/AuthHero';
import { InlineNotice } from '@/components/InlineNotice';

type Stage = 'request' | 'verify';

export default function ForgotPasswordPage() {
  const router = useRouter();
  const { showToast } = useToast();
  const [stage, setStage] = useState<Stage>('request');
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleRequest(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError('');

    try {
      await api.post('/auth/forgot-password', { email: email.trim() });
      setStage('verify');
      showToast('Recovery instructions sent. Enter the OTP from your email.', 'info');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to start password recovery.'));
    } finally {
      setLoading(false);
    }
  }

  async function handleVerify(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await api.post('/auth/verify-otp', {
        email: email.trim(),
        otp: otp.trim(),
      });

      const payload = unwrapApiData<{ resetToken: string }>(response);
      showToast('OTP verified. Set your new password now.', 'success');
      router.push(`/reset-password?token=${encodeURIComponent(payload.resetToken)}`);
    } catch (err) {
      setError(getApiErrorMessage(err, 'OTP verification failed.'));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-grid">
      <AuthHero
        eyebrow="Secure Recovery"
        title="Recover access without leaving your business stuck."
        description="We’ll send a one-time code to your email. After verification, you can set a fresh password and jump straight back into the portal."
        points={[
          'The OTP is short-lived, so use it as soon as it lands.',
          'You only need the keeper account email to begin recovery.',
          'Resetting the password will not affect your application status or shops.',
        ]}
      />

      <section className="auth-card">
        <div style={{ display: 'grid', gap: '0.45rem' }}>
          <h2>{stage === 'request' ? 'Recover password' : 'Verify OTP'}</h2>
          <p className="muted-text">
            {stage === 'request'
              ? 'Tell us which keeper email needs access restored.'
              : 'Enter the email OTP so we can open the password reset step.'}
          </p>
        </div>

        {error ? <InlineNotice tone="error" message={error} /> : null}

        {stage === 'request' ? (
          <form className="form-stack" onSubmit={handleRequest}>
            <div className="field">
              <label htmlFor="recoveryEmail">Email</label>
              <input id="recoveryEmail" type="email" value={email} onChange={(event) => setEmail(event.target.value)} required />
            </div>

            <button type="submit" className="button" disabled={loading}>
              {loading ? 'Sending...' : 'Send recovery OTP'}
            </button>
          </form>
        ) : (
          <form className="form-stack" onSubmit={handleVerify}>
            <div className="field">
              <label htmlFor="otpEmail">Email</label>
              <input id="otpEmail" type="email" value={email} onChange={(event) => setEmail(event.target.value)} required />
            </div>

            <div className="field">
              <label htmlFor="otpCode">OTP</label>
              <input id="otpCode" value={otp} onChange={(event) => setOtp(event.target.value)} required minLength={6} maxLength={12} />
            </div>

            <div className="button-row">
              <button type="submit" className="button" disabled={loading}>
                {loading ? 'Verifying...' : 'Verify OTP'}
              </button>
              <button type="button" className="button-secondary" onClick={() => setStage('request')} disabled={loading}>
                Start over
              </button>
            </div>
          </form>
        )}
      </section>
    </div>
  );
}
