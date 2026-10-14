'use client';

export default function FulfillmentToggle({
  value,
  onChange,
}: {
  value: 'delivery' | 'pickup';
  onChange: (v: 'delivery' | 'pickup') => void;
}) {
  return (
    <div className="grid grid-cols-2 gap-3">
      {(['delivery', 'pickup'] as const).map((opt) => (
        <button
          key={opt}
          type="button"
          onClick={() => onChange(opt)}
          className={`py-4 px-3 rounded-xl font-semibold border-2 transition shadow-sm flex items-center justify-center text-sm md:text-base ${
            value === opt
              ? 'bg-quickopia-navy text-white border-quickopia-navy'
              : 'bg-white border-gray-200 text-gray-700 hover:border-gray-300'
          }`}
        >
          {opt === 'delivery' ? '🛵 Doorstep Delivery' : '🏬 Click & Collect'}
        </button>
      ))}
    </div>
  );
}
