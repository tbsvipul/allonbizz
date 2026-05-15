'use client';

import React, { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { LogIn, Mail, Lock, ShieldAlert } from 'lucide-react';
import { motion } from 'framer-motion';
import api from '@/lib/api';

function extractErrorMessage(error: any) {
  const payload = error?.response?.data;

  if (payload?.errors && typeof payload.errors === 'object') {
    const firstEntry = Object.values(payload.errors)[0];
    if (Array.isArray(firstEntry) && firstEntry.length > 0) {
      return String(firstEntry[0]);
    }
  }

  return (
    payload?.detail ||
    payload?.message ||
    (error?.response?.status === 401 ? 'Invalid email or password.' : null) ||
    'Invalid credentials or server error'
  );
}

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const { login } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await api.post('/admin/auth/login', { email: email.trim(), password });
      const { accessToken, refreshToken, admin } = response.data.data;
      login(accessToken, refreshToken, admin);
    } catch (err: any) {
      setError(extractErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex-center" style={{ minHeight: '100vh', padding: '1rem' }}>
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5 }}
        className="glass-card"
        style={{ width: '100%', maxWidth: '400px', padding: '2.5rem' }}
      >
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <div className="flex-center" style={{
            width: '64px',
            height: '64px',
            borderRadius: '50%',
            background: 'hsl(var(--primary))',
            margin: '0 auto 1rem',
            color: 'white'
          }}>
            <LogIn size={32} />
          </div>
          <h1 className="text-gradient" style={{ fontSize: '1.875rem', fontWeight: 700 }}>allonbiz Admin</h1>
          <p style={{ color: 'hsl(var(--muted-foreground))', marginTop: '0.5rem' }}>Welcome back, please sign in</p>
        </div>

        {error && (
          <div style={{
            padding: '0.75rem',
            background: 'rgba(239, 68, 68, 0.1)',
            border: '1px solid rgba(239, 68, 68, 0.2)',
            borderRadius: 'var(--radius)',
            color: 'hsl(var(--destructive))',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            marginBottom: '1.5rem',
            fontSize: '0.875rem'
          }}>
            <ShieldAlert size={16} />
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div style={{ position: 'relative' }}>
            <Mail size={18} style={{
              position: 'absolute',
              top: '50%',
              left: '1rem',
              transform: 'translateY(-50%)',
              color: 'hsl(var(--muted-foreground))'
            }} />
            <input
              type="email"
              placeholder="Admin Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              style={{
                width: '100%',
                padding: '0.75rem 1rem 0.75rem 2.75rem',
                borderRadius: 'var(--radius)',
                border: '1px solid hsl(var(--border))',
                background: 'rgba(0,0,0,0.05)',
                color: 'inherit',
                outline: 'none'
              }}
            />
          </div>

          <div style={{ position: 'relative' }}>
            <Lock size={18} style={{
              position: 'absolute',
              top: '50%',
              left: '1rem',
              transform: 'translateY(-50%)',
              color: 'hsl(var(--muted-foreground))'
            }} />
            <input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={8}
              style={{
                width: '100%',
                padding: '0.75rem 1rem 0.75rem 2.75rem',
                borderRadius: 'var(--radius)',
                border: '1px solid hsl(var(--border))',
                background: 'rgba(0,0,0,0.05)',
                color: 'inherit',
                outline: 'none'
              }}
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="premium-gradient"
            style={{
              padding: '0.75rem',
              color: 'white',
              fontWeight: 600,
              border: 'none',
              marginTop: '0.5rem',
              boxShadow: '0 4px 15px rgba(124, 58, 237, 0.3)'
            }}
          >
            {loading ? 'Authenticating...' : 'Sign In'}
          </button>
        </form>
      </motion.div>
    </div>
  );
}
