'use client';

import { FormEvent, useState } from 'react';
import { EmptyState } from '@/components/EmptyState';
import { InlineNotice } from '@/components/InlineNotice';
import { PageHeader } from '@/components/PageHeader';
import { SectionCard } from '@/components/SectionCard';
import { StatusPill } from '@/components/StatusPill';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';
import api from '@/lib/api';
import { getApiErrorMessage, unwrapApiData } from '@/lib/api-response';
import { formatDateTime } from '@/lib/format';
import { KeeperDocument, ReviewMessagesReadResult } from '@/lib/types';

interface UserFormState {
  firstName: string;
  lastName: string;
  phoneNumber: string;
}

interface KeeperFormState {
  businessName: string;
  businessLicense: string;
  gstNumber: string;
  panNumber: string;
  contactPhone: string;
  socialLinksJson: string;
}

interface DocumentFormState {
  documentId: string | null;
  name: string;
  type: string;
  url: string;
}

const emptyDocumentForm: DocumentFormState = {
  documentId: null,
  name: '',
  type: 'Primary',
  url: '',
};

function PersonalProfileForm({
  initialState,
  email,
  busy,
  onSubmit,
}: {
  initialState: UserFormState;
  email: string;
  busy: boolean;
  onSubmit: (state: UserFormState) => Promise<void>;
}) {
  const [form, setForm] = useState(initialState);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await onSubmit(form);
  }

  return (
    <form className="form-stack" onSubmit={handleSubmit}>
      <div className="field-grid">
        <div className="field">
          <label htmlFor="firstName">First name</label>
          <input
            id="firstName"
            value={form.firstName}
            onChange={(event) => setForm((current) => ({ ...current, firstName: event.target.value }))}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="lastName">Last name</label>
          <input
            id="lastName"
            value={form.lastName}
            onChange={(event) => setForm((current) => ({ ...current, lastName: event.target.value }))}
            required
          />
        </div>
      </div>

      <div className="field-grid">
        <div className="field">
          <label htmlFor="profileEmail">Email</label>
          <input id="profileEmail" value={email} disabled />
        </div>
        <div className="field">
          <label htmlFor="profilePhone">Phone number</label>
          <input
            id="profilePhone"
            value={form.phoneNumber}
            onChange={(event) => setForm((current) => ({ ...current, phoneNumber: event.target.value }))}
          />
        </div>
      </div>

      <button type="submit" className="button" disabled={busy}>
        {busy ? 'Saving personal profile...' : 'Save personal profile'}
      </button>
    </form>
  );
}

function BusinessProfileForm({
  initialState,
  busy,
  onSubmit,
}: {
  initialState: KeeperFormState;
  busy: boolean;
  onSubmit: (state: KeeperFormState) => Promise<void>;
}) {
  const [form, setForm] = useState(initialState);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await onSubmit(form);
  }

  return (
    <form className="form-stack" onSubmit={handleSubmit}>
      <div className="field">
        <label htmlFor="businessName">Business name</label>
        <input
          id="businessName"
          value={form.businessName}
          onChange={(event) => setForm((current) => ({ ...current, businessName: event.target.value }))}
          required
        />
      </div>

      <div className="field-grid">
        <div className="field">
          <label htmlFor="businessLicense">Business license</label>
          <input
            id="businessLicense"
            value={form.businessLicense}
            onChange={(event) => setForm((current) => ({ ...current, businessLicense: event.target.value }))}
          />
        </div>
        <div className="field">
          <label htmlFor="contactPhone">Contact phone</label>
          <input
            id="contactPhone"
            value={form.contactPhone}
            onChange={(event) => setForm((current) => ({ ...current, contactPhone: event.target.value }))}
          />
        </div>
      </div>

      <div className="field-grid">
        <div className="field">
          <label htmlFor="gstNumber">GST number</label>
          <input
            id="gstNumber"
            value={form.gstNumber}
            onChange={(event) => setForm((current) => ({ ...current, gstNumber: event.target.value }))}
          />
        </div>
        <div className="field">
          <label htmlFor="panNumber">PAN number</label>
          <input
            id="panNumber"
            value={form.panNumber}
            onChange={(event) => setForm((current) => ({ ...current, panNumber: event.target.value }))}
          />
        </div>
      </div>

      <div className="field">
        <label htmlFor="socialLinksJson">Social links JSON</label>
        <textarea
          id="socialLinksJson"
          value={form.socialLinksJson}
          onChange={(event) => setForm((current) => ({ ...current, socialLinksJson: event.target.value }))}
        />
      </div>

      <button type="submit" className="button" disabled={busy}>
        {busy ? 'Saving business profile...' : 'Save business profile'}
      </button>
    </form>
  );
}

