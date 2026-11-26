import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/plan_preferences.dart';
import '../../app/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'desktop_workspace.dart';
import 'pace_plan_widgets.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({
    super.key,
    this.copyFrom,
    this.onViewSavedPlans,
    this.onCancel,
  });

  final Plan? copyFrom;
  final VoidCallback? onViewSavedPlans;
  final VoidCallback? onCancel;

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _DraftExercise {
  const _DraftExercise(
    this.exercise,
    this.day,
    this.sets,
    this.reps,
    this.rest,
  );

  final Exercise exercise;
  final int day;
  final int sets;
  final int reps;
  final int rest;

  NewPlanExercise toInput() => NewPlanExercise(
    exerciseId: exercise.id,
    dayOfWeek: day,
    sets: sets,
    reps: reps,
    restSeconds: rest,
  );
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _title = TextEditingController();
  final _weeks = TextEditingController(text: '6');
  final List<_DraftExercise> _drafts = [];
  Category _category = Category.strength;
  Difficulty _difficulty = Difficulty.medium;
  bool? _public;
  bool _showExercises = false;
  bool _copying = false;
  bool _saving = false;
  _DraftExercise? _revealed;
  String? _error;
  String? _lastSaved;
  int _desktopDay = 2;
  final _extraDays = <int>{2};

  @override
  void initState() {
    super.initState();
    final source = widget.copyFrom;
    if (source != null) {
      _title.text = '${source.title} (copy)';
      _weeks.text = '${source.durationWeeks}';
      _category = source.category;
      _difficulty = source.difficulty;
      _public = false;
      _copying = true;
      _loadCopy(source);
    }
  }

  Future<void> _loadCopy(Plan plan) async {
    try {
      final exercises = await ref.read(planExercisesProvider(plan.id).future);
      if (!mounted) return;
      _drafts.addAll(
        exercises.map(
          (e) => _DraftExercise(
            Exercise(id: e.exerciseId, name: e.name, muscle: e.muscle),
            e.dayOfWeek,
            e.sets,
            e.reps,
            e.restSeconds,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _error = friendly(error);
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _weeks.dispose();
    super.dispose();
  }

  Future<void> _addExercise() => _editExercise();

  Future<void> _editExercise([_DraftExercise? exercise]) async {
    final desktop = AppTokens.desktop(context);
    final draft = desktop
        ? await showDialog<_DraftExercise>(
            context: context,
            builder: (_) => Dialog(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 560,
                child: _ExerciseSheet(
                  initial: exercise,
                  initialDay: _desktopDay,
                  desktop: true,
                ),
              ),
            ),
          )
        : await showModalBottomSheet<_DraftExercise>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            backgroundColor: AppTokens.surface,
            constraints: const BoxConstraints(maxWidth: 680),
            builder: (_) => const _ExerciseSheet(),
          );
    if (!mounted || draft == null) return;
    setState(() {
      if (exercise != null && exercise.day == draft.day) {
        _drafts[_drafts.indexOf(exercise)] = draft;
      } else {
        if (exercise != null) _drafts.remove(exercise);
        final index = _drafts.lastIndexWhere((e) => e.day <= draft.day);
        _drafts.insert(index + 1, draft);
      }
      _desktopDay = draft.day;
      _lastSaved = null;
      _showExercises = true;
      _error = null;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final weeks = int.tryParse(_weeks.text.trim());
    final inputs = _drafts.map((e) => e.toInput()).toList();
    if (title.isEmpty || weeks == null || weeks < 1 || inputs.isEmpty) {
      setState(
        () => _error = title.isEmpty
            ? 'Give your plan a name.'
            : weeks == null || weeks < 1
            ? 'Enter a duration in whole weeks.'
            : 'Add at least one exercise.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(planRepositoryProvider)
          .createPlan(
            NewPlan(
              title: title,
              durationWeeks: weeks,
              difficulty: _difficulty,
              category: _category,
              isPublic:
                  _public ?? ref.read(defaultPlanPublicProvider).value ?? true,
              exercises: inputs,
            ),
          );
      if (!mounted) return;
      ref.invalidate(plansProvider);
      if (widget.copyFrom != null) {
        _closeCopy();
        return;
      }
      setState(() {
        _title.clear();
        _drafts.clear();
        _public = null;
        _showExercises = false;
        _saving = false;
        _lastSaved = title;
      });
      if (!AppTokens.desktop(context)) showSnack(context, 'Plan saved');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = friendly(error);
        _saving = false;
      });
    }
  }

  void _reorderDay(List<_DraftExercise> dayDrafts, int from, int to) {
    setState(() {
      final reordered = [...dayDrafts];
      reordered.insert(to, reordered.removeAt(from));
      final firstIndex = _drafts.indexOf(dayDrafts.first);
      _drafts.replaceRange(
        firstIndex,
        firstIndex + reordered.length,
        reordered,
      );
      _revealed = null;
    });
  }

  List<Widget> _exerciseLists(ThemeData theme) {
    final groups = <int, List<_DraftExercise>>{};
    for (final draft in _drafts) {
      (groups[draft.day] ??= []).add(draft);
    }
    return [
      if (groups.isEmpty) const SectionTitle('Exercises'),
      for (final group in groups.entries) ...[
        SectionTitle('${dayName(group.key)} · Exercises'),
        Text(
          'Hold the grip to reorder. Swipe left to delete.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) => _reorderDay(group.value, from, to),
          itemCount: group.value.length,
          itemBuilder: (context, index) {
            final draft = group.value[index];
            return Padding(
              key: ObjectKey(draft),
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ObjectKey(draft),
                direction: _saving
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  setState(() => _revealed = draft);
                  return false;
                },
                background: const ColoredBox(
                  color: AppTokens.surface,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.delete_outline, color: AppTokens.error),
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              draft.exercise.name,
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text(
                              '${draft.sets} sets × ${draft.reps} reps · ${draft.rest}s rest',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              draft.exercise.muscle.label,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (identical(_revealed, draft))
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTokens.error,
                            side: const BorderSide(color: AppTokens.error),
                          ),
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                  _drafts.remove(draft);
                                  _revealed = null;
                                }),
                          child: const Text('Delete'),
                        )
                      else
                        ReorderableDragStartListener(
                          index: index,
                          enabled: !_saving,
                          child: IconButton(
                            tooltip: 'Exercise options',
                            onPressed: _saving
                                ? null
                                : () => setState(() => _revealed = draft),
                            icon: const Icon(
                              Icons.drag_indicator,
                              color: AppTokens.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
      OutlinedButton.icon(
        onPressed: _saving || _copying ? null : _addExercise,
        icon: const Icon(Icons.add),
        label: const Text('Add exercise'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublic =
        _public ?? ref.watch(defaultPlanPublicProvider).value ?? true;
    if (AppTokens.desktop(context)) {
      final editor = _desktopEditor(theme, isPublic);
      return widget.copyFrom == null ? editor : Scaffold(body: editor);
    }
    final body = SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: ValueKey(_showExercises),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              children: [
                Row(
                  children: [
                    if (_showExercises || widget.copyFrom != null)
                      BackButton(
                        onPressed: () {
                          if (_showExercises) {
                            setState(() => _showExercises = false);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    Expanded(
                      child: Text(
                        _showExercises ? 'Plan exercises' : 'Create plan',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_showExercises)
                  Card(
                    color: AppTokens.surface,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title.text.trim().isEmpty
                                ? 'New plan'
                                : _title.text.trim(),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_weeks.text} weeks · ${_category.label} · ${_difficulty.label} · ${isPublic ? 'Public' : 'Private'}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _showExercises = false),
                              child: const Text('Edit plan details'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  AppTextField(
                    label: 'Plan name',
                    controller: _title,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Duration (weeks)',
                          controller: _weeks,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Labeled(
                          'Difficulty',
                          DropdownButtonFormField<Difficulty>(
                            initialValue: _difficulty,
                            isExpanded: true,
                            items: [
                              for (final d in Difficulty.values)
                                DropdownMenuItem(
                                  value: d,
                                  child: Text(d.label),
                                ),
                            ],
                            onChanged: _saving
                                ? null
                                : (v) => setState(
                                    () => _difficulty = v ?? _difficulty,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Labeled(
                    'Category',
                    DropdownButtonFormField<Category>(
                      initialValue: _category,
                      isExpanded: true,
                      items: [
                        for (final c in Category.values)
                          DropdownMenuItem(value: c, child: Text(c.label)),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _category = v ?? _category),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Labeled(
                    'Visibility',
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Public')),
                          ButtonSegment(value: false, label: Text('Private')),
                        ],
                        selected: {isPublic},
                        showSelectedIcon: false,
                        onSelectionChanged: _saving
                            ? null
                            : (s) => setState(() => _public = s.single),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Public plans appear in Discover.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (_copying)
                  const LinearProgressIndicator()
                else
                  ..._exerciseLists(theme),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
            child: Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ErrorMessage(_error!),
                  ),
                PrimaryButton(
                  label: 'Save plan',
                  loading: _saving,
                  loadingLabel: 'Saving plan…',
                  onPressed: _copying ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return widget.copyFrom == null
        ? body
        : Scaffold(body: SafeArea(child: body));
  }

  Future<void> _deleteExercise(_DraftExercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this exercise?'),
        content: const Text(
          'This removes the exercise and all its sets from this draft. Your other exercises will stay.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep exercise'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTokens.error,
              side: const BorderSide(color: AppTokens.error),
            ),
            child: const Text('Delete exercise'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) setState(() => _drafts.remove(exercise));
  }

  Future<void> _cancelDesktop() async {
    if (widget.copyFrom != null) {
      _closeCopy();
      return;
    }
    if (_drafts.isNotEmpty || _title.text.trim().isNotEmpty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Discard this draft?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep editing'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (!mounted || discard != true) return;
    }
    setState(() {
      _title.clear();
      _drafts.clear();
      _error = null;
      _lastSaved = null;
    });
    widget.onCancel?.call();
  }

  void _closeCopy() {
    if (widget.onCancel case final close?) {
      close();
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _desktopEditor(ThemeData theme, bool isPublic) {
    final days = {
      ..._extraDays,
      for (final exercise in _drafts) exercise.day,
    }.toList()..sort();
    final exercises = _drafts
        .where((exercise) => exercise.day == _desktopDay)
        .toList();
    final text = theme.textTheme;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: desktopPadding,
            children: [
              Text('Make a plan. Make it yours.', style: text.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Build a routine worth showing up for. Start with the essentials.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_lastSaved case final title?) ...[
                PacePanel(
                  outline: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✓  Plan saved',
                        style: TextStyle(
                          color: AppTokens.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(title),
                      if (widget.onViewSavedPlans != null)
                        TextButton(
                          onPressed: widget.onViewSavedPlans,
                          child: const Text('View My Plans'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth * .32)
                          .clamp(232, 370)
                          .toDouble(),
                      child: PacePanel(
                        outline: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Plan details', style: text.titleLarge),
                            const SizedBox(height: 14),
                            AppTextField(
                              label: 'Plan name',
                              controller: _title,
                              enabled: !_saving,
                              onChanged: (_) {
                                if (_lastSaved != null) {
                                  setState(() => _lastSaved = null);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'Duration (weeks)',
                              controller: _weeks,
                              enabled: !_saving,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _Labeled(
                              'Category',
                              DropdownButtonFormField<Category>(
                                initialValue: _category,
                                isExpanded: true,
                                items: [
                                  for (final c in Category.values)
                                    DropdownMenuItem(
                                      value: c,
                                      child: Text(c.label),
                                    ),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(
                                        () => _category = value ?? _category,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Labeled(
                              'Difficulty',
                              DropdownButtonFormField<Difficulty>(
                                initialValue: _difficulty,
                                isExpanded: true,
                                items: [
                                  for (final d in Difficulty.values)
                                    DropdownMenuItem(
                                      value: d,
                                      child: Text(d.label),
                                    ),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(
                                        () =>
                                            _difficulty = value ?? _difficulty,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Labeled(
                              'Visibility',
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(
                                    value: true,
                                    label: Text('Public'),
                                  ),
                                  ButtonSegment(
                                    value: false,
                                    label: Text('Private'),
                                  ),
                                ],
                                showSelectedIcon: false,
                                selected: {isPublic},
                                onSelectionChanged: _saving
                                    ? null
                                    : (value) => setState(
                                        () => _public = value.single,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isPublic
                                  ? 'Public plans appear in Discover.'
                                  : 'Private plans stay in your library.',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: desktopGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final day in days)
                                CategoryChip(
                                  label:
                                      'Day ${days.indexOf(day) + 1} · ${dayName(day)}',
                                  selected: day == _desktopDay,
                                  onTap: () =>
                                      setState(() => _desktopDay = day),
                                ),
                              if (days.length < 7)
                                PopupMenuButton<int>(
                                  tooltip: 'Add day',
                                  enabled: !_saving && !_copying,
                                  onSelected: (day) => setState(() {
                                    _extraDays.add(day);
                                    _desktopDay = day;
                                  }),
                                  itemBuilder: (_) => [
                                    for (var day = 1; day <= 7; day++)
                                      if (!days.contains(day))
                                        PopupMenuItem(
                                          value: day,
                                          child: Text(dayName(day)),
                                        ),
                                  ],
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('+ Day'),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${exercises.length} exercises · ${exercises.fold(0, (total, item) => total + item.sets)} sets',
                                  style: text.titleLarge,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _saving || _copying
                                    ? null
                                    : _addExercise,
                                icon: const Icon(Icons.add),
                                label: const Text('Add exercise'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_copying)
                            const LinearProgressIndicator()
                          else if (exercises.isEmpty)
                            const PacePanel(
                              child: Text('Add an exercise to begin this day.'),
                            )
                          else ...[
                            ReorderableListView.builder(
                              key: ValueKey(_desktopDay),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              onReorderItem: (from, to) =>
                                  _reorderDay(exercises, from, to),
                              itemCount: exercises.length,
                              itemBuilder: (context, index) {
                                final exercise = exercises[index];
                                return Padding(
                                  key: ObjectKey(exercise),
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: PacePanel(
                                    child: Row(
                                      children: [
                                        ReorderableDragStartListener(
                                          index: index,
                                          enabled: !_saving,
                                          child: const Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: Icon(
                                              Icons.drag_indicator,
                                              color: AppTokens.textSecondary,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exercise.exercise.name,
                                                style: text.bodyLarge,
                                              ),
                                              Text(
                                                '${exercise.sets} sets × ${exercise.reps} reps · ${exercise.rest}s rest',
                                                style: text.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _saving
                                              ? null
                                              : () => _editExercise(exercise),
                                          child: const Text('Edit'),
                                        ),
                                        TextButton(
                                          onPressed: _saving
                                              ? null
                                              : () => _deleteExercise(exercise),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            Text(
                              'Drag the handle to reorder exercises for this day.',
                              style: text.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ColoredBox(
          color: AppTokens.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _error == null
                      ? const SizedBox.shrink()
                      : ErrorMessage(_error!),
                ),
                OutlinedButton(
                  onPressed: _saving ? null : _cancelDesktop,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 176,
                  child: PrimaryButton(
                    label: 'Save plan',
                    loading: _saving,
                    loadingLabel: 'Saving plan…',
                    onPressed: _copying ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseSheet extends ConsumerStatefulWidget {
  const _ExerciseSheet({
    this.initial,
    this.initialDay = 2,
    this.desktop = false,
  });
  final _DraftExercise? initial;
  final int initialDay;
  final bool desktop;

  @override
  ConsumerState<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends ConsumerState<_ExerciseSheet> {
  late final _sets = TextEditingController(
    text: '${widget.initial?.sets ?? 3}',
  );
  late final _reps = TextEditingController(
    text: '${widget.initial?.reps ?? 12}',
  );
  late final _rest = TextEditingController(
    text: '${widget.initial?.rest ?? PlanExercise.defaultRestSeconds}',
  );
  Exercise? _exercise;
  late int _day = widget.initial?.day ?? widget.initialDay;
  String? _error;

  @override
  void initState() {
    super.initState();
    _exercise = widget.initial?.exercise;
  }

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _add() {
    final sets = int.tryParse(_sets.text.trim());
    final reps = int.tryParse(_reps.text.trim());
    final rest = int.tryParse(_rest.text.trim());
    final exercise = _exercise;
    if (exercise == null ||
        sets == null ||
        sets < 1 ||
        reps == null ||
        reps < 1 ||
        rest == null ||
        rest < 0 ||
        rest > 90) {
      setState(
        () => _error = exercise == null
            ? 'Choose an exercise.'
            : sets == null || sets < 1 || reps == null || reps < 1
            ? 'Enter positive whole numbers for sets and reps.'
            : 'Enter a rest time between 0 and 90 seconds.',
      );
      return;
    }
    Navigator.of(context).pop(_DraftExercise(exercise, _day, sets, reps, rest));
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, widget.desktop ? 12 : 0, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initial == null ? 'Add exercise' : 'Edit exercise',
                      style: text.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (!widget.desktop) ...[
                Text('Make every set count.', style: text.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Add an exercise to ${dayName(_day)}.',
                  style: text.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              exercises.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => ErrorState(
                  error,
                  onRetry: () => ref.invalidate(exercisesProvider),
                ),
                data: (items) => _Labeled(
                  'Exercise name',
                  DropdownButtonFormField<Exercise>(
                    initialValue: items
                        .where((item) => item.id == _exercise?.id)
                        .firstOrNull,
                    isExpanded: true,
                    hint: const Text('Choose an exercise'),
                    items: [
                      for (final exercise in items)
                        DropdownMenuItem(
                          value: exercise,
                          child: Text(
                            exercise.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _exercise = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Sets',
                      controller: _sets,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Reps',
                      controller: _reps,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Rest (in seconds)',
                      controller: _rest,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Labeled(
                      'Day',
                      DropdownButtonFormField<int>(
                        initialValue: _day,
                        isExpanded: true,
                        items: [
                          for (var i = 1; i <= dayNames.length; i++)
                            DropdownMenuItem(value: i, child: Text(dayName(i))),
                        ],
                        onChanged: (v) => setState(() => _day = v ?? _day),
                      ),
                    ),
                  ),
                ],
              ),
              if (_exercise case final exercise?) ...[
                const SizedBox(height: 8),
                Text(exercise.muscle.label, style: text.bodySmall),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorMessage(_error!),
              ],
              const SizedBox(height: 20),
              if (widget.desktop)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: widget.initial == null
                            ? 'Add exercise'
                            : 'Save exercise',
                        onPressed: _add,
                      ),
                    ),
                  ],
                )
              else
                PrimaryButton(
                  label: 'Add to ${dayName(_day)}',
                  onPressed: _add,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.child);
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}
