<img src="assets/icon.svg" width="64" height="64" alt="">

# Fitness App (Flutter)

Flutter port of the React Native fitness app, backed by Supabase.

## Run

```
flutter pub get
flutter run -d chrome                                   # fake data, no setup
flutter run -d chrome --dart-define-from-file=env.json  # real Supabase
```

Copy `env.example.json` to `env.json` and fill in the project URL and **publishable** key.
`env.json` is gitignored. Never put the `secret` or `service_role` key in the app.

Test logins (fake data and the practice database): `john@seed.test`, `jane@seed.test`,
`mika@seed.test`, `carlos@seed.test`, `ana@seed.test`. Password: `Password123!`

## Structure

```
lib/domain/        models and repository interfaces (what the UI depends on)
lib/data/fake/     in-memory repositories with seed data
lib/data/supabase/ real repositories
lib/app/           providers.dart picks fake vs real; app shell
lib/ui/theme/      app_theme.dart: ALL colors, fonts, radii, spacing
lib/ui/widgets/    shared widgets (read only from the theme)
lib/ui/screens/    the 6 screens + Profile
```

Restyling the app means editing `lib/ui/theme/app_theme.dart` and `lib/ui/widgets/shared_widgets.dart`.

## Known gaps vs the shared database

- `workout_logs` has RLS on but no policies, so "Finish & Log Workout" fails with a friendly message until an insert policy exists (`auth.uid() = user_id`).
- `plans` SELECT policy is `true`, so private plans are readable through the API. The app hides them.
- No rest-time column exists, so there is no rest timer.

```
flutter analyze
flutter test
```
