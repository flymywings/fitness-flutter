import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'create_screen.dart';
import 'desktop_workspace.dart';
import 'pace_plan_widgets.dart';
import 'workout_screen.dart';

void openPlanDetail(
  BuildContext context,
  Plan plan, {
  VoidCallback? onBackToDiscover,
}) {
  final workspace = DesktopWorkspaceNavigation.maybeOf(context);
  if (workspace != null) {
    workspace.onOpenPlan(plan);
    return;
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          PlanDetailScreen(plan: plan, onBackToDiscover: onBackToDiscover),
    ),
  );
}

void openWorkout(
  BuildContext context,
  Plan plan, {
  bool starter = false,
  int? initialDay,
  VoidCallback? onBackToDiscover,
}) =>
    Navigator.of(context, rootNavigator: AppTokens.desktop(context)).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          plan: plan,
          starter: starter,
          initialDay: initialDay,
          onBackToDiscover: onBackToDiscover,
        ),
      ),
    );

Map<int, List<PlanExercise>> _weeklySchedule(List<PlanExercise> exercises) {
  final ordered = [...exercises]
    ..sort((a, b) {
      final day = a.dayOfWeek.compareTo(b.dayOfWeek);
      return day == 0 ? a.sortOrder.compareTo(b.sortOrder) : day;
    });
  final days = <int, List<PlanExercise>>{};
  for (final exercise in ordered) {
    (days[exercise.dayOfWeek] ??= []).add(exercise);
  }
  return days;
}

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({
    super.key,
    required this.plan,
    this.onBackToDiscover,
  });
  final Plan plan;
  final VoidCallback? onBackToDiscover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final exercises = ref.watch(planExercisesProvider(plan.id));
    final schedule = _weeklySchedule(exercises.value ?? const []);
    final count = schedule.length;
    if (AppTokens.desktop(context)) {
      return _DesktopPlanDetail(
        plan: plan,
        exercises: exercises,
        schedule: schedule,
        onRetry: () => ref.invalidate(planExercisesProvider(plan.id)),
        onBackToDiscover: onBackToDiscover,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        centerTitle: false,
        actions: [
          if (plan.isPublic) ...[
            IconButton(
              tooltip: 'Share plan',
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => _SharePlanScreen(plan: plan)),
              ),
            ),
            IconButton(
              tooltip: 'Report plan',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const _ReportPlanScreen()),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: pagePadding,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              child: const SizedBox(
                height: 164,
                child: TrainingArt(iconSize: 124),
              ),
            ),
            const SizedBox(height: 12),
            PaceLabel('${plan.category.label} · ${plan.difficulty.label}'),
            const SizedBox(height: 8),
            Text(plan.title, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${planDuration(plan)}${count > 0 ? ' · ${workoutCount(count)} / week' : ''}',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                PaceAvatar(plan.creatorName),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    planHandle(plan.creatorName),
                    style: text.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AsyncBody<List<PlanExercise>>(
              value: exercises,
              onRetry: () => ref.invalidate(planExercisesProvider(plan.id)),
              isEmpty: (items) => items.isEmpty,
              emptyMessage: 'This plan has no exercises yet.',
              builder: (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StarterCard(
                    exercise: schedule.values.first.first,
                    onTap: () => openWorkout(
                      context,
                      plan,
                      starter: true,
                      onBackToDiscover: onBackToDiscover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Your weekly schedule', style: text.titleLarge),
                  const SizedBox(height: 4),
                  Text('Repeat each week.', style: text.bodyMedium),
                  const SizedBox(height: 12),
                  for (final (index, day) in schedule.entries.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayCard(
                        day: day.key,
                        dayNumber: index + 1,
                        exercises: day.value,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PageActions(
        children: [
          PrimaryButton(
            label: 'Start workout',
            onPressed: schedule.isEmpty
                ? null
                : () => openWorkout(
                    context,
                    plan,
                    onBackToDiscover: onBackToDiscover,
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: PlanSaveButton(plan: plan)),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: exercises.value == null
                      ? null
                      : () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => CreateScreen(copyFrom: plan),
                          ),
                        ),
                  child: const Text('Copy & edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopPlanDetail extends StatefulWidget {
  const _DesktopPlanDetail({
    required this.plan,
    required this.exercises,
    required this.schedule,
    required this.onRetry,
    this.onBackToDiscover,
  });
  final Plan plan;
  final AsyncValue<List<PlanExercise>> exercises;
  final Map<int, List<PlanExercise>> schedule;
  final VoidCallback onRetry;
  final VoidCallback? onBackToDiscover;

  @override
  State<_DesktopPlanDetail> createState() => _DesktopPlanDetailState();
}

class _DesktopPlanDetailState extends State<_DesktopPlanDetail> {
  int? _selectedDay;

  void _showDetailDialog(Widget screen) => showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: 520, height: 500, child: screen),
    ),
  );

  void _copyPlan() {
    final workspace = DesktopWorkspaceNavigation.maybeOf(context);
    if (workspace != null) {
      workspace.onCopyPlan(widget.plan);
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => CreateScreen(copyFrom: widget.plan)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final days = widget.schedule.keys.toList();
    final day = days.contains(_selectedDay) ? _selectedDay : days.firstOrNull;
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppTokens.chrome,
      child: ListView(
        padding: desktopPadding,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed:
                  widget.onBackToDiscover ??
                  () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(
                widget.onBackToDiscover == null ? 'Back' : 'Back to Discover',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(plan.title, style: text.headlineMedium),
          const SizedBox(height: 6),
          Text(
            '${plan.category.label}  /  ${plan.difficulty.label}  /  ${planDuration(plan)}'
            '${days.isEmpty ? '' : '  /  ${workoutCount(days.length)} per week'}',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          WorkspaceColumns(
            main: AsyncBody<List<PlanExercise>>(
              value: widget.exercises,
              onRetry: widget.onRetry,
              isEmpty: (items) => items.isEmpty,
              emptyMessage: 'This plan has no exercises yet.',
              builder: (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StarterCard(
                    exercise: widget.schedule[day]!.first,
                    onTap: () => openWorkout(
                      context,
                      plan,
                      starter: true,
                      initialDay: day,
                      onBackToDiscover: widget.onBackToDiscover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in days)
                        CategoryChip(
                          label:
                              'Day ${days.indexOf(key) + 1} · ${dayName(key)}',
                          selected: key == day,
                          onTap: () => setState(() => _selectedDay = key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DayCard(
                    day: day!,
                    dayNumber: days.indexOf(day) + 1,
                    exercises: widget.schedule[day]!,
                  ),
                ],
              ),
            ),
            aside: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PacePanel(
                  outline: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Make it your next plan.', style: text.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        'Everything you need for a focused training block.',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Start workout',
                        onPressed: day == null
                            ? null
                            : () => openWorkout(
                                context,
                                plan,
                                initialDay: day,
                                onBackToDiscover: widget.onBackToDiscover,
                              ),
                      ),
                      const SizedBox(height: 12),
                      PlanSaveButton(plan: plan),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: widget.exercises.hasValue ? _copyPlan : null,
                        child: const Text('Copy & Edit'),
                      ),
                      if (plan.isPublic) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton(
                              onPressed: () => _showDetailDialog(
                                _SharePlanScreen(plan: plan),
                              ),
                              child: const Text('Share'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _showDetailDialog(const _ReportPlanScreen()),
                              child: const Text('Report'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PacePanel(
                  outline: true,
                  child: Row(
                    children: [
                      PaceAvatar(plan.creatorName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planHandle(plan.creatorName),
                              style: text.bodyLarge,
                            ),
                            Text(
                              plan.isPublic ? 'Community plan' : 'Private plan',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.exercise, required this.onTap});
  final PlanExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PacePanel(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PaceLabel('Start small. Build momentum.'),
                const SizedBox(height: 4),
                Text('Try the 2-set starter', style: text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${exercise.name} · 2 × ${exercise.reps} reps',
                  style: text.bodySmall,
                ),
                Text(
                  exercise.restSeconds == 0
                      ? 'No rest between sets'
                      : '${exercise.restSeconds}-second rest between sets',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.dayNumber,
    required this.exercises,
  });
  final int day;
  final int dayNumber;
  final List<PlanExercise> exercises;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaceLabel('Day $dayNumber'),
          const SizedBox(height: 4),
          Text(dayName(day), style: text.titleLarge),
          for (final exercise in exercises) ...[
            const SizedBox(height: 12),
            Text(exercise.name, style: text.bodyLarge),
            Text(_exerciseDetails(exercise), style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

String _exerciseDetails(PlanExercise exercise) =>
    '${exercise.sets} sets × ${exercise.reps} reps · '
    '${exercise.restSeconds == 0 ? 'No rest' : 'Rest ${exercise.restSeconds}s'}';

class _SharePlanScreen extends ConsumerWidget {
  const _SharePlanScreen({required this.plan});
  final Plan plan;

  Future<void> _copy(BuildContext context, List<PlanExercise> exercises) async {
    final schedule = _weeklySchedule(exercises);
    final details = [
      plan.title,
      '${plan.category.label} · ${plan.difficulty.label} · ${planDuration(plan)}',
      'By ${planHandle(plan.creatorName)} on PACE',
      for (final day in schedule.entries) ...[
        '',
        dayName(day.key),
        for (final exercise in day.value)
          '${exercise.name} · ${_exerciseDetails(exercise)}',
      ],
    ].join('\n');
    try {
      await Clipboard.setData(ClipboardData(text: details));
      if (context.mounted) showPaceSuccess(context, 'Plan details copied');
    } catch (error) {
      if (context.mounted) {
        showSnack(context, 'Could not copy the plan. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final exercises = ref.watch(planExercisesProvider(plan.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Share plan'), centerTitle: false),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: pagePadding,
          children: [
            Text('Train better, together.', style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Send a plan to your training partner.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            CommunityPlanCard(plan: plan),
            const SizedBox(height: 16),
            PacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaceLabel('Plan details'),
                  const SizedBox(height: 8),
                  Text(
                    'Copy the plan and paste it into a message.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  AsyncBody<List<PlanExercise>>(
                    value: exercises,
                    onRetry: () =>
                        ref.invalidate(planExercisesProvider(plan.id)),
                    builder: (items) => OutlinedButton(
                      onPressed: () => _copy(context, items),
                      child: const Text('Copy plan details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportPlanScreen extends StatefulWidget {
  const _ReportPlanScreen();

  @override
  State<_ReportPlanScreen> createState() => _ReportPlanScreenState();
}

class _ReportPlanScreenState extends State<_ReportPlanScreen> {
  static const _reasons = [
    'Unsafe exercise advice',
    'Spam or misleading content',
    'Harassment or hate',
    'Something else',
  ];
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Report plan'), centerTitle: false),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: pagePadding,
          children: [
            Text('Help keep PACE safe.', style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Report submission is currently unavailable.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final reason in _reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  selected: _reason == reason,
                  child: OutlinedButton(
                    style: _reason == reason
                        ? OutlinedButton.styleFrom(
                            backgroundColor: AppTokens.textPrimary,
                            foregroundColor: AppTokens.background,
                          )
                        : null,
                    onPressed: () => setState(() => _reason = reason),
                    child: Text(reason, textAlign: TextAlign.center),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _PageActions(
        children: [
          OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              disabledBackgroundColor: AppTokens.surface,
              disabledForegroundColor: AppTokens.error.withValues(alpha: .72),
              side: BorderSide(color: AppTokens.error.withValues(alpha: .48)),
              minimumSize: const Size(0, AppTokens.actionHeight),
            ),
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}

class _PageActions extends StatelessWidget {
  const _PageActions({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppTokens.chrome,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    ),
  );
}
