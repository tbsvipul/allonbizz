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
  const [step, setStep] = useState(1);

  const [form, setForm] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    businessName: '',
    businessLicense: '',
    
    identityProofType: 'Aadhaar Card',
    identityProofNumber: '',
    identityProofImage: null as File | null,

    businessLicenseNumber: '',
    businessLicenseImage: null as File | null,

    gstCertificateImage: null as File | null,

    panCardImage: null as File | null,

    addressProofType: 'Electricity Bill',
    addressProofImage: null as File | null,

    shopFrontImage: null as File | null,
    shopInsideImage: null as File | null,
  });

  function updateField<Key extends keyof typeof form>(key: Key, value: typeof form[Key]) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  function handleFileChange(key: keyof typeof form, files: FileList | null) {
    if (files && files.length > 0) {
      updateField(key, files[0]);
    }
  }

  function validateStep(currentStep: number): boolean {
    if (currentStep === 1) {
      if (!form.firstName.trim()) { setError('First name is required'); return false; }
      if (!form.lastName.trim()) { setError('Last name is required'); return false; }
      if (!form.email.trim()) { setError('Email is required'); return false; }
      if (!form.password || form.password.length < 8) { setError('Password must be at least 8 characters'); return false; }
    } else if (currentStep === 2) {
      if (!form.businessName.trim()) { setError('Business name is required'); return false; }
      if (form.businessLicenseNumber && !form.businessLicenseImage) {
        setError('Please upload the Business License Image when Business License Number is provided');
        return false;
      }
    } else if (currentStep === 3) {
      if (form.identityProofNumber && !form.identityProofImage) {
        setError('Please upload the Identity Proof Image when Identity Proof Number is provided');
        return false;
      }
      if (form.addressProofImage && !form.addressProofType) {
        setError('Please select Address Proof Type');
        return false;
      }
    }
    setError('');
    return true;
  }

  function nextStep() {
    if (validateStep(step)) {
      setStep((s) => s + 1);
    }
  }

  function prevStep() {
    setError('');
    setStep((s) => s - 1);
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!validateStep(step)) return;

    setLoading(true);
    setError('');

    try {
      const formData = new FormData();
      formData.append('firstName', form.firstName.trim());
      formData.append('lastName', form.lastName.trim());
      formData.append('email', form.email.trim());
      formData.append('password', form.password);
      formData.append('businessName', form.businessName.trim());
      
      if (form.businessLicense) {
        formData.append('businessLicense', form.businessLicense.trim());
      }
      
      if (form.identityProofType) {
        formData.append('identityProofType', form.identityProofType);
      }
      if (form.identityProofNumber) {
        formData.append('identityProofNumber', form.identityProofNumber.trim());
      }
      if (form.identityProofImage) {
        formData.append('identityProofImage', form.identityProofImage);
      }

      if (form.businessLicenseNumber) {
        formData.append('businessLicenseNumber', form.businessLicenseNumber.trim());
      }
      if (form.businessLicenseImage) {
        formData.append('businessLicenseImage', form.businessLicenseImage);
      }

      if (form.gstCertificateImage) {
        formData.append('gstCertificateImage', form.gstCertificateImage);
      }

      if (form.panCardImage) {
        formData.append('panCardImage', form.panCardImage);
      }

      if (form.addressProofType) {
        formData.append('addressProofType', form.addressProofType);
      }
      if (form.addressProofImage) {
        formData.append('addressProofImage', form.addressProofImage);
      }

      if (form.shopFrontImage) {
        formData.append('shopFrontImage', form.shopFrontImage);
      }

      if (form.shopInsideImage) {
        formData.append('shopInsideImage', form.shopInsideImage);
      }

      const response = await api.post('/auth/register-keeper', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      const payload = unwrapApiData<{
        accessToken: string;
        refreshToken: string;
      }>(response);

      await login(payload.accessToken, payload.refreshToken);
      showToast('Keeper account created successfully.', 'success');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to create the keeper account.'));
    } finally {
      setLoading(false);
    }
  }

  // File Upload Helper Component
  const FileUploadField = ({ 
    id, 
    label, 
    value, 
    onChange 
  }: { 
    id: string; 
    label: string; 
    value: File | null; 
    onChange: (files: FileList | null) => void 
  }) => (
    <div className="field">
      <label>{label}</label>
      <div 
        className="upload-dropzone" 
        style={{
          border: '2px dashed var(--border)',
          borderRadius: 'var(--radius-md)',
          padding: '1.25rem',
          textAlign: 'center',
          background: 'var(--field-bg)',
          cursor: 'pointer',
          transition: 'all 0.2s ease',
          position: 'relative'
        }}
      >
        <input 
          id={id}
          type="file" 
          accept="image/*"
          onChange={(e) => onChange(e.target.files)}
          style={{
            position: 'absolute',
            inset: 0,
            opacity: 0,
            cursor: 'pointer'
          }}
        />
        {value ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.25rem' }}>
            <span style={{ color: 'var(--success)', fontWeight: 'bold', fontSize: '0.85rem' }}>✓ Selected</span>
            <span className="tiny-text muted-text" style={{ wordBreak: 'break-all' }}>{value.name}</span>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.25rem' }}>
            <svg 
              width="24" 
              height="24" 
              viewBox="0 0 24 24" 
              fill="none" 
              stroke="var(--text-muted)" 
              strokeWidth="2" 
              strokeLinecap="round" 
              strokeLinejoin="round"
            >
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="17 8 12 3 7 8" />
              <line x1="12" y1="3" x2="12" y2="15" />
            </svg>
            <span className="tiny-text muted-text">Click or drag image file</span>
          </div>
        )}
      </div>
    </div>
  );

  return (
    <div className="auth-grid">
      <AuthHero
        eyebrow="Merchant Onboarding"
        title="Open your keeper portal and start managing offers fast."
        description="Create the business account, complete the core business details, and keep operating updates in one place while approval is in progress."
        points={[
          'Register one keeper account per business owner email.',
          'Upload required Identity Proof & Address Proof.',
          'Verify Business License & Tax Certificate.',
          'Upload Shop Front & Inside Images to gain customer trust.',
        ]}
      />

      <section className="auth-card" style={{ maxHeight: '90vh', overflowY: 'auto' }}>
        <div style={{ display: 'grid', gap: '0.45rem' }}>
          <h2>Register as Keeper</h2>
          <p className="muted-text">Step {step} of 4: {
            step === 1 ? 'Owner Info' :
            step === 2 ? 'Business Details' :
            step === 3 ? 'Identity & Address' : 'Taxes & Shop Images'
          }</p>
          
          {/* Stepped Progress Bar */}
          <div style={{ display: 'flex', gap: '0.4rem', marginTop: '0.5rem', marginBottom: '0.5rem' }}>
            {[1, 2, 3, 4].map((i) => (
              <div 
                key={i} 
                style={{
                  flex: 1,
                  height: '6px',
                  borderRadius: '3px',
                  background: i <= step ? 'linear-gradient(90deg, var(--accent) 0%, var(--accent-alt) 100%)' : 'var(--border)',
                  transition: 'background 0.3s ease'
                }}
              />
            ))}
          </div>
        </div>

        {error ? <InlineNotice tone="error" message={error} /> : null}

        <form className="form-stack" onSubmit={(e) => e.preventDefault()}>
          {step === 1 && (
            <div className="field-stack">
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
            </div>
          )}

          {step === 2 && (
            <div className="field-stack">
              <div className="field">
                <label htmlFor="businessName">Business name</label>
                <input id="businessName" value={form.businessName} onChange={(event) => updateField('businessName', event.target.value)} required />
              </div>

              <div className="field">
                <label htmlFor="businessLicense">Business license name</label>
                <input id="businessLicense" value={form.businessLicense} onChange={(event) => updateField('businessLicense', event.target.value)} />
              </div>

              <div className="field-grid">
                <div className="field">
                  <label htmlFor="businessLicenseNumber">License number</label>
                  <input id="businessLicenseNumber" value={form.businessLicenseNumber} onChange={(event) => updateField('businessLicenseNumber', event.target.value)} />
                </div>
                <FileUploadField 
                  id="businessLicenseImage" 
                  label="License certificate" 
                  value={form.businessLicenseImage} 
                  onChange={(files) => handleFileChange('businessLicenseImage', files)} 
                />
              </div>
            </div>
          )}

          {step === 3 && (
            <div className="field-stack">
              <div className="field-grid">
                <div className="field">
                  <label htmlFor="identityProofType">Identity proof type</label>
                  <select id="identityProofType" value={form.identityProofType} onChange={(event) => updateField('identityProofType', event.target.value)}>
                    <option value="Aadhaar Card">Aadhaar Card</option>
                    <option value="Passport">Passport</option>
                    <option value="Driver's License">Driver's License</option>
                    <option value="Voter ID">Voter ID</option>
                  </select>
                </div>
                <div className="field">
                  <label htmlFor="identityProofNumber">Identity number</label>
                  <input id="identityProofNumber" value={form.identityProofNumber} onChange={(event) => updateField('identityProofNumber', event.target.value)} />
                </div>
              </div>
              
              <FileUploadField 
                id="identityProofImage" 
                label="Identity proof image" 
                value={form.identityProofImage} 
                onChange={(files) => handleFileChange('identityProofImage', files)} 
              />

              <div className="field">
                <label htmlFor="addressProofType">Address proof type</label>
                <select id="addressProofType" value={form.addressProofType} onChange={(event) => updateField('addressProofType', event.target.value)}>
                  <option value="Electricity Bill">Electricity Bill</option>
                  <option value="Water Bill">Water Bill</option>
                  <option value="Rental Agreement">Rental Agreement</option>
                  <option value="Bank Statement">Bank Statement</option>
                </select>
              </div>

              <FileUploadField 
                id="addressProofImage" 
                label="Address proof image" 
                value={form.addressProofImage} 
                onChange={(files) => handleFileChange('addressProofImage', files)} 
              />
            </div>
          )}

          {step === 4 && (
            <div className="field-stack">
              <div className="field-grid">
                <FileUploadField 
                  id="gstCertificateImage" 
                  label="GST Certificate" 
                  value={form.gstCertificateImage} 
                  onChange={(files) => handleFileChange('gstCertificateImage', files)} 
                />
                <FileUploadField 
                  id="panCardImage" 
                  label="PAN Card Image" 
                  value={form.panCardImage} 
                  onChange={(files) => handleFileChange('panCardImage', files)} 
                />
              </div>

              <div className="field-grid">
                <FileUploadField 
                  id="shopFrontImage" 
                  label="Shop Front Image" 
                  value={form.shopFrontImage} 
                  onChange={(files) => handleFileChange('shopFrontImage', files)} 
                />
                <FileUploadField 
                  id="shopInsideImage" 
                  label="Shop Inside Image" 
                  value={form.shopInsideImage} 
                  onChange={(files) => handleFileChange('shopInsideImage', files)} 
                />
              </div>
            </div>
          )}

          {/* Form Action Buttons */}
          <div className="button-row" style={{ marginTop: '1.25rem' }}>
            {step > 1 && (
              <button type="button" className="button-secondary" onClick={prevStep} style={{ flex: 1 }}>
                Back
              </button>
            )}
            
            {step < 4 ? (
              <button type="button" className="button" onClick={nextStep} style={{ flex: 2 }}>
                Next Step
              </button>
            ) : (
              <button type="button" className="button" onClick={(e) => handleSubmit(e as any)} disabled={loading} style={{ flex: 2 }}>
                {loading ? 'Submitting registration...' : 'Submit & Register'}
              </button>
            )}
          </div>
        </form>

        <div className="button-row" style={{ justifyContent: 'space-between', marginTop: '0.75rem' }}>
          <p className="muted-text tiny-text">Already registered?</p>
          <Link className="button-ghost" href="/login">
            Sign in instead
          </Link>
        </div>
      </section>
    </div>
  );
}
