'use client';

import { useState, useEffect } from 'react';
import type { Order } from '@/lib/types';
import {
  advanceStatus,
  markProductOutOfStock,
  AdminActionError,
} from '@/lib/orders';
import { AlertTriangle } from 'lucide-react';

export function Modal({
  title,
  children,
  onClose,
}: {
  title: string;
  children: React.ReactNode;
  onClose: () => void;
}) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
      <div className="bg-white rounded-2xl p-6 w-full max-w-md shadow-2xl border border-gray-100 animate-in fade-in zoom-in-95 duration-150">
        <div className="flex justify-between items-center mb-4 pb-2 border-b border-gray-100">
          <h3 className="font-bold text-lg text-quickopia-navy">{title}</h3>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 font-bold flex items-center justify-center transition"
          >
            ✕
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

export default function PackingChecklistModal({
  order,
  onClose,
  onDone,
}: {
  order: Order;
  onClose: () => void;
  onDone: () => void;
}) {
  const [checked, setChecked] = useState<Record<string, boolean>>({});
  const [outOfStock, setOutOfStock] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Each item must either be checked (packed) or flagged as out-of-stock
  const allResolved =
    order.order_items.length > 0 &&
    order.order_items.every((i) => checked[i.id] || outOfStock[i.id]);

  const flaggedCount = Object.values(outOfStock).filter(Boolean).length;

  useEffect(() => {
    if (order.status === 'placed') {
      advanceStatus(order.id, 'packing').catch(() => {});
    }
  }, [order.id, order.status]);

  const toggleOutOfStock = async (itemId: string, productId: string) => {
    const nextVal = !outOfStock[itemId];
    setOutOfStock((prev) => ({ ...prev, [itemId]: nextVal }));
    if (nextVal) {
      // Uncheck packed if marked out of stock
      setChecked((prev) => ({ ...prev, [itemId]: false }));
      // Automatically mark in catalog so future customers can't order it
      await markProductOutOfStock(productId);
    }
  };

  const markReady = async () => {
    setLoading(true);
    setError(null);
    try {
      await advanceStatus(order.id, 'ready');
      onDone();
    } catch (e) {
      setError(
        e instanceof AdminActionError
          ? e.message
          : 'Could not update this order.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal onClose={onClose} title={`Packing Checklist — #${order.order_number}`}>
      <p className="text-xs text-gray-500 mb-3 font-medium">
        Tick off items as they are gathered. If an item is missing on shelves, flag it below.
      </p>

      <div className="space-y-2.5 max-h-72 overflow-y-auto pr-1">
        {order.order_items.map((item) => {
          const isFlagged = !!outOfStock[item.id];
          const isPacked = !!checked[item.id];

          return (
            <div
              key={item.id}
              className={`border rounded-xl p-3 transition space-y-2 ${
                isFlagged
                  ? 'bg-amber-50/80 border-amber-300'
                  : isPacked
                  ? 'bg-green-50/70 border-green-300'
                  : 'bg-white border-gray-200'
              }`}
            >
              <div className="flex items-center gap-3">
                <input
                  type="checkbox"
                  disabled={isFlagged}
                  checked={isPacked}
                  onChange={(e) =>
                    setChecked((c) => ({ ...c, [item.id]: e.target.checked }))
                  }
                  className="h-4 w-4 rounded text-quickopia-navy accent-quickopia-navy cursor-pointer disabled:opacity-30"
                />
                <span
                  className={`flex-1 text-sm ${
                    isFlagged
                      ? 'text-amber-900 line-through'
                      : isPacked
                      ? 'text-gray-400 line-through'
                      : 'font-semibold text-gray-800'
                  }`}
                >
                  {item.title}
                </span>
                <span className="text-xs font-bold bg-gray-100 text-gray-700 px-2 py-1 rounded-md shrink-0">
                  &times; {item.quantity}
                </span>
              </div>

              <div className="flex justify-between items-center text-[11px] pt-1 border-t border-gray-100">
                {isFlagged ? (
                  <span className="text-amber-800 font-bold flex items-center gap-1.5">
                    <AlertTriangle className="w-3.5 h-3.5 text-amber-600" />
                    <span>Flagged Out of Stock (Catalog updated)</span>
                  </span>
                ) : (
                  <span className="text-gray-400">Shelf status: In Stock</span>
                )}
                <button
                  type="button"
                  onClick={() => toggleOutOfStock(item.id, item.product_id)}
                  className={`font-semibold hover:underline flex items-center gap-1 ${
                    isFlagged ? 'text-gray-600' : 'text-amber-700'
                  }`}
                >
                  {!isFlagged && <AlertTriangle className="w-3 h-3 text-amber-600" />}
                  <span>{isFlagged ? 'Undo flag' : 'Shelf Out of Stock'}</span>
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {flaggedCount > 0 && (
        <div className="bg-amber-50 border border-amber-200 p-2.5 rounded-xl mt-3 text-xs text-amber-900 leading-relaxed">
          <strong className="font-bold">Notice:</strong> {flaggedCount} item(s)
          flagged out-of-stock. The product catalog was updated, and staff can
          proceed with packing the available items.
        </div>
      )}

      {error && (
        <p className="text-xs text-red-600 bg-red-50 p-2.5 rounded-lg mt-3 font-medium">
          {error}
        </p>
      )}

      <button
        type="button"
        onClick={markReady}
        disabled={!allResolved || loading}
        className="w-full mt-4 bg-quickopia-navy hover:bg-slate-900 text-white font-bold py-3 rounded-xl disabled:opacity-40 transition shadow-sm text-sm"
      >
        {loading
          ? 'Updating status...'
          : allResolved
          ? flaggedCount > 0
            ? `Mark Order as Ready (${flaggedCount} item flagged)`
            : 'Mark Order as Ready'
          : `Resolve all items (${
              Object.values(checked).filter(Boolean).length + flaggedCount
            }/${order.order_items.length})`}
      </button>
    </Modal>
  );
}
