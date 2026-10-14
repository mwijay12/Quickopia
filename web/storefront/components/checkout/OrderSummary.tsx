'use client';

export default function OrderSummary({
  subtotal,
  deliveryFee,
}: {
  subtotal: number;
  deliveryFee: number;
}) {
  const fmt = (n: number) => `TZS ${n.toLocaleString('en-US')}`;

  return (
    <div className="border border-gray-200 rounded-xl p-4 space-y-2 bg-white shadow-sm">
      <h3 className="font-semibold text-sm text-quickopia-navy mb-2">
        Order Summary
      </h3>
      <Row label="Subtotal" value={fmt(subtotal)} />
      <Row
        label="Delivery Fee"
        value={deliveryFee > 0 ? fmt(deliveryFee) : 'FREE (Pickup)'}
      />
      <div className="border-t border-gray-200 pt-2.5 mt-2">
        <Row label="Total Amount" value={fmt(subtotal + deliveryFee)} bold />
      </div>
    </div>
  );
}

function Row({
  label,
  value,
  bold,
}: {
  label: string;
  value: string;
  bold?: boolean;
}) {
  return (
    <div
      className={`flex justify-between items-center text-sm ${
        bold ? 'font-extrabold text-base text-quickopia-navy' : 'text-gray-600'
      }`}
    >
      <span>{label}</span>
      <span className={bold ? 'text-quickopia-navy' : 'font-semibold text-gray-900'}>
        {value}
      </span>
    </div>
  );
}
