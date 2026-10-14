'use client';

import { useState } from 'react';
import type { ProductPerformanceItem } from '@/lib/analytics';

export default function TopProductsTable({
  byQuantity,
  byRevenue,
}: {
  byQuantity: ProductPerformanceItem[];
  byRevenue: ProductPerformanceItem[];
}) {
  const [metric, setMetric] = useState<'quantity' | 'revenue'>('quantity');
  const items = metric === 'quantity' ? byQuantity : byRevenue;

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5 shadow-xs space-y-4">
      <div className="flex justify-between items-center flex-wrap gap-2">
        <div>
          <h3 className="font-bold text-sm text-quickopia-navy">
            Top-Selling Products
          </h3>
          <p className="text-xs text-gray-500">
            Ranked by total units moved or gross revenue generated
          </p>
        </div>

        <div className="flex bg-gray-100 p-0.5 rounded-xl text-xs font-bold">
          <button
            type="button"
            onClick={() => setMetric('quantity')}
            className={`px-3 py-1.5 rounded-lg transition ${
              metric === 'quantity'
                ? 'bg-white text-quickopia-navy shadow-2xs'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            By Quantity (Units)
          </button>
          <button
            type="button"
            onClick={() => setMetric('revenue')}
            className={`px-3 py-1.5 rounded-lg transition ${
              metric === 'revenue'
                ? 'bg-white text-quickopia-navy shadow-2xs'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            By Revenue (TZS)
          </button>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs">
          <thead className="bg-gray-50 text-gray-500 font-bold uppercase tracking-wider border-b border-gray-100">
            <tr>
              <th className="p-3">#</th>
              <th className="p-3">Product Name</th>
              <th className="p-3 text-center">Units Sold</th>
              <th className="p-3 text-right">Gross Sales</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {items.map((item, idx) => (
              <tr key={item.title} className="hover:bg-gray-50/60 transition">
                <td className="p-3 font-black text-gray-400">{idx + 1}</td>
                <td className="p-3 font-bold text-gray-900">{item.title}</td>
                <td className="p-3 text-center font-bold text-quickopia-navy">
                  {item.total_sold_qty.toLocaleString('en-US')} units
                </td>
                <td className="p-3 text-right font-extrabold text-quickopia-navy">
                  TZS {item.total_sales_tzs.toLocaleString('en-US')}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {items.length === 0 && (
          <div className="py-8 text-center text-xs text-gray-400">
            No product sales recorded in this period.
          </div>
        )}
      </div>
    </div>
  );
}
