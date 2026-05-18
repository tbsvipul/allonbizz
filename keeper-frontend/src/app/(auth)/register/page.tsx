'use client';

import Link from 'next/link';
import { FormEvent, useState } from 'react';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';
import { AuthHero } from '@/components/AuthHero';
import { InlineNotice } from '@/components/InlineNotice';

export default function RegisterPage() {
  const { login } = useAuth();
  const { showToast } = useToast();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [form, setForm] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    businessName: '',
    businessLicense: '',
  });

  function updateField<Key extends keyof typeof form>(key: Key, value: string) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await api.post('/auth/register-keeper', {
        firstName: form.firstName.trim(),
        lastName: form.lastName.trim(),
        email: form.email.trim(),
        password: form.password,
        businessName: form.businessName.trim(),
        businessLicense: form.businessLicense.trim() || null,
      });

      const payload = unwrapApiData<{
        accessToken: string;
        refreshToken: string;
      }>(response);

      await login(payload.accessToken, payload.refreshToken);
      showToast('Keeper account created.', 'success');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to create the keeper account.'));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-grid">
      <AuthHero
        eyebrow="Merchant Onboarding"
        title="Open your keeper portal and start managing offers fast."
        description="Create the business account, complete the core business details, and keep operating updates in one place while approval is in progress."
        points={[
          'Register one keeper account per business owner email.',
          'Pending accounts can still sign in and finish profile details.',
          'Approval unlocks shops, offers, loyalty, and review reply actions.',
        ]}
      />

      <section className="auth-card">
        <div style={{ display: 'grid', gap: '0.45rem' }}>
          <h2>Create keeper account</h2>
          <p className="muted-text">We’ll open your portal immediately and keep the business under review.</p>
        </div>

        {error ? <InlineNotice tone="error" message={error} /> : null}

        <form className="form-stack" onSubmit={handleSubmit}>
          <div className="field-grid">
            <div className="field">
              <label htmlFor="firstName">First name</label>
              <input id="firstName" value={form.firstName} onChange={(event) => updateField('firstName', event.target.value)} required />
            </div>
            <div className="field">
              <label htmlFor="lastName">Last name</label>
              <input id="lastName" value={form.lastName} onChange={(event) => updateField('lastName', event.target.value)} required />
            </div>
          </div>

          <div className="field">
            <label htmlFor="registerEmail">Email</label>
            <input id="registerEmail" type="email" value={form.email} onChange={(event) => updateField('email', event.target.value)} required />
          </div>

          <div className="field">
            <label htmlFor="registerPassword">Password</label>
            <input
              id="registerPassword"
              type="password"
              value={form.password}
              onChange={(event) => updateField('password', event.target.value)}
              required
              minLength={8}
            />
          </div>

          <div className="field">
            <label htmlFor="businessName">Business name</label>
            <input id="businessName" value={form.businessName} onChange={(event) => updateField('businessName', event.target.value)} required />
          </div>

          <div className="field">
            <label htmlFor="businessLicense">Business license</label>
            <input id="businessLicense" value={form.businessLicense} onChange={(event) => updateField('businessLicense', event.target.value)} />
          </div>

          <button type="submit" className="button" disabled={loading}>
            {loading ? 'Creating account...' : 'Create account'}
          </button>
        </form>

        <div className="button-row" style={{ justifyContent: 'space-between' }}>
          <p className="muted-text tiny-text">Already registered?</p>
          <Link className="button-ghost" href="/login">
            Sign in instead
          </Link>
        </div>
      </section>
    </div>
  );
}
