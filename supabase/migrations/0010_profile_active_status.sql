-- 0010_profile_active_status.sql

alter table profiles add column is_active boolean not null default true;

-- Drivers who are deactivated should not appear as assignable in the
-- Dispatch modal (Prompt 13) or be able to act on orders. RLS policies
-- for order status updates already check driver_id = auth.uid(); we
-- additionally guard at the query level (fetchDrivers filters is_active)
-- and re-check server-side in the deactivation endpoint itself.
