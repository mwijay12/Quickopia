-- 0012_admin_analytics_function.sql
-- Server-side Admin Analytics Aggregation Function

create or replace function public.get_admin_analytics(p_days integer default 7)
returns json as $$
declare
  v_start_time timestamptz;
  v_result json;
begin
  if not public.is_admin() then
    raise exception 'Only admin staff can view business analytics';
  end if;

  v_start_time := now() - (p_days || ' days')::interval;

  with period_orders as (
    select *
    from orders
    where created_at >= v_start_time
  ),
  metrics as (
    select
      count(*)::integer as total_orders,
      count(*) filter (where status = 'delivered')::integer as completed_orders,
      count(*) filter (where status = 'cancelled')::integer as cancelled_orders,
      coalesce(sum(total_amount_tzs) filter (where status = 'delivered'), 0) as total_revenue_tzs,
      count(*) filter (where fulfillment_type = 'delivery')::integer as delivery_orders,
      count(*) filter (where fulfillment_type = 'pickup')::integer as pickup_orders
    from period_orders
  ),
  status_dist as (
    select json_build_object(
      'placed', count(*) filter (where status = 'placed'),
      'packing', count(*) filter (where status = 'packing'),
      'ready', count(*) filter (where status = 'ready'),
      'out_for_delivery', count(*) filter (where status = 'out_for_delivery'),
      'delivered', count(*) filter (where status = 'delivered'),
      'cancelled', count(*) filter (where status = 'cancelled')
    ) as counts
    from orders -- all-time active health check
  ),
  top_by_qty as (
    select coalesce(json_agg(t), '[]'::json) as items
    from (
      select
        oi.title,
        sum(oi.quantity)::integer as total_sold_qty,
        sum(oi.total_tzs)::numeric as total_sales_tzs
      from order_items oi
      join orders o on o.id = oi.order_id
      where o.created_at >= v_start_time
        and o.status != 'cancelled'
      group by oi.title
      order by total_sold_qty desc
      limit 5
    ) t
  ),
  top_by_rev as (
    select coalesce(json_agg(t), '[]'::json) as items
    from (
      select
        oi.title,
        sum(oi.quantity)::integer as total_sold_qty,
        sum(oi.total_tzs)::numeric as total_sales_tzs
      from order_items oi
      join orders o on o.id = oi.order_id
      where o.created_at >= v_start_time
        and o.status != 'cancelled'
      group by oi.title
      order by total_sales_tzs desc
      limit 5
    ) t
  ),
  low_stock as (
    select coalesce(json_agg(l), '[]'::json) as items
    from (
      select id, title, stock_quantity, price_tzs, unit
      from products
      where is_available = true
        and stock_quantity <= 5
      order by stock_quantity asc, title asc
      limit 10
    ) l
  ),
  driver_stats as (
    select coalesce(json_agg(d), '[]'::json) as items
    from (
      select
        p.id as driver_id,
        p.full_name as driver_name,
        p.phone as driver_phone,
        count(o.id)::integer as deliveries_completed,
        coalesce(sum(o.total_amount_tzs), 0)::numeric as revenue_delivered_tzs
      from profiles p
      left join orders o on o.driver_id = p.id
        and o.status = 'delivered'
        and o.created_at >= v_start_time
      where p.role = 'driver'
      group by p.id, p.full_name, p.phone
      order by deliveries_completed desc, p.full_name asc
    ) d
  )
  select json_build_object(
    'days_period', p_days,
    'total_orders', m.total_orders,
    'completed_orders', m.completed_orders,
    'cancelled_orders', m.cancelled_orders,
    'total_revenue_tzs', m.total_revenue_tzs,
    'delivery_orders', m.delivery_orders,
    'pickup_orders', m.pickup_orders,
    'status_counts', sd.counts,
    'top_products_by_qty', tq.items,
    'top_products_by_rev', tr.items,
    'low_stock_products', ls.items,
    'driver_performance', ds.items
  ) into v_result
  from metrics m, status_dist sd, top_by_qty tq, top_by_rev tr, low_stock ls, driver_stats ds;

  return v_result;
end;
$$ language plpgsql security definer;
