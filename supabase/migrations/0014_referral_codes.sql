-- 0014_referral_codes.sql
-- Referral Codes and Rewards Tracking with Abuse Prevention

alter table public.profiles
  add column if not exists referral_code text unique,
  add column if not exists referred_by text,
  add column if not exists referral_count integer default 0;

-- Function to generate clean alphanumeric referral codes (e.g. QK-7A9B2)
create or replace function public.generate_referral_code()
returns text as $$
declare
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := 'QK-';
  i integer;
begin
  for i in 1..5 loop
    result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
  end loop;
  return result;
end;
$$ language plpgsql volatile;

-- Populate existing profiles that lack a referral_code
update public.profiles
set referral_code = 'QK-' || upper(substr(id::text, 1, 5))
where referral_code is null;

-- Trigger to automatically set a referral_code on profile creation
create or replace function public.set_profile_referral_code()
returns trigger as $$
begin
  if new.referral_code is null then
    new.referral_code := 'QK-' || upper(substr(new.id::text, 1, 5));
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists tr_set_profile_referral_code on public.profiles;
create trigger tr_set_profile_referral_code
  before insert on public.profiles
  for each row
  execute function public.set_profile_referral_code();

-- Function for applying a friend's referral code with abuse prevention
create or replace function public.apply_referral_code(p_code text)
returns json as $$
declare
  v_user_id uuid := auth.uid();
  v_referrer_id uuid;
  v_clean_code text := upper(trim(p_code));
  v_own_code text;
  v_already_referred text;
begin
  if v_user_id is null then
    return json_build_object('success', false, 'error', 'You must be signed in to apply a code');
  end if;

  select referral_code, referred_by into v_own_code, v_already_referred
  from public.profiles
  where id = v_user_id;

  if v_already_referred is not null then
    return json_build_object('success', false, 'error', 'You have already applied a referral code');
  end if;

  -- Abuse prevention: self-referral check
  if v_own_code = v_clean_code then
    return json_build_object('success', false, 'error', 'You cannot use your own referral code');
  end if;

  -- Validate referral code exists
  select id into v_referrer_id
  from public.profiles
  where referral_code = v_clean_code;

  if v_referrer_id is null then
    return json_build_object('success', false, 'error', 'Invalid referral code. Please check and try again');
  end if;

  -- Atomically apply referral and increment referrer count
  update public.profiles
  set referred_by = v_clean_code
  where id = v_user_id;

  update public.profiles
  set referral_count = coalesce(referral_count, 0) + 1
  where id = v_referrer_id;

  return json_build_object('success', true, 'message', 'Referral code applied successfully!');
end;
$$ language plpgsql security definer;
