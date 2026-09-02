-- 0004_order_placement_function.sql
-- Quickopia Atomic Order Placement RPC Function with Concurrency Row-Locking

-- Sequence for human-readable order numbers (e.g., ORD-2026-0001)
create sequence if not exists order_number_seq start 1;

-- 4-Digit Pickup Code Generator for Click & Collect
create or replace function public.generate_pickup_code()
returns text as $$
  select lpad((floor(random() * 10000))::text, 4, '0');
$$ language sql;

-- Atomic Order Placement: Validates stock, locks rows with FOR UPDATE, decrements stock, and builds order
create or replace function public.place_order(
  p_customer_id uuid,
  p_branch_id uuid,
  p_fulfillment_type fulfillment_type,
  p_delivery_city text,
  p_delivery_neighborhood text,
  p_delivery_landmark text,
  p_delivery_house_details text,
  p_delivery_latitude double precision,
  p_delivery_longitude double precision,
  p_customer_phone text,
  p_payment_method payment_method,
  p_delivery_fee_tzs numeric,
  p_items jsonb -- Array of objects: [{ "product_id": "...", "quantity": 2 }, ...]
)
returns uuid as $$
declare
  v_order_id uuid;
  v_order_number text;
  v_pickup_code text;
  v_item jsonb;
  v_product products%rowtype;
  v_subtotal numeric := 0;
  v_line_total numeric;
begin
  -- 1. Lock and validate stock for EVERY item BEFORE inserting records
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    select * into v_product
    from products
    where id = (v_item->>'product_id')::uuid
    for update; -- Critical row lock: prevents concurrent race conditions and overselling

    if v_product.id is null then
      raise exception 'Product % not found', v_item->>'product_id';
    end if;

    if not v_product.is_available then
      raise exception 'Product % is currently unavailable', v_product.title;
    end if;

    if v_product.stock_quantity < (v_item->>'quantity')::integer then
      raise exception 'Insufficient stock for product % (available: %, requested: %)',
        v_product.title, v_product.stock_quantity, v_item->>'quantity';
    end if;
  end loop;

  -- 2. Generate unique order identifiers
  v_order_number := 'ORD-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('order_number_seq')::text, 4, '0');
  v_pickup_code := public.generate_pickup_code();

  -- 3. Create parent order header
  insert into orders (
    order_number, customer_id, branch_id, fulfillment_type, status,
    delivery_city, delivery_neighborhood, delivery_landmark, delivery_house_details,
    delivery_latitude, delivery_longitude, customer_phone, pickup_code,
    subtotal_tzs, delivery_fee_tzs, total_amount_tzs, payment_method, payment_status
  ) values (
    v_order_number, p_customer_id, p_branch_id, p_fulfillment_type, 'placed',
    p_delivery_city, p_delivery_neighborhood, p_delivery_landmark, p_delivery_house_details,
    p_delivery_latitude, p_delivery_longitude, p_customer_phone, v_pickup_code,
    0, coalesce(p_delivery_fee_tzs, 0), 0, p_payment_method, 'pending'
  ) returning id into v_order_id;

  -- 4. Create immutable line items and decrement stock atomically
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    select * into v_product from products where id = (v_item->>'product_id')::uuid;
    v_line_total := v_product.price_tzs * (v_item->>'quantity')::integer;
    v_subtotal := v_subtotal + v_line_total;

    insert into order_items (order_id, product_id, title, unit_price_tzs, quantity, total_tzs)
    values (v_order_id, v_product.id, v_product.title, v_product.price_tzs,
            (v_item->>'quantity')::integer, v_line_total);

    update products
    set stock_quantity = stock_quantity - (v_item->>'quantity')::integer,
        updated_at = now()
    where id = v_product.id;
  end loop;

  -- 5. Finalize order financial totals
  update orders
  set subtotal_tzs = v_subtotal,
      total_amount_tzs = v_subtotal + coalesce(p_delivery_fee_tzs, 0),
      updated_at = now()
  where id = v_order_id;

  return v_order_id;
end;
$$ language plpgsql security definer;
