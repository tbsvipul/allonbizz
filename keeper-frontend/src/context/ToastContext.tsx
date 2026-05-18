'use client';

import { createContext, useContext, useMemo, useState } from 'react';
import { CheckCircle2, CircleAlert, Info } from 'lucide-react';

type ToastTone = 'success' | 'error' | 'info';

interface ToastItem {
  id: string;
  message: string;
  tone: ToastTone;
}

interface ToastContextValue {
  showToast: (message: string, tone?: ToastTone) => void;
}

const ToastContext = createContext<ToastContextValue | undefined>(undefined);

function toneIcon(tone: ToastTone) {
  if (tone === 'success') {
    return <CheckCircle2 size={18} />;
  }

  if (tone === 'error') {
    return <CircleAlert size={18} />;
  }

  return <Info size={18} />;
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  const value = useMemo<ToastContextValue>(() => ({
    showToast(message, tone = 'info') {
      const id = `${Date.now()}-${Math.random()}`;
      setToasts((current) => [...current, { id, message, tone }]);

      window.setTimeout(() => {
        setToasts((current) => current.filter((item) => item.id !== id));
      }, 4200);
    },
  }), []);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="toast-viewport" aria-live="polite" aria-atomic="true">
        {toasts.map((toast) => (
          <div key={toast.id} className="toast-card" data-tone={toast.tone}>
            {toneIcon(toast.tone)}
            <p>{toast.message}</p>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used inside ToastProvider.');
  }

  return context;
}
