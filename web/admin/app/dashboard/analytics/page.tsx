'use client';

import { useEffect, useState, useCallback } from 'react';
import { fetchAnalytics, AnalyticsData } from '@/lib/analytics';
import MetricCard from '@/components/analytics/MetricCard';
import StatusBreakdownCard from '@/components/analytics/StatusBreakdownCard';
import TopProductsTable from '@/components/analytics/TopProductsTable';
import LowStockAlertCard from '@/components/analytics/LowStockAlertCard';
import DriverPerformanceTable from '@/components/analytics/DriverPerformanceTable';
import { CardGridSkeleton } from '@/components/ui/Skeleton';
import { RefreshCw, DollarSign, Package, ShoppingCart, Bike } from 'lucide-react';

const TIME_RANGES = [
  { label: 'Today', days: 1 },
  { label: 'Last 7 Days', days: 7 },
  { label: 'Last 30 Days', days: 30 },
  { label: 'Last 90 Days', days: 90 },
];

export default function AnalyticsPage() {
  const [days, setDays] = useState<number>(7);
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  const loadMetrics = useCallback(async (selectedDays: number) => {
    setLoading(true);
    try {
      const res = await fetchAnalytics(selectedDays);
      setData(res);
    } catch (e) {
      console.error('Failed to load analytics:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadMetrics(days);
  }, [days, loadMetrics]);

  const fmtTzs = (amount: number) => `TZS ${amount.toLocaleString('en-US')}`;

  const avgOrderValue =
    data && data.completed_orders > 0
      ? Math.round(data.total_revenue_tzs / data.completed_orders)
      : 0;

  const totalFulfillment =
    data ? data.delivery_orders + data.pickup_orders : 0;
  const deliveryPct =
    totalFulfillment > 0
      ? Math.round(((data?.delivery_orders ?? 0) / totalFulfillment) * 100)
      : 0;

  return (
    <div className="space-y-6 max-w-7xl pb-16">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-black text-quickopia-navy">
            Business Analytics &amp; Performance
          </h2>
          <p className="text-xs text-gray-500 mt-1">
            Executive revenue, fulfillment mix, stock health, and driver performance
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="flex bg-gray-200/80 p-1 rounded-xl text-xs font-bold">
            {TIME_RANGES.map((r) => (
              <button
                key={r.days}
                type="button"
                onClick={() => setDays(r.days)}
                className={`px-3 py-1.5 rounded-lg transition ${
                  days === r.days
                    ? 'bg-white text-quickopia-navy shadow-xs'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                {r.label}
              </button>
            ))}
          </div>

          <button
            type="button"
            onClick={() => loadMetrics(days)}
            title="Refresh analytics data"
            className="p-2.5 rounded-xl border border-gray-200 bg-white hover:bg-gray-100 text-gray-600 transition shadow-2xs flex items-center justify-center"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-quickopia-amber' : ''}`} />
          </button>
        </div>
      </div>

      {loading && !data ? (
        <div className="space-y-6">
          <CardGridSkeleton count={4} />
          <div className="h-64 bg-gray-100/80 rounded-2xl animate-pulse" />
        </div>
      ) : data ? (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <MetricCard
              title="Settled Revenue"
              value={fmtTzs(data.total_revenue_tzs)}
              subtitle={`From ${data.completed_orders} delivered orders`}
              icon={<DollarSign className="w-5 h-5 text-emerald-600" />}
              badge={{
                text: 'Delivered only (excl. cancelled)',
                color: 'green',
              }}
            />
            <MetricCard
              title="Total Orders Placed"
              value={data.total_orders}
              subtitle={`${data.completed_orders} delivered • ${data.cancelled_orders} cancelled`}
              icon={<Package className="w-5 h-5 text-quickopia-navy" />}
              badge={{
                text: `${data.cancelled_orders} Cancelled`,
                color: data.cancelled_orders > 0 ? 'amber' : 'gray',
              }}
            />
            <MetricCard
              title="Average Order Value"
              value={fmtTzs(avgOrderValue)}
              subtitle="Per completed customer order"
              icon={<ShoppingCart className="w-5 h-5 text-blue-600" />}
              badge={{ text: 'Completed', color: 'blue' }}
            />
            <MetricCard
              title="Fulfillment Mix"
              value={`${deliveryPct}% Delivery`}
              subtitle={`${data.delivery_orders} Delivery vs ${data.pickup_orders} Pickup`}
              icon={<Bike className="w-5 h-5 text-quickopia-amber" />}
              badge={{
                text: `${100 - deliveryPct}% Click & Collect`,
                color: 'amber',
              }}
            />
          </div>

          <StatusBreakdownCard counts={data.status_counts} />

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <TopProductsTable
              byQuantity={data.top_products_by_qty}
              byRevenue={data.top_products_by_rev}
            />
            <LowStockAlertCard items={data.low_stock_products} />
          </div>

          <DriverPerformanceTable drivers={data.driver_performance} />
        </>
      ) : null}
    </div>
  );
}
