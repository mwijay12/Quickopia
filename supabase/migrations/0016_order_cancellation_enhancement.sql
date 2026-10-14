-- 0016_order_cancellation_enhancement.sql
-- Allow customers to cancel their orders before packing begins, restoring stock atomically

create or replace function public.cancel_order(
  p_order_id uuid,
  p_reason text default null
)
returns void as $$
declare
  v_order orders%rowtype;
  v_item record;
begin
  select * into v_order from orders where id = p_order_id for update;

  if v_order.id is null then
    raise exception 'Order not found';
  end if;

  -- Authorization check: must be admin or the customer who placed the order
  if v_order.customer_id is distinct from auth.uid() and not public.is_admin() then
    raise exception 'You are not authorized to cancel this order';
  end if;

  -- Customer cancellation is strictly permitted only before packing begins
  if v_order.customer_id = auth.uid() and not public.is_admin() and v_order.status != 'placed' then
    raise exception 'Orders can only be cancelled before packing begins. Please contact store support.';
  end if;

  -- Prevent cancelling already closed orders
  if v_order.status in ('delivered', 'cancelled') then
    raise exception 'This order is already closed and cannot be cancelled';
  end if;

  -- Atomically restore decremented stock for each line item
  for v_item in select * from order_items where order_id = p_order_id loop
    update products
    set stock_quantity = stock_quantity + v_item.quantity,
        updated_at = now()
    where id = v_item.product_id;
  end loop;

  -- Mark order as cancelled
  update orders
  set status = 'cancelled',
      updated_at = now()
  where id = p_order_id;
end;
$$ language plpgsql security definer;
