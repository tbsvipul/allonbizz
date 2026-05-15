'use client';

import React, { useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import {
  User,
  Mail,
  Shield,
  ShieldCheck,
  Save,
  Key,
  CheckCircle2,
  AlertCircle
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';

export default function ProfilePage() {
  const { user, updateUser } = useAuth();

  const [firstName, setFirstName] = useState(user?.firstName || '');
  const [lastName, setLastName] = useState(user?.lastName || '');
  const [email, setEmail] = useState(user?.email || '');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [status, setStatus] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [savingProfile, setSavingProfile] = useState(false);
  const [savingPassword, setSavingPassword] = useState(false);

  const initials = `${firstName[0] || ''}${lastName[0] || ''}`.trim() || user?.email?.[0] || '?';

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setSavingProfile(true);
    setStatus(null);

    try {
      await api.put('/admin/auth/profile', { firstName, lastName, email });
      updateUser({ firstName, lastName, email });
      setStatus({ type: 'success', text: 'Profile updated successfully.' });
    } catch (err: any) {
      setStatus({ type: 'error', text: err.response?.data?.message || 'Failed to update profile.' });
    } finally {
      setSavingProfile(false);
      setTimeout(() => setStatus(null), 3000);
    }
  };

  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setSavingPassword(true);
    setStatus(null);

    if (!currentPassword || !newPassword) {
      setStatus({ type: 'error', text: 'Please fill in all password fields.' });
      setSavingPassword(false);
      return;
    }

    try {
      await api.post('/admin/auth/change-password', { currentPassword, newPassword });
      setStatus({ type: 'success', text: 'Password changed successfully.' });
      setCurrentPassword('');
      setNewPassword('');
    } catch (err: any) {
      setStatus({ type: 'error', text: err.response?.data?.message || 'Failed to change password.' });
    } finally {
      setSavingPassword(false);
      setTimeout(() => setStatus(null), 3000);
    }
  };

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ marginBottom: '2.5rem' }}>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Administrator Profile</h1>
          <p style={{ color: 'hsl(var(--muted-foreground))' }}>Manage your account details and security settings.</p>
        </div>

        <AnimatePresence>
          {status && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              style={{
                padding: '1rem',
                marginBottom: '1.5rem',
                borderRadius: 'var(--radius)',
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem',
                fontWeight: 600,
                background: status.type === 'success' ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)',
                color: status.type === 'success' ? '#10b981' : '#ef4444',
              }}
            >
              {status.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
              {status.text}
            </motion.div>
          )}
        </AnimatePresence>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
          <div className="glass-card" style={{ padding: '2rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', marginBottom: '2rem', paddingBottom: '2rem', borderBottom: '1px solid hsl(var(--border))' }}>
              <div style={{ width: '80px', height: '80px', borderRadius: '50%', background: 'hsl(var(--primary))', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2rem', fontWeight: 700, boxShadow: '0 8px 24px rgba(99, 102, 241, 0.3)' }}>
                {initials}
              </div>
              <div>
                <h2 style={{ fontSize: '1.25rem', fontWeight: 700 }}>{firstName} {lastName}</h2>
                <p style={{ color: 'hsl(var(--muted-foreground))', display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', marginTop: '0.25rem' }}>
                  <ShieldCheck size={14} color="hsl(var(--primary))" /> {user?.role || ''}
                </p>
              </div>
            </div>

            <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--muted-foreground))' }}>First Name</label>
                  <div style={{ position: 'relative' }}>
                    <User size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
                    <input value={firstName} onChange={(e) => setFirstName(e.target.value)} style={{ width: '100%', padding: '0.75rem 1rem 0.75rem 2.5rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.02)', outline: 'none', color: 'hsl(var(--foreground))' }} required />
                  </div>
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--muted-foreground))' }}>Last Name</label>
                  <input value={lastName} onChange={(e) => setLastName(e.target.value)} style={{ width: '100%', padding: '0.75rem 1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.02)', outline: 'none', color: 'hsl(var(--foreground))' }} required />
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--muted-foreground))' }}>Email Address</label>
                <div style={{ position: 'relative' }}>
                  <Mail size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
                  <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} style={{ width: '100%', padding: '0.75rem 1rem 0.75rem 2.5rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.02)', outline: 'none', color: 'hsl(var(--foreground))' }} required />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1rem' }}>
                <button type="submit" disabled={savingProfile} className="premium-gradient" style={{ border: 'none', color: 'white', padding: '0.75rem 1.5rem', borderRadius: 'var(--radius)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: savingProfile ? 'wait' : 'pointer' }}>
                  <Save size={18} /> Save Profile
                </button>
              </div>
            </form>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <div className="glass-card" style={{ padding: '2rem' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Shield size={20} color="hsl(var(--primary))" /> Security
              </h3>

              <form onSubmit={handleUpdatePassword} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--muted-foreground))' }}>Current Password</label>
                  <div style={{ position: 'relative' }}>
                    <Key size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
                    <input type="password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} placeholder="Enter current password" style={{ width: '100%', padding: '0.75rem 1rem 0.75rem 2.5rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.02)', outline: 'none', color: 'hsl(var(--foreground))' }} />
                  </div>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, marginBottom: '0.5rem', color: 'hsl(var(--muted-foreground))' }}>New Password</label>
                  <div style={{ position: 'relative' }}>
                    <Key size={16} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
                    <input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="Enter new password" style={{ width: '100%', padding: '0.75rem 1rem 0.75rem 2.5rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.02)', outline: 'none', color: 'hsl(var(--foreground))' }} />
                  </div>
                </div>

                <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '0.5rem' }}>
                  <button type="submit" disabled={savingPassword} style={{ background: 'hsl(var(--primary))', border: 'none', color: 'white', padding: '0.75rem 1.5rem', borderRadius: 'var(--radius)', fontWeight: 600, cursor: savingPassword ? 'wait' : 'pointer' }}>
                    Update Password
                  </button>
                </div>
              </form>
            </div>

            <div className="glass-card" style={{ padding: '2rem' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <ShieldCheck size={20} color="#10b981" /> Active Privileges
              </h3>

              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.75rem' }}>
                {(user?.permissions || []).map((permission) => (
                  <div key={permission} style={{ padding: '0.6rem 0.9rem', borderRadius: '12px', background: 'rgba(16, 185, 129, 0.05)', border: '1px solid rgba(16, 185, 129, 0.15)', fontSize: '0.8rem', fontWeight: 600 }}>
                    {permission}
                  </div>
                ))}
                {(user?.permissions || []).length === 0 && (
                  <p style={{ color: 'hsl(var(--muted-foreground))' }}>No explicit permissions available in the current session.</p>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
