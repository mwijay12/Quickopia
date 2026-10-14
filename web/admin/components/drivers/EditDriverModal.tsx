'use client';

import { useState } from 'react';
import type { DriverListItem } from '@/lib/drivers';
import { updateDriver, DriverManagementError } from '@/lib/drivers';

export default function EditDriverModal({
  driver,
  onClose,
  onDone,
}: {
  driver: DriverListItem;
  onClose: () => void;
  onDone: () => void;
}) {
  const [fullName, setFullName] = useState(driver.full_name ?? '');
  const [phone, setPhone] = useState(driver.phone ?? '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim()) {
      setError('Driver full name is required');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await updateDriver(driver.id, fullName.trim(), phone.trim());
      onDone();
    } catch (err) {
      setError(
        err instanceof DriverManagementError
          ? err.message
          : 'Could not update driver details'
      );
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
      <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-2xl border border-gray-100 animate-in fade-in zoom-in-95 duration-150 space-y-4">
        <div className="flex justify-between items-center pb-2 border-b border-gray-100">
          <h3 className="font-bold text-base text-quickopia-navy">
            Edit Driver Profile
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 font-bold flex items-center justify-center transition"
          >
            ✕
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3.5 text-xs">
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Full Name
            </label>
            <input
              type="text"
              required
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className="w-full border border-gray-300 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
            />
          </div>

          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Phone Number
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="0712 345 678"
              className="w-full border border-gray-300 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
            />
            <p className="text-[10px] text-gray-400 mt-1">
              Used by customers to call or WhatsApp regarding order delivery.
            </p>
          </div>

          {error && (
            <p className="text-red-600 bg-red-50 p-2.5 rounded-lg font-medium border border-red-200">
              {error}
            </p>
          )}

          <div className="flex gap-2 pt-2 border-t border-gray-100">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 font-bold text-gray-700 hover:bg-gray-100 rounded-xl transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 py-2.5 font-bold bg-quickopia-navy hover:bg-slate-900 text-white rounded-xl transition disabled:opacity-50 shadow-sm"
            >
              {loading ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
