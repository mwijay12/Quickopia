'use client';

import { useState } from 'react';
import {
  DriverWorkloadItem,
  setDriverActive,
} from '@/lib/drivers';
import AddDriverModal from './AddDriverModal';
import EditDriverModal from './EditDriverModal';
import { Bike, Phone } from 'lucide-react';

export default function DriverTable({
  drivers,
  onRefresh,
}: {
  drivers: DriverWorkloadItem[];
  onRefresh: () => void;
}) {
  const [showAdd, setShowAdd] = useState(false);
  const [editingDriver, setEditingDriver] = useState<DriverWorkloadItem | null>(
    null
  );

  const toggleActive = async (d: DriverWorkloadItem) => {
    const nextState = !d.is_active;
    try {
      await setDriverActive(d.id, nextState);
      onRefresh();
    } catch (e) {
      alert(`Could not update driver status: ${e}`);
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <div>
          <p className="text-xs text-gray-500">
            {drivers.length} drivers registered &bull;{' '}
            {drivers.filter((d) => d.is_active).length} active for dispatch
          </p>
        </div>
        <button
          type="button"
          onClick={() => setShowAdd(true)}
          className="bg-quickopia-navy hover:bg-slate-900 text-white px-4 py-2.5 rounded-xl text-xs font-bold transition shadow-sm flex items-center gap-1.5"
        >
          <span>+</span>
          <span>Add Driver</span>
        </button>
      </div>

      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden divide-y divide-gray-100">
        {drivers.length === 0 ? (
          <div className="text-center py-12 text-gray-400">
            <Bike className="w-8 h-8 text-gray-300 mx-auto mb-2" />
            <p className="text-xs">
              No delivery drivers provisioned yet. Click &quot;Add Driver&quot;
              above to create an account.
            </p>
          </div>
        ) : (
          drivers.map((d) => (
            <div
              key={d.id}
              className="flex flex-wrap justify-between items-center px-5 py-3.5 hover:bg-gray-50/70 transition gap-3"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-quickopia-navy/10 text-quickopia-navy font-bold flex items-center justify-center text-sm">
                  {(d.full_name ?? 'D').charAt(0).toUpperCase()}
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <p className="font-bold text-sm text-gray-900">
                      {d.full_name ?? 'Unnamed Driver'}
                    </p>
                    {d.derivedStatus === 'delivering' && (
                      <span className="text-[10px] font-extrabold bg-amber-100 text-amber-900 px-2 py-0.5 rounded-full flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
                        Delivering #{d.currentOrder?.order_number}
                      </span>
                    )}
                    {d.derivedStatus === 'available' && (
                      <span className="text-[10px] font-extrabold bg-green-100 text-green-800 px-2 py-0.5 rounded-full flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
                        Available
                      </span>
                    )}
                    {d.derivedStatus === 'inactive' && (
                      <span className="text-[10px] font-extrabold bg-gray-200 text-gray-600 px-2 py-0.5 rounded-full flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-gray-400" />
                        Offline / Inactive
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-gray-500 mt-0.5 flex items-center gap-1">
                    <Phone className="w-3 h-3 text-gray-400 inline" />
                    <span>{d.phone ?? 'No phone recorded'}</span>
                    {d.currentOrder && (
                      <span className="text-gray-400 ml-1">
                        • En route to {d.currentOrder.neighborhood},{' '}
                        {d.currentOrder.landmark}
                      </span>
                    )}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-3 text-xs">
                <div className="text-right mr-2 hidden sm:block">
                  <span className="text-[11px] text-gray-400 block font-medium">
                    Active Deliveries
                  </span>
                  <span className="font-black text-quickopia-navy">
                    {d.activeOrderCount} order{d.activeOrderCount === 1 ? '' : 's'}
                  </span>
                </div>

                <button
                  type="button"
                  onClick={() => setEditingDriver(d)}
                  className="px-3 py-1.5 rounded-lg border border-gray-200 font-bold text-gray-700 hover:bg-gray-100 transition text-xs"
                >
                  Edit Profile
                </button>

                <button
                  type="button"
                  onClick={() => toggleActive(d)}
                  className={`text-xs font-bold px-3 py-1.5 rounded-lg transition ${
                    d.is_active
                      ? 'text-red-700 hover:bg-red-50'
                      : 'text-green-700 hover:bg-green-50'
                  }`}
                >
                  {d.is_active ? 'Deactivate' : 'Reactivate'}
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {showAdd && (
        <AddDriverModal
          onClose={() => setShowAdd(false)}
          onDone={() => {
            setShowAdd(false);
            onRefresh();
          }}
        />
      )}

      {editingDriver && (
        <EditDriverModal
          driver={editingDriver}
          onClose={() => setEditingDriver(null)}
          onDone={() => {
            setEditingDriver(null);
            onRefresh();
          }}
        />
      )}
    </div>
  );
}
