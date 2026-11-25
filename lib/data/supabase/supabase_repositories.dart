/// Real repositories backed by Supabase. Table and column names match the
/// live schema (users, plans, plan_exercises, exercises, saved_plans, workout_logs).
library;

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

/// Joins plans -> users through plans.creator_id. The explicit hint avoids
/// PGRST201 ("more than one relationship") if saved_plans ever gets a primary key.
const _planCols = 'id,title,difficulty,duration_weeks,is_public,created_at,'
    'category,creator_id,users!plans_creator_id_fkey(username)';

/// Turns any error into a message that is safe to show to the user.
AppException friendlyError(Object e) {
  if (e is AppException) return e;
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return AppException('Wrong email or password.');
    }
    if (m.contains('not confirmed')) {
      return AppException('Confirm your email first, then log in.');
    }
    if (m.contains('already registered') || m.contains('already been')) {
      return AppException('That email is already registered.');
    }
    if (m.contains('missing email') || m.contains('missing password') ||
        m.contains('anonymous')) {
      return AppException('Enter your email and password.');
    }
    if (m.contains('password') && m.contains('characters')) {
      return AppException('Password is too short.');
    }
    if (m.contains('valid email') || m.contains('invalid email')) {
      return AppException('Enter a valid email address.');
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return AppException('Too many attempts. Wait a minute and try again.');
    }
    return AppException('Could not sign in. Try again.');
  }
  if (e is PostgrestException) {
    if (e.code == '42501') {
      return AppException("You don't have permission to do that.");
    }
    if (e.code == '23505') return AppException('That already exists.');
    if (e.code == '23503') {
      return AppException('That item is no longer available.');
    }
    return AppException('Could not reach the database. Try again.');
  }
  final s = e.toString().toLowerCase();
  if (s.contains('socket') || s.contains('clientexception') ||
      s.contains('failed host lookup') || s.contains('network')) {
    return AppException('No internet connection.');
  }
  return AppException('Something went wrong. Try again.');
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._c);
  final SupabaseClient _c;

  @override
  String? get currentUserId => _c.auth.currentUser?.id;

  @override
  Stream<String?> authStateChanges() async* {
    yield _c.auth.currentSession?.user.id;
    await for (final s in _c.auth.onAuthStateChange) {
      yield s.session?.user.id;
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _c.auth
          .signInWithPassword(email: email.trim(), password: password);
      await _ensureProfile();
    } catch (e) {
      throw friendlyError(e);
    }
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String username,
    required double heightCm,
    required double weightKg,
  }) async {
    try {
      final res = await _c.auth.signUp(
        email: email.trim(),
        password: password,
        // Kept in user metadata so the profile row can be created on first
        // login when email confirmation delays the session.
        data: {'username': username, 'height_cm': heightCm, 'weight_kg': weightKg},
      );
      if (res.session == null) return SignUpResult.confirmEmail;
      await _ensureProfile();
      return SignUpResult.signedIn;
    } catch (e) {
      throw friendlyError(e);
    }
  }

  /// public.users has no trigger, so the app inserts the profile row itself.
  Future<void> _ensureProfile() async {
    final user = _c.auth.currentUser;
    if (user == null) return;
    final row =
        await _c.from('users').select('id').eq('id', user.id).maybeSingle();
    if (row != null) return;
    final m = user.userMetadata ?? {};
    final name = m['username'] as String?;
    if (name == null) return;
    await _c.from('users').insert({
      'id': user.id,
      'username': name,
      'height_cm': (m['height_cm'] as num?)?.toDouble() ?? 0,
      'weight_kg': (m['weight_kg'] as num?)?.toDouble() ?? 0,
    });
  }

  @override
  Future<void> signOut() async {
    try {
      await _c.auth.signOut();
    } catch (e) {
      throw friendlyError(e);
    }
  }

  @override
  Future<AppUser?> getProfile() async {
    try {
      final id = currentUserId;
      if (id == null) return null;
      final row = await _c
          .from('users')
          .select('id,username,height_cm,weight_kg,created_at')
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : AppUser.fromJson(row);
    } catch (e) {
      throw friendlyError(e);
    }
  }
}

class SupabasePlanRepository implements PlanRepository {
  SupabasePlanRepository(this._c);
  final SupabaseClient _c;

