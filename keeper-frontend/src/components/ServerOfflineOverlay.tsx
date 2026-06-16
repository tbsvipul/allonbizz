'use client';

import React, { useState, useEffect } from 'react';
import { WifiOff, RefreshCw } from 'lucide-react';
import api from '@/lib/api';

export function ServerOfflineOverlay() {
  const [offline, setOffline] = useState(false);
  const [retrying, setRetrying] = useState(false);

  useEffect(() => {
    const handleStatus = (e: Event) => {
      const customEvent = e as CustomEvent;
      if (customEvent.detail === 'offline') {
        setOffline(true);
      } else if (customEvent.detail === 'online') {
        setOffline(false);
      }
    };

    window.addEventListener('server-status', handleStatus);
    return () => window.removeEventListener('server-status', handleStatus);
  }, []);

  const handleRetry = async () => {
    setRetrying(true);
    try {
      await api.get('/auth/ping', { timeout: 5000 });
      setOffline(false);
    } catch (e: any) {
      if (e.response && e.response.status < 502) {
        setOffline(false);
      }
    } finally {
      setRetrying(false);
    }
  };

  if (!offline) return null;

  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      width: '100vw',
      height: '100vh',
      backgroundColor: 'rgba(0, 0, 0, 0.7)',
      backdropFilter: 'blur(6px)',
      zIndex: 99999,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }}>
      <div style={{
        backgroundColor: 'var(--surface)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius-xl)',
        padding: '2.5rem',
        maxWidth: '450px',
        width: '90%',
        textAlign: 'center',
        boxShadow: 'var(--shadow)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: '1.5rem'
      }}>
        <div style={{
          width: '64px',
          height: '64px',
          borderRadius: '50%',
          backgroundColor: 'var(--danger-soft)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: 'var(--danger)'
        }}>
          <WifiOff size={32} />
        </div>
        
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 700, margin: '0 0 0.5rem', color: 'var(--text)' }}>
            Connection Lost
          </h2>
          <p style={{ margin: 0, color: 'var(--text-muted)', fontSize: '0.95rem', lineHeight: 1.5 }}>
            We cannot reach the server at this moment. Please check your internet connection or try again later.
          </p>
        </div>

        <button 
          onClick={handleRetry}
          disabled={retrying}
          className="button"
          style={{ width: '100%' }}
        >
          {retrying ? (
            <RefreshCw size={18} className="animate-spin" />
          ) : (
            <RefreshCw size={18} />
          )}
          {retrying ? 'Connecting...' : 'Retry Connection'}
        </button>
      </div>
    </div>
  );
}
