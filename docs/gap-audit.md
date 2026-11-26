# Design vs database: gap audit (Step 0)

Sources include the 2026-11-25 schema and RLS audit, the three Figma PDF exports, and the 2026-11-26 tests of the shared project.

## Shared policy review (2026-11-27)

- The database has an own-profile insert policy on `public.users`. All six core tables have row-level security enabled, and the authenticated role has the table grants used by Flutter.
- Plans are readable by signed-in users when they are public or the user owns them. Plan exercises inherit parent-plan visibility, and adding an exercise to a plan requires ownership.
- Saved plans and workout logs have owner-scoped read, insert, and delete policies. `workout_logs.user_id` and `saved_plans.user_id` now default to `auth.uid()`. Body metrics have owner-scoped read and insert policies.
- The shared `plan_exercises.rest` column is an integer with a default of 60 seconds. The proposed `rest_seconds` column is superseded.
- A two-account test against the shared project passed through the Flutter repositories. It verified signup, profile creation, password login, private plan creation, a 75-second exercise rest value, saving and unsaving a public plan, and workout logging and history. The second account could read the public plan and could not access the first account's saved plan, private plan or its exercises, workout log, or body metrics.
- The test removed both temporary accounts and their fixtures. A follow-up query confirmed zero matching Auth accounts, profiles, and private plans. The shared project already has the policies used by this flow, so the prepared 002 migration was held.

## Shared project recheck (2026-11-26)