function normalizeStatusValue(status?: string | null) {
  return String(status || '').trim().toLowerCase();
}

function isResubmittedStatus(previousStatus?: string | null, nextStatus?: string | null) {
  const previous = normalizeStatusValue(previousStatus);
  const next = normalizeStatusValue(nextStatus);
  return (previous === 'onhold' || previous === 'rejected') && next === 'pendingapproval';
}

function formatMessageType(value: string) {
  return value
    .split(/[_-]+/)
    .filter(Boolean)
    .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
    .join(' ');
}

function getDocumentToneClass(status?: string | null) {
  const normalized = normalizeStatusValue(status);
  if (normalized === 'verified') {
    return 'mini-pill pill-success';
  }

  if (normalized === 'rejected') {
    return 'mini-pill pill-danger';
  }

  return 'mini-pill pill-warning';
}

function getDocumentStatusLabel(status?: string | null) {
  const normalized = normalizeStatusValue(status);
  if (normalized === 'verified') {
    return 'Verified';
  }

  if (normalized === 'rejected') {
    return 'Needs changes';
  }

  return 'Pending review';
}

export default function ProfilePage() {
  const { user, refreshUser } = useAuth();
  const { showToast } = useToast();
  const [error, setError] = useState('');
  const [savingUser, setSavingUser] = useState(false);
  const [savingKeeper, setSavingKeeper] = useState(false);
  const [savingDocument, setSavingDocument] = useState(false);
  const [deletingDocumentId, setDeletingDocumentId] = useState('');
  const [markingMessagesRead, setMarkingMessagesRead] = useState(false);
  const [documentForm, setDocumentForm] = useState<DocumentFormState>(emptyDocumentForm);

  if (!user) {
    return null;
  }

  const sessionUser = user;
  const userFormKey = [sessionUser.userId, sessionUser.firstName, sessionUser.lastName, sessionUser.phoneNumber || ''].join('|');
  const keeperFormKey = [
    sessionUser.keeper?.keeperId || 'keeper',
    sessionUser.keeper?.businessName || '',
    sessionUser.keeper?.businessLicense || '',
    sessionUser.keeper?.gstNumber || '',
    sessionUser.keeper?.panNumber || '',
    sessionUser.keeper?.contactPhone || '',
    sessionUser.keeper?.socialLinksJson || '',
  ].join('|');
  const unreadMessageCount = sessionUser.keeper?.reviewMessages?.filter((message) => !message.isReadByKeeper).length ?? 0;
  const editingDocument = Boolean(documentForm.documentId);

  function resetDocumentForm() {
    setDocumentForm(emptyDocumentForm);
  }

  function startDocumentEdit(document: KeeperDocument) {
    setDocumentForm({
      documentId: document.id,
      name: document.name,
      type: document.type,
      url: document.url,
    });
  }

  async function handleUserSave(form: UserFormState) {
    setSavingUser(true);
    setError('');

    try {
      await api.put('/user/profile', {
        firstName: form.firstName.trim(),
        lastName: form.lastName.trim(),
        phoneNumber: form.phoneNumber.trim() || null,
      });

      await refreshUser();
      showToast('Personal profile updated.', 'success');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to update the personal profile.'));
    } finally {
      setSavingUser(false);
    }
  }

  async function handleKeeperSave(form: KeeperFormState) {
    setSavingKeeper(true);
    setError('');

    try {
      const previousStatus = sessionUser.keeper?.status;
      await api.put('/keeper/profile', {
        businessName: form.businessName.trim(),
        businessLicense: form.businessLicense.trim() || null,
        gstNumber: form.gstNumber.trim() || null,
        panNumber: form.panNumber.trim() || null,
        contactPhone: form.contactPhone.trim() || null,
        socialLinksJson: form.socialLinksJson.trim() || null,
      });

      const nextUser = await refreshUser();
      showToast(
        isResubmittedStatus(previousStatus, nextUser?.keeper?.status)
          ? 'Business profile updated and sent back for admin review.'
          : 'Business profile updated.',
        'success',
      );
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to update the business profile.'));
    } finally {
      setSavingKeeper(false);
    }
  }

  async function handleDocumentSave(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSavingDocument(true);
    setError('');

    const payload = {
      name: documentForm.name.trim(),
      type: documentForm.type.trim(),
      url: documentForm.url.trim(),
    };

    if (!payload.name || !payload.type || !payload.url) {
      setSavingDocument(false);
      setError('Document name, type, and link are required.');
      return;
    }

    try {
      const previousStatus = sessionUser.keeper?.status;
      if (documentForm.documentId) {
        await api.put(`/keeper/document/${documentForm.documentId}`, payload);
      } else {
        await api.post('/keeper/document', payload);
      }

      const nextUser = await refreshUser();
      resetDocumentForm();
      showToast(
        isResubmittedStatus(previousStatus, nextUser?.keeper?.status)
          ? 'Document saved and the application moved back to pending review.'
          : documentForm.documentId
            ? 'Document updated.'
            : 'Document attached.',
        'success',
      );
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to save the document.'));
    } finally {
      setSavingDocument(false);
    }
  }

  async function handleDocumentDelete(document: KeeperDocument) {
    setDeletingDocumentId(document.id);
    setError('');

    try {
      await api.delete(`/keeper/document/${document.id}`);
      await refreshUser();
      if (documentForm.documentId === document.id) {
        resetDocumentForm();
      }
      showToast('Document removed.', 'success');
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to remove the document.'));
    } finally {
      setDeletingDocumentId('');
    }
  }

  async function handleMarkMessagesRead() {
    setMarkingMessagesRead(true);
    setError('');

    try {
      const response = await api.post('/keeper/profile/messages/read');
      const result = unwrapApiData<ReviewMessagesReadResult>(response);
      await refreshUser();
      showToast(
        result.updatedCount > 0 ? `Marked ${result.updatedCount} admin message${result.updatedCount === 1 ? '' : 's'} as read.` : 'All admin messages are already read.',
        'success',
      );
    } catch (err) {
      setError(getApiErrorMessage(err, 'Unable to update the admin message state.'));
    } finally {
      setMarkingMessagesRead(false);
    }
  }

  return (
    <div className="field-stack">
      <PageHeader
        title="Profile"
        description="Keep both the person-level contact details and the business review profile current."
        actions={<StatusPill status={sessionUser.keeper?.status} />}
      />

      {error ? <InlineNotice tone="error" message={error} /> : null}

      <div className="panel-grid">
        <SectionCard title="Personal identity" description="This data comes from the shared signed-in user profile.">
          <PersonalProfileForm
            key={userFormKey}
            initialState={{
              firstName: sessionUser.firstName || '',
              lastName: sessionUser.lastName || '',
              phoneNumber: sessionUser.phoneNumber || '',
            }}
            email={sessionUser.email}
            busy={savingUser}
            onSubmit={handleUserSave}
          />
        </SectionCard>

        <SectionCard title="Business review profile" description="These values drive admin review and keeper approval context.">
          <BusinessProfileForm
            key={keeperFormKey}
            initialState={{
              businessName: sessionUser.keeper?.businessName || '',
              businessLicense: sessionUser.keeper?.businessLicense || '',
              gstNumber: sessionUser.keeper?.gstNumber || '',
              panNumber: sessionUser.keeper?.panNumber || '',
              contactPhone: sessionUser.keeper?.contactPhone || '',
              socialLinksJson: sessionUser.keeper?.socialLinksJson || '',
            }}
            busy={savingKeeper}
            onSubmit={handleKeeperSave}
          />
        </SectionCard>
      </div>

      <div className="panel-grid">
        <SectionCard title="Application status" description="Read-only approval details from the keeper review workflow.">
          <div className="field-stack">
            <div className="list-item">
              <strong>Status</strong>
              <p className="muted-text tiny-text" style={{ marginTop: '0.35rem' }}>{sessionUser.keeper?.status || 'Unknown'}</p>
            </div>
            <div className="list-item">
              <strong>Approved at</strong>
              <p className="muted-text tiny-text" style={{ marginTop: '0.35rem' }}>{formatDateTime(sessionUser.keeper?.approvedAt)}</p>
            </div>
            <div className="list-item">
              <strong>Hold until</strong>
              <p className="muted-text tiny-text" style={{ marginTop: '0.35rem' }}>{formatDateTime(sessionUser.keeper?.holdUntil)}</p>
            </div>
            <div className="list-item">
              <strong>Review feedback</strong>
              <p className="muted-text tiny-text" style={{ marginTop: '0.35rem' }}>
                {sessionUser.keeper?.holdReason || sessionUser.keeper?.rejectionReason || 'No blocking feedback is attached right now.'}
              </p>
            </div>
          </div>
        </SectionCard>

        <SectionCard title="Documents" description="Attach or update the business document links used during admin verification.">
          <div className="field-stack">
            <form className="form-stack" onSubmit={handleDocumentSave}>
              <div className="field-grid">
                <div className="field">
                  <label htmlFor="documentName">Document name</label>
                  <input
                    id="documentName"
                    value={documentForm.name}
                    onChange={(event) => setDocumentForm((current) => ({ ...current, name: event.target.value }))}
                    placeholder="Trade license"
                    required
                  />
                </div>
                <div className="field">
                  <label htmlFor="documentType">Document type</label>
                  <input
                    id="documentType"
                    value={documentForm.type}
                    onChange={(event) => setDocumentForm((current) => ({ ...current, type: event.target.value }))}
                    placeholder="Primary"
                    required
                  />
                </div>
              </div>

              <div className="field">
                <label htmlFor="documentUrl">Document link or data URI</label>
                <textarea
                  id="documentUrl"
                  value={documentForm.url}
                  onChange={(event) => setDocumentForm((current) => ({ ...current, url: event.target.value }))}
                  placeholder="https://example.com/license.pdf"
                  required
                />
              </div>

              <div className="button-row">
                <button type="submit" className="button" disabled={savingDocument}>
                  {savingDocument ? 'Saving document...' : editingDocument ? 'Update document' : 'Attach document'}
                </button>
                {editingDocument ? (
                  <button type="button" className="button-secondary" onClick={resetDocumentForm} disabled={savingDocument}>
                    Cancel edit
                  </button>
                ) : null}
              </div>
            </form>

            {sessionUser.keeper?.documents?.length ? (
              <div className="document-list">
                {sessionUser.keeper.documents.map((document) => (
                  <div key={document.id} className="document-item">
                    <div className="inline-row" style={{ justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <div>
                        <strong>{document.name}</strong>
                        <p className="muted-text tiny-text" style={{ marginTop: '0.35rem' }}>{document.type}</p>
                      </div>
                      <span className={getDocumentToneClass(document.status)}>{getDocumentStatusLabel(document.status)}</span>
                    </div>

                    <div className="field-stack" style={{ gap: '0.45rem', marginTop: '0.8rem' }}>
                      <p className="muted-text tiny-text">
                        {document.reviewedAt ? `Reviewed ${formatDateTime(document.reviewedAt)}` : 'Awaiting admin review.'}
                      </p>
                      {document.reviewNotes ? (
                        <p className="muted-text tiny-text">{document.reviewNotes}</p>
                      ) : null}
                    </div>

                    <div className="button-row" style={{ marginTop: '0.85rem' }}>
                      <a className="button-secondary" href={document.url} target="_blank" rel="noreferrer">
                        Open document
                      </a>
                      <button type="button" className="button-ghost" onClick={() => startDocumentEdit(document)} disabled={savingDocument || deletingDocumentId === document.id}>
                        Edit
                      </button>
                      <button
                        type="button"
                        className="button-danger"
                        onClick={() => void handleDocumentDelete(document)}
                        disabled={savingDocument || deletingDocumentId === document.id}
                      >
                        {deletingDocumentId === document.id ? 'Removing...' : 'Delete'}
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <EmptyState title="No documents attached" message="Attach at least one business document so the admin review team can verify the application." />
            )}
          </div>
        </SectionCard>
      </div>

      <SectionCard
        title="Admin messages"
        description="Structured review history from the admin team."
        action={
          unreadMessageCount > 0 ? (
            <button type="button" className="button-secondary" onClick={() => void handleMarkMessagesRead()} disabled={markingMessagesRead}>
              {markingMessagesRead ? 'Marking...' : `Mark ${unreadMessageCount} unread as read`}
            </button>
          ) : undefined
        }
      >
        {sessionUser.keeper?.reviewMessages?.length ? (
          <div className="message-list">
            {sessionUser.keeper.reviewMessages.map((message) => (
              <div
                key={message.messageId}
                className="message-item"
                style={message.isReadByKeeper ? undefined : {
                  background: 'rgba(180, 83, 9, 0.08)',
                  borderColor: 'rgba(180, 83, 9, 0.16)',
                }}
              >
                <div className="inline-row" style={{ justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div className="inline-row" style={{ alignItems: 'center' }}>
                    <strong>{message.adminName}</strong>
                    <span className="mini-pill pill-muted">{formatMessageType(message.messageType)}</span>
                    {!message.isReadByKeeper ? <span className="mini-pill pill-warning">Unread</span> : null}
                  </div>
                  <span className="mini-pill pill-muted">{formatDateTime(message.createdAt)}</span>
                </div>
                <p className="muted-text tiny-text" style={{ marginTop: '0.45rem' }}>{message.message}</p>
              </div>
            ))}
          </div>
        ) : (
          <EmptyState title="No admin history yet" message="Request-for-info notes, hold notices, and related admin comments will show up here." />
        )}
      </SectionCard>
    </div>
  );
}
