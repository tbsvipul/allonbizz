import type { Metadata } from 'next';
import './globals.css';
import { Providers } from '@/components/Providers';
import { ServerOfflineOverlay } from '@/components/ServerOfflineOverlay';

export const metadata: Metadata = {
  title: 'Keeper Portal',
  description: 'Merchant workspace for managing shops, offers, reviews, and profile status.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body suppressHydrationWarning>
        <Providers>
          <ServerOfflineOverlay />
          {children}
        </Providers>
      </body>
    </html>
  );
}
