'use client';

import { FormEvent, useState } from 'react';
import { LoyaltyProgram } from '@/lib/types';

interface LoyaltyFormState {
  isEnabled: boolean;
  programName: string;
  pointsPerRedemption: string;
  minimumPointsToRedeem: string;
  rewardDescription: string;
  termsAndConditions: string;
}

function toFormState(program: LoyaltyProgram | null): LoyaltyFormState {
  return {
    isEnabled: program?.isEnabled ?? false,
    programName: program?.programName || '',
    pointsPerRedemption: String(program?.pointsPerRedemption ?? 1),
    minimumPointsToRedeem: String(program?.minimumPointsToRedeem ?? 0),
    rewardDescription: program?.rewardDescription || '',
    termsAndConditions: program?.termsAndConditions || '',
  };
}

export function LoyaltyEditor({
  program,
  busy,
  disabled,
  onSubmit,
}: {
  program: LoyaltyProgram | null;
  busy?: boolean;
  disabled?: boolean;
  onSubmit: (state: LoyaltyFormState) => Promise<void>;
}) {
  const [form, setForm] = useState<LoyaltyFormState>(() => toFormState(program));

  function updateField<Key extends keyof LoyaltyFormState>(key: Key, value: LoyaltyFormState[Key]) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await onSubmit(form);
  }

  return (
    <form className="form-stack" onSubmit={handleSubmit}>
      <label className="inline-row" style={{ alignItems: 'center' }}>
        <input
          type="checkbox"
          checked={form.isEnabled}
          onChange={(event) => updateField('isEnabled', event.target.checked)}
          disabled={disabled || busy}
        />
        <span>Program enabled</span>
      </label>

      <div className="field-grid">
        <div className="field">
          <label htmlFor="programName">Program name</label>
          <input
            id="programName"
            value={form.programName}
            onChange={(event) => updateField('programName', event.target.value)}
            disabled={disabled || busy}
          />
        </div>

        <div className="field">
          <label htmlFor="pointsPerRedemption">Points per redemption</label>
          <input
            id="pointsPerRedemption"
            type="number"
            min={0}
            value={form.pointsPerRedemption}
            onChange={(event) => updateField('pointsPerRedemption', event.target.value)}
            disabled={disabled || busy}
          />
        </div>
      </div>

      <div className="field">
        <label htmlFor="minimumPointsToRedeem">Minimum points to redeem</label>
        <input
          id="minimumPointsToRedeem"
          type="number"
          min={0}
          value={form.minimumPointsToRedeem}
          onChange={(event) => updateField('minimumPointsToRedeem', event.target.value)}
          disabled={disabled || busy}
        />
      </div>

      <div className="field">
        <label htmlFor="rewardDescription">Reward description</label>
        <textarea
          id="rewardDescription"
          value={form.rewardDescription}
          onChange={(event) => updateField('rewardDescription', event.target.value)}
          disabled={disabled || busy}
        />
      </div>

      <div className="field">
        <label htmlFor="termsAndConditions">Terms and conditions</label>
        <textarea
          id="termsAndConditions"
          value={form.termsAndConditions}
          onChange={(event) => updateField('termsAndConditions', event.target.value)}
          disabled={disabled || busy}
        />
      </div>

      <button type="submit" className="button" disabled={disabled || busy}>
        {busy ? 'Saving loyalty settings...' : 'Save loyalty program'}
      </button>
    </form>
  );
}
