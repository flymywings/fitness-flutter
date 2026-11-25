-- PROPOSED migration: database changes the Figma design needs.
-- NOT APPLIED ANYWHERE. Do not run on the shared project; send to the RN teammate.
-- After Sean approves, apply to the practice project first and test.
-- Every change is additive and backwards compatible with the RN app
-- (new columns are nullable or have defaults; no existing column changes type).

-- ---------------------------------------------------------------------------
-- C4  workout_logs: make logging possible (REQUIRED for any workout saving)
-- Today: RLS on, zero policies, so nobody can read or write. user_id default is a random uuid.
-- ---------------------------------------------------------------------------
alter table public.workout_logs alter column user_id set default auth.uid();

create policy "Users view own logs" on public.workout_logs
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users insert own logs" on public.workout_logs
  for insert to authenticated with check ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- C3  weight and volume (design: "40 kg x 8", "640 kg volume", personal record)
-- RN docs listed total_weight_lifted_kg but the live table lacks it.
-- ---------------------------------------------------------------------------
alter table public.workout_logs
  add column if not exists total_weight_lifted_kg double precision not null default 0
    check (total_weight_lifted_kg >= 0),
  add column if not exists max_weight_kg double precision
    check (max_weight_kg is null or max_weight_kg >= 0);

-- ---------------------------------------------------------------------------
-- C5  rest seconds per exercise (design: "90s rest", rest timer)
-- ---------------------------------------------------------------------------
alter table public.plan_exercises
  add column if not exists rest_seconds smallint not null default 90
    check (rest_seconds between 0 and 600);

-- ---------------------------------------------------------------------------
-- C1  register without height/weight (design asks Name, Email, Password only)
-- Simplest: make them optional. RN app keeps sending them.
-- ---------------------------------------------------------------------------
alter table public.users alter column height_cm drop not null;
alter table public.users alter column weight_kg drop not null;

-- ---------------------------------------------------------------------------
-- C6  unsave a plan (design: Save / Saved toggle). Editing saved plans is NOT proposed.
-- ---------------------------------------------------------------------------
create policy "Users unsave own plans" on public.saved_plans
  for delete to authenticated using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- C7  save counts and Popular sort (design: "1,248 saves")
-- RLS lets a user see only their own saved_plans rows, so expose counts through a view.
-- Only counts saves of public plans.
-- ---------------------------------------------------------------------------
create or replace view public.plan_save_counts as
  select sp.plan_id, count(*)::int as saves
  from public.saved_plans sp
  join public.plans p on p.id = sp.plan_id and p.is_public
  group by sp.plan_id;
grant select on public.plan_save_counts to authenticated;

-- ---------------------------------------------------------------------------
-- C8  plan description (design: paragraph on plan detail). Optional: cut instead.
-- ---------------------------------------------------------------------------
alter table public.plans add column if not exists description text;

-- ---------------------------------------------------------------------------
-- C9  custom exercises (design: free-text exercise name + muscle tag)
-- Today exercises has no INSERT policy and only 16 rows. Optional: seed more exercises instead.
-- ---------------------------------------------------------------------------
create unique index if not exists exercises_name_lower_key on public.exercises (lower(name));
create policy "Authenticated users add exercises" on public.exercises
  for insert to authenticated with check (true);

-- ---------------------------------------------------------------------------
-- SECURITY FIXES already known (not design-driven; recommend regardless)
-- ---------------------------------------------------------------------------
-- Private plans are readable by anyone today:
drop policy if exists "All users can view the plans" on public.plans;
create policy "View public or own plans" on public.plans
  for select using (is_public or creator_id = (select auth.uid()));

-- Anyone signed in can add exercises to anyone's plan today:
drop policy if exists "All users can view the contents of the plan" on public.plan_exercises;
drop policy if exists "Enable insert for authenticated users only" on public.plan_exercises;
create policy "View exercises of visible plans" on public.plan_exercises
  for select using (exists (
    select 1 from public.plans p
    where p.id = plan_id and (p.is_public or p.creator_id = (select auth.uid()))));
create policy "Insert exercises into own plans" on public.plan_exercises
  for insert to authenticated with check (exists (
    select 1 from public.plans p
    where p.id = plan_id and p.creator_id = (select auth.uid())));

-- ---------------------------------------------------------------------------
-- C13  OPTIONAL: report a plan (design: Report plan). Recommend cutting this screen instead.
-- ---------------------------------------------------------------------------
-- create table public.plan_reports (
--   id bigint generated always as identity primary key,
--   plan_id bigint not null references public.plans(id) on delete cascade,
--   reporter_id uuid not null default auth.uid() references public.users(id) on delete cascade,
--   reason text not null,
--   created_at timestamptz not null default now()
-- );
-- alter table public.plan_reports enable row level security;
-- create policy "Users report plans" on public.plan_reports
--   for insert to authenticated with check ((select auth.uid()) = reporter_id);
