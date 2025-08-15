-- Adds a JSONB column to store the full onboarding payload and creates an index
-- Safe to run multiple times: uses IF NOT EXISTS where supported

alter table public.profiles
  add column if not exists profile_data jsonb;

-- Optional: keep specific scalar columns you already rely on (e.g., budget)
-- update public.profiles set profile_data = coalesce(profile_data, '{}'::jsonb);

-- Index to speed up containment queries if needed later
create index if not exists profiles_profile_data_idx
  on public.profiles using gin (profile_data);

-- Example to backfill a few scalar columns from JSON (optional)
-- update public.profiles
-- set budget = (profile_data ->> 'budget')
-- where profile_data ? 'budget';
