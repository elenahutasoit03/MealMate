-- Applied to the connected MealMate Supabase project on 2026-11-19.
-- Least-privilege table access for app client roles.
-- Anonymous Auth users use the authenticated Postgres role; RLS policies
-- continue to scope user state by auth.uid() = user_id.

-- Recipe catalog: app clients may read only; RLS limits rows to active recipes.
revoke all privileges on table public.recipes from anon, authenticated;
grant select on table public.recipes to anon, authenticated;

-- Per-user state: authenticated sessions may select/insert/update their own row.
revoke all privileges on table public.user_meal_mate_state from anon, authenticated;
grant select, insert, update
  on table public.user_meal_mate_state
  to authenticated;

-- Import staging is internal and is not exposed to app client roles.
revoke all privileges on table public.recipe_import_staging from anon, authenticated;
