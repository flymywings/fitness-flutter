-- Removes only the policies added by 002. Get owner approval before rollback
-- because the previous policies can expose records that 002 protects.
begin;
drop policy if exists pace_profile_insert_guard on public.users;
drop policy if exists pace_profile_insert on public.users;
drop policy if exists pace_profile_read on public.users;
drop policy if exists pace_plan_read_guard on public.plans;
drop policy if exists pace_plan_read on public.plans;
drop policy if exists pace_plan_insert_guard on public.plans;
drop policy if exists pace_plan_insert on public.plans;
drop policy if exists pace_plan_exercise_read_guard on public.plan_exercises;
drop policy if exists pace_plan_exercise_read on public.plan_exercises;
drop policy if exists pace_plan_exercise_insert_guard on public.plan_exercises;
drop policy if exists pace_plan_exercise_insert on public.plan_exercises;
drop policy if exists pace_saved_plan_guard on public.saved_plans;
drop policy if exists pace_saved_plan_read on public.saved_plans;
drop policy if exists pace_saved_plan_insert on public.saved_plans;
drop policy if exists pace_saved_plan_delete on public.saved_plans;
drop policy if exists pace_workout_log_guard on public.workout_logs;
drop policy if exists pace_workout_log_read on public.workout_logs;
drop policy if exists pace_workout_log_insert on public.workout_logs;
drop policy if exists pace_body_metrics_guard on public.user_body_metrics;
commit;
