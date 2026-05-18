import { CheckCircle2, CircleAlert, Info } from 'lucide-react';

type NoticeTone = 'success' | 'error' | 'info';

export function InlineNotice({
  tone,
  message,
}: {
  tone: NoticeTone;
  message: string;
}) {
  const Icon = tone === 'success' ? CheckCircle2 : tone === 'error' ? CircleAlert : Info;

  return (
    <div className={`notice notice-${tone}`}>
      <Icon size={18} />
      <p>{message}</p>
    </div>
  );
}
