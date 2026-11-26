import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'desktop_workspace.dart';
import 'pace_plan_widgets.dart';
import 'workout_rest_timer.dart';

part 'workout_draft.dart';
part 'workout_desktop.dart';
part 'workout_views.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({
    super.key,
    required this.plan,
    this.starter = false,
    this.initialDay,
    this.onBackToDiscover,
  });

  final Plan plan;
  final bool starter;
  final int? initialDay;
  final VoidCallback? onBackToDiscover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = planExercisesProvider(plan.id);
    final exercises = ref.watch(provider);
    final draft = ref.read(activeWorkoutProvider.notifier)._find(plan, starter);
    final data = exercises.asData?.value;
    if (draft != null || (data != null && data.isNotEmpty)) {
      return _WorkoutSession(
        plan: plan,
        starter: starter,
        initialDay: initialDay,
        exercises: data,
        onBackToDiscover: onBackToDiscover,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(starter ? 'Your 2-set starter' : plan.title)),
      body: SafeArea(
        child: AsyncBody<List<PlanExercise>>(
          value: exercises,
          onRetry: () => ref.invalidate(provider),
          isEmpty: (data) => data.isEmpty,
          emptyMessage: 'This plan has no exercises yet.',
          builder: (_) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _WorkoutSession extends ConsumerStatefulWidget {
  const _WorkoutSession({
    required this.plan,
    required this.starter,
    required this.initialDay,
    required this.exercises,
    required this.onBackToDiscover,
  });

  final Plan plan;
  final bool starter;
  final int? initialDay;
  final List<PlanExercise>? exercises;
  final VoidCallback? onBackToDiscover;

  @override
  ConsumerState<_WorkoutSession> createState() => _WorkoutSessionState();
}

class _WorkoutSessionState extends ConsumerState<_WorkoutSession>
    with WidgetsBindingObserver {
  late final _WorkoutDraft _draft;
  Timer? _restTicker;
  bool _foreground = true;
  bool _saving = false;
  String? _error;
  _WorkoutResult? _result;

  _WorkoutStage get _stage => _draft.stage;
  bool get _starter => _draft.starter;
  _ExerciseProgress get _starterExercise => _draft.exercises.first;
  bool get _showRest =>
      _stage == _WorkoutStage.rest ||
      (!_starter &&
          _stage == _WorkoutStage.active &&
          _draft.restingExercise != null);
  int get _restSeconds => _draft.restTimer.secondsRemaining(DateTime.now());

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    _draft =
        ref
            .read(activeWorkoutProvider.notifier)
            ._find(widget.plan, widget.starter) ??
        _WorkoutDraft(
          widget.plan,
          widget.starter,
          widget.exercises!,
          ref.read(authRepositoryProvider).currentUserId,
          initialDay: widget.initialDay,
        );
    _startRestTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _startRestTicker();
    if (_foreground && _showRest) setState(() {});
  }

  @override
  void dispose() {
    _restTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startRestTicker() {
    _restTicker?.cancel();
    if (!_foreground || !_showRest) return;
    final delay = _draft.restTimer.untilNextSecond(DateTime.now());
    if (delay == null) return;
    _restTicker = Timer(delay, () {
      setState(() {});
      _startRestTicker();
    });
  }

  void _keepDraft() {
    ref.read(activeWorkoutProvider.notifier)._keep(_draft);
  }

  void _startStarter() {
    setState(() {
      _draft.startedAt = DateTime.now();
      _draft.stage = _WorkoutStage.active;
    });
    _keepDraft();
  }

  void _logStarterSet() {
    final exercise = _starterExercise;
    if (!exercise.validInput) {
      _showInputError();
      return;
    }
    final setIndex = exercise.completed;
    if (setIndex >= exercise.sets.length) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _error = null;
      exercise.sets[setIndex] = exercise.logSet();
      if (exercise.pending == 0) {
        _draft.stage = _WorkoutStage.allLogged;
      } else {
        _draft.stage = _WorkoutStage.rest;
        _draft.startRest(0, setIndex);
      }
    });
    _keepDraft();
    _startRestTicker();
  }

  void _continueStarter() {
    setState(() {
      _draft.clearRest();
      _draft.stage = _WorkoutStage.active;
    });
    _keepDraft();
    _startRestTicker();
  }

  void _adjustRest(int amount) {
    setState(() => _draft.restTimer.adjust(DateTime.now(), amount));
    _startRestTicker();
  }

  void _skipRest() {
    setState(_draft.restTimer.skip);
    _startRestTicker();
  }

  void _showInputError() {
    setState(() => _error = 'Enter a valid weight and at least one rep.');
  }

  void _updateInput(_ExerciseProgress exercise, bool weight, String value) {
    setState(() {
      if (weight) {
        exercise.weightInput = value;
      } else {
        exercise.repsInput = value;
      }
      _error = null;
    });
    _keepDraft();
  }

  void _toggleSet(int exerciseIndex, int setIndex) {
    if (_saving) return;
    final exercise = _draft.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    if (set.status == _SetStatus.ready && !exercise.validInput) {
      _showInputError();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _error = null;
      exercise.sets[setIndex] = switch (set.status) {
        _SetStatus.ready => exercise.logSet(),
        _SetStatus.logged => const _WorkoutSet(_SetStatus.skipped),
        _SetStatus.skipped => const _WorkoutSet(_SetStatus.ready),
      };
      if (set.status == _SetStatus.ready && _draft.pending > 0) {
        _draft.startRest(exerciseIndex, setIndex);
      } else if (_draft.restingExercise == exerciseIndex &&
          _draft.restingSet == setIndex) {
        _draft.clearRest();
      }
    });
    _keepDraft();
    _startRestTicker();
  }

  void _selectDay(int day) {
    if (day == _draft.day || _draft.completed + _draft.skipped > 0) return;
    setState(() {
      _error = null;
      _draft.selectDay(day);
    });
    final drafts = ref.read(activeWorkoutProvider.notifier);
    if (drafts._find(_draft.plan, _starter) != null) drafts._keep(_draft);
  }

  void _toggleExercise(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _draft.expandedIndex = _draft.expandedIndex == index ? null : index;
    });
  }

  void _review() {
    setState(() {
      _error = null;
      _draft.stage = _WorkoutStage.review;
    });
    _keepDraft();
  }

  Future<void> _save({bool allowPartial = false}) async {
    if (_saving ||
        (!allowPartial && _draft.pending > 0) ||
        _draft.completed == 0) {
      return;
    }
    if (_draft.owner != ref.read(authRepositoryProvider).currentUserId) {
      setState(
        () => _error = 'Your account changed. Reopen this workout to continue.',
      );
      return;
    }
    final result = _WorkoutResult(_draft, DateTime.now());
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(workoutRepositoryProvider).logWorkout(result.logs);
      if (!mounted) return;
      ref.invalidate(recentLogsProvider);
      ref.read(activeWorkoutProvider.notifier)._finish(_draft);
      setState(() {
        _saving = false;
        _result = result;
        _draft.clearRest();
        _draft.stage = _WorkoutStage.summary;
      });
      _startRestTicker();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = friendly(error);
        _saving = false;
      });
    }
  }

  void _handleBack() {
    if (_saving) return;
    if (_stage == _WorkoutStage.review) {
      setState(() {
        _error = null;
        _draft.stage = _WorkoutStage.allLogged;
      });
      _keepDraft();
    } else if (_stage == _WorkoutStage.share) {
      setState(() => _draft.stage = _WorkoutStage.summary);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _backToDiscover() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onBackToDiscover?.call();
  }

  Future<void> _copySummary() async {
    final result = _result!;
    final summary = [
      'PACE · ${_draft.plan.title}',
      '${result.completed} of ${result.total} sets completed',
      '${result.reps} reps · ${result.volumeLabel} total volume',
      result.durationLabel,
    ].join('\n');
    try {
      await Clipboard.setData(ClipboardData(text: summary));
      if (mounted) showSnack(context, 'Workout summary copied');
    } catch (_) {
      if (mounted) showSnack(context, 'Could not copy the workout summary');
    }
  }

  String get _title => switch (_stage) {
    _WorkoutStage.intro => 'Your 2-set starter',
    _WorkoutStage.review => 'Review session',
    _WorkoutStage.summary => 'Workout summary',
    _WorkoutStage.share => 'Share workout',
    _ => _starter ? _draft.starterTitle : _draft.plan.title,
  };

  @override
  Widget build(BuildContext context) {
    final interceptBack =
        _saving ||
        _stage == _WorkoutStage.review ||
        _stage == _WorkoutStage.share;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showBack =
        (_stage != _WorkoutStage.summary || !_starter) &&
        (Navigator.of(context).canPop() || interceptBack);
    return PopScope(
      canPop: !interceptBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && interceptBack) _handleBack();
      },
      child: AppTokens.desktop(context)
          ? _desktopSession(showBack)
          : Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: showBack ? BackButton(onPressed: _handleBack) : null,
                title: Text(_title),
                flexibleSpace: _starter && _stage != _WorkoutStage.summary
                    ? const _StarterAppBarBackground()
                    : null,
              ),
              body: SafeArea(
                bottom: false,
                child: _WorkoutWidth(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    children: _body(),
                  ),
                ),
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                child: _WorkoutWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showRest && !keyboardOpen)
                        _RestBar(
                          remaining: _restSeconds,
                          onAdjust: _adjustRest,
                          onSkip: _skipRest,
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _footer(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _body() => switch (_stage) {
    _WorkoutStage.intro => _intro(),
    _WorkoutStage.active => _starter ? _starterSet() : _fullWorkout(),
    _WorkoutStage.rest => _starterRest(),
    _WorkoutStage.allLogged => _starterComplete(),
    _WorkoutStage.review => _reviewBody(),
    _WorkoutStage.summary || _WorkoutStage.share => _summary(),
  };

  List<Widget> _footer() => switch (_stage) {
    _WorkoutStage.intro => [
      _WorkoutPrimary('Start session', onPressed: _startStarter),
    ],
    _WorkoutStage.active =>
      _starter
          ? [
              _WorkoutSmall(
                _starterExercise.completed == 0
                    ? 'Next up · ${_starterExercise.restSeconds} seconds of rest'
                    : 'Your final set. Finish when you’re ready.',
              ),
              const SizedBox(height: 12),
              _WorkoutPrimary(
                'Log set ${_starterExercise.completed + 1} · '
                '${_amount(_starterExercise.weight ?? 0)} kg × '
                '${_starterExercise.reps ?? _starterExercise.exercise.reps}',
                onPressed: _logStarterSet,
              ),
            ]
          : [
              _WorkoutPrimary(
                switch (_draft.pending) {
                  0 when _draft.completed > 0 => 'Finish workout',
                  0 => 'Complete a set to finish',
                  1 => 'Complete the final set',
                  final count => '$count sets left',
                },
                onPressed: _draft.pending == 0 && _draft.completed > 0
                    ? _save
                    : null,
                loading: _saving,
              ),
            ],
    _WorkoutStage.rest => [
      _WorkoutPrimary('Continue to set 2', onPressed: _continueStarter),
    ],
    _WorkoutStage.allLogged => [
      const _WorkoutSmall('Finish to save this session to your history.'),
      const SizedBox(height: 12),
      _WorkoutPrimary('Finish workout', onPressed: _review),
    ],
    _WorkoutStage.review => [
      _WorkoutOutline(
        'Back to session',
        onPressed: _saving ? null : _handleBack,
      ),
      const SizedBox(height: 16),
      _WorkoutPrimary('Finish & save', onPressed: _save, loading: _saving),
    ],
    _WorkoutStage.summary =>
      _starter
          ? [_WorkoutPrimary('Back to Discover', onPressed: _backToDiscover)]
          : [
              Row(
                children: [
                  Expanded(
                    child: _WorkoutPrimary(
                      'Share',
                      onPressed: () =>
                          setState(() => _draft.stage = _WorkoutStage.share),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _WorkoutOutline('Done', onPressed: _handleBack),
                  ),
                ],
              ),
            ],
    _WorkoutStage.share => [
      const _WorkoutSmall('Community sharing is currently unavailable.'),
      const SizedBox(height: 8),
      const _WorkoutPrimary('Share to community'),
      const SizedBox(height: 8),
      _WorkoutOutline('Copy summary for a friend', onPressed: _copySummary),
    ],
  };
}
