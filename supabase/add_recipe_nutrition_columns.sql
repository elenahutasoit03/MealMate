-- MealMate: optional, validated per-serving nutrition metadata.
-- Existing recipe rows remain valid and receive NULL until trusted values are entered.

alter table public.recipes
  add column if not exists calories_kcal_per_serving numeric(8, 2),
  add column if not exists protein_g_per_serving numeric(8, 2),
  add column if not exists carbohydrates_g_per_serving numeric(8, 2),
  add column if not exists fat_g_per_serving numeric(8, 2);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'recipes_calories_non_negative'
      and conrelid = 'public.recipes'::regclass
  ) then
    alter table public.recipes
      add constraint recipes_calories_non_negative
      check (calories_kcal_per_serving is null or calories_kcal_per_serving >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'recipes_protein_non_negative'
      and conrelid = 'public.recipes'::regclass
  ) then
    alter table public.recipes
      add constraint recipes_protein_non_negative
      check (protein_g_per_serving is null or protein_g_per_serving >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'recipes_carbohydrates_non_negative'
      and conrelid = 'public.recipes'::regclass
  ) then
    alter table public.recipes
      add constraint recipes_carbohydrates_non_negative
      check (carbohydrates_g_per_serving is null or carbohydrates_g_per_serving >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'recipes_fat_non_negative'
      and conrelid = 'public.recipes'::regclass
  ) then
    alter table public.recipes
      add constraint recipes_fat_non_negative
      check (fat_g_per_serving is null or fat_g_per_serving >= 0);
  end if;
end $$;
