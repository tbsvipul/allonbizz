'use client';

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import {
  Settings,
  Shield,
  Users,
  Plus,
  Trash2,
  RefreshCcw,
  Save,
  Lock,
  Pencil,
  LogOut,
} from 'lucide-react';
import api from '@/lib/api';
import { unwrapApiData, unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';

type SettingsTab = 'general' | 'security' | 'admins';

interface GeneralSettingsState {
  baseUrl: string;
  firebaseProjectId: string;
  apiVersion: string;
  environment: string;
  externalServices: Record<string, string>;
}

interface SecuritySettingsState {
  enforce2FA: boolean;
  passwordExpirationDays: number;
}

interface AdminItem {
  adminId: string;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  role: string;
  isActive: boolean;
  is2FAEnabled: boolean;
  lastLoginAt?: string | null;
}

interface AdminDetail extends AdminItem {
  permissions: string[];
  failedLoginAttempts: number;
  lockoutEnd?: string | null;
}

interface AuthUserPayload {
  adminId: string;
  firstName: string;
  lastName: string;
  email: string;
  role: string;
  permissions: string[];
  is2FAEnabled?: boolean;
  lastLoginAt?: string | null;
}

interface AdminFormState {
  firstName: string;
  lastName: string;
  email: string;
  role: string;
  isActive: boolean;
  permissions: string[];
  password?: string;
}

type Notice = {
  tone: 'success' | 'error';
  message: string;
} | null;

const defaultGeneralSettings: GeneralSettingsState = {
  baseUrl: '',
  firebaseProjectId: '',
  apiVersion: '',
  environment: '',
  externalServices: {},
};

const defaultSecuritySettings: SecuritySettingsState = {
  enforce2FA: false,
  passwordExpirationDays: 0,
};

const defaultAdminForm: AdminFormState = {
  firstName: '',
  lastName: '',
  email: '',
  role: 'admin',
  isActive: true,
  permissions: [],
  password: '',
};

const allPermissions = Array.from(new Set(Object.values(PERMISSIONS))).sort();

const roleDefaultPermissions: Record<string, string[]> = {
  super_admin: [...allPermissions],
  admin: [
    PERMISSIONS.usersView,
    PERMISSIONS.usersEdit,
    PERMISSIONS.usersSuspend,
    PERMISSIONS.usersBan,
    PERMISSIONS.usersExport,
    PERMISSIONS.keepersView,
    PERMISSIONS.keepersApprove,
    PERMISSIONS.keepersReject,
    PERMISSIONS.keepersSuspend,
    PERMISSIONS.categoriesView,
    PERMISSIONS.categoriesCreate,
    PERMISSIONS.categoriesEdit,
    PERMISSIONS.categoriesDelete,
    PERMISSIONS.shopsView,
    PERMISSIONS.shopsCreate,
    PERMISSIONS.shopsEdit,
    PERMISSIONS.shopsDelete,
    PERMISSIONS.shopsApprove,
    PERMISSIONS.shopsReject,
    PERMISSIONS.tagsView,
    PERMISSIONS.tagsCreate,
    PERMISSIONS.tagsEdit,
    PERMISSIONS.tagsDelete,
    PERMISSIONS.offersView,
    PERMISSIONS.offersApprove,
    PERMISSIONS.routesView,
    PERMISSIONS.reviewsView,
    PERMISSIONS.loyaltyView,
    PERMISSIONS.journeysView,
    PERMISSIONS.journeysDelete,
    PERMISSIONS.moderationView,
    PERMISSIONS.moderationApprove,
    PERMISSIONS.moderationReject,
    PERMISSIONS.moderationEdit,
    PERMISSIONS.moderationEscalate,
    PERMISSIONS.analyticsView,
    PERMISSIONS.reportsGenerate,
    PERMISSIONS.systemView,
    PERMISSIONS.systemEdit,
    PERMISSIONS.notificationsView,
    PERMISSIONS.notificationsSend,
  ],
  moderator: [
    PERMISSIONS.usersView,
    PERMISSIONS.keepersView,
    PERMISSIONS.shopsView,
    PERMISSIONS.offersView,
    PERMISSIONS.reviewsView,
    PERMISSIONS.moderationView,
    PERMISSIONS.moderationApprove,
    PERMISSIONS.moderationReject,
    PERMISSIONS.moderationEdit,
    PERMISSIONS.moderationEscalate,
    PERMISSIONS.notificationsView,
  ],
  analyst: [
    PERMISSIONS.analyticsView,
    PERMISSIONS.reportsGenerate,
    PERMISSIONS.journeysView,
    PERMISSIONS.usersView,
    PERMISSIONS.shopsView,
    PERMISSIONS.offersView,
    PERMISSIONS.routesView,
    PERMISSIONS.loyaltyView,
  ],
};

function normalizePermissions(permissions: string[]) {
  return [...new Set(permissions)].sort();
}

function usesRoleDefaults(role: string, permissions: string[]) {
  const defaults = normalizePermissions(roleDefaultPermissions[role] || []);
  const current = normalizePermissions(permissions || []);

  if (defaults.length !== current.length) {
    return false;
  }

  return defaults.every((permission, index) => permission === current[index]);
}

export default function SettingsPage() {
  const { user, hasPermission, updateUser } = useAuth();
  const [activeTab, setActiveTab] = useState<SettingsTab>('general');
  const [generalSettings, setGeneralSettings] = useState<GeneralSettingsState>(defaultGeneralSettings);
  const [securitySettings, setSecuritySettings] = useState<SecuritySettingsState>(defaultSecuritySettings);
  const [admins, setAdmins] = useState<AdminItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [isAdminModalOpen, setIsAdminModalOpen] = useState(false);
  const [editingAdminId, setEditingAdminId] = useState<string | null>(null);
  const [loadingAdminDetails, setLoadingAdminDetails] = useState(false);
  const [useRoleDefaults, setUseRoleDefaults] = useState(true);
  const [adminForm, setAdminForm] = useState<AdminFormState>(defaultAdminForm);
  const [notice, setNotice] = useState<Notice>(null);
  const currentUserIsSuperAdmin = user?.role === 'super_admin';
  const isEditingSelf = Boolean(editingAdminId && user?.adminId === editingAdminId);
  const isEditingOwnSuperAdmin = isEditingSelf && user?.role === 'super_admin';
  const isEditingExistingSuperAdmin = Boolean(editingAdminId && adminForm.role === 'super_admin');
  const canManageSelectedSuperAdmin = currentUserIsSuperAdmin || adminForm.role !== 'super_admin';

  const tabs = useMemo(
    () =>
      [
        {
          id: 'general' as const,
          label: 'General',
          icon: Settings,
          permission: [PERMISSIONS.systemView, PERMISSIONS.settingsEdit],
        },
        {
          id: 'security' as const,
          label: 'Security',
          icon: Shield,
          permission: [PERMISSIONS.systemView, PERMISSIONS.settingsEdit],
        },
        {
          id: 'admins' as const,
          label: 'Administrators',
          icon: Users,
          permission: PERMISSIONS.adminsManage,
        },
      ].filter((tab) => hasPermission(tab.permission)),
    [hasPermission]
  );

  useEffect(() => {
    if (tabs.length > 0 && !tabs.some((tab) => tab.id === activeTab)) {
      setActiveTab(tabs[0].id);
    }
  }, [activeTab, tabs]);

  const closeAdminModal = () => {
    setIsAdminModalOpen(false);
    setEditingAdminId(null);
    setLoadingAdminDetails(false);
    setUseRoleDefaults(true);
    setAdminForm(defaultAdminForm);
  };

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      if (activeTab === 'general') {
        const response = await api.get('/settings');
        const payload = unwrapApiData<GeneralSettingsState>(response) || defaultGeneralSettings;
        setGeneralSettings({
          baseUrl: payload.baseUrl || '',
          firebaseProjectId: payload.firebaseProjectId || '',
          apiVersion: payload.apiVersion || '',
          environment: payload.environment || '',
          externalServices: payload.externalServices || {},
        });
      } else if (activeTab === 'security') {
        const response = await api.get('/settings/security');
        const payload = unwrapApiData<SecuritySettingsState>(response) || defaultSecuritySettings;
        setSecuritySettings({
          enforce2FA: payload.enforce2FA === true,
          passwordExpirationDays: Number(payload.passwordExpirationDays || 0),
        });
      } else if (activeTab === 'admins') {
        const response = await api.get('/settings/admins', { params: { pageNumber: 1, pageSize: 100 } });
        setAdmins(unwrapPagedResponse<AdminItem>(response).data);
      }
    } catch (err) {
      console.error('Failed to fetch settings data', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to fetch settings data.') });
    } finally {
      setLoading(false);
    }
  }, [activeTab]);

  useEffect(() => {
    if (tabs.length > 0) {
      void fetchData();
    }
  }, [fetchData, tabs.length]);

  const refreshCurrentAdminSession = async (adminId: string) => {
    if (!user || user.adminId !== adminId) {
      return;
    }

    try {
      const response = await api.get('/admin/auth/me');
      updateUser(unwrapApiData<AuthUserPayload>(response));
    } catch (err) {
      console.error('Failed to refresh current admin session', err);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      if (activeTab === 'general') {
        await api.put('/settings', { config: generalSettings });
        setNotice({ tone: 'success', message: 'General settings updated successfully.' });
      } else if (activeTab === 'security') {
        await api.put('/settings/security', securitySettings);
        setNotice({ tone: 'success', message: 'Security settings updated successfully.' });
      }
    } catch (err) {
      console.error('Failed to save settings', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to save changes.') });
    } finally {
      setSaving(false);
    }
  };

  const openCreateAdmin = () => {
    setEditingAdminId(null);
    setUseRoleDefaults(true);
    setAdminForm({
      ...defaultAdminForm,
      role: 'admin',
      permissions: roleDefaultPermissions.admin,
    });
    setIsAdminModalOpen(true);
  };

  const openEditAdmin = async (adminId: string) => {
    setIsAdminModalOpen(true);
    setEditingAdminId(adminId);
    setLoadingAdminDetails(true);

    try {
      const response = await api.get(`/settings/admins/${adminId}`);
      const detail = unwrapApiData<AdminDetail>(response);
      const useDefaults = usesRoleDefaults(detail.role, detail.permissions);
      setUseRoleDefaults(useDefaults);
      setAdminForm({
        firstName: detail.firstName,
        lastName: detail.lastName,
        email: detail.email,
        role: detail.role,
        isActive: detail.isActive,
        permissions: normalizePermissions(detail.permissions),
      });
    } catch (err) {
      console.error('Failed to load admin details', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to load admin details.') });
      closeAdminModal();
    } finally {
      setLoadingAdminDetails(false);
    }
  };

  const handleCreateOrUpdateAdmin = async () => {
    if (!adminForm.firstName.trim() || !adminForm.lastName.trim() || !adminForm.email.trim()) {
      setNotice({ tone: 'error', message: 'First name, last name, and email are required.' });
      return;
    }

    if (adminForm.role === 'super_admin' && !isEditingExistingSuperAdmin) {
      setNotice({ tone: 'error', message: 'Only one super admin account is allowed.' });
      return;
    }

    if (isEditingOwnSuperAdmin && adminForm.role !== 'super_admin') {
      setNotice({ tone: 'error', message: 'You cannot remove your own super admin role.' });
      return;
    }

    if (isEditingOwnSuperAdmin && !adminForm.isActive) {
      setNotice({ tone: 'error', message: 'You cannot deactivate your own super admin account.' });
      return;
    }

    setSaving(true);
    try {
      const payload = {
        firstName: adminForm.firstName.trim(),
        lastName: adminForm.lastName.trim(),
        email: adminForm.email.trim(),
        role: adminForm.role,
        isActive: adminForm.isActive,
        permissions: useRoleDefaults || isEditingOwnSuperAdmin ? undefined : normalizePermissions(adminForm.permissions),
        password: adminForm.password?.trim() || undefined,
      };

      if (editingAdminId) {
        await api.put(`/settings/admins/${editingAdminId}`, payload);
        await refreshCurrentAdminSession(editingAdminId);
        setNotice({ tone: 'success', message: 'Administrator updated successfully.' });
      } else {
        await api.post('/settings/admins', payload);
        setNotice({ tone: 'success', message: 'Administrator created successfully.' });
      }

      closeAdminModal();
      if (activeTab === 'admins') {
        await fetchData();
      }
    } catch (err) {
      console.error('Failed to save admin', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to save administrator.') });
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteAdmin = async (adminId: string) => {
    if (!window.confirm('Are you sure you want to remove this administrator?')) {
      return;
    }

    try {
      await api.delete(`/settings/admins/${adminId}`);
      setNotice({ tone: 'success', message: 'Administrator deleted successfully.' });
      await fetchData();
    } catch (err) {
      console.error('Delete failed', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to delete administrator.') });
    }
  };

  const handleResetPassword = async (adminId: string) => {
    try {
      await api.post(`/settings/admins/${adminId}/reset-password`);
      setNotice({ tone: 'success', message: 'Password reset flow triggered successfully.' });
    } catch (err) {
      console.error('Reset failed', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to trigger password reset.') });
    }
  };

  const handleTerminateSessions = async (adminId: string) => {
    if (!window.confirm('Terminate all active sessions for this administrator?')) {
      return;
    }

    try {
      await api.post(`/settings/admins/${adminId}/sessions/terminate`);
      setNotice({ tone: 'success', message: 'Administrator sessions terminated successfully.' });
    } catch (err) {
      console.error('Terminate sessions failed', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to terminate admin sessions.') });
    }
  };

  const togglePermission = (permission: string) => {
    if (isEditingOwnSuperAdmin) {
      return;
    }

    setAdminForm((current) => ({
      ...current,
      permissions: current.permissions.includes(permission)
        ? current.permissions.filter((item) => item !== permission)
        : [...current.permissions, permission],
    }));
  };

  const handleRoleChange = (role: string) => {
    if (isEditingOwnSuperAdmin) {
      return;
    }

    setAdminForm((current) => ({
      ...current,
      role,
      permissions: useRoleDefaults ? roleDefaultPermissions[role] || [] : current.permissions,
    }));
  };

  const handleUseRoleDefaultsChange = (nextValue: boolean) => {
    if (isEditingOwnSuperAdmin) {
      setUseRoleDefaults(true);
      return;
    }

    setUseRoleDefaults(nextValue);
    if (nextValue) {
      setAdminForm((current) => ({
        ...current,
        permissions: roleDefaultPermissions[current.role] || [],
      }));
    }
  };

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ marginBottom: '2.5rem' }}>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>System Settings</h1>
          <p style={{ color: 'hsl(var(--muted-foreground))' }}>
            Global configuration, security controls, and administrator management.
          </p>
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

        <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          <div style={{ width: '240px', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            {tabs.map((tab) => {
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '1rem',
                    padding: '1rem',
                    borderRadius: 'var(--radius)',
                    background: isActive ? 'hsl(var(--secondary))' : 'transparent',
                    border: 'none',
                    color: isActive ? 'hsl(var(--primary))' : 'hsl(var(--muted-foreground))',
                    fontWeight: 600,
                    textAlign: 'left',
                    transition: '0.2s',
                  }}
                >
                  <tab.icon size={20} />
                  {tab.label}
                </button>
              );
            })}
          </div>

          <div style={{ flex: 1, minWidth: '320px' }}>
            <div className="glass-card" style={{ padding: '2rem' }}>
              {loading ? (
                <div style={{ padding: '3rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>Loading settings...</div>
              ) : (
                <>
                  {activeTab === 'general' && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '1rem', flexWrap: 'wrap' }}>
                        <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>General Configuration</h3>
                        {hasPermission(PERMISSIONS.settingsEdit) && (
                          <button
                            onClick={() => void handleSave()}
                            disabled={saving}
                            className="premium-gradient"
                            style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', border: 'none', color: 'white', padding: '0.6rem 1.25rem', fontWeight: 600, opacity: saving ? 0.7 : 1 }}
                          >
                            <Save size={18} /> Save Changes
                          </button>
                        )}
                      </div>

                      <div style={{ display: 'grid', gap: '1.5rem' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            <label style={{ fontSize: '0.875rem', fontWeight: 600 }}>Base URL</label>
                            <input
                              value={generalSettings.baseUrl}
                              onChange={(event) => setGeneralSettings({ ...generalSettings, baseUrl: event.target.value })}
                              disabled={!hasPermission(PERMISSIONS.settingsEdit)}
                              style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }}
                            />
                          </div>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            <label style={{ fontSize: '0.875rem', fontWeight: 600 }}>Firebase Project ID</label>
                            <input
                              value={generalSettings.firebaseProjectId}
                              onChange={(event) => setGeneralSettings({ ...generalSettings, firebaseProjectId: event.target.value })}
                              disabled={!hasPermission(PERMISSIONS.settingsEdit)}
                              style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }}
                            />
                          </div>
                        </div>

                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            <label style={{ fontSize: '0.875rem', fontWeight: 600 }}>API Version</label>
                            <input
                              value={generalSettings.apiVersion}
                              onChange={(event) => setGeneralSettings({ ...generalSettings, apiVersion: event.target.value })}
                              disabled={!hasPermission(PERMISSIONS.settingsEdit)}
                              style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }}
                            />
                          </div>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            <label style={{ fontSize: '0.875rem', fontWeight: 600 }}>Environment</label>
                            <input
                              value={generalSettings.environment}
                              onChange={(event) => setGeneralSettings({ ...generalSettings, environment: event.target.value })}
                              disabled={!hasPermission(PERMISSIONS.settingsEdit)}
                              style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }}
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  )}

                  {activeTab === 'security' && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '1rem', flexWrap: 'wrap' }}>
                        <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>Security Settings</h3>
                        {hasPermission(PERMISSIONS.settingsEdit) && (
                          <button
                            onClick={() => void handleSave()}
                            disabled={saving}
                            className="premium-gradient"
                            style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', border: 'none', color: 'white', padding: '0.6rem 1.25rem', fontWeight: 600, opacity: saving ? 0.7 : 1 }}
                          >
                            <Save size={18} /> Update Security
                          </button>
                        )}
                      </div>

                      <div style={{ display: 'grid', gap: '1.5rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', background: 'hsl(var(--secondary))', borderRadius: 'var(--radius)' }}>
                          <div>
                            <p style={{ fontWeight: 600 }}>Force 2FA</p>
                            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Require two-factor authentication for all admins.</p>
                          </div>
                          <input
                            type="checkbox"
                            checked={securitySettings.enforce2FA}
                            disabled={!hasPermission(PERMISSIONS.settingsEdit)}
                            onChange={(event) => setSecuritySettings({ ...securitySettings, enforce2FA: event.target.checked })}
                          />
                        </div>

                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                          <label style={{ fontSize: '0.875rem', fontWeight: 600 }}>Password Expiration (Days)</label>
                          <input
                            type="number"
                            min={1}
                            value={securitySettings.passwordExpirationDays}
                            disabled={!hasPermission(PERMISSIONS.settingsEdit)}
                            onChange={(event) => setSecuritySettings({ ...securitySettings, passwordExpirationDays: Number(event.target.value || 0) })}
                            style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }}
                          />
                        </div>
                      </div>
                    </div>
                  )}

                  {activeTab === 'admins' && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '1rem', flexWrap: 'wrap' }}>
                        <h3 style={{ fontSize: '1.25rem', fontWeight: 700 }}>Administrator Management</h3>
                        <button
                          onClick={openCreateAdmin}
                          className="premium-gradient"
                          style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', border: 'none', color: 'white', padding: '0.6rem 1.25rem', fontWeight: 600 }}
                        >
                          <Plus size={18} /> Add Admin
                        </button>
                      </div>

                      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        {admins.map((admin) => {
                          const isSelf = user?.adminId === admin.adminId;
                          const targetIsSuperAdmin = admin.role === 'super_admin';
                          const canManageAdmin = currentUserIsSuperAdmin || !targetIsSuperAdmin;

                          return (
                            <div key={admin.adminId} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', padding: '1rem', border: '1px solid hsl(var(--border))', borderRadius: 'var(--radius)', flexWrap: 'wrap' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'hsl(var(--secondary))', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700 }}>
                                  {admin.fullName?.[0] || admin.email?.[0] || '?'}
                                </div>
                                <div>
                                  <p style={{ fontWeight: 600 }}>{admin.fullName}</p>
                                  <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>
                                    {admin.email} | {admin.role}
                                  </p>
                                  <p style={{ fontSize: '0.75rem', color: admin.isActive ? '#10b981' : '#ef4444' }}>
                                    {admin.isActive ? 'Active' : 'Inactive'}
                                    {admin.lastLoginAt ? ` | Last login ${new Date(admin.lastLoginAt).toLocaleString()}` : ''}
                                    {isSelf ? ' | Current session' : ''}
                                  </p>
                                </div>
                              </div>
                              <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                                <button
                                  onClick={() => void openEditAdmin(admin.adminId)}
                                  disabled={!canManageAdmin}
                                  style={{ background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', padding: '0.55rem 0.85rem', borderRadius: 'var(--radius)', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '0.35rem', opacity: canManageAdmin ? 1 : 0.45 }}
                                >
                                  <Pencil size={14} /> Edit
                                </button>
                                <button
                                  onClick={() => void handleTerminateSessions(admin.adminId)}
                                  disabled={isSelf || !canManageAdmin}
                                  style={{ background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', padding: '0.55rem 0.85rem', borderRadius: 'var(--radius)', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '0.35rem', opacity: isSelf || !canManageAdmin ? 0.45 : 1 }}
                                >
                                  <LogOut size={14} /> Terminate Sessions
                                </button>
                                <button
                                  onClick={() => void handleResetPassword(admin.adminId)}
                                  disabled={isSelf || !canManageAdmin}
                                  style={{ background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', padding: '0.55rem 0.85rem', borderRadius: 'var(--radius)', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '0.35rem', opacity: isSelf || !canManageAdmin ? 0.45 : 1 }}
                                >
                                  <RefreshCcw size={14} /> Reset Password
                                </button>
                                <button
                                  onClick={() => void handleDeleteAdmin(admin.adminId)}
                                  disabled={isSelf || !canManageAdmin}
                                  style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', padding: '0.55rem 0.85rem', borderRadius: 'var(--radius)', color: '#ef4444', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '0.35rem', opacity: isSelf || !canManageAdmin ? 0.45 : 1 }}
                                >
                                  <Trash2 size={14} /> Delete
                                </button>
                              </div>
                            </div>
                          );
                        })}

                        {admins.length === 0 && (
                          <div style={{ padding: '3rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>No administrators found.</div>
                        )}
                      </div>
                    </div>
                  )}
                </>
              )}
            </div>
          </div>
        </div>

        {isAdminModalOpen && (
          <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.8)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
            <div className="glass-card" style={{ width: '100%', maxWidth: '760px', padding: '2rem' }}>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '1.5rem' }}>
                {editingAdminId ? 'Edit Administrator' : 'Add New Administrator'}
              </h2>

              {loadingAdminDetails ? (
                <div style={{ padding: '2rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))' }}>Loading administrator details...</div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                    <input placeholder="First Name" value={adminForm.firstName} onChange={(event) => setAdminForm({ ...adminForm, firstName: event.target.value })} style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'white' }} />
                    <input placeholder="Last Name" value={adminForm.lastName} onChange={(event) => setAdminForm({ ...adminForm, lastName: event.target.value })} style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'white' }} />
                  </div>

                  <input placeholder="Email" value={adminForm.email} onChange={(event) => setAdminForm({ ...adminForm, email: event.target.value })} style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'white' }} />
                  <input
                    type="password"
                    placeholder={editingAdminId ? "Password (leave blank to keep unchanged)" : "Password (optional, auto-generated if blank)"}
                    value={adminForm.password || ''}
                    onChange={(event) => setAdminForm({ ...adminForm, password: event.target.value })}
                    style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'white' }}
                  />
                  {!editingAdminId && !adminForm.password && (
                    <p style={{ fontSize: '0.8125rem', color: 'hsl(var(--muted-foreground))' }}>
                      A setup OTP will be emailed to the new administrator so they can complete their password creation flow securely.
                    </p>
                  )}

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                    {isEditingExistingSuperAdmin ? (
                      <select value={adminForm.role} disabled style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'white', opacity: 0.7 }}>
                        <option value="super_admin">Super Admin</option>
                      </select>
                    ) : (
                      <select value={adminForm.role} onChange={(event) => handleRoleChange(event.target.value)} disabled={isEditingOwnSuperAdmin} style={{ padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', color: 'white', opacity: isEditingOwnSuperAdmin ? 0.7 : 1 }}>
                        <option value="admin">Admin</option>
                        <option value="moderator">Moderator</option>
                        <option value="analyst">Analyst</option>
                      </select>
                    )}

                    <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.75rem 1rem', borderRadius: 'var(--radius)', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))' }}>
                      <input type="checkbox" checked={adminForm.isActive} disabled={isEditingOwnSuperAdmin} onChange={(event) => setAdminForm({ ...adminForm, isActive: event.target.checked })} />
                      Active Account
                    </label>
                  </div>

                  <div style={{ padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'rgba(255,255,255,0.02)' }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem', fontWeight: 600 }}>
                      <input type="checkbox" checked={useRoleDefaults || isEditingOwnSuperAdmin} disabled={isEditingOwnSuperAdmin} onChange={(event) => handleUseRoleDefaultsChange(event.target.checked)} />
                      Use role default permissions
                    </label>

                    <p style={{ fontSize: '0.8rem', color: 'hsl(var(--muted-foreground))', marginBottom: useRoleDefaults ? 0 : '0.75rem' }}>
                      {isEditingOwnSuperAdmin
                        ? 'Your own super admin account always keeps the full default permission set.'
                        : useRoleDefaults
                        ? `This ${adminForm.role} account will use ${normalizePermissions(roleDefaultPermissions[adminForm.role] || []).length} default permissions.`
                        : 'Custom permissions override the role defaults for this admin.'}
                    </p>

                    {!useRoleDefaults && !isEditingOwnSuperAdmin && canManageSelectedSuperAdmin && (
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '0.75rem', maxHeight: '260px', overflowY: 'auto' }}>
                        {allPermissions.map((permission) => (
                          <label key={permission} style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', padding: '0.6rem 0.75rem', borderRadius: '10px', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))' }}>
                            <input
                              type="checkbox"
                              checked={adminForm.permissions.includes(permission)}
                              onChange={() => togglePermission(permission)}
                            />
                            <span style={{ fontSize: '0.8rem' }}>{permission}</span>
                          </label>
                        ))}
                      </div>
                    )}
                  </div>

                  <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                    <button onClick={closeAdminModal} style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'none', color: 'white' }}>
                      Cancel
                    </button>
                    <button onClick={() => void handleCreateOrUpdateAdmin()} className="premium-gradient" style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius)', border: 'none', color: 'white', fontWeight: 600, opacity: saving ? 0.7 : 1 }} disabled={saving}>
                      <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem' }}>
                        {editingAdminId ? <Pencil size={16} /> : <Lock size={16} />}
                        {editingAdminId ? 'Update Admin' : 'Create & Send Invite'}
                      </span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
