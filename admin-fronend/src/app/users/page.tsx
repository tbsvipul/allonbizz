'use client';

/* eslint-disable @next/next/no-img-element */

import React, { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import {
  Search,
  MoreVertical,
  UserX,
  UserCheck,
  Shield,
  ChevronLeft,
  ChevronRight,
  Mail,
  Calendar,
  Users,
  User,
  Store,
  CheckCircle2,
  XCircle,
  Clock,
  Filter,
  Ban
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { unwrapPagedResponse } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';
import CustomSelect from '@/components/CustomSelect';

interface User {
  userId: string;
  firstName: string;
  lastName: string;
  email: string;
  avatarUrl?: string | null;
  role: string;
  status: string;
  createdAt: string;
}

const menuButtonStyle: React.CSSProperties = {
  display: 'flex',
  alignItems: 'center',
  gap: '0.75rem',
  width: '100%',
  padding: '0.6rem 0.75rem',
  borderRadius: 'calc(var(--radius) - 2px)',
  fontSize: '0.875rem',
  fontWeight: 500,
  background: 'none',
  border: 'none',
  color: 'inherit',
  textAlign: 'left',
  cursor: 'pointer',
  transition: '0.2s',
};

export default function UsersPage() {
  const router = useRouter();
  const { hasPermission } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalUsers, setTotalUsers] = useState(0);
  const [activeMenu, setActiveMenu] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const navigateToUserProfile = (userId: string) => {
    router.push(`/users/${userId}`);
  };

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/users', {
        params: {
          search,
          page,
          pageSize: 10,
          role: roleFilter || undefined,
          status: statusFilter || undefined,
        },
      });

      const { data, pagination } = unwrapPagedResponse<User>(response);
      setUsers(data);
      setTotalPages(pagination?.totalPages || 1);
      setTotalUsers(pagination?.totalCount || 0);
    } catch (err) {
      console.error('Failed to fetch users', err);
      setError(getApiErrorMessage(err, 'Failed to fetch users.'));
    } finally {
      setLoading(false);
    }
  }, [page, roleFilter, search, statusFilter]);

  const handleStatusUpdate = async (userId: string, action: string) => {
    try {
      if (action === 'ban') {
        await api.post(`/users/${userId}/ban`, { reason: 'Administrative action', deleteContent: false });
      } else if (action === 'suspend') {
        await api.post(`/users/${userId}/suspend`, { reason: 'Administrative action', durationDays: 7 });
      } else if (action === 'unban') {
        await api.post(`/users/${userId}/unban`, {});
      } else if (action === 'unsuspend') {
        await api.post(`/users/${userId}/unsuspend`, {});
      } else if (action === 'active') {
        await api.put(`/users/${userId}/status`, { status: 'Active' });
      }

      await fetchUsers();
      setActiveMenu(null);
    } catch (err) {
      console.error('Status update failed', err);
      setError(getApiErrorMessage(err, 'Failed to update user status.'));
    }
  };

  useEffect(() => {
    void fetchUsers();
  }, [fetchUsers]);

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'active':
        return { bg: 'rgba(16, 185, 129, 0.1)', text: '#10b981' };
      case 'pending':
        return { bg: 'rgba(245, 158, 11, 0.1)', text: '#f59e0b' };
      case 'banned':
        return { bg: 'rgba(239, 68, 68, 0.1)', text: '#ef4444' };
      case 'suspended':
        return { bg: 'rgba(107, 114, 128, 0.1)', text: '#6b7280' };
      default:
        return { bg: 'rgba(99, 102, 241, 0.1)', text: '#6366f1' };
    }
  };

  const handleExport = async () => {
    try {
      const response = await api.get('/users/export', {
        params: { search, role: roleFilter, status: statusFilter },
        responseType: 'blob',
      });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `users-export-${new Date().getTime()}.csv`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (err) {
      console.error('Export failed', err);
      setError(getApiErrorMessage(err, 'Failed to export users.'));
    }
  };

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>User Management</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))' }}>
              Manage all platform users, their roles, and account statuses.
            </p>
          </div>
          <button
            onClick={handleExport}
            className="premium-gradient"
            style={{ border: 'none', color: 'white', padding: '0.75rem 1.5rem', fontWeight: 600, borderRadius: 'var(--radius)' }}
            disabled={!hasPermission(PERMISSIONS.usersExport)}
          >
            Export CSV
          </button>
        </div>

        <div className="glass-card" style={{ padding: '1.5rem', marginBottom: '2rem' }}>
          {error && (
            <div
              style={{
                marginBottom: '1rem',
                padding: '0.875rem 1rem',
                borderRadius: 'var(--radius)',
                background: 'rgba(239, 68, 68, 0.12)',
                color: '#ef4444',
                fontSize: '0.875rem',
                fontWeight: 600,
              }}
            >
              {error}
            </div>
          )}

          <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem', flexWrap: 'wrap' }}>
            <div style={{ position: 'relative', flex: 1, minWidth: '260px' }}>
              <Search
                size={18}
                style={{
                  position: 'absolute',
                  left: '1rem',
                  top: '50%',
                  transform: 'translateY(-50%)',
                  color: 'hsl(var(--muted-foreground))',
                }}
              />
              <input
                placeholder="Search by name, email or role..."
                value={search}
                onChange={(event) => {
                  setSearch(event.target.value);
                  setPage(1);
                }}
                style={{
                  width: '100%',
                  padding: '0.75rem 1rem 0.75rem 2.75rem',
                  borderRadius: 'var(--radius)',
                  border: '1px solid hsl(var(--border))',
                  background: 'hsl(var(--secondary))',
                  outline: 'none',
                }}
              />
            </div>
            <CustomSelect
              value={roleFilter}
              onChange={(val) => {
                setRoleFilter(val);
                setPage(1);
              }}
              options={[
                { value: '', label: 'All Roles', icon: <Users size={16} /> },
                { value: 'customer', label: 'Customer', icon: <User size={16} /> },
                { value: 'keeper', label: 'Keeper', icon: <Store size={16} /> },
              ]}
              style={{ minWidth: '160px' }}
            />
            <CustomSelect
              value={statusFilter}
              onChange={(val) => {
                setStatusFilter(val);
                setPage(1);
              }}
              options={[
                { value: '', label: 'All Status', icon: <Filter size={16} /> },
                { value: 'active', label: 'Active', icon: <CheckCircle2 size={16} />, color: '#10b981' },
                { value: 'inactive', label: 'Inactive', icon: <XCircle size={16} />, color: '#ef4444' },
                { value: 'suspended', label: 'Suspended', icon: <Clock size={16} />, color: '#f59e0b' },
                { value: 'banned', label: 'Banned', icon: <Ban size={16} />, color: '#dc2626' },
              ]}
              style={{ minWidth: '160px' }}
            />
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 0.5rem' }}>
              <thead>
                <tr style={{ textAlign: 'left', color: 'hsl(var(--muted-foreground))', fontSize: '0.875rem' }}>
                  <th style={{ padding: '1rem' }}>User</th>
                  <th style={{ padding: '1rem' }}>Role</th>
                  <th style={{ padding: '1rem' }}>Joined</th>
                  <th style={{ padding: '1rem' }}>Status</th>
                  <th style={{ padding: '1rem' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                <AnimatePresence mode="popLayout">
                  {users.map((user, index) => (
                    <motion.tr
                      key={user.userId}
                      onClick={() => navigateToUserProfile(user.userId)}
                      initial={{ opacity: 0, x: -10 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: 10 }}
                      transition={{ delay: index * 0.05 }}
                      style={{ background: 'rgba(255,255,255,0.03)', borderRadius: 'var(--radius)', cursor: 'pointer' }}
                    >
                      <td style={{ padding: '1rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                          <div
                            style={{
                              width: '40px',
                              height: '40px',
                              borderRadius: '50%',
                              background: 'hsl(var(--secondary))',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontWeight: 600,
                              overflow: 'hidden',
                            }}
                          >
                            {user.avatarUrl ? (
                              <img src={user.avatarUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                            ) : (
                              user.firstName?.[0] || user.email?.[0] || '?'
                            )}
                          </div>
                          <div>
                            <p style={{ fontWeight: 600, fontSize: '0.9375rem' }}>{`${user.firstName} ${user.lastName}`}</p>
                            <p
                              style={{
                                fontSize: '0.75rem',
                                color: 'hsl(var(--muted-foreground))',
                                display: 'flex',
                                alignItems: 'center',
                                gap: '0.25rem',
                              }}
                            >
                              <Mail size={12} /> {user.email}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '1rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <Shield size={16} style={{ color: user.role?.toLowerCase() === 'admin' ? 'hsl(var(--primary))' : 'inherit' }} />
                          <span style={{ fontSize: '0.875rem' }}>{user.role}</span>
                        </div>
                      </td>
                      <td style={{ padding: '1rem' }}>
                        <div style={{ fontSize: '0.875rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <Calendar size={16} color="hsl(var(--muted-foreground))" />
                          {new Date(user.createdAt).toLocaleDateString()}
                        </div>
                      </td>
                      <td style={{ padding: '1rem' }}>
                        <span
                          style={{
                            padding: '0.25rem 0.75rem',
                            borderRadius: '20px',
                            fontSize: '0.75rem',
                            fontWeight: 600,
                            ...getStatusColor(user.status),
                          }}
                        >
                          {user.status}
                        </span>
                      </td>
                      <td style={{ padding: '1rem', position: 'relative' }}>
                        <button
                          onClick={(event) => {
                            event.stopPropagation();
                            setActiveMenu(activeMenu === user.userId ? null : user.userId);
                          }}
                          style={{ background: 'none', border: 'none', color: 'hsl(var(--muted-foreground))' }}
                        >
                          <MoreVertical size={20} />
                        </button>

                        <AnimatePresence mode="wait">
                          {activeMenu === user.userId && (
                            <motion.div
                              initial={{ opacity: 0, scale: 0.95, y: -10 }}
                              animate={{ opacity: 1, scale: 1, y: 0 }}
                              exit={{ opacity: 0, scale: 0.95, y: -10 }}
                              className="glass-card"
                              style={{
                                position: 'absolute',
                                right: '100%',
                                top: '0',
                                zIndex: 100,
                                width: '180px',
                                padding: '0.5rem',
                                boxShadow: '0 10px 25px -5px rgba(0,0,0,0.3)',
                              }}
                            >
                              <button
                                onClick={(event) => {
                                  event.stopPropagation();
                                  navigateToUserProfile(user.userId);
                                  setActiveMenu(null);
                                }}
                                style={menuButtonStyle}
                              >
                                <Search size={16} /> View Profile
                              </button>
                              <div style={{ height: '1px', background: 'hsl(var(--border))', margin: '0.25rem 0' }} />
                              {hasPermission(PERMISSIONS.usersEdit) && (
                                <button
                                  onClick={(event) => {
                                    event.stopPropagation();
                                    void handleStatusUpdate(user.userId, 'active');
                                  }}
                                  style={menuButtonStyle}
                                >
                                  <UserCheck size={16} /> Activate
                                </button>
                              )}
                              {hasPermission(PERMISSIONS.usersSuspend) && (
                                <button
                                  onClick={(event) => {
                                    event.stopPropagation();
                                    void handleStatusUpdate(user.userId, 'suspend');
                                  }}
                                  style={menuButtonStyle}
                                >
                                  <Shield size={16} /> Suspend
                                </button>
                              )}
                              {hasPermission(PERMISSIONS.usersBan) && (
                                <button
                                  onClick={(event) => {
                                    event.stopPropagation();
                                    void handleStatusUpdate(user.userId, 'ban');
                                  }}
                                  style={{ ...menuButtonStyle, color: '#ef4444' }}
                                >
                                  <UserX size={16} /> Ban User
                                </button>
                              )}
                              {user.status === 'Banned' && hasPermission(PERMISSIONS.usersBan) && (
                                <button
                                  onClick={(event) => {
                                    event.stopPropagation();
                                    void handleStatusUpdate(user.userId, 'unban');
                                  }}
                                  style={menuButtonStyle}
                                >
                                  Unban
                                </button>
                              )}
                              {user.status === 'Suspended' && hasPermission(PERMISSIONS.usersSuspend) && (
                                <button
                                  onClick={(event) => {
                                    event.stopPropagation();
                                    void handleStatusUpdate(user.userId, 'unsuspend');
                                  }}
                                  style={menuButtonStyle}
                                >
                                  Unsuspend
                                </button>
                              )}
                            </motion.div>
                          )}
                        </AnimatePresence>
                      </td>
                    </motion.tr>
                  ))}
                </AnimatePresence>
              </tbody>
            </table>
          </div>

          {!loading && users.length === 0 && (
            <div
              style={{
                padding: '2rem',
                marginTop: '1rem',
                borderRadius: 'var(--radius)',
                background: 'rgba(255,255,255,0.03)',
                textAlign: 'center',
                color: 'hsl(var(--muted-foreground))',
              }}
            >
              No users matched the current filters.
            </div>
          )}

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '1.5rem', padding: '0 1rem' }}>
            <p style={{ fontSize: '0.875rem', color: 'hsl(var(--muted-foreground))' }}>
              Showing {users.length} of {totalUsers} users
            </p>
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button
                onClick={() => setPage((current) => Math.max(1, current - 1))}
                disabled={page === 1}
                style={{ background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', padding: '0.5rem', borderRadius: 'var(--radius)' }}
              >
                <ChevronLeft size={18} />
              </button>
              <button
                onClick={() => setPage((current) => current + 1)}
                disabled={page === totalPages}
                style={{ background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', padding: '0.5rem', borderRadius: 'var(--radius)' }}
              >
                <ChevronRight size={18} />
              </button>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
