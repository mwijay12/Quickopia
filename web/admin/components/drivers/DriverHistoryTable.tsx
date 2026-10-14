'use client';

import { useEffect, useState } from 'react';
import type { DriverListItem } from '@/lib/drivers';
import { fetchDeliveryHistory } from '@/lib/drivers';
import { Phone } from 'lucide-react';

interface DeliveryHistoryItem {
  id: string;
  order_number: string;
  created_at: string;
  updated_at: string;
  total_amount_tzs: number;
  delivery_fee_tzs: number;
  delivery_neighborhood: string | null;
  delivery_landmark: string | null;
  customer?: { full_name: string | null };
  driver?: { id: string; full_name: string | null; phone: string | null };
}

export default function DriverHistoryTable({
  drivers,
}: {
  drivers: DriverListItem[];
}) {
  const [selectedDriverId, setSelectedDriverId] = useState<string>('');
  const [history, setHistory] = useState<DeliveryHistoryItem[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async (driverId?: string) => {
    setLoading(true);
    try {
      const data = await fetchDeliveryHistory(driverId || undefined);
      setHistory((data ?? []) as unknown as DeliveryHistoryItem[]);
    } catch (e) {
      console.error('Failed to load history:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load(selectedDriverId);
  }, [selectedDriverId]);

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center flex-wrap gap-3">
        <div>
          <h3 className="font-bold text-sm text-quickopia-navy">
            Completed Delivery History
          </h3>
          <p className="text-xs text-gray-500">
            Historical settlement records for delivered orders
          </p>
        </div>

        <div className="flex items-center gap-2">
          <label className="text-xs font-semibold text-gray-700">
            Filter by Driver:
          </label>
          <select
            value={selectedDriverId}
            onChange={(e) => setSelectedDriverId(e.target.value)}
            className="border border-gray-300 rounded-xl px-3 py-1.5 text-xs bg-white focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
          >
            <option value="">All Drivers ({drivers.length})</option>
            {drivers.map((d) => (
              <option key={d.id} value={d.id}>
                {d.full_name ?? 'Driver'}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-x-auto">
        <table className="w-full text-left text-xs">
          <thead className="bg-gray-50 text-gray-500 font-bold uppercase tracking-wider border-b border-gray-100">
            <tr>
              <th className="p-3.5">Order</th>
              <th className="p-3.5">Delivered Driver</th>
              <th className="p-3.5">Customer &amp; Area</th>
              <th className="p-3.5">Date &amp; Time</th>
              <th className="p-3.5 text-right">Total (TZS)</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {history.map((h) => (
              <tr key={h.id} className="hover:bg-gray-50/60 transition">
                <td className="p-3.5 font-bold text-quickopia-navy">
                  #{h.order_number}
                </td>
                <td className="p-3.5 font-semibold text-gray-800">
                  {h.driver?.full_name ?? 'Unknown Driver'}
                  {h.driver?.phone && (
                    <span className="flex items-center gap-1 text-[11px] text-gray-400 font-normal mt-0.5">
                      <Phone className="w-3 h-3 text-gray-400 inline" /> {h.driver.phone}
                    </span>
                  )}
                </td>
                <td className="p-3.5 text-gray-700">
                  <span className="font-semibold text-gray-900 block">
                    {h.customer?.full_name ?? 'Customer'}
                  </span>
                  <span className="text-[11px] text-gray-500">
                    {h.delivery_neighborhood} &bull; {h.delivery_landmark}
                  </span>
                </td>
                <td className="p-3.5 text-gray-500">
                  {new Date(h.updated_at).toLocaleDateString('en-GB', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </td>
                <td className="p-3.5 text-right font-extrabold text-quickopia-navy">
                  TZS {h.total_amount_tzs.toLocaleString('en-US')}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {loading ? (
          <div className="py-12 text-center text-gray-400 text-xs">
            Loading delivery history...
          </div>
        ) : history.length === 0 ? (
          <div className="py-12 text-center text-gray-400 text-xs">
            No completed delivery records found.
          </div>
        ) : null}
      </div>
    </div>
  );
}
