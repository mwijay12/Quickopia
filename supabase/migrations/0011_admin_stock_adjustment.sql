-- 0011_admin_stock_adjustment.sql
-- Concurrency-Safe Stock Adjustment RPC Function

create or replace function public.admin_adjust_stock(
  p_product_id uuid,
  p_delta integer
)
returns integer as $$
declare
  v_new_stock integer;
begin
  if not public.is_admin() then
    raise exception 'Only admin staff can adjust stock';
  end if;

  update products
  set stock_quantity = greatest(0, stock_quantity + p_delta),
      updated_at = now()
  where id = p_product_id
  returning stock_quantity into v_new_stock;

  return v_new_stock;
end;
$$ language plpgsql security definer;
