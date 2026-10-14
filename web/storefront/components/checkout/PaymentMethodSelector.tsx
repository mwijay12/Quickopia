'use client';

import type { Branch } from '@/lib/types';

export default function PaymentMethodSelector({
  value,
  onChange,
  branch,
}: {
  value: 'cod' | 'lipa_namba';
  onChange: (v: 'cod' | 'lipa_namba') => void;
  branch: Branch | null;
}) {
  return (
    <div className="space-y-2.5">
      {(['cod', 'lipa_namba'] as const).map((opt) => {
        const isSelected = value === opt;
        return (
          <label
            key={opt}
            className={`flex items-start gap-3 border rounded-xl p-3.5 cursor-pointer transition ${
              isSelected
                ? 'border-quickopia-navy bg-quickopia-navy/5 shadow-sm'
                : 'border-gray-200 hover:border-gray-300 bg-white'
            }`}
          >
            <input
              type="radio"
              name="payment_method"
              checked={isSelected}
              onChange={() => onChange(opt)}
              className="mt-1 h-4 w-4 text-quickopia-navy accent-quickopia-navy cursor-pointer"
            />
            <div className="flex-1">
              <p className="font-semibold text-sm text-gray-900">
                {opt === 'cod'
                  ? 'Cash on Delivery / Pickup'
                  : 'Lipa Kwa Simu (M-Pesa / Tigo Pesa / Airtel)'}
              </p>
              <p className="text-xs text-gray-500 mt-0.5">
                {opt === 'cod'
                  ? 'Pay cash directly when receiving your order'
                  : 'Mobile money merchant payment'}
              </p>
              {opt === 'lipa_namba' && isSelected && (
                <div className="text-xs text-amber-900 bg-amber-50 border border-amber-200 rounded-lg p-2.5 mt-2.5">
                  <p className="font-bold">
                    Lipa Namba / Branch Phone: {branch?.phone ?? 'Store Phone'}
                  </p>
                  <p className="mt-0.5 text-amber-800">
                    Send mobile money payment and show confirmation SMS upon delivery/pickup.
                  </p>
                </div>
              )}
            </div>
          </label>
        );
      })}
    </div>
  );
}
