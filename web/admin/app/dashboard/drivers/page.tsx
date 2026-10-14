'use client';

import { useEffect, useState } from 'react';
import type { Order } from '@/lib/types';
import {
  fetchDriverWorkloads,
  fetchUnassignedDeliveries,
  fetchActiveDispatches,
  assignDriver,
  DriverWorkloadItem,
} from '@/lib/drivers';
import DriverTable from '@/components/drivers/DriverTable';
import DriverHistoryTable from '@/components/drivers/DriverHistoryTable';
import ReassignDriverModal from '@/components/drivers/ReassignDriverModal';
import MotorcycleFleetManager from '@/components/drivers/MotorcycleFleetManager';
import { TableSkeleton } from '@/components/ui/Skeleton';
import { Phone, CheckCircle2, Wrench } from 'lucide-react';

export default function DriversPage() {
  const [activeTab, setActiveTab] = useState<
    'roster' | 'motorcycles' | 'unassigned' | 'dispatches' | 'history'
  >('roster');

  const [drivers, setDrivers] = useState<DriverWorkloadItem[]>([]);
  const [unassigned, setUnassigned] = useState<Order[]>([]);
  const [activeDispatches, setActiveDispatches] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDriverMap, setSelectedDriverMap] = useState<
    Record<string, string>
  >({});
  const [assigningId, setAssigningId] = useState<string | null>(null);
  const [reassignOrder, setReassignOrder] = useState<Order | null>(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const [drvs, unass, disp] = await Promise.all([
        fetchDriverWorkloads(),
        fetchUnassignedDeliveries(),
        fetchActiveDispatches(),
      ]);
      setDrivers(drvs);
      setUnassigned(unass);
      setActiveDispatches(disp);

      // Pre-select first available active driver for unassigned orders
      const firstActive = drvs.find((d) => d.is_active);
      if (firstActive) {
        const initialMap: Record<string, string> = {};
        unass.forEach((o) => {
          initialMap[o.id] = firstActive.id;
        });
        setSelectedDriverMap(initialMap);
      }
    } catch (e) {
      console.error('Failed to load driver dashboard data:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleAssign = async (orderId: string) => {
    const driverId = selectedDriverMap[orderId];
    if (!driverId) {
      alert('Please select a driver first.');
      return;
    }
    setAssigningId(orderId);
    try {
      await assignDriver(orderId, driverId);
      await loadData();
    } catch (e) {
      alert(`Could not assign driver: ${e}`);
    } finally {
      setAssigningId(null);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-black text-quickopia-navy">
          Driver Fleet Management &amp; Assignment
        </h2>
        <p className="text-xs text-gray-500 mt-1">
          Monitor driver workloads, assign ready delivery orders, manage motorcycle maintenance &amp; fuel, and review historical logs.
        </p>
      </div>

      <div className="flex bg-gray-200/80 p-1 rounded-xl max-w-3xl gap-1 text-xs font-bold overflow-x-auto">
        <button
          type="button"
          onClick={() => setActiveTab('roster')}
          className={`flex-1 py-2 px-3 rounded-lg transition whitespace-nowrap ${
            activeTab === 'roster'
              ? 'bg-white text-quickopia-navy shadow-xs'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Active Drivers ({drivers.length})
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('motorcycles')}
          className={`flex-1 py-2 px-3 rounded-lg transition whitespace-nowrap flex items-center justify-center gap-1.5 ${
            activeTab === 'motorcycles'
              ? 'bg-white text-quickopia-navy shadow-xs'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <Wrench className="w-3.5 h-3.5 text-quickopia-amber" />
          <span>Motorcycles &amp; Maintenance</span>
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('unassigned')}
          className={`flex-1 py-2 px-3 rounded-lg transition whitespace-nowrap flex items-center justify-center gap-1.5 ${
            activeTab === 'unassigned'
              ? 'bg-white text-quickopia-navy shadow-xs'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <span>Unassigned</span>
          {unassigned.length > 0 && (
            <span className="w-5 h-5 rounded-full bg-amber-500 text-black text-[10px] font-black flex items-center justify-center">
              {unassigned.length}
            </span>
          )}
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('dispatches')}
          className={`flex-1 py-2 px-3 rounded-lg transition whitespace-nowrap flex items-center justify-center gap-1.5 ${
            activeTab === 'dispatches'
              ? 'bg-white text-quickopia-navy shadow-xs'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          <span>Dispatches</span>
          {activeDispatches.length > 0 && (
            <span className="w-5 h-5 rounded-full bg-quickopia-navy text-white text-[10px] font-black flex items-center justify-center">
              {activeDispatches.length}
            </span>
          )}
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('history')}
          className={`flex-1 py-2 px-3 rounded-lg transition whitespace-nowrap ${
            activeTab === 'history'
              ? 'bg-white text-quickopia-navy shadow-xs'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Delivery History
        </button>
      </div>

      {loading ? (
        <TableSkeleton rows={6} />
      ) : (
        <>
          {activeTab === 'roster' && (
            <DriverTable drivers={drivers} onRefresh={loadData} />
          )}

          {activeTab === 'motorcycles' && (
            <MotorcycleFleetManager />
          )}

          {activeTab === 'unassigned' && (
            <div className="space-y-4">
              <div className="bg-amber-50 border border-amber-200 rounded-xl p-3.5 text-xs text-amber-900 flex justify-between items-center">
                <span>
                  <strong>{unassigned.length} order(s)</strong> packed and ready
                  for doorstep delivery awaiting driver assignment.
                </span>
                <span className="text-[11px] text-amber-800">
                  Select an available driver with the lowest workload.
                </span>
              </div>

              <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-gray-50 text-gray-500 font-bold uppercase tracking-wider border-b border-gray-100">
                    <tr>
                      <th className="p-3.5">Order</th>
                      <th className="p-3.5">Customer &amp; Phone</th>
                      <th className="p-3.5">Delivery Destination</th>
                      <th className="p-3.5">Amount</th>
                      <th className="p-3.5">Assign Driver</th>
                      <th className="p-3.5 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {unassigned.map((o) => (
                      <tr key={o.id} className="hover:bg-gray-50/60 transition">
                        <td className="p-3.5 font-bold text-quickopia-navy">
                          #{o.order_number}
                        </td>
                        <td className="p-3.5 font-medium text-gray-900">
                          {o.customer?.full_name ?? 'Customer'}
                          <span className="flex items-center gap-1 text-[11px] text-gray-400 mt-0.5">
                            <Phone className="w-3 h-3 text-gray-400 inline" /> {o.customer_phone}
                          </span>
                        </td>
                        <td className="p-3.5 text-gray-700">
                          <span className="font-semibold text-gray-900">
                            {o.delivery_neighborhood}
                          </span>
                          <span className="block text-[11px] text-gray-500">
                            {o.delivery_landmark}
                          </span>
                        </td>
                        <td className="p-3.5 font-black text-quickopia-navy">
                          TZS {o.total_amount_tzs.toLocaleString('en-US')}
                        </td>
                        <td className="p-3.5">
                          <select
                            value={selectedDriverMap[o.id] || ''}
                            onChange={(e) =>
                              setSelectedDriverMap((prev) => ({
                                ...prev,
                                [o.id]: e.target.value,
                              }))
                            }
                            className="border border-gray-300 rounded-xl px-2.5 py-1.5 text-xs bg-white focus:outline-none focus:ring-2 focus:ring-quickopia-amber"
                          >
                            {drivers
                              .filter((d) => d.is_active)
                              .map((d) => (
                                <option key={d.id} value={d.id}>
                                  {d.full_name} ({d.activeOrderCount} active load
                                  {d.derivedStatus === 'delivering'
                                    ? ' • on delivery'
                                    : ' • free'}
                                  )
                                </option>
                              ))}
                          </select>
                        </td>
                        <td className="p-3.5 text-right">
                          <button
                            type="button"
                            disabled={assigningId === o.id}
                            onClick={() => handleAssign(o.id)}
                            className="bg-quickopia-navy hover:bg-slate-900 text-white font-bold px-3.5 py-1.5 rounded-xl transition text-xs shadow-xs disabled:opacity-50"
                          >
                            {assigningId === o.id
                              ? 'Assigning...'
                              : 'Dispatch Order'}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>

                {unassigned.length === 0 && (
                  <div className="py-12 text-center text-gray-400 text-xs flex items-center justify-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-emerald-500" /> All ready delivery orders currently have assigned drivers!
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === 'dispatches' && (
            <div className="space-y-4">
              <div className="bg-blue-50 border border-blue-200 rounded-xl p-3.5 text-xs text-blue-900">
                <strong>Live Delivery Fleet:</strong> Orders currently en route.
                If a driver encounters a vehicle breakdown or delay, click{' '}
                <strong>Reassign Driver</strong> to transfer the delivery
                instantly.
              </div>

              <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-gray-50 text-gray-500 font-bold uppercase tracking-wider border-b border-gray-100">
                    <tr>
                      <th className="p-3.5">Order</th>
                      <th className="p-3.5">Assigned Driver</th>
                      <th className="p-3.5">Destination</th>
                      <th className="p-3.5">Customer &amp; Phone</th>
                      <th className="p-3.5">Dispatched At</th>
                      <th className="p-3.5 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {activeDispatches.map((o) => (
                      <tr key={o.id} className="hover:bg-gray-50/60 transition">
                        <td className="p-3.5 font-bold text-quickopia-navy">
                          #{o.order_number}
                        </td>
                        <td className="p-3.5 font-bold text-gray-900">
                          {o.driver?.full_name ?? 'Assigned Driver'}
                          {o.driver?.phone && (
                            <span className="flex items-center gap-1 text-[11px] text-gray-400 font-normal mt-0.5">
                              <Phone className="w-3 h-3 text-gray-400 inline" /> {o.driver.phone}
                            </span>
                          )}
                        </td>
                        <td className="p-3.5 text-gray-700">
                          <span className="font-semibold text-gray-900">
                            {o.delivery_neighborhood}
                          </span>
                          <span className="block text-[11px] text-gray-500">
                            {o.delivery_landmark}
                          </span>
                        </td>
                        <td className="p-3.5 text-gray-700">
                          {o.customer?.full_name ?? 'Customer'}
                          <span className="flex items-center gap-1 text-[11px] text-gray-400 mt-0.5">
                            <Phone className="w-3 h-3 text-gray-400 inline" /> {o.customer_phone}
                          </span>
                        </td>
                        <td className="p-3.5 text-gray-500">
                          {new Date(o.created_at).toLocaleTimeString('en-US', {
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </td>
                        <td className="p-3.5 text-right">
                          <button
                            type="button"
                            onClick={() => setReassignOrder(o)}
                            className="bg-amber-100 hover:bg-amber-200 text-amber-900 font-bold px-3 py-1.5 rounded-xl transition text-xs shadow-2xs"
                          >
                            Reassign Driver
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>

                {activeDispatches.length === 0 && (
                  <div className="py-12 text-center text-gray-400 text-xs">
                    No active deliveries currently in transit.
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === 'history' && (
            <DriverHistoryTable drivers={drivers} />
          )}
        </>
      )}

      {reassignOrder && (
        <ReassignDriverModal
          order={reassignOrder}
          onClose={() => setReassignOrder(null)}
          onDone={() => {
            setReassignOrder(null);
            loadData();
          }}
        />
      )}
    </div>
  );
}
