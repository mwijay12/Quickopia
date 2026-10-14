-- 0007_realtime_and_driver_visibility.sql
-- Quickopia: Enable Realtime on orders table and scope driver profile visibility

-- 1. Enable Realtime change broadcasts on the orders table
alter publication supabase_realtime add table orders;

-- 2. Allow a customer to view ONLY the driver profile assigned to one of their own orders.
-- This is additive to the existing "users can view own profile" policy from Prompt 1.
create policy "customers can view their assigned driver profile"
  on profiles for select
  using (
    role = 'driver'
    and exists (
      select 1 from orders
      where orders.driver_id = profiles.id
      and orders.customer_id = auth.uid()
    )
  );
