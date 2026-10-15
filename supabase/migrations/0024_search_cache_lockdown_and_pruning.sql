-- 0024_search_cache_lockdown_and_pruning.sql
-- Closes anonymous write/update loopholes on search_query_cache.
-- Prevents search poisoning and unbounded storage growth on 500 MB Free Tier.

-- 1. DROP ALL PERMISSIVE WRITE/UPDATE POLICIES
DROP POLICY IF EXISTS "Allow insert on search_query_cache" ON public.search_query_cache;
DROP POLICY IF EXISTS "Allow update on search_query_cache" ON public.search_query_cache;
DROP POLICY IF EXISTS "only service role or admin inserts search_query_cache" ON public.search_query_cache;

-- Ensure read access remains open for zero-AI client lookup
DROP POLICY IF EXISTS "Allow read on search_query_cache" ON public.search_query_cache;
CREATE POLICY "Allow read on search_query_cache"
  ON public.search_query_cache
  FOR SELECT
  USING (true);

-- Explicit write policy for service_role and admin only
CREATE POLICY "only service_role or admin writes search_query_cache"
  ON public.search_query_cache
  FOR ALL
  USING (public.is_admin() OR auth.role() = 'service_role')
  WITH CHECK (public.is_admin() OR auth.role() = 'service_role');

-- Revoke direct table manipulation from anon and authenticated
REVOKE INSERT, UPDATE, DELETE ON public.search_query_cache FROM anon, authenticated, public;
GRANT SELECT ON public.search_query_cache TO anon, authenticated;
GRANT ALL ON public.search_query_cache TO service_role;

-- 2. ADD LRU TRACKING COLUMN AND INDEX
ALTER TABLE public.search_query_cache
  ADD COLUMN IF NOT EXISTS last_used_at timestamptz DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_search_query_cache_last_used
  ON public.search_query_cache (last_used_at ASC);

-- 3. BOUNDED CACHE EVICTION FUNCTION (LRU Pruning)
CREATE OR REPLACE FUNCTION public.prune_search_cache(p_max_rows integer DEFAULT 5000)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
declare
  v_current_count integer;
  v_deleted_count integer := 0;
  v_excess integer;
begin
  select count(*) into v_current_count from public.search_query_cache;

  if v_current_count > p_max_rows then
    v_excess := v_current_count - p_max_rows;

    with to_delete as (
      select query_normalized
      from public.search_query_cache
      order by last_used_at asc
      limit v_excess
    )
    delete from public.search_query_cache
    where query_normalized in (select query_normalized from to_delete);

    get diagnostics v_deleted_count = row_count;
  end if;

  return v_deleted_count;
end;
$$;

-- 4. UPDATE HIT INCREMENT TO UPDATE last_used_at & PROBABILISTICALLY PRUNE (~1 in 50 calls)
CREATE OR REPLACE FUNCTION public.increment_search_cache_hit(p_query text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
begin
  update public.search_query_cache
  set
    hit_count = coalesce(hit_count, 0) + 1,
    last_used_at = now(),
    updated_at = now()
  where query_normalized = lower(trim(p_query));

  -- Self-maintaining eviction: ~1 in 50 calls triggers bounded pruning
  if random() < 0.02 then
    perform public.prune_search_cache(5000);
  end if;
end;
$$;

-- Execution grants
REVOKE EXECUTE ON FUNCTION public.prune_search_cache(integer) FROM public;
GRANT EXECUTE ON FUNCTION public.prune_search_cache(integer) TO service_role, authenticated;

REVOKE EXECUTE ON FUNCTION public.increment_search_cache_hit(text) FROM public;
GRANT EXECUTE ON FUNCTION public.increment_search_cache_hit(text) TO anon, authenticated, service_role;
