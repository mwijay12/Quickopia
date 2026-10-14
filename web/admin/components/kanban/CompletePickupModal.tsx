'use client';

import { useState } from 'react';
import type { Order } from '@/lib/types';
import { completePickup, AdminActionError } from '@/lib/orders';
import { Modal } from './PackingChecklistModal';

export default function CompletePickupModal({
  order,
  onClose,
  onDone,
}: {
  order: Order;
  onClose: () => void;
  onDone: () => void;
}) {
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const confirm = async () => {
    setLoading(true);
    setError(null);
    try {
      await completePickup(order.id, code.trim(), 'paid');
      onDone();
    } catch (e) {
      setError(
        e instanceof AdminActionError
          ? e.message
          : 'Could not complete this order.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      title={`Complete In-Store Pickup — #${order.order_number}`}
      onClose={onClose}
    >
      <div className="space-y-4">
        <p className="text-xs text-gray-500 leading-relaxed font-medium">
          Ask the customer at the collection counter for their 4-digit pickup
          code from their order confirmation screen.
        </p>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1.5 uppercase tracking-wider text-center">
            Enter 4-Digit Customer Pickup Code
          </label>
          <input
            type="text"
            inputMode="numeric"
            value={code}
            onChange={(e) =>
              setCode(e.target.value.replace(/\D/g, '').slice(0, 4))
            }
            maxLength={4}
            className="w-full border-2 border-quickopia-navy/30 focus:border-quickopia-navy rounded-xl px-3 py-3 text-center text-3xl tracking-[0.4em] font-mono font-black focus:outline-none transition bg-gray-50"
            placeholder="••••"
            autoFocus
          />
        </div>

        {error && (
          <p className="text-xs text-red-600 bg-red-50 p-2.5 rounded-lg font-medium text-center">
            {error}
          </p>
        )}

        <button
          type="button"
          onClick={confirm}
          disabled={loading || code.length !== 4}
          className="w-full bg-quickopia-navy hover:bg-slate-900 text-white font-bold py-3 rounded-xl disabled:opacity-40 transition shadow-sm text-sm"
        >
          {loading ? 'Verifying code...' : 'Confirm & Hand Over Order'}
        </button>
      </div>
    </Modal>
  );
}
