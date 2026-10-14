-- 0015_security_hardening.sql
-- Security Audit Hardening: RLS Tightening, Trigger Column Guards & Input Validation

-- =====================================================================
-- 1. HARDEN SEARCH_QUERY_CACHE RLS
-- =====================================================================
-- Drop overly broad update policy from 0013
drop policy if exists "Allow update on search_query_cache" on public.search_query_cache;

-- Restrict update on search_query_cache strictly to admin staff
create policy "only admin updates search_query_cache"
  on public.search_query_cache
  for update
  using (public.is_admin());

-- Safe hit-counter increment function for Edge Functions and client searches
create or replace function public.increment_search_cache_hit(p_query text)
returns void as $$
begin
  update public.search_query_cache
  set hit_count = coalesce(hit_count, 0) + 1,
      updated_at = now()
  where query_normalized = lower(trim(p_query));
end;
$$ language plpgsql security definer;

-- =====================================================================
-- 2. PROTECT PROFILES SYSTEM-GOVERNED COLUMNS
-- =====================================================================
-- Ensure non-admins cannot tamper with role, branch_id, referral_count,
-- referred_by, referral_code, or is_active through direct PostgREST updates
create or replace function public.enforce_profile_system_integrity()
returns trigger as $$
begin
  if not public.is_admin() then
    new.role := old.role;
    new.branch_id := old.branch_id;
    new.referral_count := old.referral_count;
    new.referred_by := old.referred_by;
    new.referral_code := old.referral_code;
    new.is_active := old.is_active;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists tr_enforce_profile_system_integrity on public.profiles;
create trigger tr_enforce_profile_system_integrity
  before update on public.profiles
  for each row
  execute function public.enforce_profile_system_integrity();

-- =====================================================================
-- 3. HARDEN ATOMIC ORDER PLACEMENT RPC INPUT VALIDATION
-- =====================================================================
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
  p_items jsonb
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
  v_qty integer;
begin
  -- Input Validation: caller must be the customer or an admin
  if auth.uid() is not null and auth.uid() != p_customer_id and not public.is_admin() then
    raise exception 'Unauthorized customer assignment';
  end if;

  -- Input Validation: items array must not be empty
  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'Order items list cannot be empty';
  end if;

  -- 1. Lock and validate stock for EVERY item BEFORE inserting records
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := (v_item->>'quantity')::integer;
    -- Input validation: positive integer quantities strictly required
    if v_qty is null or v_qty <= 0 then
      raise exception 'Item quantity must be a positive integer';
    end if;

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

    if v_product.stock_quantity < v_qty then
      raise exception 'Insufficient stock for product % (available: %, requested: %)',
        v_product.title, v_product.stock_quantity, v_qty;
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
    v_qty := (v_item->>'quantity')::integer;
    v_line_total := v_product.price_tzs * v_qty;
    v_subtotal := v_subtotal + v_line_total;

    insert into order_items (order_id, product_id, title, unit_price_tzs, quantity, total_tzs)
    values (v_order_id, v_product.id, v_product.title, v_product.price_tzs, v_qty, v_line_total);

    update products
    set stock_quantity = stock_quantity - v_qty,
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
