/// In-memory data matching database/seed.sql (5 fake users).
/// Shared by all Fake* repositories so changes show up across screens.
library;

import 'dart:async';

import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

class FakeAccount {
  FakeAccount(this.email, this.password, this.user);
  final String email;
  String password;
  final AppUser user;
}

class FakeStore {
  FakeStore._();

  /// Fresh seeded store. Tests create their own so they stay isolated.
  factory FakeStore.seeded() {
    final s = FakeStore._();
    s._seed();
    return s;
  }

  static const seedPassword = 'Password123!';

  final List<FakeAccount> accounts = [];
  final List<Exercise> exercises = [];
  final List<Plan> plans = [];
  final List<PlanExercise> planExercises = []; // planId lives in _planOf
  final Map<PlanExercise, int> _planOf = Map.identity();
  final Map<String, Set<int>> saved = {}; // userId -> plan ids
  final List<(String userId, WorkoutLog log)> logs = [];

  String? currentUserId;
  final _auth = StreamController<String?>.broadcast();
  Stream<String?> get authChanges => _auth.stream;
  void setCurrentUser(String? id) {
    currentUserId = id;
    _auth.add(id);
  }

  int _nextPlanId = 1;
  int _nextLogId = 1;

  // --- helpers used by repositories ---
  List<PlanExercise> exercisesOf(int planId) =>
      planExercises.where((e) => _planOf[e] == planId).toList();

  void addPlanExercise(int planId, PlanExercise e) {
    planExercises.add(e);
    _planOf[e] = planId;
  }

  int nextPlanId() => _nextPlanId++;
  int nextLogId() => _nextLogId++;

  AppUser? userById(String id) {
    for (final a in accounts) {
      if (a.user.id == id) return a.user;
    }
    return null;
  }

