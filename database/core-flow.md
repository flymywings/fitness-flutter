# Shared Supabase core flow

**Status on 2026-11-27.** The shared database already has the core owner-scoped policies. A hosted two-account test passed with the Flutter repositories, and a cleanup query confirmed zero matching test accounts, profiles, and private plans. No migration was applied. The migration below is a tested reference for another environment with the same schema and missing policies. The [gap audit](../docs/gap-audit.md) records the hosted test results.

The earlier signed-in check received `42501` when Flutter attempted to create its `public.users` row. The plan, saved-plan, and workout-log writes then failed at foreign keys that require that row. The latest test completed all four operations successfully.

## Owner review and rollout

1. Run these read-only queries in the intended project's SQL Editor. Confirm that row-level security is enabled on these tables, review any existing restrictive policies, and check the authenticated table grants. Existing restrictive policies can still block legitimate requests after the migration.

   ```sql
   select tablename, policyname, permissive, roles, cmd, qual, with_check
   from pg_policies
   where schemaname = 'public'
     and tablename in (
       'users', 'plans', 'plan_exercises', 'saved_plans',
       'workout_logs', 'user_body_metrics'
     )
   order by tablename, policyname;

   select c.relname as tablename, c.relrowsecurity as rls_enabled,
          has_table_privilege('authenticated', c.oid, 'SELECT') as signed_in_select,
          has_table_privilege('authenticated', c.oid, 'INSERT') as signed_in_insert,
          has_table_privilege('authenticated', c.oid, 'DELETE') as signed_in_delete
   from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relname in (
       'users', 'plans', 'plan_exercises', 'saved_plans',
       'workout_logs', 'user_body_metrics'
     )
   order by c.relname;
   ```

2. Apply [002_core_flow_policies.sql](proposed/002_core_flow_policies.sql) to a disposable project with the current shared schema first. It keeps existing policies and data, adds the access needed by Flutter, and constrains older permissive policies for the affected operations. It expects the separate `user_body_metrics` table from the shared project. The older practice schema still stores required height and weight in `users` and needs to be brought up to date separately.
3. Sign up a fresh test account in Flutter. Confirm Profile opens, then create one private and one public plan with an exercise and custom rest. Log a workout and reopen the app to check its history. Save and unsave the public plan.
4. Sign in with a second test account. Confirm it can see the public plan and its exercise, and that the first account's private plan, workout history, saved rows, and body measurements are inaccessible through the signed-in API. Use test records you control when checking visibility.
5. For an environment with missing policies, have its owner review and apply the tested migration, then repeat the checks with designated test accounts.

[Rollback SQL](proposed/002_core_flow_policies_rollback.sql) removes only the custom policies created by this migration. Rolling back can restore older access rules, including overly broad ones. Have the owner review those rules before rolling back.

## Local verification

[002_core_flow.sql](tests/002_core_flow.sql) creates a small fixture, reproduces the profile rejection, then verifies provisioning, plan and exercise visibility, workout logging, save and unsave, metrics privacy, reapplication, and rollback. It can be run with `psql -X -v ON_ERROR_STOP=1 -f database/tests/002_core_flow.sql` against a **disposable empty database**. This fixture verifies PostgreSQL roles and constraints. The owner steps above verify hosted Auth and the Data API.
