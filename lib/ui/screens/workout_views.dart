part of 'workout_screen.dart';

extension _WorkoutViews on _WorkoutSessionState {
  List<Widget> _intro() {
    final exercise = _starterExercise;
    return [
      const _WorkoutHero(
        caption: 'PACE / STARTER',
        title: 'Start strong.',
        subtitle: 'Two sets. One good habit.',
      ),
      const SizedBox(height: 24),
      Text(_draft.plan.title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      _WorkoutSmall('${_draft.starterTitle} · ${_draft.plan.creatorName}'),
      const SizedBox(height: 24),
      _WorkoutCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkoutCaption(exercise.exercise.name.toUpperCase()),
            const SizedBox(height: 12),
            Text(
              '2 sets × ${exercise.exercise.reps} reps',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${exercise.restSeconds}-second rest between sets',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const _WorkoutSmall(
        'A short preview of the full plan. Warm up first and use a weight '
        'that feels controlled.',
      ),
    ];
  }

  List<Widget> _starterSet() {
    final exercise = _starterExercise;
    final first = exercise.completed == 0;
    return [
      _WorkoutCaption('SET ${exercise.completed + 1} OF 2'),
      const SizedBox(height: 12),
      _WorkoutHeading(first ? 'Build your rhythm.' : 'Make it count.'),
      const SizedBox(height: 12),
      Text(
        exercise.exercise.name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 8),
      _WorkoutSmall(
        '${exercise.completed} of 2 sets logged · ${exercise.restSeconds}s rest',
      ),
      const SizedBox(height: 24),
      _inputs(exercise),
      if (_error != null) ...[
        const SizedBox(height: 12),
        ErrorMessage(_error!),
      ],
      const SizedBox(height: 24),
      ..._starterRows(readyIndex: exercise.completed),
      const SizedBox(height: 24),
      const _WorkoutCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkoutCaption('CONTROL EVERY REP'),
            SizedBox(height: 8),
            Text('Keep each rep smooth and controlled.'),
          ],
        ),
      ),
    ];
  }

  List<Widget> _starterRest() {
    final exercise = _starterExercise;
    return [
      const _WorkoutCaption('1 OF 2 SETS LOGGED'),
      const SizedBox(height: 12),
      _WorkoutHeading(
        _restSeconds > 0 ? 'Take a breather.' : 'Ready for round two?',
      ),
      const SizedBox(height: 12),
      Text(
        'Set 1 logged · ${_setDescription(exercise.sets.first)}',
        style: const TextStyle(color: AppTokens.success),
      ),
      const SizedBox(height: 32),
      ..._starterRows(),
      const SizedBox(height: 24),
      const _WorkoutCaption('UP NEXT'),
      const SizedBox(height: 12),
      Text(
        'Set 2 · ${exercise.exercise.name}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ];
  }

  List<Widget> _starterComplete() {
    final result = _WorkoutResult(_draft, DateTime.now());
    return [
      const _WorkoutCaption('2 OF 2 SETS LOGGED', success: true),
      const SizedBox(height: 12),
      const _WorkoutHeading('Strong finish.'),
      const SizedBox(height: 12),
      Text(
        'Every rep is in. Take a moment to recover.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 32),
      ..._starterRows(),
      const SizedBox(height: 24),
      _WorkoutCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkoutMetric('TOTAL VOLUME', result.volumeLabel),
            const SizedBox(height: 12),
            _WorkoutSmall('2 sets · ${result.reps} reps · No skipped sets'),
          ],
        ),
      ),
    ];
  }

  List<Widget> _starterRows({int? readyIndex}) {
    final exercise = _starterExercise;
    return [
      for (var index = 0; index < exercise.sets.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        _WorkoutCard(
          padding: const EdgeInsets.all(8),
          outlined: index == readyIndex,
          child: Row(
            children: [
              _WorkoutSetChip(
                index + 1,
                exercise.sets[index].status,
                subdued: index != readyIndex && !exercise.sets[index].isLogged,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.sets[index].isLogged
                          ? _setDescription(exercise.sets[index])
                          : exercise.target,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (exercise.sets[index].isLogged)
                      _WorkoutSmall(
                        'Logged · ${_amount(exercise.sets[index].volume)} kg volume',
                        success: true,
                      )
                    else
                      _WorkoutSmall(
                        index == readyIndex ? 'Ready to log' : 'Up next',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _fullWorkout({bool desktop = false}) => [
    if (_draft.days.length > 1) ...[
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final day in _draft.days)
            ChoiceChip(
              label: Text(dayName(day)),
              selected: _draft.day == day,
              onSelected: _draft.completed + _draft.skipped == 0 && !_saving
                  ? (_) => _selectDay(day)
                  : null,
            ),
        ],
      ),
      const SizedBox(height: 16),
    ],
    _WorkoutSmall(
      '${_draft.completed} / ${_draft.total} sets completed · '
      '${_draft.skipped} skipped',
    ),
    const SizedBox(height: 12),
    LinearProgressIndicator(
      value: _draft.total == 0 ? 0 : _draft.completed / _draft.total,
      minHeight: 8,
      backgroundColor: AppTokens.border,
      color: AppTokens.success,
      borderRadius: BorderRadius.circular(8),
      semanticsLabel: 'Sets completed',
    ),
    const SizedBox(height: 12),
    if (_draft.pending == 1)
      Text(
        'One more set. Finish strong.',
        style: Theme.of(context).textTheme.titleLarge,
      )
    else
      const _WorkoutSmall(
        'Tap to complete a set. Tap again to skip it, or once more to reset.',
      ),
    if (_error != null) ...[const SizedBox(height: 12), ErrorMessage(_error!)],
    const SizedBox(height: 16),
    for (var index = 0; index < _draft.exercises.length; index++) ...[
      _fullExercise(index, keepSetControls: desktop),
      const SizedBox(height: 12),
    ],
  ];

  Widget _fullExercise(int index, {bool keepSetControls = false}) {
    final entry = _draft.exercises[index];
    final expanded = _draft.expandedIndex == index;
    final resolved = entry.pending == 0;
    final firstReady = entry.sets.indexWhere(
      (set) => set.status == _SetStatus.ready,
    );
    final logged = entry.sets.where((set) => set.isLogged);
    final firstLogged = logged.firstOrNull;
    final repeat =
        firstLogged != null &&
        logged.every(
          (set) =>
              set.reps == firstLogged.reps && set.weight == firstLogged.weight,
        );
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.exercise.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        _WorkoutSmall(
          resolved
              ? '${entry.completed > 0 ? '✓ ' : ''}'
                    '${entry.completed} / ${entry.sets.length} sets completed'
                    '${entry.skipped > 0 ? ' · ${entry.skipped} skipped' : ''}'
                    '${repeat ? ' · ${_setDescription(firstLogged)}' : ''}'
              : '${entry.exercise.reps} reps · ${entry.restSeconds}s rest'
                    '${entry.completed > 0 ? ' · ${entry.completed} complete' : ''}',
          success: resolved && entry.completed > 0,
        ),
      ],
    );
    return _WorkoutCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _saving ? null : () => _toggleExercise(index),
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: header),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTokens.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded || keepSetControls)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (expanded) ...[
                    _inputs(entry, key: ValueKey((_draft.day, index))),
                    const SizedBox(height: 16),
                  ],
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      for (var set = 0; set < entry.sets.length; set++)
                        _WorkoutSetChip(
                          set + 1,
                          entry.sets[set].status,
                          subdued:
                              entry.sets[set].status == _SetStatus.ready &&
                              set != firstReady,
                          onTap: _saving ? null : () => _toggleSet(index, set),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputs(_ExerciseProgress exercise, {Key? key}) => Row(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _WorkoutInput(
          label: 'Weight · kg',
          initialValue: exercise.weightInput,
          decimal: true,
          onChanged: (value) => _updateInput(exercise, true, value),
          enabled: !_saving,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _WorkoutInput(
          label: 'Reps',
          initialValue: exercise.repsInput,
          onChanged: (value) => _updateInput(exercise, false, value),
          enabled: !_saving,
        ),
      ),
    ],
  );

  List<Widget> _reviewBody() {
    final result = _WorkoutResult(_draft, DateTime.now());
    return [
      const _WorkoutCaption('BEFORE YOU GO'),
      const SizedBox(height: 20),
      const _WorkoutHeading('Ready to wrap up?'),
      const SizedBox(height: 16),
      Text(
        'Your two-set starter is complete. Save your session to keep it in '
        'your history.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 32),
      _WorkoutCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _draft.plan.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _WorkoutSmall(_draft.starterTitle),
            const SizedBox(height: 24),
            _WorkoutDetail(
              'Sets completed',
              '${result.completed} / 2',
              success: true,
            ),
            const SizedBox(height: 16),
            _WorkoutDetail('Reps completed', '${result.reps}'),
            const SizedBox(height: 16),
            _WorkoutDetail('Total volume', result.volumeLabel),
          ],
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 16),
        ErrorMessage(_error!),
      ],
    ];
  }

  List<Widget> _summary() {
    final result = _result!;
    if (_starter) {
      final first = result.sets.first;
      final matchingSets = result.sets.every(
        (set) => set.weight == first.weight && set.reps == first.reps,
      );
      return [
        SizedBox(
          height: 164,
          child: Image.asset(
            'assets/images/pace-completion.webp',
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 20),
        const _WorkoutCaption('SESSION SAVED', success: true),
        const SizedBox(height: 12),
        const _WorkoutHeading('You showed up.'),
        const SizedBox(height: 8),
        _WorkoutSmall('${_draft.plan.title} · 2-set starter'),
        const SizedBox(height: 24),
        _WorkoutCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _WorkoutMetric(
                  'Total volume',
                  result.volumeLabel,
                  captionFirst: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WorkoutMetric(
                  'Reps completed',
                  '${result.reps}',
                  captionFirst: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _WorkoutCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _starterExercise.exercise.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _WorkoutSmall(
                '2 / 2 sets saved · ${matchingSets ? '${_setDescription(first)} each' : '${result.reps} reps total'}',
              ),
            ],
          ),
        ),
      ];
    }
    final localizations = MaterialLocalizations.of(context);
    final finished = result.finishedAt;
    final date = DateUtils.isSameDay(finished, DateTime.now())
        ? 'Today'
        : localizations.formatShortDate(finished);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(finished),
    );
    return [
      const Align(
        alignment: Alignment.centerLeft,
        child: Icon(Icons.emoji_events_outlined, color: AppTokens.success),
      ),
      const SizedBox(height: 16),
      const _WorkoutHeading('Session complete.'),
      const SizedBox(height: 12),
      Text(
        '${_draft.plan.title} · $date, $time',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 24),
      _WorkoutCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkoutMetric('TOTAL VOLUME', result.volumeLabel),
            const SizedBox(height: 16),
            _WorkoutMetric('DURATION', result.durationLabel),
            const SizedBox(height: 16),
            _WorkoutMetric('SETS COMPLETED', result.setsLabel),
          ],
        ),
      ),
    ];
  }
}

