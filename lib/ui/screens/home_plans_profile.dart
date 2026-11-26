import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'desktop_workspace.dart';
import 'pace_plan_widgets.dart';
import 'plan_detail.dart';
import 'workout_screen.dart';

export 'profile_settings.dart' show ProfileScreen;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onCreate, this.onDiscover, this.onLibrary});

  final VoidCallback? onCreate;
  final VoidCallback? onDiscover;
  final VoidCallback? onLibrary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final logs = ref.watch(recentLogsProvider);
    final saved = ref.watch(savedPlansProvider);
    final active = ref.watch(activeWorkoutProvider);
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final name = profile.value?.username;
    final firstName = name?.trim().split(RegExp(r'\s+')).first;
    final suffix = firstName == null || firstName.isEmpty ? '' : ', $firstName';
    final hasActivity = logs.value?.isNotEmpty ?? false;
    final greeting = switch (now.hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };
    if (AppTokens.desktop(context)) {
      final items = logs.value ?? const <WorkoutLog>[];
      final stats = TrainingStats.fromLogs(items, now);
      return ListView(
        padding: desktopPadding,
        children: [
          Text(
            '${hasActivity || active != null ? greeting : 'Let’s start your training story'}$suffix.',
            style: text.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Small steps. Stronger you. Let’s keep your momentum going.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          WorkspaceGrid(
            minTileWidth: 200,
            children: [
              WorkspaceStat(
                '${stats.streak} ${stats.streak == 1 ? 'day' : 'days'}',
                'Current workout streak',
                highlight: stats.streak > 0,
              ),
              WorkspaceStat('${stats.thisWeek}', 'Training days this week'),
              WorkspaceStat(
                '${items.fold(0, (total, log) => total + log.totalSetsDone)}',
                'Sets in recent activity',
              ),
            ],
          ),
          const SizedBox(height: 16),
          WorkspaceColumns(
            main: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (active != null)
                  _ResumeCard(draft: active, onDiscover: onDiscover)
                else
                  AsyncBody<List<WorkoutLog>>(
                    value: logs,
                    onRetry: () => ref.invalidate(recentLogsProvider),
                    builder: (logs) => logs.isEmpty
                        ? PaceEmptyCard(
                            icon: Icons.fitness_center,
                            title: 'No activity yet.',
                            message: 'Your first session starts a new streak.',
                            buttonLabel: 'Create a plan',
                            onAction: onCreate,
                          )
                        : _RecentWorkoutCard(
                            log: logs.first,
                            onDiscover: onDiscover,
                          ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text('Saved plans', style: text.titleLarge),
                    ),
                    if (onLibrary != null)
                      TextButton(
                        onPressed: onLibrary,
                        child: const Text('View all'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AsyncBody<List<Plan>>(
                  value: saved,
                  onRetry: () => ref.invalidate(savedPlansProvider),
                  builder: (plans) => plans.isEmpty
                      ? PaceEmptyCard(
                          icon: Icons.bookmark_border,
                          title: 'No saved plans yet.',
                          message: 'Discover a plan worth coming back to.',
                          buttonLabel: 'Discover plans',
                          onAction: onDiscover,
                        )
                      : WorkspaceGrid(
                          maxColumns: 2,
                          minTileWidth: 250,
                          children: [
                            for (final plan in plans)
                              CommunityPlanCard(
                                plan: plan,
                                onTap: () => openPlanDetail(
                                  context,
                                  plan,
                                  onBackToDiscover: onDiscover,
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
            aside: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PacePanel(
                  outline: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your week', style: text.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        '${stats.thisWeek} training ${stats.thisWeek == 1 ? 'day' : 'days'} logged.',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: stats.thisWeek / 7,
                        color: AppTokens.success,
                        backgroundColor: AppTokens.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PacePanel(
                  outline: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent activity', style: text.titleLarge),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        Text(
                          'Your logged exercises will appear here.',
                          style: text.bodyMedium,
                        ),
                      for (final log in items.take(3)) ...[
                        Text(log.exerciseName, style: text.bodyLarge),
                        Text(
                          '${log.totalSetsDone} sets · ${MaterialLocalizations.of(context).formatShortDate(log.loggedAt)}',
                          style: text.bodySmall,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(recentLogsProvider);
          ref.invalidate(savedPlansProvider);
          await ref.read(savedPlansProvider.future).catchError((_) => <Plan>[]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'PACE',
                  style: text.headlineMedium?.copyWith(
                    fontSize: 56,
                    height: 1,
                    letterSpacing: -3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Divider(color: AppTokens.primary, thickness: 3),
                ),
              ],
            ),
            const SizedBox(height: 6),
            PaceLabel(MaterialLocalizations.of(context).formatMediumDate(now)),
            const SizedBox(height: 12),
            Text(
              '${hasActivity || active != null ? greeting : 'Let’s get moving'}$suffix.',
              style: text.headlineMedium,
            ),
            const SizedBox(height: 8),
            AsyncBody<List<WorkoutLog>>(
              value: logs,
              onRetry: () => ref.invalidate(recentLogsProvider),
              builder: (items) {
                final stats = TrainingStats.fromLogs(items, now);
                return PacePanel(
                  outline: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _HomeStat(
                          label: 'CURRENT STREAK',
                          value: '${stats.streak} day streak',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HomeStat(
                          label: 'THIS WEEK',
                          value:
                              '${stats.thisWeek} training ${stats.thisWeek == 1 ? 'day' : 'days'}',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (active != null) ...[
              Text('Continue workout', style: text.titleLarge),
              const SizedBox(height: 8),
              _ResumeCard(draft: active, onDiscover: onDiscover),
            ] else if (logs.value case final items?)
              if (items.isEmpty)
                const _NoActivityCard()
              else
                _RecentWorkoutCard(log: items.first, onDiscover: onDiscover),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Saved Plans', style: text.titleLarge)),
                if (onDiscover != null)
                  IconButton(
                    tooltip: 'Find plans to save',
                    icon: const Icon(Icons.add),
                    onPressed: onDiscover,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AsyncBody<List<Plan>>(
              value: saved,
              onRetry: () => ref.invalidate(savedPlansProvider),
              builder: (items) => items.isEmpty
                  ? PaceEmptyCard(
                      icon: Icons.description_outlined,
                      title: 'Make room for progress.',
                      message: 'Build your first plan, then make every session count.',
                      buttonLabel: 'Create a plan',
                      onAction: onCreate,
                    )
                  : Column(
                      children: [
                        for (final plan in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SavedPlanPreview(
                              plan: plan,
                              onDiscover: onDiscover,
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

class _HomeStat extends StatelessWidget {
  const _HomeStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PaceLabel(label),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class _NoActivityCard extends StatelessWidget {
  const _NoActivityCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No activity yet', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Your first session starts a new streak.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.draft, this.onDiscover});
  final WorkoutResume draft;
  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PacePanel(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned.fill(
            child: TrainingArt(
              iconSize: 100,
              asset: 'assets/images/pace-dumbbells.webp',
              fit: BoxFit.cover,
              alignment: Alignment(.7, -.35),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTokens.surface,
                    AppTokens.surface.withValues(alpha: .42),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaceLabel(draft.plan.category.label),
                const SizedBox(height: 4),
                Text(draft.plan.title, style: text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${draft.starter ? '2-set starter' : dayName(draft.day)} · '
                  '${draft.setsDone} of ${draft.totalSets} sets completed'
                  '${draft.setsSkipped > 0 ? ' · ${draft.setsSkipped} skipped' : ''}',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Resume workout',
                  onPressed: () => openWorkout(
                    context,
                    draft.plan,
                    starter: draft.starter,
                    onBackToDiscover: onDiscover,
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

class _RecentWorkoutCard extends ConsumerWidget {
  const _RecentWorkoutCard({required this.log, this.onDiscover});
  final WorkoutLog log;
  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider(null)).value ?? const <Plan>[];
    final plan = plans.where((plan) => plan.id == log.planId).firstOrNull;
    final text = Theme.of(context).textTheme;
    final day = MaterialLocalizations.of(context).formatShortDate(log.loggedAt);
    return PacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaceLabel('Recent workout'),
          const SizedBox(height: 4),
          Text(plan?.title ?? log.exerciseName, style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${plan == null ? '' : '${log.exerciseName} · '}${log.totalSetsDone} sets · $day',
            style: text.bodySmall,
          ),
          if (plan != null) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Start workout',
              onPressed: () =>
                  openWorkout(context, plan, onBackToDiscover: onDiscover),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavedPlanPreview extends ConsumerWidget {
  const _SavedPlanPreview({required this.plan, this.onDiscover});
  final Plan plan;
  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(planExercisesProvider(plan.id)).value;
    final count = exercises
        ?.map((exercise) => exercise.dayOfWeek)
        .toSet()
        .length;
    final text = Theme.of(context).textTheme;
    return PacePanel(
      onTap: () => openPlanDetail(context, plan, onBackToDiscover: onDiscover),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${count == null ? '' : '${workoutCount(count)} · '}${plan.category.label}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: SizedBox.square(
              dimension: 64,
              child: TrainingArt(
                iconSize: 34,
                asset: plan.category == Category.generalFitness
                    ? 'assets/images/pace-login.webp'
                    : 'assets/images/pace-dumbbells.webp',
                fit: BoxFit.cover,
                alignment: const Alignment(.65, -.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key, this.desktopQuery});

  final ValueNotifier<String>? desktopQuery;

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

enum _PlanSort { popular, newest }

class _PlansScreenState extends ConsumerState<PlansScreen> {
  final _search = TextEditingController();
  Category? _category;
  _PlanSort _sort = _PlanSort.popular;

  @override
  void initState() {
    super.initState();
    final desktop = widget.desktopQuery;
    _category = desktop == null ? Category.strength : null;
    if (desktop != null) {
      _search.text = desktop.value;
      desktop.addListener(_applyGlobalQuery);
    }
  }

  void _applyGlobalQuery() {
    setState(() {
      _search.text = widget.desktopQuery!.value;
      _category = null;
    });
  }

  @override
  void dispose() {
    widget.desktopQuery?.removeListener(_applyGlobalQuery);
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    setState(() => _category = null);
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider(null));
    final text = Theme.of(context).textTheme;
    final query = _search.text.trim().toLowerCase();
    final matching = [
      for (final plan in plans.value ?? const <Plan>[])
        if (plan.isPublic &&
            (_category == null || _category == plan.category) &&
            _matches(plan, query))
          plan,
    ];
    final ranked = matching.any((plan) => plan.saveCount != null);
    matching.sort((a, b) {
      if (_sort == _PlanSort.popular && ranked) {
        final bySaves = (b.saveCount ?? -1).compareTo(a.saveCount ?? -1);
        if (bySaves != 0) return bySaves;
      }
      final byDate = b.createdAt.compareTo(a.createdAt);
      return byDate == 0 ? b.id.compareTo(a.id) : byDate;
    });
    final featured = _sort == _PlanSort.popular && query.isEmpty
        ? matching.firstOrNull
        : null;
    if (widget.desktopQuery != null) {
      return _desktopResults(plans, matching, ranked);
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(plansProvider(null));
          ref.invalidate(savedPlansProvider);
          await ref
              .read(plansProvider(null).future)
              .catchError((_) => <Plan>[]);
        },
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding,
          children: [
            Text('Discover', style: text.headlineMedium),
            const SizedBox(height: 8),
            Text('Find your next training block.', style: text.bodyMedium),
            if (featured != null) ...[
              const SizedBox(height: 16),
              _FeaturedPlan(plan: featured, ranked: ranked),
            ],
            const SizedBox(height: 16),
            Text('Search plans', style: text.bodyLarge),
            const SizedBox(height: 6),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by goal, plan or coach',
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              runSpacing: 8,
              children: [
                for (final category in Category.values)
                  CategoryChip(
                    label: category.label,
                    selected: _category == category,
                    onTap: () => setState(
                      () => _category = _category == category ? null : category,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            PaceSegment<_PlanSort>(
              options: const {
                _PlanSort.popular: 'Popular',
                _PlanSort.newest: 'New',
              },
              selected: _sort,
              onChanged: (sort) => setState(() => _sort = sort),
            ),
            const SizedBox(height: 16),
            AsyncBody<List<Plan>>(
              value: plans,
              onRetry: () => ref.invalidate(plansProvider(null)),
              builder: (_) => matching.isEmpty
                  ? PaceEmptyCard(
                      icon: Icons.search,
                      title: 'No plans found',
                      message: 'Try another search or clear your filters.',
                      buttonLabel: 'Clear filters',
                      onAction: _clearFilters,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PaceLabel(switch (_sort) {
                          _PlanSort.newest => 'Just added',
                          _PlanSort.popular when ranked =>
                            'Community favourites',
                          _PlanSort.popular => 'Community plans',
                        }),
                        if (_sort == _PlanSort.popular && !ranked) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Showing newest plans while popularity rankings are unavailable.',
                            style: text.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 12),
                        for (final plan in matching)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CommunityPlanCard(
                              key: ValueKey(plan.id),
                              plan: plan,
                              showDate: _sort == _PlanSort.newest,
                              onTap: () => openPlanDetail(context, plan),
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

  Widget _desktopResults(
    AsyncValue<List<Plan>> plans,
    List<Plan> matching,
    bool ranked,
  ) {
    final text = Theme.of(context).textTheme;
    return ListView(
      key: const PageStorageKey('desktop-discover'),
      padding: desktopPadding,
      children: [
        Text('Find your next training block.', style: text.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Built by the community. Made for your goals.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by plan, goal or coach',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 210,
              child: PaceSegment<_PlanSort>(
                options: const {
                  _PlanSort.popular: 'Popular',
                  _PlanSort.newest: 'New',
                },
                selected: _sort,
                onChanged: (sort) => setState(() => _sort = sort),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          runSpacing: 8,
          children: [
            CategoryChip(
              label: 'All plans',
              selected: _category == null,
              onTap: () => setState(() => _category = null),
            ),
            for (final category in Category.values)
              CategoryChip(
                label: category.label,
                selected: _category == category,
                onTap: () => setState(() => _category = category),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                _sort == _PlanSort.newest
                    ? 'Just added'
                    : ranked
                    ? 'Recommended for you'
                    : 'Community plans',
                style: text.titleLarge,
              ),
            ),
            if (plans.hasValue)
              Text(
                '${matching.length} community ${matching.length == 1 ? 'plan' : 'plans'}',
                style: text.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: 12),
        AsyncBody<List<Plan>>(
          value: plans,
          onRetry: () => ref.invalidate(plansProvider(null)),
          builder: (_) => matching.isEmpty
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: PaceEmptyCard(
                      icon: Icons.search,
                      title: 'No plans found.',
                      message: 'Try another search or clear your filters.',
                      buttonLabel: 'Clear filters',
                      onAction: _clearFilters,
                    ),
                  ),
                )
              : WorkspaceGrid(
                  children: [
                    for (final plan in matching)
                      CommunityPlanCard(
                        key: ValueKey(plan.id),
                        plan: plan,
                        showDate: _sort == _PlanSort.newest,
                        onTap: () => openPlanDetail(context, plan),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  bool _matches(Plan plan, String query) {
    final words = query.split(RegExp(r'\s+'));
    final searchText =
        '${plan.title} ${plan.category.label} '
                '${planHandle(plan.creatorName)} ${plan.difficulty.label}'
            .toLowerCase();
    return words.every(searchText.contains);
  }
}

class _FeaturedPlan extends StatelessWidget {
  const _FeaturedPlan({required this.plan, required this.ranked});
  final Plan plan;
  final bool ranked;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PacePanel(
      padding: EdgeInsets.zero,
      onTap: () => openPlanDetail(context, plan),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 162, child: TrainingArt(iconSize: 118)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PaceLabel(ranked ? 'Community favourite' : 'Featured plan'),
                const SizedBox(height: 4),
                Text(plan.title, style: text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${planDuration(plan)} · ${plan.category.label} · ${planHandle(plan.creatorName)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
