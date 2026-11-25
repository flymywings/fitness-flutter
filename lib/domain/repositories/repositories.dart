/// Contracts the UI depends on. Screens never talk to Supabase directly.
/// Two implementations exist: data/fake (in-memory) and data/supabase.
library;

import '../models/enums.dart';
import '../models/models.dart';

abstract class AuthRepository {
  /// Emits the signed-in user id (or null) now and on every change.
  Stream<String?> authStateChanges();
  String? get currentUserId;

  Future<void> signIn({required String email, required String password});
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String username,
    required double heightCm,
    required double weightKg,
  });
  Future<void> signOut();
  Future<AppUser?> getProfile();
}

abstract class PlanRepository {
  /// Public plans plus the current user's own plans.
  Future<List<Plan>> getPlans({Category? category});
  Future<List<Plan>> getSavedPlans();
  Future<List<PlanExercise>> getPlanExercises(int planId);
  Future<List<Exercise>> getExercises();
  Future<int> createPlan(NewPlan plan);
  Future<void> savePlan(int planId);
}

abstract class WorkoutRepository {
  Future<void> logWorkout(List<NewWorkoutLog> logs);
  Future<List<WorkoutLog>> getRecentLogs({int limit = 5});
}
