'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { getOrderById, subscribeToOrder } from '@/lib/orders';
import type { Order } from '@/lib/types';
import OrderStatusTimeline from '@/components/OrderStatusTimeline';

export default function OrderConfirmationPage() {
  const { id } = useParams<{ id: string }>();
  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    let unsubscribe: (() => void) | undefined;

    getOrderById(id)
      .then((o) => {
        setOrder(o);
        setLoading(false);
        unsubscribe = subscribeToOrder(id, (updated) => {
          setOrder(updated);
        });
      })
      .catch((err) => {
        console.error('Failed to load order:', err);
        setError('Order could not be loaded.');
        setLoading(false);
      });

    return () => {
      unsubscribe?.();
    };
  }, [id]);

  if (loading) {
    return (
      <main className="max-w-lg mx-auto p-8 text-center py-24">
        <div className="inline-block w-8 h-8 border-4 border-quickopia-navy border-t-transparent rounded-full animate-spin mb-4" />
        <p className="text-gray-600 font-medium text-sm">
          Loading your order details...
        </p>
      </main>
    );
  }

  if (error || !order) {
    return (
      <main className="max-w-lg mx-auto p-8 text-center py-20">
        <span className="text-4xl">⚠️</span>
        <h1 className="text-xl font-bold mt-3 text-quickopia-navy">Order not found</h1>
        <p className="text-gray-500 text-sm mt-2 mb-6">
          We could not find an order matching that confirmation link.
        </p>
        <Link
          href="/"
          className="inline-block bg-quickopia-navy text-white px-6 py-3 rounded-xl font-bold"
        >
          Return to Storefront
        </Link>
      </main>
    );
  }

  const isPickup = order.fulfillment_type === 'pickup';
  const fmt = (n: number) => `TZS ${n.toLocaleString('en-US')}`;

  return (
    <main className="max-w-lg mx-auto p-4 sm:p-6 space-y-6 pb-24">
      <div className="text-center pt-2">
        <div className="inline-flex items-center justify-center w-14 h-14 bg-green-100 text-green-700 rounded-full text-2xl mb-2">
          ✓
        </div>
        <h1 className="text-2xl font-black text-quickopia-navy">
          Order #{order.order_number}
        </h1>
        <p className="text-gray-600 text-xs sm:text-sm mt-1">
          {isPickup
            ? 'Show your 4-digit pickup code when collecting at the store.'
            : 'This page updates live via Realtime as your order progresses.'}
        </p>
      </div>

      {isPickup && (
        <div className="bg-quickopia-navy text-white rounded-2xl py-6 px-4 text-center shadow-md">
          <p className="text-[11px] font-bold tracking-widest text-quickopia-amber uppercase">
            Store Collection Code
          </p>
          <p className="text-4xl sm:text-5xl font-extrabold tracking-[0.3em] sm:tracking-[0.4em] mt-2 font-mono text-white">
            {order.pickup_code}
          </p>
          <p className="text-xs text-white/75 mt-3">
            Present this code to the supermarket cashier or collection desk.
          </p>
        </div>
      )}

      <div className="bg-white border border-gray-200 rounded-2xl p-5 shadow-sm">
        <div className="flex items-center justify-between mb-3 border-b border-gray-100 pb-2">
          <h2 className="font-bold text-sm text-quickopia-navy">Order Status</h2>
          <span className="text-xs bg-green-50 text-green-700 font-semibold px-2 py-0.5 rounded-full flex items-center gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-ping" />
            Live Tracking
          </span>
        </div>
        <OrderStatusTimeline
          status={order.status}
          fulfillmentType={order.fulfillment_type}
        />
      </div>

      <div className="bg-white border border-gray-200 rounded-2xl p-5 shadow-sm space-y-3">
        <h2 className="font-bold text-sm text-quickopia-navy border-b border-gray-100 pb-2">
          Order Items ({order.order_items?.length ?? 0})
        </h2>
        <div className="divide-y divide-gray-100">
          {(order.order_items || []).map((item) => (
            <div
              key={item.id}
              className="flex justify-between items-center py-2.5 text-sm"
            >
              <div>
                <p className="font-semibold text-gray-900">{item.title}</p>
                <p className="text-xs text-gray-500">
                  Qty: {item.quantity} &times; {fmt(item.unit_price_tzs)}
                </p>
              </div>
              <span className="font-bold text-quickopia-navy">
                {fmt(item.total_tzs)}
              </span>
            </div>
          ))}
        </div>

        <div className="border-t border-gray-200 pt-3 space-y-1.5 text-sm">
          <div className="flex justify-between text-gray-600">
            <span>Subtotal</span>
            <span>{fmt(order.subtotal_tzs)}</span>
          </div>
          <div className="flex justify-between text-gray-600">
            <span>Delivery Fee</span>
            <span>
              {order.delivery_fee_tzs > 0
                ? fmt(order.delivery_fee_tzs)
                : 'FREE (Pickup)'}
            </span>
          </div>
          <div className="flex justify-between font-extrabold text-base text-quickopia-navy pt-2 border-t border-gray-100">
            <span>Total Amount</span>
            <span>{fmt(order.total_amount_tzs)}</span>
          </div>
        </div>
      </div>

      {order.payment_method === 'lipa_namba' && order.payment_status !== 'paid' && (
        <div className="bg-amber-50 border-2 border-amber-300 rounded-2xl p-5 text-xs text-amber-950 space-y-2">
          <div className="flex items-center gap-2">
            <span className="text-xl">📱</span>
            <h3 className="font-extrabold text-sm text-quickopia-navy">
              Lipa Namba Payment Instructions
            </h3>
          </div>
          <p className="font-medium leading-relaxed">
            Please transfer{' '}
            <strong className="text-quickopia-navy underline">
              {fmt(order.total_amount_tzs)}
            </strong>{' '}
            via M-Pesa, Tigo Pesa, or Airtel Money to the supermarket account:
          </p>
          <div className="bg-white/90 border border-amber-200 rounded-xl p-3 font-mono font-black text-sm text-quickopia-navy text-center tracking-wider">
            LIPA NAMBA: 554433 (Quickopia Supermarket)
          </div>
          <p className="text-[11px] text-amber-800">
            Show the transaction confirmation SMS to your delivery driver upon
            arrival or to the cashier when collecting in-store.
          </p>
        </div>
      )}

      <div className="bg-gray-50 border border-gray-200 rounded-xl p-4 text-xs text-gray-600 space-y-1">
        <p>
          <span className="font-semibold text-gray-800">Fulfillment:</span>{' '}
          {isPickup ? 'Click & Collect (Store Pickup)' : 'Doorstep Delivery'}
        </p>
        <p>
          <span className="font-semibold text-gray-800">Payment:</span>{' '}
          {order.payment_method === 'cod'
            ? 'Cash on Delivery / Pickup'
            : 'Lipa Kwa Simu (Mobile Money)'}{' '}
          &bull;{' '}
          <span className="capitalize font-semibold text-amber-800">
            {order.payment_status}
          </span>
        </p>
      </div>

      <Link
        href="/"
        className="block text-center bg-quickopia-amber hover:bg-amber-400 text-black font-extrabold py-3.5 px-4 rounded-xl shadow transition"
      >
        Back to Shopping
      </Link>
    </main>
  );
}
