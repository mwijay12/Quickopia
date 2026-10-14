-- 0008_complete_delivery_function.sql
-- Quickopia: Secure Delivery Completion RPC with Pickup Code Verification

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

  -- Only the assigned driver may complete their own order
  if v_order.driver_id is distinct from auth.uid() then
    raise exception 'You are not assigned to this order';
  end if;

  if v_order.status = 'delivered' then
    raise exception 'This order is already marked as delivered';
  end if;

  if v_order.pickup_code is distinct from p_entered_code then
    raise exception 'Incorrect confirmation code';
  end if;

  update orders
  set status = 'delivered',
      payment_status = p_payment_status,
      updated_at = now()
  where id = p_order_id;
end;
$$ language plpgsql security definer;
