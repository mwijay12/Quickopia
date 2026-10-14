'use client';

import { useState } from 'react';
import type { Order } from '@/lib/types';
import { cancelOrder, AdminActionError } from '@/lib/orders';
import { Modal } from './PackingChecklistModal';
import { AlertTriangle } from 'lucide-react';

export default function CancelOrderDialog({
  order,
  onClose,
  onDone,
}: {
  order: Order;
  onClose: () => void;
  onDone: () => void;
}) {
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const confirm = async () => {
    setLoading(true);
    setError(null);
    try {
      await cancelOrder(order.id, reason.trim() || undefined);
      onDone();
    } catch (e) {
      setError(
        e instanceof AdminActionError
          ? e.message
          : 'Could not cancel this order.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal title={`Cancel Order — #${order.order_number}`} onClose={onClose}>
      <div className="space-y-4">
        <div className="bg-red-50 border border-red-200 rounded-xl p-3.5 text-xs text-red-800">
          <p className="font-bold flex items-center gap-1.5">
            <AlertTriangle className="w-4 h-4 text-red-600 inline" />
            <span>Irreversible Stock Restoration</span>
          </p>
          <p className="mt-1">
            Cancelling will mark this order as cancelled and automatically
            restore inventory for all {order.order_items.length} line items back
            to supermarket stock.
          </p>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Cancellation Reason (optional)
          </label>
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g. Out of stock, customer requested cancellation, unreachable"
            className="w-full border border-gray-300 rounded-xl p-3 text-xs focus:outline-none focus:ring-2 focus:ring-red-500 bg-white"
            rows={2}
          />
        </div>

        {error && (
          <p className="text-xs text-red-600 bg-red-50 p-2.5 rounded-lg font-medium">
            {error}
          </p>
        )}

        <button
          type="button"
          onClick={confirm}
          disabled={loading}
          className="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-3 rounded-xl disabled:opacity-40 transition shadow-sm text-sm"
        >
          {loading ? 'Restoring stock & cancelling...' : 'Confirm Cancellation'}
        </button>
      </div>
    </Modal>
  );
}
