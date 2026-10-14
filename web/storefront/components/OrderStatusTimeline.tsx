'use client';

const DELIVERY_STEPS = [
  { key: 'placed', label: 'Order Placed' },
  { key: 'packing', label: 'Packing at Supermarket' },
  { key: 'out_for_delivery', label: 'Out for Delivery' },
  { key: 'delivered', label: 'Delivered' },
];

const PICKUP_STEPS = [
  { key: 'placed', label: 'Order Placed' },
  { key: 'packing', label: 'Packing at Supermarket' },
  { key: 'ready', label: 'Ready for Pickup' },
  { key: 'delivered', label: 'Collected' },
];

export default function OrderStatusTimeline({
  status,
  fulfillmentType,
}: {
  status: string;
  fulfillmentType: string;
}) {
  const steps = fulfillmentType === 'pickup' ? PICKUP_STEPS : DELIVERY_STEPS;
  const currentIndex = steps.findIndex((s) => s.key === status);

  if (status === 'cancelled') {
    return (
      <div className="bg-red-50 text-red-700 border border-red-200 p-4 rounded-xl font-semibold text-sm">
        This order was cancelled.
      </div>
    );
  }

  return (
    <div className="space-y-0 py-2">
      {steps.map((s, i) => {
        const isDone = i <= currentIndex;
        const isCurrent = i === currentIndex;
        return (
          <div key={s.key} className="flex items-start gap-3">
            <div className="flex flex-col items-center">
              <div
                className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold transition shadow-sm ${
                  isDone
                    ? 'bg-green-600 text-white'
                    : 'bg-gray-200 text-gray-400'
                } ${isCurrent ? 'ring-4 ring-green-100 animate-pulse' : ''}`}
              >
                {isDone ? '✓' : i + 1}
              </div>
              {i < steps.length - 1 && (
                <div
                  className={`w-0.5 h-8 my-0.5 ${
                    i < currentIndex ? 'bg-green-600' : 'bg-gray-200'
                  }`}
                />
              )}
            </div>
            <div className="pt-0.5">
              <p
                className={`text-sm leading-tight ${
                  isCurrent
                    ? 'font-bold text-quickopia-navy'
                    : isDone
                    ? 'font-semibold text-gray-800'
                    : 'text-gray-400'
                }`}
              >
                {s.label}
              </p>
            </div>
          </div>
        );
      })}
    </div>
  );
}