  String get _uid {
    final id = _c.auth.currentUser?.id;
    if (id == null) throw AppException('Please log in first.');
    return id;
  }

  @override
  Future<List<Plan>> getPlans({Category? category}) async {
    try {
      // Public plans plus your own. The server currently lets everyone read
      // private plans, so this filter is what keeps them hidden.
      var q = _c
          .from('plans')
          .select(_planCols)
          .or('is_public.eq.true,creator_id.eq.$_uid');
      if (category != null) q = q.eq('category', category.db);
      final rows = await q.order('created_at', ascending: false).order('id');
      return rows.map(Plan.fromJson).toList();
    } catch (e) {
      throw friendlyError(e);
    }
  }

  @override
  Future<List<Plan>> getSavedPlans() async {
    try {
      final rows = await _c
          .from('saved_plans')
          .select('plans!inner($_planCols)')
          .eq('user_id', _uid);
      return rows
          .map((r) => Plan.fromJson(r['plans'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw friendlyError(e);
    }
  }

  @override
  Future<List<PlanExercise>> getPlanExercises(int planId) async {
    try {
      final rows = await _c
          .from('plan_exercises')
          .select(
              'sets,reps,day_of_week,sort_order,exercises!inner(id,name,primary_muscle_group)')
          .eq('plan_id', planId)
          .order('day_of_week')
          .order('sort_order');
      return rows.map(PlanExercise.fromJson).toList();
    } catch (e) {
      throw friendlyError(e);
    }
  }

  @override
  Future<List<Exercise>> getExercises() async {
    try {
      final rows = await _c
          .from('exercises')
          .select('id,name,primary_muscle_group')
          .order('name');
      return rows.map(Exercise.fromJson).toList();
    } catch (e) {
      throw friendlyError(e);
    }
  }

  @override
  Future<int> createPlan(NewPlan plan) async {
    try {
      final created = await _c
          .from('plans')
          .insert({
            // creator_id defaults to auth.uid() on the server.
            'title': plan.title,
            'duration_weeks': plan.durationWeeks,
            'difficulty': plan.difficulty.db,
            'category': plan.category.db,
            'is_public': plan.isPublic,
            'created_at': _date(DateTime.now()), // column is a date with no default
          })
          .select('id')
          .single();
      final id = (created['id'] as num).toInt();
      if (plan.exercises.isNotEmpty) {
        await _c.from('plan_exercises').insert([
          for (var i = 0; i < plan.exercises.length; i++)
            {
              'plan_id': id,
              'exercise_id': plan.exercises[i].exerciseId,
              'day_of_week': plan.exercises[i].dayOfWeek,
              'sort_order': i + 1,
              'sets': plan.exercises[i].sets,
              'reps': plan.exercises[i].reps,
            }
        ]);
      }
      return id;
    } catch (e) {
      throw friendlyError(e);
    }
  }

  @override
  Future<void> savePlan(int planId) async {
    try {
      await _c.from('saved_plans').insert({'plan_id': planId}); // user_id defaults to auth.uid()
    } catch (e) {
      throw friendlyError(e);
    }
  }
}

class SupabaseWorkoutRepository implements WorkoutRepository {
  SupabaseWorkoutRepository(this._c);
  final SupabaseClient _c;

  @override
  Future<void> logWorkout(List<NewWorkoutLog> logs) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw AppException('Please log in first.');
    try {
      await _c.from('workout_logs').insert([
        for (final l in logs)
          {
            // user_id is sent explicitly: its server default is a random uuid.
            'user_id': uid,
            'exercise_id': l.exerciseId,
            'plan_id': l.planId,
            'logged_at': _date(DateTime.now()),
            'total_sets_done': l.setsDone,
            'total_reps_done': l.repsDone,
          }
      ]);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw AppException(
            'Saving workouts is not enabled on the server yet. Ask the database owner to add an insert policy on workout_logs.');
      }
      throw friendlyError(e);
    } catch (e) {
      throw friendlyError(e);
    }
  }

  @override
  Future<List<WorkoutLog>> getRecentLogs({int limit = 5}) async {
    try {
      final rows = await _c
          .from('workout_logs')
          .select(
              'id,exercise_id,plan_id,logged_at,total_sets_done,total_reps_done,exercises(name)')
          .order('logged_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);
      return rows.map(WorkoutLog.fromJson).toList();
    } catch (e) {
      throw friendlyError(e);
    }
  }
}
