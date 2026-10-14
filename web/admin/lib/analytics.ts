import { createClient } from './supabase/client';

export interface ProductPerformanceItem {
  title: string;
  total_sold_qty: number;
  total_sales_tzs: number;
}

export interface LowStockItem {
  id: string;
  title: string;
  stock_quantity: number;
  price_tzs: number;
  unit: string | null;
}

export interface DriverPerformanceItem {
  driver_id: string;
  driver_name: string | null;
  driver_phone: string | null;
  deliveries_completed: number;
  revenue_delivered_tzs: number;
}

export interface AnalyticsData {
  days_period: number;
  total_orders: number;
  completed_orders: number;
  cancelled_orders: number;
  total_revenue_tzs: number;
  delivery_orders: number;
  pickup_orders: number;
  status_counts: {
    placed: number;
    packing: number;
    ready: number;
    out_for_delivery: number;
    delivered: number;
    cancelled: number;
  };
  top_products_by_qty: ProductPerformanceItem[];
  top_products_by_rev: ProductPerformanceItem[];
  low_stock_products: LowStockItem[];
  driver_performance: DriverPerformanceItem[];
}

export async function fetchAnalytics(days: number): Promise<AnalyticsData> {
  const supabase = createClient();

  // Primary: Fast Postgres RPC aggregation
  const { data, error } = await supabase.rpc('get_admin_analytics', {
    p_days: days,
  });

  if (!error && data) {
    return data as AnalyticsData;
  }

  // Fallback: Client aggregation if migration not yet applied
  console.warn('Falling back to client query aggregation:', error?.message);
  const startTime = new Date(
    Date.now() - days * 24 * 60 * 60 * 1000
  ).toISOString();

  const [ordersRes, allOrdersRes, productsRes, driversRes] = await Promise.all([
    supabase
      .from('orders')
      .select('*, order_items(*)')
      .gte('created_at', startTime),
    supabase.from('orders').select('status'),
    supabase
      .from('products')
      .select('id, title, stock_quantity, price_tzs, unit, is_available')
      .eq('is_available', true)
      .lte('stock_quantity', 5)
      .order('stock_quantity', { ascending: true })
      .limit(10),
    supabase
      .from('profiles')
      .select('id, full_name, phone')
      .eq('role', 'driver'),
  ]);

  const orders = ordersRes.data ?? [];
  const allOrders = allOrdersRes.data ?? [];
  const lowStock = (productsRes.data ?? []) as LowStockItem[];
  const drivers = driversRes.data ?? [];

  const completed = orders.filter((o) => o.status === 'delivered');
  const cancelled = orders.filter((o) => o.status === 'cancelled');
  const revenue = completed.reduce((sum, o) => sum + (o.total_amount_tzs || 0), 0);
  const delivery = orders.filter((o) => o.fulfillment_type === 'delivery').length;
  const pickup = orders.filter((o) => o.fulfillment_type === 'pickup').length;

  const statusCounts = {
    placed: allOrders.filter((o) => o.status === 'placed').length,
    packing: allOrders.filter((o) => o.status === 'packing').length,
    ready: allOrders.filter((o) => o.status === 'ready').length,
    out_for_delivery: allOrders.filter((o) => o.status === 'out_for_delivery').length,
    delivered: allOrders.filter((o) => o.status === 'delivered').length,
    cancelled: allOrders.filter((o) => o.status === 'cancelled').length,
  };

  // Aggregate items
  const productMap: Record<string, { qty: number; rev: number }> = {};
  orders
    .filter((o) => o.status !== 'cancelled')
    .forEach((o) => {
      (o.order_items || []).forEach((item: { title: string; quantity: number; total_tzs: number }) => {
        if (!productMap[item.title]) {
          productMap[item.title] = { qty: 0, rev: 0 };
        }
        productMap[item.title].qty += item.quantity;
        productMap[item.title].rev += item.total_tzs;
      });
    });

  const productList: ProductPerformanceItem[] = Object.entries(productMap).map(
    ([title, stats]) => ({
      title,
      total_sold_qty: stats.qty,
      total_sales_tzs: stats.rev,
    })
  );

  const topByQty = [...productList]
    .sort((a, b) => b.total_sold_qty - a.total_sold_qty)
    .slice(0, 5);

  const topByRev = [...productList]
    .sort((a, b) => b.total_sales_tzs - a.total_sales_tzs)
    .slice(0, 5);

  const driverPerformance: DriverPerformanceItem[] = drivers.map((d) => {
    const driverOrders = completed.filter((o) => o.driver_id === d.id);
    return {
      driver_id: d.id,
      driver_name: d.full_name,
      driver_phone: d.phone,
      deliveries_completed: driverOrders.length,
      revenue_delivered_tzs: driverOrders.reduce(
        (sum, o) => sum + (o.total_amount_tzs || 0),
        0
      ),
    };
  });

  return {
    days_period: days,
    total_orders: orders.length,
    completed_orders: completed.length,
    cancelled_orders: cancelled.length,
    total_revenue_tzs: revenue,
    delivery_orders: delivery,
    pickup_orders: pickup,
    status_counts: statusCounts,
    top_products_by_qty: topByQty,
    top_products_by_rev: topByRev,
    low_stock_products: lowStock,
    driver_performance: driverPerformance,
  };
}
