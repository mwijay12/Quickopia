'use client';

import Image from 'next/image';
import type { Product } from '@/lib/types';
import { useCart } from '@/context/CartContext';

export default function ProductCard({ product }: { product: Product }) {
  const { quantityOf, addItem, increment, decrement } = useCart();
  const qty = quantityOf(product.id);
  const inStock = product.is_available && product.stock_quantity > 0;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200/80 overflow-hidden flex flex-col hover:shadow-md transition">
      <div className="aspect-square bg-gray-100 relative">
        {product.image_url ? (
          <Image
            src={product.image_url}
            alt={product.title}
            fill
            sizes="(max-width: 768px) 50vw, 25vw"
            className="object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-gray-400 text-xs font-medium">
            No image
          </div>
        )}
        {product.is_popular && (
          <span className="absolute top-2 left-2 bg-quickopia-navy text-white text-[10px] font-bold px-2 py-0.5 rounded shadow">
            POPULAR
          </span>
        )}
      </div>
      <div className="p-3 flex flex-col gap-1 flex-1">
        <h3
          className="font-semibold text-sm line-clamp-2 text-gray-900"
          title={product.title}
        >
          {product.title}
        </h3>
        {product.unit && (
          <span className="text-xs text-gray-500 font-medium">
            {product.unit}
          </span>
        )}
        <div className="mt-auto flex items-center justify-between pt-2">
          <span className="font-bold text-sm text-quickopia-navy">
            TZS {product.price_tzs.toLocaleString('en-US')}
          </span>
          {!inStock ? (
            <span className="text-xs text-red-600 font-semibold bg-red-50 px-2 py-0.5 rounded">
              Out of stock
            </span>
          ) : qty === 0 ? (
            <button
              type="button"
              onClick={() => addItem(product)}
              className="bg-quickopia-amber hover:bg-amber-400 text-black w-8 h-8 rounded-lg font-bold flex items-center justify-center transition shadow-sm"
              title="Add to cart"
            >
              +
            </button>
          ) : (
            <div className="flex items-center gap-2 bg-quickopia-amber rounded-lg px-2 py-1 shadow-sm">
              <button
                type="button"
                onClick={() => decrement(product.id)}
                className="font-bold text-black hover:opacity-75 px-1"
              >
                −
              </button>
              <span className="font-bold text-sm text-black min-w-[14px] text-center">
                {qty}
              </span>
              <button
                type="button"
                onClick={() =>
                  qty < product.stock_quantity && increment(product.id)
                }
                className={`font-bold text-black px-1 ${
                  qty >= product.stock_quantity
                    ? 'opacity-30 cursor-not-allowed'
                    : 'hover:opacity-75'
                }`}
              >
                +
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
