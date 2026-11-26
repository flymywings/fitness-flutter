/// Plain Dart models mapped 1:1 to the Supabase tables.
library;

import 'enums.dart';

/// Thrown by repositories. [message] is safe to show to the user.
class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Row of `public.users`.
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  final String id;
  final String username;
  final DateTime createdAt;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as String,
    username: j['username'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

/// Row of `public.plans` plus the creator's username.
class Plan {
  const Plan({
    required this.id,
    required this.title,
    required this.durationWeeks,
    required this.difficulty,
    required this.isPublic,
    required this.createdAt,
    required this.category,
    required this.creatorId,
    required this.creatorName,
    this.saveCount,
  });

  final int id;
  final String title;
  final int durationWeeks;
  final Difficulty difficulty;
  final bool isPublic;
  final DateTime createdAt;
  final Category category;
  final String creatorId;
  final String creatorName;
  final int? saveCount;

  Plan withSaveCount(int count) => Plan(
    id: id,
    title: title,
    durationWeeks: durationWeeks,
    difficulty: difficulty,
    isPublic: isPublic,
    createdAt: createdAt,
    category: category,
    creatorId: creatorId,
    creatorName: creatorName,
    saveCount: count,
  );

  /// Expects the `users` key to hold `{username: ...}` (joined from plans.creator_id).
  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id: (j['id'] as num).toInt(),
    title: j['title'] as String,
    durationWeeks: (j['duration_weeks'] as num).toInt(),
    difficulty: Difficulty.fromDb(j['difficulty'] as String?),
    isPublic: j['is_public'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
    category: Category.fromDb(j['category'] as String?),
    creatorId: j['creator_id'] as String? ?? '',
    creatorName:
        (j['users'] as Map<String, dynamic>?)?['username'] as String? ??
        'unknown',
  );
}

/// Row of `public.exercises`.
class Exercise {
  const Exercise({required this.id, required this.name, required this.muscle});
  final int id;
  final String name;
  final Muscle muscle;

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    muscle: Muscle.fromDb(j['primary_muscle_group'] as String?),
  );
}

/// Row of `public.plan_exercises` joined with `exercises`.
class PlanExercise {
  static const defaultRestSeconds = 60;

  const PlanExercise({
    required this.exerciseId,
    required this.name,
    required this.muscle,
    required this.sets,
    required this.reps,
    required this.dayOfWeek,
    required this.sortOrder,
    this.restSeconds = defaultRestSeconds,
  });

  final int exerciseId;
  final String name;
  final Muscle muscle;
  final int sets;
  final int reps; // number, not text: the DB column is int
  final int dayOfWeek;
  final int sortOrder;
  final int restSeconds;

  factory PlanExercise.fromJson(Map<String, dynamic> j) {
    final ex = j['exercises'] as Map<String, dynamic>;
    return PlanExercise(
      exerciseId: (ex['id'] as num).toInt(),
      name: ex['name'] as String,
      muscle: Muscle.fromDb(ex['primary_muscle_group'] as String?),
      sets: (j['sets'] as num).toInt(),
      reps: (j['reps'] as num).toInt(),
      dayOfWeek: (j['day_of_week'] as num).toInt(),
      sortOrder: (j['sort_order'] as num).toInt(),
      restSeconds: (j['rest'] as num?)?.toInt() ?? defaultRestSeconds,
    );
  }
}

/// Row of `public.workout_logs` joined with the exercise name.
class WorkoutLog {
  const WorkoutLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.planId,
    required this.loggedAt,
    required this.totalSetsDone,
    required this.totalRepsDone,
  });

  final int id;
  final int exerciseId;
  final String exerciseName;
  final int? planId;
  final DateTime loggedAt;
  final int totalSetsDone;
  final int totalRepsDone;

  factory WorkoutLog.fromJson(Map<String, dynamic> j) => WorkoutLog(
    id: (j['id'] as num).toInt(),
    exerciseId: (j['exercise_id'] as num).toInt(),
    exerciseName:
        (j['exercises'] as Map<String, dynamic>?)?['name'] as String? ??
        'Exercise',
    planId: (j['plan_id'] as num?)?.toInt(),
    loggedAt: DateTime.parse(j['logged_at'] as String),
    totalSetsDone: (j['total_sets_done'] as num).toInt(),
    totalRepsDone: (j['total_reps_done'] as num).toInt(),
  );
}

/// Input for creating a plan.
class NewPlan {
  const NewPlan({
    required this.title,
    required this.durationWeeks,
    required this.difficulty,
    required this.category,
    required this.isPublic,
    required this.exercises,
  });
  final String title;
  final int durationWeeks;
  final Difficulty difficulty;
  final Category category;
  final bool isPublic;
  final List<NewPlanExercise> exercises;
}

class NewPlanExercise {
  const NewPlanExercise({
    required this.exerciseId,
    required this.dayOfWeek,
    required this.sets,
    required this.reps,
    this.restSeconds = PlanExercise.defaultRestSeconds,
  });
  final int exerciseId;
  final int dayOfWeek;
  final int sets;
  final int reps;
  final int restSeconds;
}

/// Input for logging one finished exercise.
class NewWorkoutLog {
  const NewWorkoutLog({
    required this.exerciseId,
    required this.planId,
    required this.setsDone,
    required this.repsDone,
  });
  final int exerciseId;
  final int? planId;
  final int setsDone;
  final int repsDone;
}

enum SignUpResult { signedIn, confirmEmail }
