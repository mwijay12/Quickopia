-- 0001_enums_and_extensions.sql
-- Quickopia Database Schema: Extensions and Core Enums

create extension if not exists "pgcrypto";

-- User Role: strict role separation
do $$ begin
  create type user_role as enum ('customer', 'driver', 'admin');
exception
  when duplicate_object then null;
end $$;

-- Fulfillment Type: Delivery to doorstep vs Click & Collect store pickup
do $$ begin
  create type fulfillment_type as enum ('delivery', 'pickup');
exception
  when duplicate_object then null;
end $$;

-- Order Status: lifecycle stages matching Kanban & Driver workflow
do $$ begin
  create type order_status as enum (
    'placed',
    'packing',
    'ready',
    'out_for_delivery',
    'delivered',
    'cancelled'
  );
exception
  when duplicate_object then null;
end $$;

-- Payment Method: manual/cash-first for Tanzania MVP
do $$ begin
  create type payment_method as enum ('cod', 'lipa_namba', 'mobile_money');
exception
  when duplicate_object then null;
end $$;

-- Payment Status: tracking payment lifecycle
do $$ begin
  create type payment_status as enum ('pending', 'paid', 'failed');
exception
  when duplicate_object then null;
end $$;

-- Driver Employment Type: in-house supermarket driver vs future partner pool
do $$ begin
  create type driver_employment_type as enum ('in_house', 'partner');
exception
  when duplicate_object then null;
end $$;