- **Profiles and equipment.** The shared database removed `users.height_cm` and `users.weight_kg`, closing the exposure through those profile columns. The app now uses `id`, `username`, and `created_at`. The shared equipment catalog has seven entries and the exercise catalog has 16. The API reports that `exercises.equipment_id` is absent.
- **New account blocker.** Email signup and password login succeeded. The new account had no `public.users` row, and its attempt to insert its own profile returned HTTP 403 (`42501`, row-level security). Creating a private plan, logging a workout without a plan, and saving a visible public plan each returned HTTP 409 (`23503`) on the foreign key pointing to the missing user row. The Auth test accounts `pace_smoke_00f5e504_a@example.com` and `pace_smoke_00f5e504_b@example.com` remain for the project owner to remove.
- **Permissions still to verify.** The workout insert reached the foreign-key check, so the earlier blanket RLS denial did not reproduce for that payload. PostgreSQL evaluates applicable insert policies before constraints. Successful workout logging and reading, deleting a saved plan, and private-plan visibility across accounts remain unverified. The signed-in test could see a public plan. Signed-out plan and log queries returned zero rows. The `workout_logs.user_id` default and authenticated exercise inserts also remain unverified. [PostgreSQL policy documentation](https://www.postgresql.org/docs/current/sql-createpolicy.html)
- **Design fields still missing.** The API rejected both proposed workout weight columns, `plan_exercises.rest_seconds`, and `plans.description` with `42703`. The `plan_save_counts` view returned `PGRST205`. The API also rejected `saved_plans.id` and `saved_plans.created_at`.
- **Practice project.** It still has the old measurement columns. Existing profile reads only need the three common columns. Practice signup needs those legacy columns to accept omitted values before it can use the new registration form.

**Status codes**
- **A** backed by the database today
- **B** computable in the app (or stored on the device)
- **C** needs a database change (SQL in `database/proposed/`, not applied anywhere)
- **D** not backed by anything: recommend cut or stub

## 1. Known conflicts: confirmed or not

| # | Claim | Result | Evidence |
|---|---|---|---|
| 1 | Register has no height/weight, `users` requires them | **Resolved on shared** | Both columns were removed. Shared profile creation still fails under RLS. Practice has the older schema |
| 2 | Full name vs `@handle` vs `username` | **Confirmed** | one `username text NOT NULL` column, no unique constraint |
| 3 | Weight per set and volume | **Confirmed** | `workout_logs` has only `total_sets_done`, `total_reps_done`. RN `DATABASE.md` lists `total_weight_lifted_kg` but the live table lacks it |
| 4 | Rest seconds per exercise | **Confirmed absent** | no column on `plan_exercises` |
| 5 | Skipped sets | **Not a DB problem** | skipped = planned sets minus logged sets (B) |
| 6 | Save counts, streaks, sessions under RLS | **Counts view absent** | The original practice test saw 2 of 9 `saved_plans` rows and 0 of 9 `workout_logs`. Shared signed-in log access is unverified |
| 7 | Difficulty labels | **Confirmed, B** | DB `EASY/MEDIUM/HARD`; design shows "Beginner", "Intermediate". "Advanced" is inferred, never shown |
| 8 | "Day 1" vs `day_of_week` | **Confirmed, B with a catch** | Day N maps to `day_of_week = N`, so the RN app shows Day 1 as Sunday. Max 7 days per plan |
| 9 | Reorder, delete, Copy & edit | **Split** | draft reorder/delete: B. Copy: A (insert own plan + exercises). Editing a saved plan: C (no UPDATE/DELETE policy; UPDATE returns `[]`) |
| 10 | Share, Report, Settings prefs | **Confirmed unbacked** | see matrix |
| 11 | Forgot password, email-confirmation deep links | **Config, not schema** | shared `mailer_autoconfirm=true` (no confirmation email), practice `false`. No redirect URL or deep link is configured |

## 2. Findings the brief did not list

1. **Shared private-plan access is unverified.** Another user could read plan 9002 and its six exercises in the original practice test. The app requests public plans and the signed-in user's own plans.
2. **The shared profile measurement columns were removed.** The earlier audit found that anyone could read them.
3. **The shared database has only 16 exercises**, none matching the design's ("Barbell bench press", "Single-arm half-kneeling cable row", "Wide-grip lat pulldown", ...). The equipment catalog now has seven entries. The practice seed uses different exercise names.
4. **The app sends `workout_logs.user_id` explicitly.** The original audit recorded a `gen_random_uuid()` default. The current shared default is unverified.
5. **Practice and shared auth differ** (confirmation on vs off). Set practice to match.
6. **`plans.created_at` is a `date`**, so "2h ago" cannot be shown.

## 3. Screen-by-screen matrix

### Access
| Field | Status | Note |
|---|---|---|
| Welcome hero photo, "Today's plan" preview card | D | decorative; hardcode, placeholder image until license confirmed |
| Login email/password | A | |
| Forgot password | **decision** | needs Site URL + redirect + app deep link; recommend hide |
| Password visibility toggle | B | |
| Create account: Name | **C or B** | decision 1 |
| Create account: height/weight | Removed | Shared profiles no longer store these fields |
| "8+ characters, including a number" | B | client rule; server minimum not verifiable with the publishable key |
| Terms of Service / Privacy Policy links | D | no pages: stub |
| Login error, loading states | B | friendly messages already exist |

### Home
| Field | Status | Note |
|---|---|---|
| Date, "Good morning, Alex" | B | uses `username` |
| This week: streak, sessions | B after C4 | session = distinct `logged_at` date; needs a `workout_logs` SELECT policy |
| Continue / Resume workout | **B (device storage)** | in-progress workout kept in `shared_preferences`. Decision 8 |
| Saved Plans list, "4 workouts" | A / B | workouts = distinct days |
| Plan thumbnails | D | static art per category |
| "+" next to Saved Plans | D | target unspecified: assume goes to Discover |
| Empty states | B | |

### Discover
| Field | Status | Note |
|---|---|---|
| Category chips, Clear filters | A / B | |
| Search by goal, plan or coach | A | `ilike` on title/category; coach = username |
| New sort | A | `created_at desc` (date only, so ties) |
| Popular sort, "1,248 saves", "12 saves" | **C** | needs counts view (C7) |
| Save / Saved | A | |
| Unsave | **C** | Shared DELETE access is unverified (C6) |
| "2h ago", "Just added" | D | cut; show date |
| Avatar | D | initials |
| Featured "Community favourite" | B after C7 | top by saves |

### Plan detail
| Field | Status | Note |
|---|---|---|
| Title, category, difficulty, weeks, creator | A | |
| Workouts per week | B | distinct days |
| "35–45 min" | D | cut |
| Creator full name | D | show username |
| Description | **C** | `plans.description` (C8) or cut |
| Plan link `pace.fit/p/...` | D | no domain |
| Day cards: day name "Pull & press" | D | derive "Day N" plus muscle summary |
| Exercise rows: "4 sets × 8 reps" | A | |
| Exercise rows: "Rest 90s" | **C** | C5 |
| Starter card "2 × 8 reps · 40 kg" | B | weight cannot be prescribed (no column); show reps only |
| Start workout, Save, Copy & edit | A | copy = client-side insert |
| Share, Report icons | decision | see below |

### Create plan
| Field | Status | Note |
|---|---|---|
| Name, duration, difficulty, category, visibility | A | |
| Draft add / reorder / delete exercise | B | `sort_order` written on save |
| Exercise name free text | **C** | Shared INSERT access is unverified and only 16 rows exist |
| Muscle tag | A (existing) / **C** (new exercise) | |
| Rest between sets | **C** | C5 |
| Edit plan details after save | **C** | C6, recommend skip |
| Toast "Plan saved" | B | |

### Workout
| Field | Status | Note |
|---|---|---|
| Set states ready / logged / skipped | B | |
| Weight × reps per set, set volume | B (screen) / **C** (stored) | C3 |
| Total volume, personal record | **C** | C3 |
| Duration "42 min 18 sec" | B | shown on summary only, not stored |
| Reps "per side" | D | cut |
| Rest timer | B | 90 s default until C5 |
| Review session, summary | B | |
| Share to community | D | no feed: cut |
| Share with a friend | B | system share sheet |

### Profile and settings
| Field | Status | Note |
|---|---|---|
| Name, avatar | D / B | username + initials |
| Sessions, streak, volume | B after C3/C4 | |
| My plans Public / Private | A | `creator_id = me` |
| Saved plans | A | |
| Notifications row | D | no push: cut |
| Default plan privacy, Weight units | B | device preferences |
| Privacy & security, Help & feedback | D | stub (static page, `mailto:`) |
| Log out | A | |
| Report plan flow | D / **C** | no table: cut or C13 |

## 4. Design inconsistencies to confirm with Allen

1. Foundations say `bg/base #0B0B0D`, but screens render pure black behind content. Which wins?
2. Active tab color is a light red/pink, not `action/primary #E32636`.
3. Selected chips are white fill with black text, not red.
4. Auth screens put small text over a photo, against the design's own "never place small text over a busy subject" rule.
5. Rest timer at 0: "+15s" is enabled, "−15s" and Skip are disabled. Assumed: +15s restarts a 15 s rest.
6. Two logging models exist: guided starter (per-set button) and full workout (tap chips, tap again to skip). Both will be built.
7. White text on `#E32636` computes to 4.57:1, passing AA for normal text by a thin margin. Tests will assert it.
8. Photos look like stock or generated images. Their license is unconfirmed; the repo is public.

## 5. Decisions needed (nothing in C or D is built until you answer)

See the chat summary; recommended answers are in `database/proposed/001_design_support.sql`.
