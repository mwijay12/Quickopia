import type { DriverPerformanceItem } from '@/lib/analytics';

export default function DriverPerformanceTable({
  drivers,
}: {
  drivers: DriverPerformanceItem[];
}) {
  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5 shadow-xs space-y-4">
      <div>
        <h3 className="font-bold text-sm text-quickopia-navy">
          Driver Delivery Performance
        </h3>
        <p className="text-xs text-gray-500">
          Completed doorstep deliveries and delivered value during the selected period
        </p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs">
          <thead className="bg-gray-50 text-gray-500 font-bold uppercase tracking-wider border-b border-gray-100">
            <tr>
              <th className="p-3">Driver Name</th>
              <th className="p-3">Phone</th>
              <th className="p-3 text-center">Completed Deliveries</th>
              <th className="p-3 text-right">Value Delivered</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {drivers.map((d) => (
              <tr key={d.driver_id} className="hover:bg-gray-50/60 transition">
                <td className="p-3 font-bold text-gray-900">
                  {d.driver_name ?? 'Driver'}
                </td>
                <td className="p-3 text-gray-500">{d.driver_phone ?? '—'}</td>
                <td className="p-3 text-center font-bold text-quickopia-navy">
                  {d.deliveries_completed} deliveries
                </td>
                <td className="p-3 text-right font-extrabold text-quickopia-navy">
                  TZS {d.revenue_delivered_tzs.toLocaleString('en-US')}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {drivers.length === 0 && (
          <div className="py-8 text-center text-xs text-gray-400">
            No driver delivery data available for this timeframe.
          </div>
        )}
      </div>
    </div>
  );
}
