/// Build Custom Workout.
/// Differs from the first mockup in one way: exercises are PICKED from the
/// database list (the database stores an exercise id, not free text) and each
/// gets a day of the week.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});
  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _Draft {
  _Draft(this.exercise, this.day, this.sets, this.reps);
  final Exercise exercise;
  final int day;
  final int sets;
  final int reps;
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _title = TextEditingController();
  final _weeks = TextEditingController(text: '12');
  final _sets = TextEditingController(text: '3');
  final _reps = TextEditingController(text: '10');
  Category _category = Category.generalFitness;
  Difficulty _difficulty = Difficulty.easy;
  bool _public = true;
  Exercise? _exercise;
  int _day = 2;
  final List<_Draft> _drafts = [];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_title, _weeks, _sets, _reps]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    final s = int.tryParse(_sets.text.trim());
    final r = int.tryParse(_reps.text.trim());
    if (_exercise == null) {
      setState(() => _error = 'Pick an exercise first.');
      return;
    }
    if (s == null || r == null || s <= 0 || r <= 0) {
      setState(() => _error = 'Sets and reps must be whole numbers above 0.');
      return;
    }
    setState(() {
      _drafts.add(_Draft(_exercise!, _day, s, r));
      _exercise = null;
      _error = null;
    });
  }

  Future<void> _save() async {
    final weeks = int.tryParse(_weeks.text.trim());
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Give your routine a name.');
      return;
    }
    if (weeks == null || weeks <= 0) {
      setState(() => _error = 'Duration must be a whole number of weeks.');
      return;
    }
    if (_drafts.isEmpty) {
      setState(() => _error = 'Add at least one exercise.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(planRepositoryProvider).createPlan(NewPlan(
            title: _title.text.trim(),
            durationWeeks: weeks,
            difficulty: _difficulty,
            category: _category,
            isPublic: _public,
            exercises: [
              for (final d in _drafts)
                NewPlanExercise(
                    exerciseId: d.exercise.id,
                    dayOfWeek: d.day,
                    sets: d.sets,
                    reps: d.reps),
            ],
          ));
      ref.invalidate(plansProvider);
      if (!mounted) return;
      setState(() {
        _title.clear();
        _drafts.clear();
        _saving = false;
      });
      showSnack(context, 'Workout plan saved.');
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
    final exercises = ref.watch(exercisesProvider);
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          Text('Build Custom Workout', style: text.headlineMedium),
          const SizedBox(height: AppTokens.space1),
          Text('Create your own routine and run it with the live tracker.',
              style: text.bodyMedium),
          const SizedBox(height: AppTokens.space4),
          AppTextField(
              label: 'Routine Name',
              hint: 'e.g. Upper Body Power',
              controller: _title,
              textInputAction: TextInputAction.next),
          const SizedBox(height: AppTokens.space3),
          AppTextField(
              label: 'Estimated Duration (weeks)',
              controller: _weeks,
              keyboardType: TextInputType.number),
          const SizedBox(height: AppTokens.space3),
          _Labeled(
            'Category',
            DropdownButtonFormField<Category>(
              initialValue: _category,
              isExpanded: true,
              items: [
                for (final c in Category.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          _Labeled(
            'Difficulty',
            DropdownButtonFormField<Difficulty>(
              initialValue: _difficulty,
              isExpanded: true,
              items: [
                for (final d in Difficulty.values)
                  DropdownMenuItem(value: d, child: Text(d.db)),
              ],
              onChanged: (v) => setState(() => _difficulty = v ?? _difficulty),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Text('Visibility', style: text.bodyMedium),
          const SizedBox(height: AppTokens.space2),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                  value: true,
                  icon: Icon(Icons.visibility_outlined),
                  label: Text('Public')),
              ButtonSegment(
                  value: false,
                  icon: Icon(Icons.visibility_off_outlined),
                  label: Text('Private')),
            ],
            selected: {_public},
            onSelectionChanged: (s) => setState(() => _public = s.first),
          ),
          const SizedBox(height: AppTokens.space1),
          Text(
              _public
                  ? 'Everyone can view and save your plan.'
                  : 'Only you can see your plan in the app.',
              style: text.bodySmall),
          const SectionTitle('Add Exercise'),
          Container(
            padding: const EdgeInsets.all(AppTokens.space3),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: AppTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                exercises.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => ErrorState(e,
                      onRetry: () => ref.invalidate(exercisesProvider)),
                  data: (list) => DropdownButtonFormField<Exercise>(
                    key: ValueKey(_drafts.length), // resets after each add
                    initialValue: _exercise,
                    isExpanded: true,
                    hint: const Text('Choose an exercise'),
                    items: [
                      for (final e in list)
                        DropdownMenuItem(
                            value: e,
                            child: Text('${e.name} · ${e.muscle.label}')),
                    ],
                    onChanged: (v) => setState(() => _exercise = v),
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                _Labeled(
                  'Day',
                  DropdownButtonFormField<int>(
                    initialValue: _day,
                    isExpanded: true,
                    items: [
                      for (var d = 1; d <= 7; d++)
                        DropdownMenuItem(value: d, child: Text(dayName(d))),
                    ],
                    onChanged: (v) => setState(() => _day = v ?? _day),
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            label: 'Sets',
                            controller: _sets,
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                        child: AppTextField(
                            label: 'Reps',
                            controller: _reps,
                            keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: AppTokens.space3),
                OutlinedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise to List'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppTokens.minTap)),
                ),
              ],
            ),
          ),
          if (_drafts.isNotEmpty) ...[
            const SectionTitle('Exercises in this plan'),
            for (var i = 0; i < _drafts.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_drafts[i].exercise.name, style: text.bodyLarge),
                subtitle: Text(
                    '${dayName(_drafts[i].day)} · ${_drafts[i].sets} sets × ${_drafts[i].reps} reps',
                    style: text.bodySmall),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _drafts.removeAt(i)),
                ),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppTokens.space3),
            ErrorMessage(_error!),
          ],
          const SizedBox(height: AppTokens.space4),
          PrimaryButton(
            label: 'Save Workout Plan',
            icon: Icons.done_all,
            onPressed: _save,
            loading: _saving,
          ),
        ],
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
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppTokens.space2),
          child,
        ],
      );
}
