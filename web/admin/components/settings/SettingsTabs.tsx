'use client';

import { useState } from 'react';
import StoreProfileForm from './StoreProfileForm';
import DeliveryZonesManager from './DeliveryZonesManager';
import { Store, Fuel } from 'lucide-react';

export default function SettingsTabs() {
  const [activeTab, setActiveTab] = useState<'profile' | 'delivery'>('profile');

  return (
    <div className="space-y-6">
      <div className="flex bg-gray-200/80 p-1 rounded-xl max-w-md gap-1 text-xs font-bold">
        <button
          type="button"
          onClick={() => setActiveTab('profile')}
          className={`flex-1 py-2 px-3 rounded-lg transition flex items-center justify-center gap-1.5 ${
            activeTab === 'profile'
              ? 'bg-white text-quickopia-navy shadow-xs'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <Store className="w-3.5 h-3.5 text-quickopia-amber" />
          <span>Profile &amp; Storefront</span>
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('delivery')}
          className={`flex-1 py-2 px-3 rounded-lg transition flex items-center justify-center gap-1.5 ${
            activeTab === 'delivery'
              ? 'bg-white text-quickopia-navy shadow-xs'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <Fuel className="w-3.5 h-3.5 text-quickopia-amber" />
          <span>Delivery Zones &amp; Tariffs</span>
        </button>
      </div>

      {activeTab === 'profile' ? (
        <StoreProfileForm />
      ) : (
        <DeliveryZonesManager />
      )}
    </div>
  );
}
