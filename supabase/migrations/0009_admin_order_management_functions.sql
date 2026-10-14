-- 0009_admin_order_management_functions.sql

-- CORRECTION: allow admin/staff to complete an order too (needed for in-store
-- pickup handoff, which is confirmed by staff at the counter, not a driver).
-- The mandatory code-check is unchanged and still applies to BOTH paths.
create or replace function public.complete_delivery(
  p_order_id uuid,
  p_entered_code text,
  p_payment_status payment_status
)
returns void as $$
declare
  v_order orders%rowtype;
begin
  select * into v_order from orders where id = p_order_id for update;

  if v_order.id is null then
    raise exception 'Order not found';
  end if;

  if v_order.driver_id is distinct from auth.uid() and not public.is_admin() then
    raise exception 'You are not authorized to complete this order';
  end if;

  if v_order.status = 'delivered' then
    raise exception 'This order is already marked as delivered';
  end if;

  if v_order.pickup_code is distinct from p_entered_code then
    raise exception 'Incorrect confirmation code';
  end if;

  update orders
  set status = 'delivered', payment_status = p_payment_status, updated_at = now()
  where id = p_order_id;
end;
$$ language plpgsql security definer;


-- NEW: the single validated entry point for admin-driven status changes
-- (placed -> packing -> ready, and attaching a driver at dispatch time).
-- Prevents accidentally reopening an already-closed order.
create or replace function public.admin_update_order_status(
  p_order_id uuid,
  p_new_status order_status,
  p_driver_id uuid default null
)
returns void as $$
declare
  v_order orders%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Only admin staff can update orders this way';
  end if;

  select * into v_order from orders where id = p_order_id for update;
  if v_order.id is null then
    raise exception 'Order not found';
  end if;

  if v_order.status in ('delivered', 'cancelled') then
    raise exception 'This order is already closed and cannot be changed';
  end if;

  update orders
  set status = p_new_status,
      driver_id = coalesce(p_driver_id, driver_id),
      updated_at = now()
  where id = p_order_id;
end;
$$ language plpgsql security definer;


-- NEW: admin-only cancellation that safely restores stock for every line item
-- in the same transaction — something a raw client update could never do atomically.
create or replace function public.cancel_order(p_order_id uuid, p_reason text default null)
returns void as $$
declare
  v_order orders%rowtype;
  v_item record;
begin
  if not public.is_admin() then
    raise exception 'Only admin staff can cancel orders';
  end if;

  select * into v_order from orders where id = p_order_id for update;
  if v_order.id is null then
    raise exception 'Order not found';
  end if;
  if v_order.status in ('delivered', 'cancelled') then
    raise exception 'This order cannot be cancelled anymore';
  end if;

  for v_item in select * from order_items where order_id = p_order_id loop
    update products set stock_quantity = stock_quantity + v_item.quantity where id = v_item.product_id;
  end loop;

  update orders set status = 'cancelled', updated_at = now() where id = p_order_id;
end;
$$ language plpgsql security definer;
