-- Owner-reviewed migration for the shared schema. Run the checks in
-- database/core-flow.md first. Existing grants, rows, and policies are retained.
begin;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users', 'plans', 'plan_exercises', 'saved_plans',
    'workout_logs', 'user_body_metrics'
  ] loop
    if not exists (
      select 1
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = table_name
        and c.relrowsecurity
    ) then
      raise exception 'public.% must exist with row-level security enabled', table_name;
    end if;
  end loop;

  foreach table_name in array array[
    'users', 'plans', 'plan_exercises', 'saved_plans', 'workout_logs'
  ] loop
    if not has_table_privilege('authenticated', 'public.' || table_name, 'SELECT')
      or not has_table_privilege('authenticated', 'public.' || table_name, 'INSERT')
    then
      raise exception 'Review the existing authenticated SELECT and INSERT grants on public.%', table_name;
    end if;
  end loop;

  if not has_table_privilege('authenticated', 'public.saved_plans', 'DELETE') then
    raise exception 'Review the existing authenticated DELETE grant on public.saved_plans';
  end if;
end
$$;

-- Restrictive policies also constrain older permissive policies on these
-- operations. The permissive policies give the app the intended access.
drop policy if exists pace_profile_insert_guard on public.users;
create policy pace_profile_insert_guard on public.users
  as restrictive for insert to public
  with check (id = (select auth.uid()));
drop policy if exists pace_profile_insert on public.users;
create policy pace_profile_insert on public.users
  for insert to authenticated with check (id = (select auth.uid()));
drop policy if exists pace_profile_read on public.users;
create policy pace_profile_read on public.users
  for select to authenticated using (id = (select auth.uid()));

drop policy if exists pace_plan_read_guard on public.plans;
create policy pace_plan_read_guard on public.plans
  as restrictive for select to public
  using (is_public or creator_id = (select auth.uid()));
drop policy if exists pace_plan_read on public.plans;
create policy pace_plan_read on public.plans
  for select to authenticated
  using (is_public or creator_id = (select auth.uid()));
drop policy if exists pace_plan_insert_guard on public.plans;
create policy pace_plan_insert_guard on public.plans
  as restrictive for insert to public
  with check (creator_id = (select auth.uid()));
drop policy if exists pace_plan_insert on public.plans;
create policy pace_plan_insert on public.plans
  for insert to authenticated with check (creator_id = (select auth.uid()));

drop policy if exists pace_plan_exercise_read_guard on public.plan_exercises;
create policy pace_plan_exercise_read_guard on public.plan_exercises
  as restrictive for select to public
  using (exists (select 1 from public.plans p where p.id = plan_id));
drop policy if exists pace_plan_exercise_read on public.plan_exercises;
create policy pace_plan_exercise_read on public.plan_exercises
  for select to authenticated
  using (exists (select 1 from public.plans p where p.id = plan_id));
drop policy if exists pace_plan_exercise_insert_guard on public.plan_exercises;
create policy pace_plan_exercise_insert_guard on public.plan_exercises
  as restrictive for insert to public
  with check (exists (
    select 1 from public.plans p
    where p.id = plan_id and p.creator_id = (select auth.uid())
  ));
drop policy if exists pace_plan_exercise_insert on public.plan_exercises;
create policy pace_plan_exercise_insert on public.plan_exercises
  for insert to authenticated
  with check (exists (
    select 1 from public.plans p
    where p.id = plan_id and p.creator_id = (select auth.uid())
  ));

drop policy if exists pace_saved_plan_guard on public.saved_plans;
create policy pace_saved_plan_guard on public.saved_plans
  as restrictive for all to public
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.plans p where p.id = plan_id)
  );
drop policy if exists pace_saved_plan_read on public.saved_plans;
create policy pace_saved_plan_read on public.saved_plans
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists pace_saved_plan_insert on public.saved_plans;
create policy pace_saved_plan_insert on public.saved_plans
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists pace_saved_plan_delete on public.saved_plans;
create policy pace_saved_plan_delete on public.saved_plans
  for delete to authenticated using (user_id = (select auth.uid()));

drop policy if exists pace_workout_log_guard on public.workout_logs;
create policy pace_workout_log_guard on public.workout_logs
  as restrictive for all to public
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and (plan_id is null or exists (select 1 from public.plans p where p.id = plan_id))
  );
drop policy if exists pace_workout_log_read on public.workout_logs;
create policy pace_workout_log_read on public.workout_logs
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists pace_workout_log_insert on public.workout_logs;
create policy pace_workout_log_insert on public.workout_logs
  for insert to authenticated with check (user_id = (select auth.uid()));

-- Keep the existing metrics features and restrict their scope to the owner.
drop policy if exists pace_body_metrics_guard on public.user_body_metrics;
create policy pace_body_metrics_guard on public.user_body_metrics
  as restrictive for all to public
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

commit;
