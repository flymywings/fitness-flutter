/// Wiring. This is the ONLY place that decides fake vs real data.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/fake/fake_repositories.dart';
import '../data/fake/fake_store.dart';
import '../data/supabase/supabase_repositories.dart';
import '../domain/models/enums.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';

/// Pass these with --dart-define-from-file=env.json to use the real database.
/// Without them the app runs on fake data.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const forceFake = bool.fromEnvironment('USE_FAKE');

  static bool get useFake => forceFake || supabaseUrl.isEmpty || supabaseKey.isEmpty;
}

final fakeStoreProvider = Provider<FakeStore>((ref) => FakeStore.seeded());

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AppConfig.useFake
        ? FakeAuthRepository(ref.watch(fakeStoreProvider))
        : SupabaseAuthRepository(Supabase.instance.client));

final planRepositoryProvider = Provider<PlanRepository>((ref) =>
    AppConfig.useFake
        ? FakePlanRepository(ref.watch(fakeStoreProvider))
        : SupabasePlanRepository(Supabase.instance.client));

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) =>
    AppConfig.useFake
        ? FakeWorkoutRepository(ref.watch(fakeStoreProvider))
        : SupabaseWorkoutRepository(Supabase.instance.client));

/// Signed-in user id, or null. Everything below re-runs when it changes.
final authStateProvider = StreamProvider<String?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());

final profileProvider = FutureProvider<AppUser?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).getProfile();
});

final plansProvider = FutureProvider.family<List<Plan>, Category?>((ref, cat) {
  ref.watch(authStateProvider);
  return ref.watch(planRepositoryProvider).getPlans(category: cat);
});

final savedPlansProvider = FutureProvider<List<Plan>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(planRepositoryProvider).getSavedPlans();
});

final planExercisesProvider =
    FutureProvider.family<List<PlanExercise>, int>((ref, planId) =>
        ref.watch(planRepositoryProvider).getPlanExercises(planId));

final exercisesProvider = FutureProvider<List<Exercise>>(
    (ref) => ref.watch(planRepositoryProvider).getExercises());

final recentLogsProvider = FutureProvider<List<WorkoutLog>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(workoutRepositoryProvider).getRecentLogs();
});
