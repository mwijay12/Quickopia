-- 0018_fix_orders_and_addresses_phone.sql
-- Fix orders table schema, order_items table, place_order RPC, and address phone persistence

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'orders') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'order_number') THEN
      ALTER TABLE orders RENAME TO orders_legacy;
    END IF;
  END IF;
END $$;

create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,
  customer_id uuid references profiles(id) not null,
  branch_id uuid references branches(id) not null,
  driver_id uuid references profiles(id),
  fulfillment_type fulfillment_type not null,
  status order_status not null default 'placed',
  delivery_city text,
  delivery_neighborhood text,
  delivery_landmark text,
  delivery_house_details text,
  delivery_latitude double precision,
  delivery_longitude double precision,
  customer_phone text not null,
  pickup_code text not null,
  subtotal_tzs numeric(12,2) not null,
  delivery_fee_tzs numeric(12,2) not null default 0,
  total_amount_tzs numeric(12,2) not null,
  payment_method payment_method not null,
  payment_status payment_status not null default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade not null,
  product_id uuid references products(id) not null,
  title text not null,
  unit_price_tzs numeric(12,2) not null,
  quantity integer not null check (quantity > 0),
  total_tzs numeric(12,2) not null
);

alter table addresses add column if not exists phone text;

create sequence if not exists order_number_seq start 1;

create or replace function public.generate_pickup_code()
returns text as $$
  select lpad((floor(random() * 10000))::text, 4, '0');
$$ language sql;

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
  v_effective_branch_id uuid := p_branch_id;
begin
  if v_effective_branch_id is null or not exists (select 1 from branches where id = v_effective_branch_id) then
    select id into v_effective_branch_id from branches limit 1;
  end if;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    select * into v_product
    from products
    where id = (v_item->>'product_id')::uuid
    for update;

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

  v_order_number := 'ORD-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('order_number_seq')::text, 4, '0');
  v_pickup_code := public.generate_pickup_code();

  insert into orders (
    order_number, customer_id, branch_id, fulfillment_type, status,
    delivery_city, delivery_neighborhood, delivery_landmark, delivery_house_details,
    delivery_latitude, delivery_longitude, customer_phone, pickup_code,
    subtotal_tzs, delivery_fee_tzs, total_amount_tzs, payment_method, payment_status
  ) values (
    v_order_number, p_customer_id, v_effective_branch_id, p_fulfillment_type, 'placed',
    p_delivery_city, p_delivery_neighborhood, p_delivery_landmark, p_delivery_house_details,
    p_delivery_latitude, p_delivery_longitude, p_customer_phone, v_pickup_code,
    0, coalesce(p_delivery_fee_tzs, 0), 0, p_payment_method, 'pending'
  ) returning id into v_order_id;

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

  update orders
  set subtotal_tzs = v_subtotal,
      total_amount_tzs = v_subtotal + coalesce(p_delivery_fee_tzs, 0),
      updated_at = now()
  where id = v_order_id;

  return v_order_id;
end;
$$ language plpgsql security definer;

alter table orders enable row level security;
alter table order_items enable row level security;

drop policy if exists "customers view own orders" on orders;
create policy "customers view own orders"
  on orders for select
  using (auth.uid() = customer_id);

drop policy if exists "drivers view assigned orders" on orders;
create policy "drivers view assigned orders"
  on orders for select
  using (auth.uid() = driver_id);

drop policy if exists "admin views all orders" on orders;
create policy "admin views all orders"
  on orders for select
  using (public.is_admin());

drop policy if exists "customers can insert own orders fallback" on orders;
create policy "customers can insert own orders fallback"
  on orders for insert
  with check (auth.uid() = customer_id or public.is_admin());

drop policy if exists "drivers update their assigned order status" on orders;
create policy "drivers update their assigned order status"
  on orders for update
  using (auth.uid() = driver_id)
  with check (auth.uid() = driver_id);

drop policy if exists "admin updates any order" on orders;
create policy "admin updates any order"
  on orders for update
  using (public.is_admin());

drop policy if exists "view order items via parent order access" on order_items;
create policy "view order items via parent order access"
  on order_items for select
  using (
    exists (
      select 1 from orders
      where orders.id = order_items.order_id
      and (orders.customer_id = auth.uid() or orders.driver_id = auth.uid() or public.is_admin())
    )
  );

drop policy if exists "insert order items via parent order access" on order_items;
create policy "insert order items via parent order access"
  on order_items for insert
  with check (
    exists (
      select 1 from orders
      where orders.id = order_items.order_id
      and (orders.customer_id = auth.uid() or public.is_admin())
    )
  );

grant execute on function public.place_order to authenticated, anon;
grant execute on function public.generate_pickup_code to authenticated, anon;