String _setDescription(_WorkoutSet set) =>
    '${_amount(set.weight)} kg × ${set.reps} reps';

class _WorkoutWidth extends StatelessWidget {
  const _WorkoutWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: child,
    ),
  );
}

class _StarterAppBarBackground extends StatelessWidget {
  const _StarterAppBarBackground();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      height: kToolbarHeight,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTokens.chrome,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
    ),
  );
}

class _WorkoutPrimary extends StatelessWidget {
  const _WorkoutPrimary(this.label, {this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: PrimaryButton(label: label, onPressed: onPressed, loading: loading),
  );
}

class _WorkoutOutline extends StatelessWidget {
  const _WorkoutOutline(
    this.label, {
    required this.onPressed,
    this.minHeight = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final double minHeight;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppTokens.textPrimary,
      minimumSize: Size(0, minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}

class _WorkoutHeading extends StatelessWidget {
  const _WorkoutHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.headlineMedium);
}

class _WorkoutSmall extends StatelessWidget {
  const _WorkoutSmall(this.label, {this.success = false});

  final String label;
  final bool success;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: success ? AppTokens.success : AppTokens.textSecondary,
    ),
  );
}

class _WorkoutCaption extends StatelessWidget {
  const _WorkoutCaption(this.label, {this.success = false});

