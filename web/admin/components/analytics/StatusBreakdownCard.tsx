import type { AnalyticsData } from '@/lib/analytics';

export default function StatusBreakdownCard({
  counts,
}: {
  counts: AnalyticsData['status_counts'];
}) {
  const total =
    counts.placed +
    counts.packing +
    counts.ready +
    counts.out_for_delivery +
    counts.delivered +
    counts.cancelled;

  const items = [
    { label: 'New', count: counts.placed, color: 'bg-blue-500' },
    { label: 'Packing', count: counts.packing, color: 'bg-amber-500' },
    { label: 'Ready', count: counts.ready, color: 'bg-purple-500' },
    { label: 'Dispatched', count: counts.out_for_delivery, color: 'bg-indigo-500' },
    { label: 'Delivered', count: counts.delivered, color: 'bg-green-500' },
    { label: 'Cancelled', count: counts.cancelled, color: 'bg-red-400' },
  ];

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5 shadow-xs space-y-4">
      <div className="flex justify-between items-center">
        <div>
          <h3 className="font-bold text-sm text-quickopia-navy">
            Operational Order Status Distribution
          </h3>
          <p className="text-xs text-gray-500">
            Current health check across all active and settled orders
          </p>
        </div>
        <span className="text-xs font-bold text-gray-600 bg-gray-100 px-2.5 py-1 rounded-lg">
          {total} Total Lifetime Orders
        </span>
      </div>

      {total > 0 && (
        <div className="w-full h-3 rounded-full bg-gray-100 overflow-hidden flex">
          {items.map((it) => {
            const pct = (it.count / total) * 100;
            if (pct === 0) return null;
            return (
              <div
                key={it.label}
                style={{ width: `${pct}%` }}
                className={`${it.color} h-full transition-all duration-500`}
                title={`${it.label}: ${it.count} (${pct.toFixed(1)}%)`}
              />
            );
          })}
        </div>
      )}

      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-3 pt-1 text-xs">
        {items.map((it) => (
          <div
            key={it.label}
            className="border border-gray-100 rounded-xl p-2.5 bg-gray-50/50"
          >
            <div className="flex items-center gap-1.5 mb-1">
              <span className={`w-2 h-2 rounded-full ${it.color}`} />
              <span className="text-gray-600 font-semibold">{it.label}</span>
            </div>
            <p className="text-lg font-black text-gray-900">{it.count}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
