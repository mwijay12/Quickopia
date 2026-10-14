import Link from 'next/link';
import type { LowStockItem } from '@/lib/analytics';
import { AlertTriangle, CheckCircle2 } from 'lucide-react';

export default function LowStockAlertCard({
  items,
}: {
  items: LowStockItem[];
}) {
  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5 shadow-xs space-y-4">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="font-bold text-sm text-quickopia-navy flex items-center gap-1.5">
            <AlertTriangle className="w-4 h-4 text-amber-500" />
            <span>Low-Stock Inventory Alerts</span>
          </h3>
          <p className="text-xs text-gray-500">
            Active products with 5 or fewer units remaining on shelves
          </p>
        </div>
        <Link
          href="/dashboard/catalog"
          className="text-xs font-bold text-quickopia-navy hover:underline"
        >
          Manage Catalog &rarr;
        </Link>
      </div>

      <div className="space-y-2">
        {items.map((item) => (
          <div
            key={item.id}
            className="flex justify-between items-center p-3 rounded-xl border border-gray-100 hover:bg-gray-50/60 transition text-xs"
          >
            <div>
              <p className="font-bold text-gray-900">{item.title}</p>
              <p className="text-[11px] text-gray-500">
                TZS {item.price_tzs.toLocaleString('en-US')}{' '}
                {item.unit ? `per ${item.unit}` : ''}
              </p>
            </div>
            <div className="text-right">
              <span
                className={`font-black px-2.5 py-1 rounded-full text-xs ${
                  item.stock_quantity === 0
                    ? 'bg-red-100 text-red-700'
                    : 'bg-amber-100 text-amber-800'
                }`}
              >
                {item.stock_quantity === 0
                  ? 'Out of Stock'
                  : `${item.stock_quantity} left`}
              </span>
            </div>
          </div>
        ))}

        {items.length === 0 && (
          <div className="py-8 text-center text-xs text-emerald-700 bg-emerald-50/50 rounded-xl border border-emerald-100 flex items-center justify-center gap-1.5">
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            <span>All active products have healthy inventory levels (&gt; 5 units).</span>
          </div>
        )}
      </div>
    </div>
  );
}
