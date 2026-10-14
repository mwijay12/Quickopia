-- 0013_search_query_cache.sql
-- Table for caching AI query expansions across English & Swahili

create table if not exists public.search_query_cache (
  query_normalized text primary key,
  expanded_terms text[] not null,
  hit_count integer default 1,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.search_query_cache enable row level security;

-- Allow public read access to cached expansions
create policy "Allow read on search_query_cache"
  on public.search_query_cache
  for select
  using (true);

-- Allow public/edge function inserts
create policy "Allow insert on search_query_cache"
  on public.search_query_cache
  for insert
  with check (true);

-- Allow updates to increment hit_count
create policy "Allow update on search_query_cache"
  on public.search_query_cache
  for update
  using (true);

-- Seed common supermarket bilingual terms into cache
insert into public.search_query_cache (query_normalized, expanded_terms)
values
  ('sukari', array['sukari', 'sugar', 'white sugar', 'brown sugar']),
  ('sugar', array['sugar', 'sukari', 'white sugar', 'brown sugar']),
  ('unga', array['unga', 'flour', 'wheat flour', 'maize flour', 'sembe']),
  ('flour', array['flour', 'unga', 'wheat flour', 'maize flour']),
  ('mafuta', array['mafuta', 'oil', 'cooking oil', 'sunflower oil', 'vegetable oil']),
  ('oil', array['oil', 'mafuta', 'cooking oil', 'sunflower oil']),
  ('maziwa', array['maziwa', 'milk', 'fresh milk', 'yogurt', 'yoghurt']),
  ('milk', array['milk', 'maziwa', 'fresh milk', 'uht milk']),
  ('mkate', array['mkate', 'bread', 'sliced bread', 'toast']),
  ('bread', array['bread', 'mkate', 'sliced bread']),
  ('sabuni', array['sabuni', 'soap', 'detergent', 'bar soap', 'liquid soap']),
  ('soap', array['soap', 'sabuni', 'detergent', 'bar soap'])
on conflict (query_normalized) do nothing;
