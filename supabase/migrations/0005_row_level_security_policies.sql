-- 0005_row_level_security_policies.sql
-- Quickopia Row Level Security (RLS) Policies

-- 1. Enable RLS on every table (strict security by design)
alter table branches enable row level security;
alter table profiles enable row level security;
alter table categories enable row level security;
alter table products enable row level security;
alter table addresses enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;

-- =====================================================================
-- 2. BRANCHES POLICIES
-- =====================================================================
create policy "branches are publicly readable"
  on branches for select using (true);

create policy "only admin can modify branches"
  on branches for all
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 3. PROFILES POLICIES
-- =====================================================================
create policy "users can view own profile"
  on profiles for select
  using (auth.uid() = id or public.is_admin());

-- Column-level protection: users can edit their name/phone, but CANNOT self-promote their role or branch
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

-- =====================================================================
-- 4. CATEGORIES POLICIES
-- =====================================================================
create policy "categories are publicly readable"
  on categories for select
  using (true);

create policy "only admin manages categories"
  on categories for insert
  with check (public.is_admin());

create policy "only admin updates categories"
  on categories for update
  using (public.is_admin());

create policy "only admin deletes categories"
  on categories for delete
  using (public.is_admin());

-- =====================================================================
-- 5. PRODUCTS POLICIES
-- =====================================================================
-- Anonymous/customers can browse available items; admins can view all (including hidden/archived)
create policy "available products are publicly readable"
  on products for select
  using (is_available = true or public.is_admin());

create policy "only admin manages products"
  on products for insert
  with check (public.is_admin());

create policy "only admin updates products"
  on products for update
  using (public.is_admin());

create policy "only admin deletes products"
  on products for delete
  using (public.is_admin());

-- =====================================================================
-- 6. ADDRESSES POLICIES
-- =====================================================================
-- Strictly private to the owning user
create policy "users manage their own addresses"
  on addresses for all
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

-- =====================================================================
-- 7. ORDERS POLICIES
-- =====================================================================
create policy "customers view own orders"
  on orders for select
  using (auth.uid() = customer_id);

create policy "drivers view assigned orders"
  on orders for select
  using (auth.uid() = driver_id);

create policy "admin views all orders"
  on orders for select
  using (public.is_admin());

-- Controlled write path: raw client inserts are blocked; orders are ONLY created via place_order() RPC
create policy "block direct order inserts from clients"
  on orders for insert
  with check (false);

-- Status updates: drivers can update their assigned delivery status; admins have full update authority
create policy "drivers update their assigned order status"
  on orders for update
  using (auth.uid() = driver_id)
  with check (auth.uid() = driver_id);

create policy "admin updates any order"
  on orders for update
  using (public.is_admin());

-- =====================================================================
-- 8. ORDER_ITEMS POLICIES
-- =====================================================================
-- Visible only to the customer who placed it, the driver delivering it, or the admin
create policy "view order items via parent order access"
  on order_items for select
  using (
    exists (
      select 1 from orders
      where orders.id = order_items.order_id
      and (orders.customer_id = auth.uid() or orders.driver_id = auth.uid() or public.is_admin())
    )
  );

-- Block direct line item manipulation from client; inserted exclusively via place_order()
create policy "block direct order_item inserts from clients"
  on order_items for insert
  with check (false);
