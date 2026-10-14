'use client';

import { useEffect, useState } from 'react';
import type { Order, DriverProfile } from '@/lib/types';
import { fetchDrivers } from '@/lib/drivers';
import { advanceStatus, AdminActionError } from '@/lib/orders';
import { Modal } from './PackingChecklistModal';

export default function DispatchModal({
  order,
  onClose,
  onDone,
}: {
  order: Order;
  onClose: () => void;
  onDone: () => void;
}) {
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [selected, setSelected] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchDrivers().then(setDrivers);
  }, []);

  const confirm = async () => {
    if (!selected) {
      setError('Please select an assigned driver first.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await advanceStatus(order.id, 'out_for_delivery', selected);
      onDone();
    } catch (e) {
      setError(
        e instanceof AdminActionError
          ? e.message
          : 'Could not dispatch this order.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      title={`Dispatch Delivery — #${order.order_number}`}
      onClose={onClose}
    >
      <div className="space-y-4">
        <div className="bg-gray-50 border border-gray-200 rounded-xl p-3 text-xs text-gray-700 space-y-1">
          <p>
            <strong className="text-gray-900">Destination:</strong>{' '}
            {order.delivery_neighborhood} — {order.delivery_landmark}
          </p>
          <p>
            <strong className="text-gray-900">Customer Phone:</strong>{' '}
            {order.customer_phone}
          </p>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1.5 uppercase tracking-wider">
            Assign Delivery Driver
          </label>
          {drivers.length === 0 ? (
            <p className="text-xs text-amber-700 bg-amber-50 border border-amber-200 p-3 rounded-xl">
              No registered drivers found. To add one, create an account in
              Supabase Auth and set its role to <code>driver</code> in the profiles table.
            </p>
          ) : (
            <select
              value={selected}
              onChange={(e) => setSelected(e.target.value)}
              className="w-full border border-gray-300 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-quickopia-amber bg-white transition"
            >
              <option value="">Choose a driver...</option>
              {drivers.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.full_name ?? 'Driver'} ({d.phone ?? 'No phone'})
                </option>
              ))}
            </select>
          )}
        </div>

        {error && (
          <p className="text-xs text-red-600 bg-red-50 p-2.5 rounded-lg font-medium">
            {error}
          </p>
        )}

        <button
          type="button"
          onClick={confirm}
          disabled={loading || drivers.length === 0}
          className="w-full bg-quickopia-navy hover:bg-slate-900 text-white font-bold py-3 rounded-xl disabled:opacity-40 transition shadow-sm text-sm"
        >
          {loading ? 'Dispatching driver...' : 'Confirm & Dispatch Driver'}
        </button>
      </div>
    </Modal>
  );
}