  // --- seed ---
  void _seed() {
    const names = <(String, Muscle)>[
      ('Barbell Bench Press', Muscle.chest), // 1
      ('Incline Dumbbell Press', Muscle.chest),
      ('Push-Up', Muscle.chest),
      ('Overhead Shoulder Press', Muscle.shoulders),
      ('Cable Lateral Raise', Muscle.shoulders),
      ('Tricep Rope Pushdown', Muscle.triceps),
      ('Barbell Row', Muscle.back),
      ('Pull-Up', Muscle.back),
      ('Lat Pulldown', Muscle.back),
      ('Deadlift', Muscle.back),
      ('Barbell Curl', Muscle.biceps),
      ('Dumbbell Curl', Muscle.biceps),
      ('Back Squat', Muscle.quads),
      ('Leg Press', Muscle.quads),
      ('Bodyweight Squat', Muscle.quads),
      ('Lunges', Muscle.quads),
      ('Romanian Deadlift', Muscle.hamstrings),
      ('Hip Thrust', Muscle.glutes),
      ('Standing Calf Raise', Muscle.calves),
      ('Plank', Muscle.abs),
      ('Mountain Climber', Muscle.abs),
      ('Burpee', Muscle.fullBody),
      ('Kettlebell Swing', Muscle.fullBody),
      ('Jump Rope', Muscle.fullBody), // 24
    ];
    for (var i = 0; i < names.length; i++) {
      exercises.add(
          Exercise(id: i + 1, name: names[i].$1, muscle: names[i].$2));
    }
    Exercise ex(String n) => exercises.firstWhere((e) => e.name == n);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    const users = <(String, String, String, double, double)>[
      ('a0000000-0000-0000-0000-000000000001', 'john@seed.test', 'john_doe69', 180, 82),
      ('a0000000-0000-0000-0000-000000000002', 'jane@seed.test', 'janeganda<3', 165, 58),
      ('a0000000-0000-0000-0000-000000000003', 'mika@seed.test', 'mika_lifts', 172, 70),
      ('a0000000-0000-0000-0000-000000000004', 'carlos@seed.test', 'carlos_fit', 178, 76),
      ('a0000000-0000-0000-0000-000000000005', 'ana@seed.test', 'ana_runs', 160, 52),
    ];
    for (final u in users) {
      accounts.add(FakeAccount(
        u.$2,
        seedPassword,
        AppUser(
            id: u.$1,
            username: u.$3,
            heightCm: u.$4,
            weightKg: u.$5,
            createdAt: today),
      ));
    }
    String uid(int n) => users[n - 1].$1;
    String uname(int n) => users[n - 1].$3;

    // (id, creator#, title, weeks, difficulty, public, daysAgo, category)
    final planRows = <(int, int, String, int, Difficulty, bool, int, Category)>[
      (9001, 1, 'Upper Lower Compound Lifts', 12, Difficulty.medium, true, 30, Category.strength),
      (9002, 1, 'Push Pull Legs (Private)', 8, Difficulty.hard, false, 20, Category.hypertrophy),
      (9003, 2, 'Body Weights Only', 12, Difficulty.easy, true, 25, Category.generalFitness),
      (9004, 2, 'Fat Burn Circuit', 6, Difficulty.medium, true, 12, Category.fatLoss),
      (9005, 3, 'Hypertrophy Bro Split', 10, Difficulty.hard, true, 18, Category.hypertrophy),
      (9006, 3, 'Deload Week (Private)', 1, Difficulty.easy, false, 5, Category.generalFitness),
      (9007, 4, 'Beginner Strength 5x5', 8, Difficulty.easy, true, 40, Category.strength),
      (9008, 5, '5K Endurance Base', 12, Difficulty.medium, true, 15, Category.endurance),
      (9009, 5, 'Home Mobility (Private)', 4, Difficulty.easy, false, 8, Category.generalFitness),
    ];
    for (final p in planRows) {
      plans.add(Plan(
        id: p.$1,
        title: p.$3,
        durationWeeks: p.$4,
        difficulty: p.$5,
        isPublic: p.$6,
        createdAt: today.subtract(Duration(days: p.$7)),
        category: p.$8,
        creatorId: uid(p.$2),
        creatorName: uname(p.$2),
      ));
    }

    // (plan, exercise, day, sort, sets, reps)
    const pe = <(int, String, int, int, int, int)>[
      (9001, 'Barbell Bench Press', 2, 1, 4, 8), (9001, 'Barbell Row', 2, 2, 4, 8),
      (9001, 'Overhead Shoulder Press', 2, 3, 3, 10), (9001, 'Back Squat', 3, 1, 4, 6),
      (9001, 'Romanian Deadlift', 3, 2, 3, 8), (9001, 'Standing Calf Raise', 3, 3, 4, 12),
      (9001, 'Incline Dumbbell Press', 5, 1, 3, 10), (9001, 'Pull-Up', 5, 2, 3, 8),
      (9001, 'Leg Press', 6, 1, 3, 12),
      (9002, 'Barbell Bench Press', 2, 1, 4, 8), (9002, 'Cable Lateral Raise', 2, 2, 4, 12),
      (9002, 'Tricep Rope Pushdown', 2, 3, 3, 12), (9002, 'Lat Pulldown', 3, 1, 4, 10),
      (9002, 'Barbell Curl', 3, 2, 3, 12), (9002, 'Back Squat', 4, 1, 5, 5),
      (9003, 'Push-Up', 2, 1, 3, 12), (9003, 'Bodyweight Squat', 2, 2, 3, 15),
      (9003, 'Plank', 2, 3, 3, 30), (9003, 'Lunges', 4, 1, 3, 12),
      (9003, 'Burpee', 4, 2, 3, 10), (9003, 'Mountain Climber', 6, 1, 3, 20),
      (9004, 'Burpee', 2, 1, 4, 12), (9004, 'Kettlebell Swing', 2, 2, 4, 15),
      (9004, 'Jump Rope', 3, 1, 5, 50), (9004, 'Mountain Climber', 3, 2, 4, 20),
      (9004, 'Bodyweight Squat', 5, 1, 4, 20),
      (9005, 'Barbell Bench Press', 2, 1, 4, 10), (9005, 'Incline Dumbbell Press', 2, 2, 4, 12),
      (9005, 'Cable Lateral Raise', 2, 3, 4, 15), (9005, 'Tricep Rope Pushdown', 2, 4, 3, 12),
      (9005, 'Deadlift', 3, 1, 4, 8), (9005, 'Barbell Row', 3, 2, 4, 10),
      (9005, 'Dumbbell Curl', 3, 3, 3, 12), (9005, 'Back Squat', 5, 1, 4, 10),
      (9005, 'Leg Press', 5, 2, 4, 12), (9005, 'Hip Thrust', 5, 3, 3, 12),
      (9006, 'Plank', 2, 1, 2, 30), (9006, 'Bodyweight Squat', 2, 2, 2, 12),
      (9006, 'Push-Up', 3, 1, 2, 10),
      (9007, 'Back Squat', 2, 1, 5, 5), (9007, 'Barbell Bench Press', 2, 2, 5, 5),
      (9007, 'Barbell Row', 2, 3, 5, 5), (9007, 'Back Squat', 4, 1, 5, 5),
      (9007, 'Overhead Shoulder Press', 4, 2, 5, 5), (9007, 'Deadlift', 4, 3, 1, 5),
      (9008, 'Jump Rope', 2, 1, 5, 60), (9008, 'Lunges', 2, 2, 3, 12),
      (9008, 'Plank', 2, 3, 3, 45), (9008, 'Kettlebell Swing', 4, 1, 4, 15),
      (9008, 'Hip Thrust', 4, 2, 3, 12),
      (9009, 'Plank', 2, 1, 3, 30), (9009, 'Bodyweight Squat', 3, 1, 3, 15),
    ];
    for (final r in pe) {
      final e = ex(r.$2);
      addPlanExercise(
        r.$1,
        PlanExercise(
          exerciseId: e.id,
          name: e.name,
          muscle: e.muscle,
          sets: r.$5,
          reps: r.$6,
          dayOfWeek: r.$3,
          sortOrder: r.$4,
        ),
      );
    }

    saved[uid(1)] = {9003, 9005};
    saved[uid(2)] = {9001, 9007};
    saved[uid(3)] = {9001, 9003};
    saved[uid(4)] = {9001};
    saved[uid(5)] = {9005, 9007};

    // (user#, plan, exercise, daysAgo, sets, reps)
    const lg = <(int, int, String, int, int, int)>[
      (1, 9001, 'Barbell Bench Press', 1, 4, 32),
      (1, 9001, 'Back Squat', 3, 4, 24),
      (1, 9001, 'Pull-Up', 5, 3, 24),
      (2, 9003, 'Push-Up', 2, 3, 36),
      (2, 9004, 'Kettlebell Swing', 4, 4, 60),
      (3, 9005, 'Deadlift', 1, 4, 32),
      (3, 9005, 'Dumbbell Curl', 1, 3, 36),
      (4, 9007, 'Back Squat', 2, 5, 25),
      (5, 9008, 'Jump Rope', 1, 5, 300),
    ];
    for (final l in lg) {
      final e = ex(l.$3);
      logs.add((
        uid(l.$1),
        WorkoutLog(
          id: nextLogId(),
          exerciseId: e.id,
          exerciseName: e.name,
          planId: l.$2,
          loggedAt: today.subtract(Duration(days: l.$4)),
          totalSetsDone: l.$5,
          totalRepsDone: l.$6,
        )
      ));
    }
  }
}