  final String label;
  final bool success;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: success ? AppTokens.success : AppTokens.textSecondary,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.outlined = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTokens.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      side: outlined
          ? const BorderSide(color: AppTokens.textSecondary)
          : BorderSide.none,
    ),
    child: Padding(padding: padding, child: child),
  );
}

class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({
    required this.caption,
    required this.title,
    required this.subtitle,
  });

  final String caption;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 224),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [AppTokens.surface, AppTokens.surfaceAlt],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/pace-starter.webp',
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  excludeFromSemantics: true,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTokens.surface, Color(0x10000000)],
                      stops: [0.30, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FractionallySizedBox(
              widthFactor: 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WorkoutCaption(caption),
                  const SizedBox(height: 24),
                  _WorkoutHeading(title),
                  const SizedBox(height: 24),
                  Text(subtitle),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _WorkoutInput extends StatelessWidget {
  const _WorkoutInput({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    required this.enabled,
    this.decimal = false,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool decimal;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      Semantics(
        label: label,
        child: TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          enabled: enabled,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
            ),
            LengthLimitingTextInputFormatter(decimal ? 8 : 5),
          ],
          decoration: const InputDecoration(),
        ),
      ),
    ],
  );
}

class _WorkoutSetChip extends StatelessWidget {
  const _WorkoutSetChip(
    this.number,
    this.status, {
    this.onTap,
    this.subdued = false,
  });

