-- Run with psql against a disposable empty PostgreSQL database only.
\set ON_ERROR_STOP on

create role anon;
create role authenticated;
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
grant usage on schema auth to anon, authenticated;

create table public.users (
  id uuid primary key references auth.users(id),
  username text not null,
  created_at date not null default current_date
);
create table public.plans (
  id int primary key,
  creator_id uuid not null default auth.uid() references public.users(id),
  is_public boolean not null,
  title text not null
);
create table public.plan_exercises (
  plan_id int references public.plans(id),
  exercise_id int not null,
  day_of_week int not null,
  rest int not null default 60
);
create table public.saved_plans (
  user_id uuid default auth.uid() references public.users(id),
  plan_id int references public.plans(id)
);
create table public.workout_logs (
  user_id uuid references public.users(id),
  plan_id int references public.plans(id),
  total_sets_done int not null,
  total_reps_done int not null
);
create table public.user_body_metrics (
  user_id uuid primary key references public.users(id),
  height_cm int,
  weight_kg int
);

alter table public.users enable row level security;
alter table public.plans enable row level security;
alter table public.plan_exercises enable row level security;
alter table public.saved_plans enable row level security;
alter table public.workout_logs enable row level security;
alter table public.user_body_metrics enable row level security;
grant select on all tables in schema public to anon;
grant select, insert, delete on all tables in schema public to authenticated;

-- Simulate existing permissive policies that must coexist with 002.
create policy legacy_profiles on public.users for select using (true);
create policy legacy_plans on public.plans for select using (true);
create policy legacy_exercises on public.plan_exercises for all using (true) with check (true);
create policy legacy_saved on public.saved_plans for all using (true) with check (true);
create policy legacy_logs on public.workout_logs for all using (true) with check (true);
create policy legacy_metrics on public.user_body_metrics for select using (true);

insert into auth.users values
  ('00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000002'),
  ('00000000-0000-0000-0000-000000000003');

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', false);
do $$
begin
  insert into public.users (id, username) values (auth.uid(), 'owner');
  raise exception 'Expected the original profile insert to fail';
exception when insufficient_privilege then
  null;
end
$$;
reset role;

\ir ../proposed/002_core_flow_policies.sql
\ir ../proposed/002_core_flow_policies.sql

set role authenticated;
insert into public.users (id, username) values (auth.uid(), 'owner');
insert into public.plans (id, is_public, title) values
  (101, false, 'Owner private plan'),
  (102, true, 'Owner public plan')
  returning id;
insert into public.plan_exercises (plan_id, exercise_id, day_of_week, rest)
  values (101, 1, 2, 75), (102, 1, 2, 60);
insert into public.workout_logs (user_id, plan_id, total_sets_done, total_reps_done)
  values (auth.uid(), 101, 3, 24), (auth.uid(), null, 1, 8);
insert into public.saved_plans (plan_id) values (101), (102);
do $$
begin
  if (select count(*) from public.users where id = auth.uid()) <> 1
    or (select count(*) from public.plans) <> 2
    or (select rest from public.plan_exercises where plan_id = 101) is distinct from 75
    or (select count(*) from public.workout_logs) <> 2
    or (select count(*) from public.saved_plans) <> 2 then
    raise exception 'Owner could not read their new records';
  end if;
end
$$;
delete from public.saved_plans where plan_id = 102 returning plan_id;
do $$
begin
  if exists (select 1 from public.saved_plans where plan_id = 102) then
    raise exception 'Owner could not unsave their own plan';
  end if;
end
$$;
reset role;
insert into public.user_body_metrics values
  ('00000000-0000-0000-0000-000000000001', 170, 70);

set role authenticated;
do $$
begin
  if (select count(*) from public.user_body_metrics) <> 1 then
    raise exception 'Existing own-metrics visibility changed';
  end if;
end
$$;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', false);
insert into public.users (id, username) values (auth.uid(), 'reader');
insert into public.saved_plans (plan_id) values (102);
do $$
begin
  if (select count(*) from public.plans where id = 101) <> 0
    or (select count(*) from public.plans where id = 102) <> 1
    or (select count(*) from public.plan_exercises where plan_id = 101) <> 0
    or (select count(*) from public.plan_exercises where plan_id = 102) <> 1
    or (select count(*) from public.workout_logs) <> 0
    or (select count(*) from public.user_body_metrics) <> 0
    or (select count(*) from public.saved_plans) <> 1
    or (select plan_id from public.saved_plans) <> 102 then
    raise exception 'Second account visibility was incorrect';
  end if;

  begin
    insert into public.users (id, username)
      values ('00000000-0000-0000-0000-000000000003', 'third');
    raise exception 'Could insert a profile for someone else';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.plan_exercises (plan_id, exercise_id, day_of_week)
      values (102, 2, 2);
    raise exception 'Could add exercises to another account''s plan';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.saved_plans (plan_id) values (101);
    raise exception 'Could save another account''s private plan';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.workout_logs (user_id, plan_id, total_sets_done, total_reps_done)
      values ('00000000-0000-0000-0000-000000000001', 102, 1, 8);
    raise exception 'Could insert a workout log for another account';
  exception when insufficient_privilege then null;
  end;

  delete from public.saved_plans where plan_id = 101;
  if found then raise exception 'Could unsave another account''s plan'; end if;
end
$$;

reset role;
select set_config('request.jwt.claim.sub', '', false);
set role anon;
do $$
begin
  if (select count(*) from public.plans where id = 101) <> 0
    or (select count(*) from public.plan_exercises where plan_id = 101) <> 0
    or (select count(*) from public.user_body_metrics) <> 0
    or (select count(*) from public.workout_logs) <> 0
    or (select count(*) from public.saved_plans) <> 0 then
    raise exception 'Signed-out access exposed private records';
  end if;
end
$$;
reset role;

\ir ../proposed/002_core_flow_policies_rollback.sql
do $$
begin
  if (select count(*) from pg_policies where left(policyname, 5) = 'pace_') <> 0
    or (select count(*) from pg_policies where left(policyname, 7) = 'legacy_') <> 6
    or (select count(*) from public.users) <> 2
    or (select count(*) from public.plans) <> 2
    or (select count(*) from public.plan_exercises) <> 2
    or (select count(*) from public.saved_plans) <> 2
    or (select count(*) from public.workout_logs) <> 2
    or (select count(*) from public.user_body_metrics) <> 1 then
    raise exception 'Rollback changed existing policies or removed application data';
  end if;
end
$$;
select 'Core flow policies, role checks, reapplication, and rollback passed' as result;
