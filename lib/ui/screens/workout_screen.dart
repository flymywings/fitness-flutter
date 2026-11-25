/// Active Workout. Tick sets per exercise, then "Finish & Log Workout" writes
/// one workout_logs row per exercise that had at least one set done.
/// Rest time and a rest timer are NOT here: the database has no column for rest.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.plan});
  final Plan plan;
  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  int? _day;
  // exercise (by identity) -> completed set numbers (1-based)
  final Map<PlanExercise, Set<int>> _done = Map.identity();
  bool _saving = false;
  String? _error;

  Future<void> _finish(List<PlanExercise> items) async {
    final logs = <NewWorkoutLog>[];
    for (final e in items) {
      final n = _done[e]?.length ?? 0;
      if (n > 0) {
        logs.add(NewWorkoutLog(
            exerciseId: e.exerciseId,
            planId: widget.plan.id,
            setsDone: n,
            repsDone: n * e.reps));
      }
    }
    if (logs.isEmpty) {
      setState(() => _error = 'Complete at least one set first.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(workoutRepositoryProvider).logWorkout(logs);
      ref.invalidate(recentLogsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(context, 'Workout logged. Nice work!');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendly(e);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(planExercisesProvider(widget.plan.id));
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Workout')),
      body: SafeArea(
        child: AsyncBody<List<PlanExercise>>(
          value: async,
          onRetry: () => ref.invalidate(planExercisesProvider(widget.plan.id)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: 'This plan has no exercises yet.',
          builder: (all) {
            final days = {for (final e in all) e.dayOfWeek}.toList()..sort();
            final day = days.contains(_day) ? _day! : days.first;
            final items = all.where((e) => e.dayOfWeek == day).toList();
            final total = items.fold<int>(0, (s, e) => s + e.sets);
            final doneCount =
                items.fold<int>(0, (s, e) => s + (_done[e]?.length ?? 0));

            return ListView(
              padding: const EdgeInsets.all(AppTokens.space4),
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: const Center(
                      child: Icon(Icons.fitness_center,
                          size: 56, color: AppTokens.primary)),
                ),
                const SizedBox(height: AppTokens.space3),
                Text(widget.plan.title, style: text.headlineMedium),
                if (days.length > 1) ...[
                  const SizedBox(height: AppTokens.space3),
                  SizedBox(
                    height: AppTokens.minTap,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final d in days)
                          CategoryChip(
                            label: dayName(d),
                            selected: d == day,
                            onTap: () => setState(() {
                              _day = d;
                              _done.clear();
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.space2),
                Text('Progress: $doneCount / $total sets completed',
                    style: text.bodySmall),
                const SizedBox(height: AppTokens.space3),
                for (final e in items)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppTokens.space3),
                    padding: const EdgeInsets.all(AppTokens.space4),
                    decoration: BoxDecoration(
                      color: AppTokens.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      border: Border.all(color: AppTokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(e.name, style: text.titleLarge)),
                            Text(e.muscle.label,
                                style: const TextStyle(
                                    color: AppTokens.primary,
                                    fontSize: AppTokens.fontSmall)),
                          ],
                        ),
                        Text('Target: ${e.sets} sets × ${e.reps} reps',
                            style: text.bodySmall),
                        const SizedBox(height: AppTokens.space3),
                        Wrap(
                          spacing: AppTokens.space2,
                          runSpacing: AppTokens.space2,
                          children: [
                            for (var n = 1; n <= e.sets; n++)
                              SetToggleButton(
                                label: 'Set $n',
                                done: _done[e]?.contains(n) ?? false,
                                onTap: () => setState(() {
                                  final s = _done.putIfAbsent(e, () => {});
                                  s.contains(n) ? s.remove(n) : s.add(n);
                                }),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  ErrorMessage(_error!),
                  const SizedBox(height: AppTokens.space3),
                ],
                PrimaryButton(
                  label: 'Finish & Log Workout',
                  icon: Icons.emoji_events_outlined,
                  loading: _saving,
                  onPressed: () => _finish(items),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
