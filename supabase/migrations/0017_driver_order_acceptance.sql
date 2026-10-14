-- 0017_driver_order_acceptance.sql
-- Enables drivers to browse available ready delivery orders and accept assignments

-- 1. Function for drivers to retrieve available unassigned deliveries
create or replace function public.get_available_deliveries()
returns setof public.orders as $$
  select * from public.orders
  where driver_id is null
    and status in ('ready', 'packing', 'placed')
    and fulfillment_type = 'delivery'
  order by created_at asc;
$$ language sql security definer stable;

-- 2. Atomic RPC for a driver to claim/accept a delivery order
create or replace function public.accept_order_delivery(p_order_id uuid)
returns void as $$
declare
  v_order public.orders%rowtype;
begin
  select * into v_order from public.orders where id = p_order_id for update;

  if v_order.id is null then
    raise exception 'Order not found';
  end if;

  if v_order.driver_id is not null and v_order.driver_id is distinct from auth.uid() then
    raise exception 'This order has already been claimed by another driver';
  end if;

  if v_order.status in ('delivered', 'cancelled') then
    raise exception 'This order is already closed and cannot be accepted';
  end if;

  update public.orders
  set driver_id = auth.uid(),
      status = 'out_for_delivery',
      updated_at = now()
  where id = p_order_id;
end;
$$ language plpgsql security definer;

-- 3. Policy: allow drivers to view unassigned orders awaiting dispatch
do $$ begin
  create policy "drivers view unassigned ready orders"
    on public.orders for select
    using (
      public.is_driver()
      and driver_id is null
      and status in ('ready', 'packing', 'placed')
      and fulfillment_type = 'delivery'
    );
exception when duplicate_object then null;
end $$;
