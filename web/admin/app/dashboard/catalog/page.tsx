'use client';

import { useState } from 'react';
import { ShoppingBag, Layers, Image as ImageIcon } from 'lucide-react';
import CategoryTable from '@/components/catalog/CategoryTable';
import ProductTable from '@/components/catalog/ProductTable';
import HeroBannersManager from '@/components/catalog/HeroBannersManager';

export default function CatalogPage() {
  const [tab, setTab] = useState<'products' | 'categories' | 'banners'>('products');

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h2 className="text-2xl font-black text-quickopia-navy">
            Catalog &amp; Storefront Hub
          </h2>
          <p className="text-xs text-gray-500 mt-1">
            Manage supermarket categories, products, stock levels, and active hero banners
          </p>
        </div>

        <div className="flex gap-1.5 bg-gray-200/80 p-1 rounded-xl w-fit">
          <TabBtn
            active={tab === 'products'}
            onClick={() => setTab('products')}
            label="Products"
            icon={<ShoppingBag className="w-3.5 h-3.5" />}
          />
          <TabBtn
            active={tab === 'categories'}
            onClick={() => setTab('categories')}
            label="Categories"
            icon={<Layers className="w-3.5 h-3.5" />}
          />
          <TabBtn
            active={tab === 'banners'}
            onClick={() => setTab('banners')}
            label="Hero Banners & Ads"
            icon={<ImageIcon className="w-3.5 h-3.5" />}
          />
        </div>
      </div>

      {tab === 'products' ? (
        <ProductTable />
      ) : tab === 'categories' ? (
        <CategoryTable />
      ) : (
        <HeroBannersManager />
      )}
    </div>
  );
}

function TabBtn({
  active,
  onClick,
  label,
  icon,
}: {
  active: boolean;
  onClick: () => void;
  label: string;
  icon: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`px-4 py-2 rounded-lg text-xs font-bold transition flex items-center gap-1.5 shadow-2xs ${
        active
          ? 'bg-quickopia-navy text-white shadow-sm'
          : 'text-gray-600 hover:text-gray-900 hover:bg-white/60'
      }`}
    >
      <span>{icon}</span>
      <span>{label}</span>
    </button>
  );
}
