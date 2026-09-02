-- =====================================================================
-- QUICKOPIA COMPLETE DATABASE SCHEMA (ALL-IN-ONE SQL)
-- For execution in Supabase Dashboard SQL Editor or via Supabase CLI
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. EXTENSIONS & ENUMS
-- ---------------------------------------------------------------------
create extension if not exists "pgcrypto";

do $$ begin
  create type user_role as enum ('customer', 'driver', 'admin');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type fulfillment_type as enum ('delivery', 'pickup');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type order_status as enum (
    'placed', 'packing', 'ready', 'out_for_delivery', 'delivered', 'cancelled'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type payment_method as enum ('cod', 'lipa_namba', 'mobile_money');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type payment_status as enum ('pending', 'paid', 'failed');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type driver_employment_type as enum ('in_house', 'partner');
exception when duplicate_object then null;
end $$;

-- ---------------------------------------------------------------------
-- 2. CORE TABLES & INDEXES
-- ---------------------------------------------------------------------
create table if not exists branches (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text not null,
  neighborhood text,
  landmark text,
  latitude double precision,
  longitude double precision,
  phone text,
  commission_rate numeric(5,2) default 0.00,
  created_at timestamptz default now()
);

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role user_role not null default 'customer',
  branch_id uuid references branches(id),
  employment_type driver_employment_type,
  created_at timestamptz default now()
);

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_sw text,
  icon text,
  display_order integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid references branches(id) not null,
  category_id uuid references categories(id) not null,
  title text not null,
  description text,
  price_tzs numeric(12,2) not null check (price_tzs >= 0),
  unit text,
  image_url text,
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  is_available boolean default true,
  is_popular boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists addresses (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade not null,
  label text,
  city text not null,
  neighborhood text not null,
  landmark text not null,
  house_details text,
  latitude double precision,
  longitude double precision,
  is_default boolean default false,
  created_at timestamptz default now()
);

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

create index if not exists idx_products_category on products(category_id);
create index if not exists idx_products_branch on products(branch_id);
create index if not exists idx_orders_customer on orders(customer_id);
create index if not exists idx_orders_driver on orders(driver_id);
create index if not exists idx_orders_status on orders(status);
create index if not exists idx_addresses_profile on addresses(profile_id);

-- ---------------------------------------------------------------------
-- 3. AUTH TRIGGER & NON-RECURSIVE SECURITY DEFINERS
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'phone', new.phone),
    'customer'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.current_user_role()
returns user_role as $$
  select role from public.profiles where id = auth.uid();
$$ language sql security definer stable;

create or replace function public.is_admin()
returns boolean as $$
  select coalesce(public.current_user_role() = 'admin', false);
$$ language sql security definer stable;

create or replace function public.is_driver()
returns boolean as $$
  select coalesce(public.current_user_role() = 'driver', false);
$$ language sql security definer stable;

-- ---------------------------------------------------------------------
-- 4. ORDER PLACEMENT ATOMIC RPC FUNCTION
-- ---------------------------------------------------------------------
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
begin
  -- 1. Row-lock all items to prevent concurrent overselling
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

  -- 2. Identifiers
  v_order_number := 'ORD-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('order_number_seq')::text, 4, '0');
  v_pickup_code := public.generate_pickup_code();

  -- 3. Header insert
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

  -- 4. Line items & stock decrement
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

  -- 5. Totals update
  update orders
  set subtotal_tzs = v_subtotal,
      total_amount_tzs = v_subtotal + coalesce(p_delivery_fee_tzs, 0),
      updated_at = now()
  where id = v_order_id;

  return v_order_id;
end;
$$ language plpgsql security definer;

-- ---------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ---------------------------------------------------------------------
alter table branches enable row level security;
alter table profiles enable row level security;
alter table categories enable row level security;
alter table products enable row level security;
alter table addresses enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;

-- Branches
create policy "branches are publicly readable"
  on branches for select using (true);

create policy "only admin can modify branches"
  on branches for all
  using (public.is_admin())
  with check (public.is_admin());

-- Profiles
create policy "users can view own profile"
  on profiles for select
  using (auth.uid() = id or public.is_admin());

create policy "users can update own basic info"
  on profiles for update
  using (auth.uid() = id)
  with check (
    auth.uid() = id
    and role = (select role from profiles where id = auth.uid())
    and branch_id is not distinct from (select branch_id from profiles where id = auth.uid())
  );

create policy "admin can update any profile"
  on profiles for update
  using (public.is_admin());

-- Categories
create policy "categories are publicly readable"
  on categories for select using (true);

create policy "only admin manages categories"
  on categories for insert with check (public.is_admin());

create policy "only admin updates categories"
  on categories for update using (public.is_admin());

create policy "only admin deletes categories"
  on categories for delete using (public.is_admin());

-- Products
create policy "available products are publicly readable"
  on products for select
  using (is_available = true or public.is_admin());

create policy "only admin manages products"
  on products for insert with check (public.is_admin());

create policy "only admin updates products"
  on products for update using (public.is_admin());

create policy "only admin deletes products"
  on products for delete using (public.is_admin());

-- Addresses
create policy "users manage their own addresses"
  on addresses for all
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

-- Orders
create policy "customers view own orders"
  on orders for select using (auth.uid() = customer_id);

create policy "drivers view assigned orders"
  on orders for select using (auth.uid() = driver_id);

create policy "admin views all orders"
  on orders for select using (public.is_admin());

create policy "block direct order inserts from clients"
  on orders for insert with check (false);

create policy "drivers update their assigned order status"
  on orders for update
  using (auth.uid() = driver_id)
  with check (auth.uid() = driver_id);

create policy "admin updates any order"
  on orders for update using (public.is_admin());

-- Order Items
create policy "view order items via parent order access"
  on order_items for select
  using (
    exists (
      select 1 from orders
      where orders.id = order_items.order_id
      and (orders.customer_id = auth.uid() or orders.driver_id = auth.uid() or public.is_admin())
    )
  );

create policy "block direct order_item inserts from clients"
  on order_items for insert with check (false);

-- ---------------------------------------------------------------------
-- 6. INITIAL SEED DATA
-- ---------------------------------------------------------------------
insert into branches (name, city, neighborhood, landmark, phone, commission_rate)
values (
  'Quickopia Pilot Branch',
  'Dar es Salaam',
  'Mikocheni',
  'Near Shoppers Plaza, Mwai Kibaki Road',
  '+255700000000',
  10.00
);

insert into categories (name, name_sw, display_order) values
('Fresh Produce', 'Mboga na Matunda', 1),
('Dairy & Eggs', 'Maziwa na Mayai', 2),
('Bakery', 'Mikate', 3),
('Beverages', 'Vinywaji', 4),
('Household & Cleaning', 'Bidhaa za Nyumbani', 5),
('Personal Care', 'Vipodozi na Usafi', 6),
('Electronics & Accessories', 'Vifaa vya Elektroniki', 7),
('Baby Products', 'Bidhaa za Watoto', 8),
('Pantry & Staples', 'Vyakula vya Ghala', 9);
