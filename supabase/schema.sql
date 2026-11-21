-- MealMate Supabase bootstrap for a NEW, dedicated Supabase project.
-- Do not run this seed/bootstrap file blindly on the existing hosted project.
-- It creates the minimum runtime schema and adds seven starter catalog recipes.
-- The current hosted catalog is larger and is maintained separately.

create table if not exists public.recipes (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text not null,
  minutes integer not null check (minutes > 0),
  cost_per_serving integer not null check (cost_per_serving >= 0),
  icon text not null default 'restaurant',
  image_url text,
  source_record_id integer,
  category text,
  meal_type text check (
    meal_type is null or meal_type in ('main_meal', 'snack_or_side')
  ),
  servings integer check (servings is null or servings > 0),
  cost_estimate_confidence text check (
    cost_estimate_confidence is null or
    cost_estimate_confidence in ('low', 'medium', 'high')
  ),
  cost_estimate_basis text,
  data_source text,
  source_license text,
  image_source_url text,
  image_credit text,
  calories_kcal_per_serving numeric(8, 2),
  protein_g_per_serving numeric(8, 2),
  carbohydrates_g_per_serving numeric(8, 2),
  fat_g_per_serving numeric(8, 2),
  ingredients jsonb not null default '[]'::jsonb
    check (jsonb_typeof(ingredients) = 'array'),
  steps jsonb not null default '[]'::jsonb
    check (jsonb_typeof(steps) = 'array'),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint recipes_calories_non_negative
    check (calories_kcal_per_serving is null or calories_kcal_per_serving >= 0),
  constraint recipes_protein_non_negative
    check (protein_g_per_serving is null or protein_g_per_serving >= 0),
  constraint recipes_carbohydrates_non_negative
    check (carbohydrates_g_per_serving is null or carbohydrates_g_per_serving >= 0),
  constraint recipes_fat_non_negative
    check (fat_g_per_serving is null or fat_g_per_serving >= 0)
);

create index if not exists recipes_active_sort_order_idx
  on public.recipes (is_active, sort_order, name);

grant usage on schema public to anon, authenticated;

alter table public.recipes enable row level security;
drop policy if exists "Anyone can read active MealMate recipes"
  on public.recipes;
create policy "Anyone can read active MealMate recipes"
  on public.recipes
  for select
  to anon, authenticated
  using (is_active = true);

revoke all privileges on table public.recipes from anon, authenticated;
grant select on table public.recipes to anon, authenticated;

