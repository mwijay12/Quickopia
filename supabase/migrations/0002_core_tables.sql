-- 0002_core_tables.sql
-- Quickopia Database Schema: Core Tables and Indexes

-- 1. BRANCHES: Single supermarket pilot, multi-branch scalable
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

-- 2. PROFILES: Extends auth.users, holds role + personal information
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role user_role not null default 'customer',
  branch_id uuid references branches(id),
  employment_type driver_employment_type,
  created_at timestamptz default now()
);

-- 3. CATEGORIES: Fully admin-defined, supports all supermarket departments
create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_sw text,
  icon text,
  display_order integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- 4. PRODUCTS: Multi-category supermarket inventory with non-negative price/stock check
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

-- 5. ADDRESSES: Customer saved delivery locations (Landmark-first model)
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

-- 6. ORDERS: Central order ledger with immutable delivery address & pricing snapshot
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,
  customer_id uuid references profiles(id) not null,
  branch_id uuid references branches(id) not null,
  driver_id uuid references profiles(id),
  fulfillment_type fulfillment_type not null,
  status order_status not null default 'placed',

  -- Delivery snapshot captured at order placement time
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

-- 7. ORDER_ITEMS: Line items per order with snapshot of title & price at purchase time
create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade not null,
  product_id uuid references products(id) not null,
  title text not null,
  unit_price_tzs numeric(12,2) not null,
  quantity integer not null check (quantity > 0),
  total_tzs numeric(12,2) not null
);

-- Indexes for optimal query performance across mobile, admin, and driver surfaces
create index if not exists idx_products_category on products(category_id);
create index if not exists idx_products_branch on products(branch_id);
create index if not exists idx_orders_customer on orders(customer_id);
create index if not exists idx_orders_driver on orders(driver_id);
create index if not exists idx_orders_status on orders(status);
create index if not exists idx_addresses_profile on addresses(profile_id);
