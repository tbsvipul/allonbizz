'use client';

import React, { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import {
  FolderTree,
  Plus,
  Edit2,
  Trash2,
  RefreshCw,
  ChevronRight,
  ChevronDown,
  XCircle,
  X,
  Upload,
  Check
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import api from '@/lib/api';
import { getApiErrorMessage } from '@/lib/api-error';
import { unwrapApiData } from '@/lib/api-response';
import { PERMISSIONS } from '@/lib/permissions';
import CustomSelect from '@/components/CustomSelect';

interface Category {
  categoryId: string;
  name: string;
  icon?: string;
  color?: string;
  description?: string;
  parentCategoryId?: string | null;
  businessCount?: number;
  isActive: boolean;
  children?: Category[];
}

type Notice = {
  tone: 'success' | 'error';
  message: string;
} | null;

function isMediaValue(value?: string | null) {
  return !!value && (value.startsWith('data:') || value.startsWith('http'));
}

export default function CategoriesPage() {
  const { hasPermission } = useAuth();
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});
  const [isEditing, setIsEditing] = useState(false);
  const [currentCat, setCurrentCat] = useState<Category | null>(null);
  const [notice, setNotice] = useState<Notice>(null);
  const [formData, setFormData] = useState({
    name: '',
    icon: 'folder',
    color: '#6366f1',
    description: '',
    isActive: true,
    parentCategoryId: null as string | null,
  });

  const fetchCategories = async () => {
    setLoading(true);
    try {
      const response = await api.get('/admin/categories');
      setCategories(unwrapApiData<Category[]>(response) || []);
    } catch (err) {
      console.error('Failed to fetch categories', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to fetch categories.') });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchCategories();
  }, []);

  const handleSave = async () => {
    if (!formData.name.trim()) return;

    try {
      if (currentCat) {
        await api.put(`/admin/categories/${currentCat.categoryId}`, formData);
        setNotice({ tone: 'success', message: 'Category updated successfully.' });
      } else {
        await api.post('/admin/categories', formData);
        setNotice({ tone: 'success', message: 'Category created successfully.' });
      }
      setIsEditing(false);
      setCurrentCat(null);
      await fetchCategories();
    } catch (err) {
      console.error('Save failed', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to save category.') });
    }
  };

  const openEditor = (cat?: Category) => {
    setCurrentCat(cat || null);
    setFormData({
      name: cat?.name || '',
      icon: cat?.icon || 'folder',
      color: cat?.color || '#6366f1',
      description: cat?.description || '',
      isActive: cat?.isActive ?? true,
      parentCategoryId: cat?.parentCategoryId || null,
    });
    setIsEditing(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this category?')) return;
    try {
      await api.delete(`/admin/categories/${id}`);
      setNotice({ tone: 'success', message: 'Category deleted successfully.' });
      await fetchCategories();
    } catch (err) {
      console.error('Delete failed', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to delete category.') });
    }
  };

  const handleSync = async () => {
    setSyncing(true);
    try {
      await api.post('/admin/categories/sync-firestore');
      setNotice({ tone: 'success', message: 'Categories synced successfully.' });
    } catch (err) {
      console.error('Sync failed', err);
      setNotice({ tone: 'error', message: getApiErrorMessage(err, 'Failed to sync categories.') });
    } finally {
      setSyncing(false);
    }
  };

  const toggleExpand = (id: string) => {
    setExpanded((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  const handleIconUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const dataUrl = await new Promise<string>((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(String(reader.result || ''));
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });

    setFormData((current) => ({ ...current, icon: dataUrl }));
  };

  const renderCategoryIcon = (cat: Pick<Category, 'icon' | 'color' | 'name'>) => {
    if (isMediaValue(cat.icon)) {
      // eslint-disable-next-line @next/next/no-img-element
      return <img src={cat.icon} alt={cat.name} style={{ width: '20px', height: '20px', objectFit: 'cover', borderRadius: '6px' }} />;
    }

    return <FolderTree size={16} color={cat.color || 'currentColor'} />;
  };

  const renderCategoryRow = (cat: Category, level = 0) => (
    <React.Fragment key={cat.categoryId}>
      <motion.div
        layout
        className="glass-card"
        style={{
          padding: '1rem',
          marginLeft: `${level * 2}rem`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '0.5rem',
          background: level > 0 ? 'rgba(255,255,255,0.02)' : 'rgba(255,255,255,0.05)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          {cat.children && cat.children.length > 0 ? (
            <button onClick={() => toggleExpand(cat.categoryId)} style={{ background: 'none', border: 'none', color: 'inherit' }}>
              {expanded[cat.categoryId] ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
            </button>
          ) : (
            <div style={{ width: '18px' }} />
          )}
          <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'hsl(var(--secondary))', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {renderCategoryIcon(cat)}
          </div>
          <div>
            <p style={{ fontWeight: 600 }}>{cat.name}</p>
            <p style={{ fontSize: '0.75rem', color: 'hsl(var(--muted-foreground))' }}>{cat.businessCount || 0} items</p>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <span
            style={{
              fontSize: '0.75rem',
              fontWeight: 600,
              color: cat.isActive ? '#10b981' : '#ef4444',
              display: 'flex',
              alignItems: 'center',
              gap: '0.25rem',
            }}
          >
            {cat.isActive ? <Check size={14} /> : <XCircle size={14} />}
            {cat.isActive ? 'Active' : 'Hidden'}
          </span>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            {hasPermission(PERMISSIONS.categoriesEdit) && (
              <button onClick={() => openEditor(cat)} style={{ background: 'hsl(var(--secondary))', border: 'none', padding: '0.5rem', borderRadius: 'var(--radius)' }}>
                <Edit2 size={16} />
              </button>
            )}
            {hasPermission(PERMISSIONS.categoriesDelete) && (
              <button onClick={() => handleDelete(cat.categoryId)} style={{ background: 'rgba(239, 68, 68, 0.1)', border: 'none', padding: '0.5rem', borderRadius: 'var(--radius)', color: '#ef4444' }}>
                <Trash2 size={16} />
              </button>
            )}
          </div>
        </div>
      </motion.div>
      <AnimatePresence>{expanded[cat.categoryId] && cat.children?.map((child) => renderCategoryRow(child, level + 1))}</AnimatePresence>
    </React.Fragment>
  );

  const flatCategories = categories.flatMap((category) => [category, ...(category.children || [])]);
  const canSaveCategory = currentCat ? hasPermission(PERMISSIONS.categoriesEdit) : hasPermission(PERMISSIONS.categoriesCreate);

  return (
    <DashboardLayout>
      <div className="animate-fade-in">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 700, marginBottom: '0.5rem' }}>Category Management</h1>
            <p style={{ color: 'hsl(var(--muted-foreground))' }}>Organize business types and sync them with the mobile app.</p>
          </div>
          <div style={{ display: 'flex', gap: '1rem' }}>
            {hasPermission(PERMISSIONS.categoriesEdit) && (
              <button
                onClick={handleSync}
                disabled={syncing}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  background: 'hsl(var(--secondary))',
                  border: '1px solid hsl(var(--border))',
                  padding: '0.75rem 1.25rem',
                  fontWeight: 600,
                }}
              >
                <RefreshCw size={18} className={syncing ? 'animate-spin' : ''} />
                {syncing ? 'Syncing...' : 'Sync to Firestore'}
              </button>
            )}
            {hasPermission(PERMISSIONS.categoriesCreate) && (
              <button onClick={() => openEditor()} className="premium-gradient" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', border: 'none', color: 'white', padding: '0.75rem 1.5rem', fontWeight: 600 }}>
                <Plus size={18} />
                Add Category
              </button>
            )}
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
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

          {categories.map((cat) => renderCategoryRow(cat))}
          {categories.length === 0 && !loading && (
            <div className="flex-center glass-card" style={{ padding: '4rem' }}>
              <p style={{ color: 'hsl(var(--muted-foreground))' }}>No categories found.</p>
            </div>
          )}
        </div>

        <AnimatePresence>
          {isEditing && (
            <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.8)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className="glass-card"
                style={{ width: '100%', maxWidth: '560px', padding: '2.5rem', position: 'relative' }}
              >
                <button onClick={() => setIsEditing(false)} style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: 'none', border: 'none', color: 'hsl(var(--muted-foreground))' }}>
                  <X size={24} />
                </button>

                <h2 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1.5rem' }}>{currentCat ? 'Edit Category' : 'Add New Category'}</h2>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                  <div>
                    <label style={{ fontSize: '0.875rem', fontWeight: 600, display: 'block', marginBottom: '0.5rem' }}>Category Name</label>
                    <input
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      placeholder="e.g. Restaurants, Specialty Coffee"
                      style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }}
                    />
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: '0.75rem', alignItems: 'end' }}>
                    <div>
                      <label style={{ fontSize: '0.875rem', fontWeight: 600, display: 'block', marginBottom: '0.5rem' }}>Icon Name or Data URL</label>
                      <input
                        value={formData.icon}
                        onChange={(e) => setFormData({ ...formData, icon: e.target.value })}
                        placeholder="e.g. shopping-bag, coffee, or uploaded image"
                        style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }}
                      />
                    </div>
                    <label style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1rem', borderRadius: 'var(--radius)', background: 'hsl(var(--secondary))', border: '1px solid hsl(var(--border))', cursor: 'pointer', fontWeight: 600 }}>
                      <Upload size={16} />
                      Upload
                      <input type="file" accept="image/*" onChange={handleIconUpload} style={{ display: 'none' }} />
                    </label>
                  </div>

                  {isMediaValue(formData.icon) && (
                    <div style={{ padding: '0.75rem', borderRadius: 'var(--radius)', background: 'rgba(255,255,255,0.03)', border: '1px solid hsl(var(--border))' }}>
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={formData.icon} alt="Category icon preview" style={{ width: '48px', height: '48px', objectFit: 'cover', borderRadius: '10px' }} />
                    </div>
                  )}

                  <div>
                    <label style={{ fontSize: '0.875rem', fontWeight: 600, display: 'block', marginBottom: '0.5rem' }}>Color Hex</label>
                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      <input type="color" value={formData.color} onChange={(e) => setFormData({ ...formData, color: e.target.value })} style={{ width: '40px', height: '40px', padding: 0, border: 'none', borderRadius: '4px', background: 'none' }} />
                      <input value={formData.color} onChange={(e) => setFormData({ ...formData, color: e.target.value })} placeholder="#000000" style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none' }} />
                    </div>
                  </div>

                  <div>
                    <label style={{ fontSize: '0.875rem', fontWeight: 600, display: 'block', marginBottom: '0.5rem' }}>Parent Category</label>
                    <CustomSelect
                      value={formData.parentCategoryId || ''}
                      onChange={(val) => setFormData({ ...formData, parentCategoryId: val || null })}
                      options={[
                        { value: '', label: 'Top-level category', icon: <FolderTree size={16} /> },
                        ...flatCategories
                          .filter((category) => category.categoryId !== currentCat?.categoryId)
                          .map((category) => ({
                            value: category.categoryId,
                            label: category.name,
                            icon: <FolderTree size={16} />
                          }))
                      ]}
                      style={{ width: '100%' }}
                    />
                  </div>

                  <div>
                    <label style={{ fontSize: '0.875rem', fontWeight: 600, display: 'block', marginBottom: '0.5rem' }}>Description</label>
                    <textarea
                      value={formData.description}
                      onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                      placeholder="Brief description..."
                      style={{ width: '100%', padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'hsl(var(--secondary))', outline: 'none', minHeight: '80px' }}
                    />
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <input type="checkbox" checked={formData.isActive} onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })} style={{ width: '18px', height: '18px' }} />
                    <span style={{ fontSize: '0.875rem', fontWeight: 500 }}>Visible on platform</span>
                  </div>

                  <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                    <button onClick={() => setIsEditing(false)} style={{ flex: 1, padding: '0.75rem', borderRadius: 'var(--radius)', border: '1px solid hsl(var(--border))', background: 'none', fontWeight: 600 }}>
                      Cancel
                    </button>
                    <button onClick={handleSave} disabled={!canSaveCategory} className="premium-gradient" style={{ flex: 2, padding: '0.75rem', borderRadius: 'var(--radius)', border: 'none', color: 'white', fontWeight: 600, opacity: canSaveCategory ? 1 : 0.6 }}>
                      {currentCat ? 'Update Category' : 'Create Category'}
                    </button>
                  </div>
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>
      </div>

      <style jsx>{`
        .animate-spin {
          animation: spin 1s linear infinite;
        }
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
    </DashboardLayout>
  );
}
