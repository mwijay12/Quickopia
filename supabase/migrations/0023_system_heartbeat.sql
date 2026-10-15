-- 0023_system_heartbeat.sql
-- Lightweight, bounded keep-alive marker table and RPCs for Supabase Free Tier.
-- Prevents inactive project pausing after 7 days without incoming traffic.

create table if not exists public.system_heartbeat (
  id integer primary key default 1 check (id = 1),
  last_ping_at timestamptz not null default now(),
  ping_count bigint not null default 1,
  pinger_id text not null default 'github-actions',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Ensure table contains exactly one row
insert into public.system_heartbeat (id, last_ping_at, ping_count, pinger_id)
values (1, now(), 1, 'bootstrap')
on conflict (id) do nothing;

alter table public.system_heartbeat enable row level security;

-- Read policy: Anyone can inspect heartbeat status
create policy "Allow read on system_heartbeat"
  on public.system_heartbeat
  for select
  using (true);

-- No direct client inserts/updates — writes must go through heartbeat_ping() RPC or service_role
create policy "Only service_role writes system_heartbeat"
  on public.system_heartbeat
  for all
  using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');

-- ----------------------------------------------------------------------------
-- heartbeat_ping(p_pinger text):
-- Updates heartbeat timestamp with rate-limiting (throttled to <= 1 write per minute).
-- Safe to call by external scheduled pingers (GitHub Actions, cron-job.org).
-- ----------------------------------------------------------------------------
create or replace function public.heartbeat_ping(
  p_pinger text default 'github-actions'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_last_ping timestamptz;
  v_count bigint;
  v_now timestamptz := now();
begin
  select last_ping_at, ping_count
  into v_last_ping, v_count
  from public.system_heartbeat
  where id = 1;

  if not found then
    insert into public.system_heartbeat (id, last_ping_at, ping_count, pinger_id, updated_at)
    values (1, v_now, 1, coalesce(p_pinger, 'unknown'), v_now);
    return jsonb_build_object(
      'status', 'ok',
      'action', 'inserted',
      'last_ping_at', v_now,
      'ping_count', 1
    );
  end if;

  -- Throttle: do not write to disk more often than once every 60 seconds
  if v_last_ping is not null and v_now < (v_last_ping + interval '60 seconds') then
    return jsonb_build_object(
      'status', 'ok',
      'action', 'throttled',
      'last_ping_at', v_last_ping,
      'ping_count', v_count,
      'message', 'Ping registered but write throttled to 1/minute'
    );
  end if;

  update public.system_heartbeat
  set
    last_ping_at = v_now,
    ping_count = v_count + 1,
    pinger_id = coalesce(p_pinger, pinger_id),
    updated_at = v_now
  where id = 1;

  return jsonb_build_object(
    'status', 'ok',
    'action', 'updated',
    'last_ping_at', v_now,
    'ping_count', v_count + 1
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- heartbeat_status():
-- Diagnostic function reporting system health & time-to-pause window.
-- ----------------------------------------------------------------------------
create or replace function public.heartbeat_status()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_record record;
  v_elapsed_seconds numeric;
  v_status text;
  v_grace_hours_remaining numeric;
begin
  select * into v_record from public.system_heartbeat where id = 1;

  if not found then
    return jsonb_build_object(
      'status', 'UNKNOWN',
      'message', 'No heartbeat records found'
    );
  end if;

  v_elapsed_seconds := extract(epoch from (now() - v_record.last_ping_at));

  -- 7 days = 168 hours = 604,800 seconds
  v_grace_hours_remaining := greatest(0, round((604800 - v_elapsed_seconds) / 3600.0, 1));

  if v_elapsed_seconds < (26 * 3600) then
    v_status := 'ALIVE';
  elsif v_elapsed_seconds < (7 * 86400) then
    v_status := 'PINGER_STALLED';
  else
    v_status := 'PAUSED';
  end if;

  return jsonb_build_object(
    'status', v_status,
    'last_ping_at', v_record.last_ping_at,
    'seconds_since_last_ping', round(v_elapsed_seconds),
    'grace_hours_remaining', v_grace_hours_remaining,
    'ping_count', v_record.ping_count,
    'pinger_id', v_record.pinger_id
  );
end;
$$;

-- Execution grants
revoke execute on function public.heartbeat_ping(text) from public;
grant execute on function public.heartbeat_ping(text) to anon, authenticated, service_role;

revoke execute on function public.heartbeat_status() from public;
grant execute on function public.heartbeat_status() to anon, authenticated, service_role;
