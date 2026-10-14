'use client';

import { useEffect, useState } from 'react';
import type { Order, DriverProfile } from '@/lib/types';
import { fetchDrivers, reassignDriver, DriverManagementError } from '@/lib/drivers';

export default function ReassignDriverModal({
  order,
  onClose,
  onDone,
}: {
  order: Order;
  onClose: () => void;
  onDone: () => void;
}) {
  const [drivers, setDrivers] = useState<DriverProfile[]>([]);
  const [selectedDriverId, setSelectedDriverId] = useState('');
  const [loadingDrivers, setLoadingDrivers] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchDrivers()
      .then((list) => {
        setDrivers(list);
        const otherDrivers = list.filter((d) => d.id !== order.driver_id);
        if (otherDrivers.length > 0) {
          setSelectedDriverId(otherDrivers[0].id);
        }
      })
      .finally(() => setLoadingDrivers(false));
  }, [order.driver_id]);

  const handleReassign = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDriverId) {
      setError('Please select a replacement driver');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await reassignDriver(order.id, selectedDriverId);
      onDone();
    } catch (err) {
      setError(
        err instanceof DriverManagementError
          ? err.message
          : 'Could not reassign order.'
      );
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
      <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-2xl border border-gray-100 animate-in fade-in zoom-in-95 duration-150 space-y-4">
        <div className="flex justify-between items-center pb-2 border-b border-gray-100">
          <div>
            <h3 className="font-bold text-base text-quickopia-navy">
              Reassign Order #{order.order_number}
            </h3>
            <p className="text-[11px] text-gray-500">
              Transfer in-transit delivery to another driver
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 font-bold flex items-center justify-center transition"
          >
            ✕
          </button>
        </div>

        <div className="bg-gray-50 rounded-xl p-3 text-xs text-gray-700 space-y-1 border border-gray-200">
          <p>
            <strong className="text-gray-900">Destination:</strong>{' '}
            {order.delivery_neighborhood} &mdash; {order.delivery_landmark}
          </p>
          <p>
            <strong className="text-gray-900">Current Driver:</strong>{' '}
            {order.driver?.full_name ?? 'Assigned Driver'} (
            {order.driver?.phone ?? 'No phone'})
          </p>
        </div>

        <form onSubmit={handleReassign} className="space-y-3.5 text-xs">
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Select Replacement Driver
            </label>
            {loadingDrivers ? (
              <p className="text-gray-400 py-2">Loading active drivers...</p>
            ) : drivers.length === 0 ? (
              <p className="text-red-500 font-medium py-1">
                No active drivers found in fleet.
              </p>
            ) : (
              <select
                value={selectedDriverId}
                onChange={(e) => setSelectedDriverId(e.target.value)}
                className="w-full border border-gray-300 rounded-xl px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
              >
                {drivers.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.full_name ?? 'Driver'} &mdash; {d.phone ?? 'No phone'}
                    {d.id === order.driver_id ? ' (Current)' : ''}
                  </option>
                ))}
              </select>
            )}
          </div>

          <p className="text-[10px] text-amber-800 bg-amber-50 p-2.5 rounded-xl border border-amber-200">
            Realtime alert: The old driver&apos;s app will remove this order,
            and the new driver will receive instant notification and pickup
            details.
          </p>

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
              disabled={submitting || !selectedDriverId}
              className="flex-1 py-2.5 font-bold bg-quickopia-navy hover:bg-slate-900 text-white rounded-xl transition disabled:opacity-50 shadow-sm"
            >
              {submitting ? 'Reassigning...' : 'Confirm Reassign'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
