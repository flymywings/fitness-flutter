# Handoff: Flutter fitness app ("PACE")

Read this file, then `docs/gap-audit.md`, `docs/design-spec.md`, then `README.md`. Last updated 2026-11-26.

## Who and what

Sean owns data, Supabase integration and final assembly, and is the person you work with. Allen is the designer and works only in Figma/Canva; he does not code. Arwin made the first mockups. A teammate (the "RN teammate") owns the shared Supabase project and the React Native app (https://github.com/Aelfsige/fitness-react-native). The goal is a Flutter version of that app, with Allen's Figma design applied.

Repo: https://github.com/flymywings/fitness-flutter (public). Branch `main`. Do not commit secrets, `env.json`, or photos.

## State of the code (all pushed)

- Flutter 3.47, `flutter_riverpod` 3, `supabase_flutter` 2.
- Layers: `lib/domain/` (models, repository interfaces), `lib/data/fake/` (in-memory, seeded with 5 users), `lib/data/supabase/` (real), `lib/app/providers.dart` (the only place that picks fake or real), `lib/ui/theme/app_theme.dart` (AppTokens, placeholder values), `lib/ui/widgets/shared_widgets.dart`, `lib/ui/screens/`.
- Screens built from Arwin's mockups: Landing, Login, Register, Home, Plans, Create, Workout, Profile. They are a placeholder look, NOT Allen's design.
- The app runs on fake data unless started with `--dart-define-from-file=env.json`.
- `flutter analyze` is clean and 9 tests pass.
- Step 0 of the Figma implementation is done: `docs/gap-audit.md` and `database/proposed/001_design_support.sql` (not applied anywhere).

## Current status: waiting on Sean's decisions

Nothing in categories C or D of the audit may be built until Sean answers. The ten decisions, with the recommended answer:

1. Create account has Name, Email, Password only. Recommended: Name becomes `username`, show a derived display handle like `@alex.morgan`, make `height_cm` and `weight_kg` optional (C1).
2. Weight, volume, personal records, rest timer: apply C3 + C4 + C5 (two `workout_logs` columns, read/insert policies, `plan_exercises.rest_seconds`).
3. Save counts and Popular tab: C7 (counts view).
4. Custom exercises: C9 (insert policy and unique name), or a picker over existing exercises plus a larger seed.
5. Unsave: yes (C6). Editing saved plans: no.
6. Plan description: add one nullable column (C8).
7. Cut or hide: the "35–45 min" duration, creator full name, avatar photos, "2h ago", per-side reps, Share to community, Notifications row, Report plan, Copy link, Forgot password.
8. "Day N" writes `day_of_week = N` (the RN app shows Day 1 as Sunday; max 7 days). Accept.
9. Resume workout on Home: keep the in-progress workout on the device (`shared_preferences`).
10. Photos: ask Allen for source and license. Until confirmed, use placeholders.

Sean's answers will be in the prompt that started your session. If they are missing, ask before building anything beyond Step 1.

## Next steps (in order)

1. Apply the approved parts of `database/proposed/001_design_support.sql` to the PRACTICE project only (Sean runs it in the SQL Editor; give him exact text). Sean forwards the same file to the RN teammate for the shared project.
2. Step 1: update `AppTokens` from the design values below. Bundle the Inter font as an asset. Build a Widgetbook with every component and state. Add tests for contrast and tap sizes.
3. Step 2: screens, one vertical slice at a time, commit and push each: Welcome/Login/Create account (with error and loading), Home (with empty), Discover (filters, no results), Plan detail, Create plan (add, reorder, delete), Workout, Profile and Settings. Share and Report last, or cut.
4. Step 3: workout flow and rest timer. Set states ready, logged, skipped. Timer: 90 s max, 1 s ticks, ±15 s, Skip, "READY FOR THE NEXT SET" at 0. Base it on timestamps, not tick counting, and test it with `fake_async`.
5. Step 4: fake repositories must not do anything the real backend can't. Write one contract test suite and run it against both fakes and the practice project.
6. Step 5: golden tests at 390×844 beside the Figma exports, `flutter analyze`, `flutter test`, an RLS test where user A cannot read user B's private data, a cross-app check against the RN app, device screenshots, and a list of every deviation from the design.

## Design values (from the foundations sheet)

Colors: `bg/base #0B0B0D`, `bg/card #18181B`, `action/primary #E32636`, `action/primary-pressed #B91C2C`, `text/primary #FFFFFF`, `text/secondary #A1A1AA`, `border/default #303036`, `status/success #22C55E`. Error text on the Login error screen is a light red/pink.
Type (Inter): Display 28/32, Title 20/24, Body 16/24, Caption 13/16 (caption is uppercase in places).
Spacing scale 8, 16, 24, 32, 40, 48 (12 also appears). Corners 12 px. Minimum tap target 44 px, workout actions 56 px.
Rules from the sheet: red means action, green confirms a logged set, always pair color with a label, never put small text directly over a busy photo.
Screens (39): Discover, Plan detail, 2-set starter intro, Workout (set ready, rest running, rest complete, set 2 ready, two sets logged), Review session, Summary; Welcome, Login, Create account, Login error, Create account loading, Home, Home with no plans; Discover (new, no results), Share plan, Report plan; Create plan, Plan exercises, Add exercise, reordered, delete, after delete; Active workout, last set, Workout summary, Share workout; Profile (public, private, no activity), Settings; four toasts. Bottom tabs: Home, Discover, Create, Profile.

The full text description of every component, state and all 39 screens is in `docs/design-spec.md`. It is the design reference, because the original Figma PDF exports are not in this repo (they contain photos of uncertain license). Sean no longer has the original attachments in his chat tool; he keeps copies on his PC only. Without the PDFs, pixel golden tests cannot compare to Figma exports: build the spec's layouts, ask Sean for screenshots from Allen for any detail the spec marks "confirm", and say so in the deviation list.

## Backend facts you need

- **Shared project (the team's, live): never write to it.** Auth auto-confirms email signups (`mailer_autoconfirm=true`). Tables: `users`, `plans`, `exercises` (only 16 rows: Bench Press, Bicep Curl, Burpees, Calf Raise, Hip Raise, Incline Bench Press, Lat Pull Down, Leg Curl, Leg Press, Overhead Press, Pull Ups, Push Ups, Romanian Dead Lift, Sit Ups, Squat, Tricep Extension), `equipments` (empty), `plan_exercises`, `saved_plans` (no primary key), `workout_logs`.
- **Known RLS problems on shared (pre-existing):** `plans` SELECT is `true`, so private plans are readable; `users` SELECT is `true`, so height and weight are public; `workout_logs` has RLS on and zero policies, so it cannot be read or written; `plan_exercises` INSERT is open to any signed-in user; there are no UPDATE or DELETE policies anywhere. `workout_logs.user_id` defaults to `gen_random_uuid()`, so the app sends `user_id` explicitly.
- **Practice project (Sean's own, safe to change):** schema Part 1 applied (identical to shared), Part 2 fixes NOT applied, so it behaves like shared. `saved_plans` primary key was dropped to match shared. Seeded with 5 fake users (`john@seed.test`, `jane@seed.test`, `mika@seed.test`, `carlos@seed.test`, `ana@seed.test`, password `Password123!`), 9 plans (3 private, ids 9001–9009), exercises with different names than shared, logs that nobody can read. Email confirmation is ON there; switch it off to match shared (dashboard: Authentication, Sign In / Providers, Email, "Confirm email"). Rows can be removed with the cleanup SQL (delete `workout_logs` and `saved_plans` for the seed user ids, then `delete from auth.users where email like '%@seed.test'`). The seed SQL lives only in the earlier chat, not in this repo: recreate it from `lib/data/fake/fake_store.dart` if needed, and consider re-seeding exercises from the shared list.
- Keys: the practice URL and publishable key go in `env.json` (gitignored; copy from `env.example.json`). The `secret` and `service_role` keys must never be used or committed.

## Gotchas learned the hard way

- In PowerShell 5.1, `@($x).Count` on an empty JSON array returns a wrong count. Check raw response bodies (`[]`) instead.
- Embedding `users` from `plans` returns PGRST201 if `saved_plans` has a composite primary key. The code uses the hint `users!plans_creator_id_fkey(username)`.
- In widget tests, `ListView` builds only visible cards, so find items near the top of a list.
- Riverpod 3: use `.value` on `AsyncValue`, not `valueOrNull`. `Supabase.initialize` takes `publishableKey`.
- Git author email must be the GitHub no-reply address (repo-local config), since the repo is public.
- Flutter on Sean's Windows PC is at `C:\src\flutter` (added to PATH). Android SDK path contains a space, so test on Chrome (`flutter run -d chrome`). `gh` is installed and logged in as `flymywings` on that PC only.

## Rules

- Never write to the shared Supabase project. Database changes go in SQL files Sean forwards to the RN teammate, tested only on the practice project.
- No secrets in git. Report with evidence: command output, test results, screenshots.
- The repo is public: no photos until Allen confirms the license.
- Ask Sean about anything the audit cannot settle.
