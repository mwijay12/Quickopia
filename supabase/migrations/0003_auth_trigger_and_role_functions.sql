-- 0003_auth_trigger_and_role_functions.sql
-- Quickopia Auth Trigger & Non-Recursive Role Security Definers

-- 1. Automatically create a public.profiles record when a new user signs up in auth.users
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'phone', new.phone),
    'customer' -- every new signup strictly defaults to customer
  );
  return new;
end;
$$ language plpgsql security definer;

-- Drop trigger if it already exists to ensure idempotent execution
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 2. SECURITY DEFINER helper functions: safely inspect user role without RLS recursion
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
