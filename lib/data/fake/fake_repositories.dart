/// In-memory repositories. Behave like the real ones, including the same
/// visibility rules (public plans + your own) and friendly error messages.
library;

import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import 'fake_store.dart';

const _latency = Duration(milliseconds: 250);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._s);
  final FakeStore _s;

  @override
  String? get currentUserId => _s.currentUserId;

  @override
  String? get currentUserEmail =>
      _s.accounts.where((a) => a.user.id == currentUserId).firstOrNull?.email;

  @override
  Stream<String?> authStateChanges() async* {
    yield _s.currentUserId;
    yield* _s.authChanges;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(_latency);
    if (email.trim().isEmpty || password.isEmpty) {
      throw AppException('Enter your email and password.');
    }
    final acc = _s.accounts
        .where((a) => a.email == email.trim().toLowerCase())
        .firstOrNull;
    if (acc == null || acc.password != password) {
      throw AppException('Wrong email or password.');
    }
    _s.setCurrentUser(acc.user.id);
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    await Future<void>.delayed(_latency);
    final e = email.trim().toLowerCase();
    if (_s.accounts.any((a) => a.email == e)) {
      throw AppException('That email is already registered.');
    }
    final user = AppUser(
      id: 'fake-${_s.accounts.length + 1}',
      username: username,
      createdAt: DateTime.now(),
    );
    _s.accounts.add(FakeAccount(e, password, user));
    _s.setCurrentUser(user.id);
    return SignUpResult.signedIn;
  }

  @override
  Future<void> signOut() async => _s.setCurrentUser(null);

  @override
  Future<AppUser?> getProfile() async {
    await Future<void>.delayed(_latency);
    final id = _s.currentUserId;
    return id == null ? null : _s.userById(id);
  }
}

class FakePlanRepository implements PlanRepository {
  FakePlanRepository(this._s);
  final FakeStore _s;

  String get _uid {
    final id = _s.currentUserId;
    if (id == null) throw AppException('Please log in first.');
    return id;
  }

  @override
  Future<List<Plan>> getPlans({Category? category}) async {
    await Future<void>.delayed(_latency);
    final uid = _uid;
    final list =
        _s.plans
            .where((p) => p.isPublic || p.creatorId == uid)
            .where((p) => category == null || p.category == category)
            .map(_withSaveCount)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<Plan>> getSavedPlans() async {
    await Future<void>.delayed(_latency);
    final ids = _s.saved[_uid] ?? {};
    return _s.plans
        .where((p) => ids.contains(p.id))
        .map(_withSaveCount)
        .toList();
  }

  Plan _withSaveCount(Plan plan) => plan.withSaveCount(
    _s.saved.values.where((ids) => ids.contains(plan.id)).length,
  );

  @override
  Future<List<PlanExercise>> getPlanExercises(int planId) async {
    await Future<void>.delayed(_latency);
    final list = _s.exercisesOf(planId)
      ..sort((a, b) {
        final d = a.dayOfWeek.compareTo(b.dayOfWeek);
        return d != 0 ? d : a.sortOrder.compareTo(b.sortOrder);
      });
    return list;
  }

  @override
  Future<List<Exercise>> getExercises() async {
    await Future<void>.delayed(_latency);
    return [..._s.exercises]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<int> createPlan(NewPlan plan) async {
    await Future<void>.delayed(_latency);
    final uid = _uid;
    final me = _s.userById(uid);
    final id = _s.nextPlanId();
    final now = DateTime.now();
    _s.plans.add(
      Plan(
        id: id,
        title: plan.title,
        durationWeeks: plan.durationWeeks,
        difficulty: plan.difficulty,
        isPublic: plan.isPublic,
        createdAt: DateTime(now.year, now.month, now.day),
        category: plan.category,
        creatorId: uid,
        creatorName: me?.username ?? 'me',
      ),
    );
    for (var i = 0; i < plan.exercises.length; i++) {
      final x = plan.exercises[i];
      final ex = _s.exercises.firstWhere((e) => e.id == x.exerciseId);
      _s.addPlanExercise(
        id,
        PlanExercise(
          exerciseId: ex.id,
          name: ex.name,
          muscle: ex.muscle,
          sets: x.sets,
          reps: x.reps,
          dayOfWeek: x.dayOfWeek,
          sortOrder: i + 1,
          restSeconds: x.restSeconds,
        ),
      );
    }
    return id;
  }

  @override
  Future<void> savePlan(int planId) async {
    await Future<void>.delayed(_latency);
    (_s.saved[_uid] ??= {}).add(planId);
  }

  @override
  Future<void> unsavePlan(int planId) async {
    await Future<void>.delayed(_latency);
    _s.saved[_uid]?.remove(planId);
  }
}

class FakeWorkoutRepository implements WorkoutRepository {
  FakeWorkoutRepository(this._s);
  final FakeStore _s;

  @override
  Future<void> logWorkout(List<NewWorkoutLog> logs) async {
    await Future<void>.delayed(_latency);
    final uid = _s.currentUserId;
    if (uid == null) throw AppException('Please log in first.');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final l in logs) {
      final ex = _s.exercises.firstWhere((e) => e.id == l.exerciseId);
      _s.logs.add((
        uid,
        WorkoutLog(
          id: _s.nextLogId(),
          exerciseId: ex.id,
          exerciseName: ex.name,
          planId: l.planId,
          loggedAt: today,
          totalSetsDone: l.setsDone,
          totalRepsDone: l.repsDone,
        ),
      ));
    }
  }

  @override
  Future<List<WorkoutLog>> getRecentLogs({int limit = 5}) async {
    await Future<void>.delayed(_latency);
    final uid = _s.currentUserId;
    final mine = _s.logs.where((r) => r.$1 == uid).map((r) => r.$2).toList()
      ..sort((a, b) {
        final d = b.loggedAt.compareTo(a.loggedAt);
        return d != 0 ? d : b.id.compareTo(a.id);
      });
    return mine.take(limit).toList();
  }
}
