part of 'workout_screen.dart';

/// The current account's most recently updated workout.
final activeWorkoutProvider = NotifierProvider<WorkoutDrafts, WorkoutResume?>(
  WorkoutDrafts.new,
);

class WorkoutResume {
  const WorkoutResume._({
    required this.plan,
    required this.starter,
    required this.day,
    required this.setsDone,
    required this.setsSkipped,
    required this.totalSets,
  });

  final Plan plan;
  final bool starter;
  final int day;
  final int setsDone;
  final int setsSkipped;
  final int totalSets;
}

class WorkoutDrafts extends Notifier<WorkoutResume?> {
  final _drafts = <(int, bool), _WorkoutDraft>{};

  @override
  WorkoutResume? build() {
    var owner = ref.read(authRepositoryProvider).currentUserId;
    ref.listen(authStateProvider, (_, next) {
      if (next.hasValue && next.value != owner) {
        owner = next.value;
        _drafts.clear();
        state = null;
      }
    });
    return null;
  }

  _WorkoutDraft? _find(Plan plan, bool starter) {
    final draft = _drafts[(plan.id, starter)];
    return draft?.owner == ref.read(authRepositoryProvider).currentUserId
        ? draft
        : null;
  }

  void _keep(_WorkoutDraft draft) {
    if (draft.owner != ref.read(authRepositoryProvider).currentUserId) return;
    _drafts.remove(draft.key);
    _drafts[draft.key] = draft;
    state = draft.resume;
  }

  void _finish(_WorkoutDraft draft) {
    if (identical(draft, _drafts[draft.key])) _drafts.remove(draft.key);
    state = _drafts.values.lastOrNull?.resume;
  }
}

enum _WorkoutStage { intro, active, rest, allLogged, review, summary, share }

enum _SetStatus { ready, logged, skipped }

class _WorkoutSet {
  const _WorkoutSet(this.status, {this.weight = 0, this.reps = 0});

  final _SetStatus status;
  final double weight;
  final int reps;

  double get volume => weight * reps;
  bool get isLogged => status == _SetStatus.logged;
}

class _ExerciseProgress {
  _ExerciseProgress(this.exercise, int setCount)
    : sets = List.filled(setCount, const _WorkoutSet(_SetStatus.ready)),
      repsInput = exercise.reps.toString();

  final PlanExercise exercise;
  final List<_WorkoutSet> sets;
  String weightInput = '0';
  String repsInput;

  int get restSeconds => WorkoutRestTimer.limit(exercise.restSeconds);
  int? get reps => int.tryParse(repsInput.trim());

  double? get weight {
    final value = double.tryParse(weightInput.trim().replaceAll(',', '.'));
    return value != null && value.isFinite && value >= 0 ? value : null;
  }

  bool get validInput => (reps ?? 0) > 0 && weight != null;
  int get completed => sets.where((set) => set.isLogged).length;
  int get skipped =>
      sets.where((set) => set.status == _SetStatus.skipped).length;
  int get pending => sets.length - completed - skipped;
  String get target =>
      '${_amount(weight ?? 0)} kg × ${reps ?? exercise.reps} reps';

  _WorkoutSet logSet() =>
      _WorkoutSet(_SetStatus.logged, weight: weight!, reps: reps!);
}

class _WorkoutDraft {
  _WorkoutDraft(
    this.plan,
    this.starter,
    List<PlanExercise> exercises,
    this.owner, {
    int? initialDay,
  }) : _planExercises = [...exercises]..sort(_sortExercises),
       stage = starter ? _WorkoutStage.intro : _WorkoutStage.active {
    selectDay(days.contains(initialDay) ? initialDay! : days.first);
  }

  final Plan plan;
  final bool starter;
  final String? owner;
  final List<PlanExercise> _planExercises;
  final restTimer = WorkoutRestTimer();

  _WorkoutStage stage;
  late DateTime startedAt;
  late int day;
  late List<_ExerciseProgress> exercises;
  int? expandedIndex;
  int? restingExercise;
  int? restingSet;

  (int, bool) get key => (plan.id, starter);
  List<int> get days => {for (final e in _planExercises) e.dayOfWeek}.toList();
  int get completed => exercises.fold(0, (count, e) => count + e.completed);
  int get skipped => exercises.fold(0, (count, e) => count + e.skipped);
  int get total => exercises.fold(0, (count, e) => count + e.sets.length);
  int get pending => total - completed - skipped;

  WorkoutResume get resume => WorkoutResume._(
    plan: plan,
    starter: starter,
    day: day,
    setsDone: completed,
    setsSkipped: skipped,
    totalSets: total,
  );

  String get starterTitle {
    final name = exercises.first.exercise.name;
    if (name.toLowerCase() == 'barbell bench press') {
      return 'Bench-press starter';
    }
    return '$name starter';
  }

  void selectDay(int value) {
    day = value;
    final daily = _planExercises.where((e) => e.dayOfWeek == day);
    exercises = starter
        ? [_ExerciseProgress(daily.first, 2)]
        : daily.map((e) => _ExerciseProgress(e, e.sets)).toList();
    expandedIndex = 0;
    startedAt = DateTime.now();
    clearRest();
  }

  void startRest(int exerciseIndex, int setIndex) {
    restingExercise = exerciseIndex;
    restingSet = setIndex;
    restTimer.start(DateTime.now(), exercises[exerciseIndex].restSeconds);
  }

  void clearRest() {
    restingExercise = null;
    restingSet = null;
    restTimer.skip();
  }

  static int _sortExercises(PlanExercise first, PlanExercise second) {
    final day = first.dayOfWeek.compareTo(second.dayOfWeek);
    return day != 0 ? day : first.sortOrder.compareTo(second.sortOrder);
  }
}

class _WorkoutResult {
  _WorkoutResult(_WorkoutDraft draft, this.finishedAt)
    : total = draft.total,
      skipped = draft.skipped,
      elapsed = finishedAt.isBefore(draft.startedAt)
          ? Duration.zero
          : finishedAt.difference(draft.startedAt),
      sets = [
        for (final e in draft.exercises) ...e.sets.where((set) => set.isLogged),
      ],
      logs = [
        for (final e in draft.exercises)
          if (e.completed > 0)
            NewWorkoutLog(
              exerciseId: e.exercise.exerciseId,
              planId: draft.plan.id,
              setsDone: e.completed,
              repsDone: e.sets
                  .where((set) => set.isLogged)
                  .fold(0, (reps, set) => reps + set.reps),
            ),
      ];

  final DateTime finishedAt;
  final Duration elapsed;
  final int total;
  final int skipped;
  final List<_WorkoutSet> sets;
  final List<NewWorkoutLog> logs;

  int get completed => sets.length;
  int get reps => sets.fold(0, (reps, set) => reps + set.reps);
  double get volume => sets.fold(0, (volume, set) => volume + set.volume);
  String get volumeLabel => '${_amount(volume)} kg';
  String get setsLabel => '$completed of $total · $skipped skipped';
  String get durationLabel =>
      '${elapsed.inMinutes} min ${elapsed.inSeconds % 60} sec';
}

String _amount(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final decimals = parts.last.replaceFirst(RegExp(r'0+$'), '');
  return decimals.isEmpty ? whole : '$whole.$decimals';
}
