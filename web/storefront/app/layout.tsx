import type { Metadata } from 'next';
import './globals.css';
import { CartProvider } from '@/context/CartContext';
import Navbar from '@/components/Navbar';

export const metadata: Metadata = {
  title: 'Quickopia — Supermarket Delivery & Click & Collect in Dar es Salaam',
  description:
    'Order fresh groceries, drinks, household goods, and supermarket essentials delivered in 30-60 minutes or Click & Collect in Dar es Salaam.',
  keywords: [
    'Quickopia',
    'supermarket Dar es Salaam',
    'online grocery Tanzania',
    'chakula',
    'sukari',
    'unga',
    'doorstep delivery',
    'Click & Collect',
  ],
  openGraph: {
    title: 'Quickopia — Supermarket Delivery & Click & Collect',
    description:
      'Order fresh groceries, pantry staples, and household essentials delivered in 30-60 minutes in Dar es Salaam.',
    siteName: 'Quickopia',
    locale: 'en_TZ',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Quickopia — Supermarket Online Tanzania',
    description:
      'Fast doorstep grocery delivery and Click & Collect in Dar es Salaam.',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-gray-50 text-gray-900 antialiased min-h-screen flex flex-col">
        <CartProvider>
          <Navbar />
          <div className="flex-1">{children}</div>
          <footer className="bg-white border-t border-gray-200 py-8 px-4 text-center text-xs text-gray-500">
            <p className="font-semibold text-quickopia-navy text-sm mb-1">
              Quickopia Tanzania
            </p>
            <p>On-demand supermarket shopping &bull; Dar es Salaam</p>
            <p className="mt-2 text-gray-400">
              Prices in Tanzanian Shillings (TZS) &bull; Deliveries within Dar es Salaam
            </p>
          </footer>
        </CartProvider>
      </body>
    </html>
  );
}
