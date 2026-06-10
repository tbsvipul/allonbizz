'use client';

import React, { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { Plus, X, Check, XCircle, Hash, Upload, Tag as TagIcon, Store, Settings, Search } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { unwrapApiData } from '@/lib/api-response';
import { getApiErrorMessage } from '@/lib/api-error';
import { PERMISSIONS } from '@/lib/permissions';
import CustomSelect from '@/components/CustomSelect';

interface Tag {
  tagId: string;
  name: string;
  type: string;
  color: string;
  iconData?: string | null;
  isActive: boolean;
  createdAt: string;
}

type Notice = {
  tone: 'success' | 'error';
  message: string;
} | null;

function isMediaValue(value?: string | null) {
  return !!value && (value.startsWith('data:') || value.startsWith('http'));
}

export default function TagsPage() {
  const { hasPermission } = useAuth();
  const [tags, setTags] = useState<Tag[]>([]);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [currentTag, setCurrentTag] = useState<Tag | null>(null);
  const [notice, setNotice] = useState<Notice>(null);
  const [formData, setFormData] = useState({
    name: '',
    type: 'General',
    color: '#6366f1',
    iconData: '',
    isActive: true,
  });

  const [currentPage, setCurrentPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const itemsPerPage = 12;

  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery]);

  const fetchTags = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/tags');
      setTags(unwrapApiData<Tag[]>(response) || []);
    } catch (err) {
      console.error('Failed to fetch tags', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to fetch tags.') });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchTags();
  }, []);

  const resetEditor = () => {
    setIsEditing(false);
    setCurrentTag(null);
    setFormData({
      name: '',
      type: 'General',
      color: '#6366f1',
      iconData: '',
      isActive: true,
    });
  };

  const handleSave = async () => {
    try {
      if (currentTag) {
        await api.put(`/admin/tags/${currentTag.tagId}`, formData);
        setNotice({ tone: 'success', message: 'Tag updated successfully.' });
      } else {
        await api.post('/admin/tags', formData);
        setNotice({ tone: 'success', message: 'Tag created successfully.' });
      }
      resetEditor();
      await fetchTags();
    } catch (err) {
      console.error('Save failed', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to save tag.') });
    }
  };

  const openEditor = (tag?: Tag) => {
    setCurrentTag(tag || null);
    setFormData({
      name: tag?.name || '',
      type: tag?.type || 'General',
      color: tag?.color || '#6366f1',
      iconData: tag?.iconData || '',
      isActive: tag?.isActive ?? true,
    });
    setIsEditing(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this tag?')) {
      return;
    }

    try {
      await api.delete(`/admin/tags/${id}`);
      setNotice({ tone: 'success', message: 'Tag deleted successfully.' });
      await fetchTags();
    } catch (err) {
      console.error('Delete failed', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to delete tag.') });
    }
  };

  const handleIconUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) {
      return;
    }

    const dataUrl = await new Promise<string>((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(String(reader.result || ''));
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });

    setFormData((current) => ({ ...current, iconData: dataUrl }));
  };

  const renderTagIcon = (tag: Pick<Tag, 'iconData' | 'color' | 'name'>) => {
    const iconSrc = tag.iconData || undefined;

    if (iconSrc && isMediaValue(iconSrc)) {
      // eslint-disable-next-line @next/next/no-img-element
      return <img src={iconSrc} alt={tag.name} style={{ width: '20px', height: '20px', objectFit: 'cover', borderRadius: '6px' }} />;
    }

    return <Hash size={20} />;
  };

  const canSaveTag = currentTag ? hasPermission(PERMISSIONS.tagsEdit) : hasPermission(PERMISSIONS.tagsCreate);

  const filteredTags = tags.filter((tag) => {
    const search = searchQuery.toLowerCase();
    const nameMatch = tag.name ? tag.name.toLowerCase().includes(search) : false;
    const typeMatch = tag.type ? tag.type.toLowerCase().includes(search) : false;
    return nameMatch || typeMatch;
  });
  const totalPages = Math.ceil(filteredTags.length / itemsPerPage);
  const currentTags = filteredTags.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem', gap: '1rem', flexWrap: 'wrap' }}>
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Tag Management</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))' }}>Manage offer and shop tags used for discovery and filtering.</p>
          </div>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <div style={{ position: 'relative' }}>
              <Search size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'hsl(var(--muted-foreground))' }} />
              <input 
                type="text" 
                placeholder="Search tags..." 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  padding: '0.75rem 1rem 0.75rem 2.8rem',
                  borderRadius: 'var(--radius)',
                  border: '1px solid hsl(var(--border))',
                  background: 'rgba(255,255,255,0.03)',
                  outline: 'none',
                  minWidth: '260px',
                  color: 'var(--foreground)'
                }}
              />
            </div>
            {hasPermission(PERMISSIONS.tagsCreate) && (
              <button onClick={() => openEditor()} className="premium-gradient" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', border: 'none', color: 'white', padding: '0.75rem 1.5rem', fontWeight: 600, borderRadius: 'var(--radius)' }}>
                <Plus size={18} />
                Add Tag
              </button>
            )}
          </div>
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

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1.5rem' }}>
          {currentTags.map((tag) => (
            <motion.div key={tag.tagId} layout className="glass-card" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: `${tag.color}15`, color: tag.color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    {renderTagIcon(tag)}
                  </div>
                  <div>
                    <h3 style={{ fontWeight: 700, fontSize: '1.125rem' }}>{tag.name}</h3>
                    <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>Type: {tag.type}</p>
                  </div>
                </div>
                <span
                  style={{
                    fontSize: '0.75rem',
                    fontWeight: 600,
                    color: tag.isActive ? '#10b981' : '#ef4444',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.25rem',
                  }}
                >
                  {tag.isActive ? <Check size={14} /> : <XCircle size={14} />}
                  {tag.isActive ? 'Active' : 'Hidden'}
                </span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid hsl(var(--border))', gap: '1rem' }}>
                <p style={{ fontSize: '0.7rem', color: 'hsl(var(--muted-foreground))' }}>Created {new Date(tag.createdAt).toLocaleDateString()}</p>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  {hasPermission(PERMISSIONS.tagsEdit) && (
                    <button onClick={() => openEditor(tag)} style={{ background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', padding: '0.55rem 0.95rem', borderRadius: 'var(--radius)', fontWeight: 700 }}>
                      Update
                    </button>
                  )}
                  {hasPermission(PERMISSIONS.tagsDelete) && (
                    <button onClick={() => void handleDelete(tag.tagId)} style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', padding: '0.55rem 0.95rem', borderRadius: 'var(--radius)', color: '#ef4444', fontWeight: 700 }}>
                      Delete
                    </button>
                  )}
                </div>
              </div>
            </motion.div>
          ))}

          {filteredTags.length === 0 && !loading && (
            <div className="flex-center glass-card" style={{ padding: '4rem', gridColumn: '1 / -1', textAlign: 'center' }}>
              <p style={{ color: 'hsl(var(--muted-foreground))' }}>
                {tags.length === 0 ? 'No tags found.' : 'No tags match your search query.'}
              </p>
            </div>
          )}

          {loading && (
            <div className="glass-card" style={{ padding: '3rem', textAlign: 'center', color: 'hsl(var(--muted-foreground))', gridColumn: '1 / -1' }}>
              Loading tags...
            </div>
          )}
        </div>

        {!loading && totalPages > 1 && (
          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', marginTop: '2rem', gap: '1rem' }}>
            <button
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              style={{ padding: '0.5rem 1rem', borderRadius: 'var(--radius)', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', fontWeight: 600, cursor: currentPage === 1 ? 'not-allowed' : 'pointer', opacity: currentPage === 1 ? 0.5 : 1, color: 'var(--foreground)' }}
            >
              Previous
            </button>
            <span style={{ fontSize: '0.875rem', fontWeight: 600, color: 'var(--foreground)' }}>
              Page {currentPage} of {totalPages}
            </span>
            <button
              onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
              style={{ padding: '0.5rem 1rem', borderRadius: 'var(--radius)', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', fontWeight: 600, cursor: currentPage === totalPages ? 'not-allowed' : 'pointer', opacity: currentPage === totalPages ? 0.5 : 1, color: 'var(--foreground)' }}
            >
              Next
            </button>
          </div>
        )}

        <AnimatePresence>
          {isEditing && (
            <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.8)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className="glass-card"
                style={{ width: '100%', maxWidth: '520px', padding: '2.5rem', position: 'relative' }}
              >
                <button onClick={resetEditor} style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: 'none', border: 'none', color: 'hsl(var(--muted-foreground))' }}>
                  <X size={24} />
                </button>

                <h2 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1.5rem' }}>{currentTag ? 'Edit Tag' : 'Add New Tag'}</h2>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                  <div>
                    <label style={{ fontSize: '0.875rem', fontWeight: 600, display: 'block', marginBottom: '0.5rem' }}>Tag Name</label>
                    <input value={formData.name} onChange={(event) => setFormData({ ...formData, name: event.target.value })} placeholder="e.g. Sustainable, 24/7, Luxury" style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }} />
                  </div>

                  <div>
                    <label style={{ fontSize: '0.875rem', fontWeight: 600, display: 'block', marginBottom: '0.5rem' }}>Tag Type</label>
                    <CustomSelect
                      value={formData.type}
                      onChange={(val) => setFormData({ ...formData, type: val })}
                      options={[
                        { value: 'General', label: 'General', icon: <Hash size={16} /> },
                        { value: 'Offer', label: 'Offer Specific', icon: <TagIcon size={16} /> },
                        { value: 'Shop', label: 'Shop Specific', icon: <Store size={16} /> },
                        { value: 'System', label: 'System', icon: <Settings size={16} /> },
                      ]}
                      style={{ width: '100%' }}
                    />
                  </div>

                  <div>
                    <label style={{ fontSize: '0.875rem', fontWeight: 600, display: 'block', marginBottom: '0.5rem' }}>Display Color</label>
                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      <input type="color" value={formData.color} onChange={(event) => setFormData({ ...formData, color: event.target.value })} style={{ width: '40px', height: '40px', padding: 0, border: 'none', borderRadius: '4px', background: 'none' }} />
                      <input value={formData.color} onChange={(event) => setFormData({ ...formData, color: event.target.value })} style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }} />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: '0.75rem', alignItems: 'end' }}>
                    <div>
                      <label style={{ fontSize: '0.875rem', fontWeight: 600, display: 'block', marginBottom: '0.5rem' }}>Icon Data URL</label>
                      <input value={formData.iconData} onChange={(event) => setFormData({ ...formData, iconData: event.target.value })} placeholder="Paste a data URL or upload an image" style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }} />
                    </div>
                    <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1rem', borderRadius: 'var(--radius)', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', cursor: 'pointer', fontWeight: 600 }}>
                      <Upload size={16} />
                      Upload
                      <input type="file" accept="image/*" onChange={handleIconUpload} style={{ display: 'none' }} />
                    </label>
                  </div>

                  {isMediaValue(formData.iconData) && (
                    <div style={{ padding: '0.75rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={formData.iconData} alt="Tag icon preview" style={{ width: '48px', height: '48px', objectFit: 'cover', borderRadius: '10px' }} />
                    </div>
                  )}

                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <input type="checkbox" checked={formData.isActive} onChange={(event) => setFormData({ ...formData, isActive: event.target.checked })} style={{ width: '18px', height: '18px' }} />
                    <span style={{ fontSize: '0.875rem', fontWeight: 500 }}>Active (available for use)</span>
                  </div>

                  <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                    <button onClick={resetEditor} style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'none', fontWeight: 600 }}>
                      Cancel
                    </button>
                    <button onClick={() => void handleSave()} disabled={!canSaveTag} className="premium-gradient" style={{ flex: 2, padding: '0.75rem', borderRadius: 'var(--radius)', border: 'none', color: 'white', fontWeight: 600, opacity: canSaveTag ? 1 : 0.6 }}>
                      {currentTag ? 'Update Tag' : 'Create Tag'}
                    </button>
                  </div>
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>
      </div>
    </DashboardLayout>
  );
}
