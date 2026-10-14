import type { Order } from '@/lib/types';
import OrderCard from './OrderCard';
import { ClipboardList } from 'lucide-react';

export default function OrderColumn({
  title,
  orders,
  onAction,
}: {
  title: string;
  orders: Order[];
  onAction: (
    order: Order,
    action: 'packing-modal' | 'dispatch' | 'complete-pickup' | 'cancel'
  ) => void;
}) {
  return (
    <div className="bg-gray-100/90 rounded-2xl p-4 w-80 flex-shrink-0 flex flex-col border border-gray-200/80">
      <div className="flex justify-between items-center mb-3.5 pb-2 border-b border-gray-200">
        <h3 className="font-extrabold text-sm text-quickopia-navy">{title}</h3>
        <span className="text-xs font-black bg-white text-quickopia-navy px-2.5 py-0.5 rounded-full border border-gray-200 shadow-2xs">
          {orders.length}
        </span>
      </div>

      <div className="space-y-3 flex-1 overflow-y-auto max-h-[calc(100vh-220px)] pr-0.5">
        {orders.length === 0 ? (
          <div className="text-center py-12 text-gray-400 text-xs">
            <ClipboardList className="w-7 h-7 mx-auto mb-1.5 opacity-40 text-gray-400" />
            <p>No orders in this column</p>
          </div>
        ) : (
          orders.map((o) => (
            <OrderCard key={o.id} order={o} onAction={(a) => onAction(o, a)} />
          ))
        )}
      </div>
    </div>
  );
}
