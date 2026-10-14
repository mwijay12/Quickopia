'use client';

import { useState } from 'react';
import type { Order } from '@/lib/types';
import { updatePaymentStatus } from '@/lib/orders';
import { Store, Bike, ChevronDown, ChevronUp, AlertCircle } from 'lucide-react';

const fmt = (n: number) => `TZS ${n.toLocaleString('en-US')}`;

export default function OrderCard({
  order,
  onAction,
}: {
  order: Order;
  onAction: (
    action: 'packing-modal' | 'dispatch' | 'complete-pickup' | 'cancel'
  ) => void;
}) {
  const [expanded, setExpanded] = useState(false);
  const [updatingPayment, setUpdatingPayment] = useState(false);
  const isPickup = order.fulfillment_type === 'pickup';

  return (
    <div className="bg-white border border-gray-200 rounded-xl p-3.5 shadow-sm space-y-2.5 hover:shadow-md transition">
      <div className="flex justify-between items-start">
        <div>
          <p className="font-extrabold text-sm text-quickopia-navy">
            #{order.order_number}
          </p>
          <p className="text-xs text-gray-600 mt-0.5">
            {order.customer?.full_name ?? 'Customer'} &bull; {order.customer_phone}
          </p>
        </div>
        <span
          className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wider flex items-center gap-1 ${
            isPickup
              ? 'bg-blue-100 text-blue-800 border border-blue-200'
              : 'bg-amber-100 text-amber-800 border border-amber-200'
          }`}
        >
          {isPickup ? (
            <>
              <Store className="w-3 h-3" /> Pickup
            </>
          ) : (
            <>
              <Bike className="w-3 h-3" /> Delivery
            </>
          )}
        </span>
      </div>

      <div className="flex justify-between items-center text-xs">
        <button
          type="button"
          onClick={() => setExpanded((e) => !e)}
          className="font-semibold text-quickopia-navy hover:underline flex items-center gap-1"
        >
          {expanded ? (
            <>
              <ChevronUp className="w-3.5 h-3.5" />
              <span>Hide items</span>
            </>
          ) : (
            <>
              <ChevronDown className="w-3.5 h-3.5" />
              <span>{order.order_items.length} item(s)</span>
            </>
          )}
        </button>
        <span className="font-extrabold text-gray-900">
          {fmt(order.total_amount_tzs)}
        </span>
      </div>

      {expanded && (
        <div className="text-xs text-gray-600 space-y-1.5 border-t border-gray-100 pt-2.5 bg-gray-50/70 -mx-3.5 px-3.5 py-2">
          <div className="space-y-1">
            {order.order_items.map((i) => (
              <div key={i.id} className="flex justify-between text-gray-700">
                <span>
                  {i.title} &times; {i.quantity}
                </span>
                <span className="font-medium">{fmt(i.total_tzs)}</span>
              </div>
            ))}
          </div>
          {!isPickup && (
            <p className="pt-1 text-gray-800 border-t border-gray-200/60">
              <strong className="text-gray-900">Address:</strong>{' '}
              {order.delivery_neighborhood} &mdash; {order.delivery_landmark}
              {order.delivery_house_details ? ` (${order.delivery_house_details})` : ''}
            </p>
          )}
          <p className="pt-0.5 text-gray-700">
            <strong className="text-gray-900">Payment:</strong>{' '}
            {order.payment_method === 'cod' ? 'Cash on Delivery' : 'Lipa Namba'} &bull;{' '}
            <span
              className={`capitalize font-bold ${
                order.payment_status === 'paid'
                  ? 'text-emerald-700'
                  : 'text-amber-800'
              }`}
            >
              {order.payment_status}
            </span>
          </p>
        </div>
      )}

      {/* Lipa Namba Verification Guard */}
      {order.payment_method === 'lipa_namba' && order.payment_status === 'pending' && (
        <div className="bg-amber-50 border border-amber-200 rounded-lg p-2 text-xs text-amber-900 flex items-center justify-between gap-2">
          <div className="flex items-center gap-1.5 min-w-0">
            <AlertCircle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
            <span className="truncate text-[11px] font-medium">
              Verify M-Pesa / Tigo Pesa SMS before dispatch
            </span>
          </div>
          <button
            type="button"
            disabled={updatingPayment}
            onClick={async () => {
              try {
                setUpdatingPayment(true);
                await updatePaymentStatus(order.id, 'paid');
              } catch (err) {
                alert('Could not update payment: ' + err);
              } finally {
                setUpdatingPayment(false);
              }
            }}
            className="shrink-0 px-2 py-0.5 bg-amber-600 hover:bg-amber-700 text-white rounded text-[10px] font-bold transition disabled:opacity-50"
          >
            {updatingPayment ? '...' : 'Mark Paid'}
          </button>
        </div>
      )}

      <div className="flex flex-wrap gap-1.5 pt-1">
        {order.status === 'placed' && (
          <ActionBtn
            label="Start Packing"
            onClick={() => onAction('packing-modal')}
            primary
          />
        )}
        {order.status === 'packing' && (
          <ActionBtn
            label="Open Checklist"
            onClick={() => onAction('packing-modal')}
            primary
          />
        )}
        {order.status === 'ready' && isPickup && (
          <ActionBtn
            label="Complete Pickup"
            onClick={() => onAction('complete-pickup')}
            primary
          />
        )}
        {order.status === 'ready' && !isPickup && (
          <ActionBtn
            label="Assign Driver & Dispatch"
            onClick={() => onAction('dispatch')}
            primary
          />
        )}
        {order.status === 'out_for_delivery' && (
          <span className="text-[11px] text-gray-400 font-medium py-1 italic">
            Out with driver &bull; Awaiting code delivery
          </span>
        )}
        {(order.status === 'placed' ||
          order.status === 'packing' ||
          order.status === 'ready') && (
          <ActionBtn
            label="Cancel"
            onClick={() => onAction('cancel')}
            danger
          />
        )}
      </div>
    </div>
  );
}

function ActionBtn({
  label,
  onClick,
  primary,
  danger,
}: {
  label: string;
  onClick: () => void;
  primary?: boolean;
  danger?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`text-xs font-bold px-3 py-1.5 rounded-lg transition shadow-sm ${
        danger
          ? 'bg-red-50 text-red-700 hover:bg-red-100 border border-red-200'
          : primary
          ? 'bg-quickopia-navy text-white hover:bg-slate-900'
          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
      }`}
    >
      {label}
    </button>
  );
}
