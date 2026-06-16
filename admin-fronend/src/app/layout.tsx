import type { Metadata } from "next";
import { Providers } from "@/components/Providers";
import "./globals.css";
import { ServerOfflineOverlay } from '@/components/ServerOfflineOverlay';

export const metadata: Metadata = {
  title: "ROUTENT Admin | Premium Control Panel",
  description: "Next-gen admin dashboard for ROUTENT ecosystem",
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