  final int number;
  final _SetStatus status;
  final VoidCallback? onTap;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final logged = status == _SetStatus.logged;
    final prefix = switch (status) {
      _SetStatus.ready => '',
      _SetStatus.logged => '✓ ',
      _SetStatus.skipped => '— ',
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      side: logged
          ? BorderSide.none
          : BorderSide(
              color: subdued ? AppTokens.border : AppTokens.textSecondary,
            ),
    );
    final chip = Material(
      shape: shape,
      color: logged ? AppTokens.success : AppTokens.surface,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                '${onTap == null ? '' : prefix}$number',
                style: TextStyle(
                  color: logged ? AppTokens.background : AppTokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return chip;
    return Tooltip(message: 'Set $number, ${status.name}', child: chip);
  }
}

class _RestBar extends StatelessWidget {
  const _RestBar({
    required this.remaining,
    required this.onAdjust,
    required this.onSkip,
  });

  final int remaining;
  final ValueChanged<int> onAdjust;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppTokens.surface,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _WorkoutCaption(
                  remaining == 0
                      ? 'READY FOR THE NEXT SET'
                      : 'REST TIMER · SECONDS',
                ),
              ),
              Text(
                '$remaining',
                key: const ValueKey('workout-rest-seconds'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WorkoutOutline(
                  '−15s',
                  onPressed: remaining > 0 ? () => onAdjust(-15) : null,
                  minHeight: AppTokens.minTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WorkoutOutline(
                  '+15s',
                  onPressed: remaining < WorkoutRestTimer.maxSeconds
                      ? () => onAdjust(15)
                      : null,
                  minHeight: AppTokens.minTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: remaining > 0 ? onSkip : null,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTokens.textPrimary,
                    minimumSize: const Size(0, AppTokens.minTap),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _WorkoutMetric extends StatelessWidget {
  const _WorkoutMetric(this.label, this.value, {this.captionFirst = true});

  final String label;
  final String value;
  final bool captionFirst;

  @override
  Widget build(BuildContext context) {
    final caption = _WorkoutCaption(label);
    final metric = _WorkoutHeading(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        captionFirst ? caption : metric,
        const SizedBox(height: 4),
        captionFirst ? metric : caption,
      ],
    );
  }
}

class _WorkoutDetail extends StatelessWidget {
  const _WorkoutDetail(this.label, this.value, {this.success = false});

  final String label;
  final String value;
  final bool success;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 8),
      Text(
        value,
        style: TextStyle(
          color: success ? AppTokens.success : AppTokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
