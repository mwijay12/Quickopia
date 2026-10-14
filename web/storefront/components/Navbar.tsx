'use client';

import { useState } from 'react';
import { ShoppingBag } from 'lucide-react';
import { useCart } from '@/context/CartContext';
import CartDrawer from './CartDrawer';

import QuickopiaLogo from './ui/QuickopiaLogo';

export default function Navbar() {
  const { itemCount } = useCart();
  const [drawerOpen, setDrawerOpen] = useState(false);

  return (
    <>
      <nav className="sticky top-0 z-40 bg-quickopia-navy text-white px-4 py-3 flex items-center justify-between shadow-md">
        <QuickopiaLogo variant="light" size="md" />

        <button
          onClick={() => setDrawerOpen(true)}
          className="relative flex items-center gap-2 bg-quickopia-amber hover:bg-amber-400 text-black px-4 py-2 rounded-lg font-bold transition shadow-sm"
        >
          <ShoppingBag className="w-4 h-4" />
          <span>Cart</span>
          {itemCount > 0 && (
            <span className="absolute -top-2 -right-2 bg-red-600 text-white text-xs font-bold rounded-full h-5 w-5 flex items-center justify-center animate-pulse">
              {itemCount}
            </span>
          )}
        </button>
      </nav>
      <CartDrawer open={drawerOpen} onClose={() => setDrawerOpen(false)} />
    </>
  );
}