create table if not exists public.user_meal_mate_state (
  user_id uuid primary key references auth.users (id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_meal_mate_state enable row level security;

drop policy if exists "Users can read their own MealMate state"
  on public.user_meal_mate_state;
create policy "Users can read their own MealMate state"
  on public.user_meal_mate_state
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their own MealMate state"
  on public.user_meal_mate_state;
create policy "Users can insert their own MealMate state"
  on public.user_meal_mate_state
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own MealMate state"
  on public.user_meal_mate_state;
create policy "Users can update their own MealMate state"
  on public.user_meal_mate_state
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all privileges on table public.user_meal_mate_state from anon, authenticated;
grant select, insert, update
  on table public.user_meal_mate_state
  to authenticated;

-- Public read-only recipe image bucket. App clients do not receive upload policies.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'meal-recipe-images',
  'meal-recipe-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- Seven starter recipes for a fresh database only.
-- ON CONFLICT DO NOTHING prevents this bootstrap script from overwriting
-- a recipe with the same name if it is accidentally re-run.
insert into public.recipes (
  name, description, minutes, cost_per_serving, icon, image_url,
  ingredients, steps, sort_order, is_active
) values
(
  'Nasi Ayam Teriyaki',
  'Ayam teriyaki gurih dengan sayuran dan nasi hangat.',
  25, 12000, 'restaurant', null,
  $$[
    {"name":"Dada ayam","amount":"150 g","price":14000},
    {"name":"Beras","amount":"150 g","price":3000},
    {"name":"Wortel dan buncis","amount":"100 g","price":2500},
    {"name":"Bawang dan bumbu","amount":"secukupnya","price":2000},
    {"name":"Saus teriyaki","amount":"2 sdm","price":2000}
  ]$$::jsonb,
  $$[
    "Cuci beras, lalu masak hingga menjadi nasi.",
    "Potong ayam dan sayuran sesuai ukuran.",
    "Masak ayam dengan saus teriyaki hingga matang.",
    "Sajikan ayam bersama nasi dan sayuran."
  ]$$::jsonb,
  1, true
),
(
  'Sup Sayur Sederhana',
  'Sup hangat berisi sayuran segar dan kuah bening.',
  30, 9500, 'soup_kitchen', null,
  $$[
    {"name":"Wortel","amount":"1 buah","price":2500},
    {"name":"Kentang","amount":"1 buah","price":3000},
    {"name":"Buncis","amount":"50 g","price":1500},
    {"name":"Bawang putih","amount":"2 siung","price":500},
    {"name":"Kaldu dan bumbu","amount":"secukupnya","price":2000}
  ]$$::jsonb,
  $$[
    "Cuci dan potong semua sayuran.",
    "Didihkan air bersama bawang dan kaldu.",
    "Masukkan sayuran dari yang paling keras.",
    "Bumbui secukupnya dan sajikan hangat."
  ]$$::jsonb,
  2, true
),
(
  'Nasi Ayam Kecap',
  'Ayam kecap rumahan dengan rasa manis gurih.',
  35, 10500, 'rice_bowl', null,
  $$[
    {"name":"Ayam","amount":"150 g","price":7000},
    {"name":"Beras","amount":"150 g","price":3000},
    {"name":"Kecap dan bumbu","amount":"secukupnya","price":2500}
  ]$$::jsonb,
  $$[
    "Masak nasi hingga matang.",
    "Tumis bawang hingga harum, lalu masukkan ayam.",
    "Tambahkan kecap dan sedikit air, masak hingga meresap.",
    "Sajikan bersama nasi hangat."
  ]$$::jsonb,
  3, true
),
(
  'Tumis Sayur dan Tahu',
  'Menu sederhana kaya sayur dengan tahu gurih.',
  20, 8000, 'eco', null,
  $$[
    {"name":"Tahu putih","amount":"2 potong","price":3000},
    {"name":"Wortel","amount":"1 buah","price":2000},
    {"name":"Buncis","amount":"50 g","price":1500},
    {"name":"Bumbu tumis","amount":"secukupnya","price":1500}
  ]$$::jsonb,
  $$[
    "Potong tahu dan sayuran.",
    "Tumis bumbu hingga harum.",
    "Masukkan sayuran dan sedikit air.",
    "Tambahkan tahu, masak hingga matang."
  ]$$::jsonb,
  4, true
),
(
  'Sup Sayur Telur',
  'Sup sayuran sederhana dengan telur yang mengenyangkan.',
  25, 7500, 'egg_alt', null,
  $$[
    {"name":"Telur","amount":"1 butir","price":2500},
    {"name":"Wortel","amount":"1 buah","price":2000},
    {"name":"Sayuran hijau","amount":"50 g","price":1500},
    {"name":"Bumbu kuah","amount":"secukupnya","price":1500}
  ]$$::jsonb,
  $$[
    "Didihkan air dan bumbu kuah.",
    "Masukkan wortel dan masak hingga lunak.",
    "Tuangkan telur sambil diaduk perlahan.",
    "Tambahkan sayuran hijau lalu sajikan."
  ]$$::jsonb,
  5, true
),
(
  'Nasi Ayam Panggang',
  'Ayam panggang berbumbu dengan nasi dan lalapan.',
  45, 13500, 'outdoor_grill', null,
  $$[
    {"name":"Ayam","amount":"150 g","price":8000},
    {"name":"Beras","amount":"150 g","price":3000},
    {"name":"Bumbu panggang","amount":"secukupnya","price":2500}
  ]$$::jsonb,
  $$[
    "Lumuri ayam dengan bumbu dan diamkan 15 menit.",
    "Panggang ayam hingga matang merata.",
    "Siapkan nasi dan sayuran pelengkap.",
    "Sajikan selagi hangat."
  ]$$::jsonb,
  6, true
),
(
  'Mi Sayur Rumahan',
  'Mi hangat dengan sayuran dan telur.',
  20, 8500, 'ramen_dining', null,
  $$[
    {"name":"Mi telur","amount":"1 porsi","price":4000},
    {"name":"Telur","amount":"1 butir","price":2500},
    {"name":"Sayuran","amount":"secukupnya","price":1500},
    {"name":"Bumbu","amount":"secukupnya","price":500}
  ]$$::jsonb,
  $$[
    "Rebus mi hingga matang lalu tiriskan.",
    "Tumis bumbu dan masukkan telur.",
    "Tambahkan sayuran dan mi.",
    "Aduk rata lalu sajikan."
  ]$$::jsonb,
  7, true
)
on conflict (name) do nothing;
