'use client';

import { useCart } from '@/context/CartContext';
import { buildWhatsAppOrderUrl } from '@/lib/whatsapp';

export default function CartDrawer({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const { items, subtotalTzs, increment, decrement, removeItem } = useCart();
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end animate-in fade-in duration-200">
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="relative bg-white w-full max-w-sm h-full p-5 overflow-y-auto flex flex-col shadow-2xl">
        <div className="flex justify-between items-center pb-4 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <h2 className="text-xl font-bold text-quickopia-navy">Your Cart</h2>
            <span className="text-xs bg-gray-100 px-2 py-0.5 rounded-full font-bold text-gray-700">
              {items.length} items
            </span>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-700 flex items-center justify-center font-bold transition"
          >
            ✕
          </button>
        </div>

        {items.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center text-center p-6">
            <span className="text-4xl mb-3">🛒</span>
            <p className="text-gray-700 font-bold">Your cart is empty</p>
            <p className="text-gray-400 text-xs mt-1">
              Add products from the catalog to build your order.
            </p>
          </div>
        ) : (
          <div className="flex-1 space-y-4 py-4 divide-y divide-gray-100 overflow-y-auto">
            {items.map((i) => (
              <div
                key={i.productId}
                className="flex justify-between items-start pt-3 first:pt-0"
              >
                <div className="pr-3 flex-1">
                  <p className="font-semibold text-sm text-gray-900 leading-snug">
                    {i.title}
                  </p>
                  {i.unit && (
                    <p className="text-xs text-gray-500 mt-0.5">{i.unit}</p>
                  )}
                  <p className="text-sm font-bold text-quickopia-navy mt-1">
                    TZS {(i.priceTzs * i.quantity).toLocaleString('en-US')}
                  </p>
                </div>
                <div className="flex flex-col items-end gap-1.5 shrink-0">
                  <div className="flex items-center gap-2 bg-gray-100 rounded-lg px-2 py-1">
                    <button
                      type="button"
                      onClick={() => decrement(i.productId)}
                      className="font-bold text-sm text-gray-700 hover:text-black px-1"
                    >
                      −
                    </button>
                    <span className="font-bold text-sm text-black min-w-[14px] text-center">
                      {i.quantity}
                    </span>
                    <button
                      type="button"
                      onClick={() => increment(i.productId)}
                      className="font-bold text-sm text-gray-700 hover:text-black px-1"
                    >
                      +
                    </button>
                  </div>
                  <button
                    type="button"
                    onClick={() => removeItem(i.productId)}
                    className="text-red-500 hover:text-red-700 text-xs font-medium"
                  >
                    Remove
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        <div className="border-t border-gray-100 pt-4 mt-auto">
          <div className="flex justify-between items-center font-bold mb-4 text-base">
            <span className="text-gray-600">Subtotal</span>
            <span className="text-quickopia-navy text-lg">
              TZS {subtotalTzs.toLocaleString('en-US')}
            </span>
          </div>
          <a
            href={items.length > 0 ? '/checkout' : undefined}
            aria-disabled={items.length === 0}
            onClick={items.length === 0 ? (e) => e.preventDefault() : undefined}
            className={`block text-center py-3.5 px-4 rounded-xl font-bold transition shadow mb-2.5 ${
              items.length === 0
                ? 'bg-gray-200 text-gray-400 pointer-events-none'
                : 'bg-quickopia-navy hover:bg-slate-900 text-white'
            }`}
          >
            Checkout Now
          </a>
          <a
            href={
              items.length > 0
                ? buildWhatsAppOrderUrl(items, subtotalTzs)
                : undefined
            }
            target="_blank"
            rel="noopener noreferrer"
            aria-disabled={items.length === 0}
            className={`block text-center py-3 px-4 rounded-xl font-bold transition border border-green-600 text-green-700 hover:bg-green-50 ${
              items.length === 0
                ? 'bg-gray-200 text-gray-400 pointer-events-none border-transparent'
                : ''
            }`}
          >
            Or Send Order via WhatsApp
          </a>
          <p className="text-[11px] text-gray-500 mt-2.5 text-center leading-relaxed">
            Direct web checkout places your order instantly. Or chat with store staff on WhatsApp.
          </p>
        </div>
      </div>
    </div>
  );
}
