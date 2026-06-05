'use client';

import Link from 'next/link';
import { FormEvent, useState } from 'react';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';
import { AuthHero } from '@/components/AuthHero';
import { InlineNotice } from '@/components/InlineNotice';

export default function LoginPage() {
  const { login } = useAuth();
  const { showToast } = useToast();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await api.post('/auth/user-login', {
        email: email.trim(),
        password,
      });

      const payload = unwrapApiData<{
        accessToken: string;
        refreshToken: string;
        role: string;
      }>(response);

      if (String(payload.role || '').toLowerCase() !== 'keeper') {
        setError('This sign-in is only for keeper accounts.');
        return;
      }

      await login(payload.accessToken, payload.refreshToken);
      showToast('Signed in successfully.', 'success');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to sign in right now.'));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-grid">
      <AuthHero
        eyebrow="Keeper Workspace"
        title="Run your local business with sharper daily visibility."
        description="Sign in to track shop activity, launch offers, and answer customer reviews."
        points={[
          'See offer performance and redemptions in one dashboard.',
          'Keep shop details updated without waiting on admin support.',
          'Respond to customer feedback before it turns into churn.',
        ]}
      />

      <section className="auth-card">
        <div style={{ display: 'grid', gap: '0.45rem' }}>
          <h2>Sign in</h2>
          <p className="muted-text">Use the email and password from your keeper account.</p>
        </div>

        {error ? <InlineNotice tone="error" message={error} /> : null}

        <form className="form-stack" onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="email">Email</label>
            <input id="email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} required />
          </div>

          <div className="field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
              minLength={8}
            />
          </div>

          <button type="submit" className="button" disabled={loading}>
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>

        <div className="button-row" style={{ justifyContent: 'space-between' }}>
          <Link className="button-ghost" href="/forgot-password">
            Forgot password
          </Link>
          <Link className="button-secondary" href="/register">
            Create keeper account
          </Link>
        </div>
      </section>
    </div>
  );
}
