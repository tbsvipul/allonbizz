'use client';

import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import { SectionCard } from '@/components/SectionCard';
import { LoyaltyEditor } from '@/features/loyalty/LoyaltyEditor';
import api from '@/lib/api';
import { formatDateTime } from '@/lib/format';
import { LoyaltyProgram, ShopSummary } from '@/lib/types';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { useAuth } from '@/context/AuthContext';

export default function LoyaltyPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [shops, setShops] = useState<ShopSummary[]>([]);
  const [selectedShopId, setSelectedShopId] = useState('');
  const [program, setProgram] = useState<LoyaltyProgram | null>(null);

  useEffect(() => {
    let active = true;

    async function loadShops() {
      setLoading(true);
      setError('');

      try {
        const response = await api.get('/keeper/shops');
        const nextShops = unwrapApiData<ShopSummary[]>(response);

        if (!active) {
          return;
        }

        setShops(nextShops);
        setSelectedShopId((current) => current || nextShops[0]?.id || '');
      } catch (err) {
        if (active) {
          setError(getApiErrorMessage(err, 'Unable to load shops for loyalty configuration.'));
        }
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    void loadShops();

    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    let active = true;

    async function loadProgram() {
      if (!selectedShopId) {
        setProgram(null);
        return;
      }

      try {
        const response = await api.get('/keeper/loyalty', {
          params: {
            shopId: selectedShopId,
          },
        });

        if (active) {
          setProgram(unwrapApiData<LoyaltyProgram>(response));
        }
      } catch (err) {
        if (active) {
          setError(getApiErrorMessage(err, 'Unable to load the loyalty program.'));
        }
      }
    }

    void loadProgram();

    return () => {
      active = false;
    };
  }, [selectedShopId]);

  async function handleSave(form: {
    isEnabled: boolean;
    programName: string;
    pointsPerRedemption: string;
    minimumPointsToRedeem: string;
    rewardDescription: string;
    termsAndConditions: string;
  }) {
    if (!selectedShopId) {
      setError('Choose a shop before saving loyalty settings.');
      return;
    }

    setSaving(true);
    setError('');

    try {
      const response = await api.put('/keeper/loyalty', {
        shopId: selectedShopId,
        isEnabled: form.isEnabled,
        programName: form.programName.trim() || null,
        pointsPerRedemption: Number(form.pointsPerRedemption || 0),
        minimumPointsToRedeem: Number(form.minimumPointsToRedeem || 0),
        rewardDescription: form.rewardDescription.trim() || null,
        termsAndConditions: form.termsAndConditions.trim() || null,
      });

      setProgram(unwrapApiData<LoyaltyProgram>(response));
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to save loyalty settings.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="field-stack">
      <PageHeader
        title="Loyalty"
        description="Configure the reward experience per shop and keep the points logic easy for customers to understand."
      />

      {error ? <InlineNotice tone="error" message={error} /> : null}

      {loading ? (
        <p className="muted-text">Loading loyalty configuration...</p>
      ) : shops.length === 0 ? (
        <EmptyState title="No shops available" message="Create a shop first so the loyalty program has a place to live." />
      ) : (
        <SectionCard title="Shop loyalty program" description="Choose the shop, set point rules, and define the customer reward.">
          <div className="field-stack">
            <div className="field" style={{ maxWidth: '320px' }}>
              <label htmlFor="loyaltyShop">Shop</label>
              <select id="loyaltyShop" value={selectedShopId} onChange={(event) => setSelectedShopId(event.target.value)}>
                {shops.map((shop) => (
                  <option key={shop.id} value={shop.id}>
                    {shop.name}
                  </option>
                ))}
              </select>
            </div>

            {program?.updatedAt ? (
              <p className="muted-text tiny-text">Last updated {formatDateTime(program.updatedAt)}</p>
            ) : null}

            <LoyaltyEditor
              key={selectedShopId || 'loyalty'}
              program={program}
              busy={saving}
              disabled={!user?.canManage}
              onSubmit={handleSave}
            />
          </div>
        </SectionCard>
      )}
    </div>
  );
}
