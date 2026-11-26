part of 'workout_screen.dart';

extension _DesktopWorkout on _WorkoutSessionState {
  Widget _desktopSession(bool showBack) {
    final complete =
        _stage == _WorkoutStage.summary || _stage == _WorkoutStage.share;
    final username = ref.watch(profileProvider).value?.username;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        leading: showBack ? BackButton(onPressed: _handleBack) : null,
        title: Text(complete ? 'Workout complete' : 'Workout in progress'),
        actions: [
          if (username != null) ...[
            PaceAvatar(username, size: 36),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Center(child: Text(username)),
            ),
          ],
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent ||
              event.logicalKey != LogicalKeyboardKey.space ||
              !_starter ||
              _stage != _WorkoutStage.active ||
              _saving) {
            return KeyEventResult.ignored;
          }
          final focusContext = FocusManager.instance.primaryFocus?.context;
          if (focusContext?.widget is EditableText ||
              focusContext?.findAncestorWidgetOfExactType<EditableText>() !=
                  null) {
            return KeyEventResult.ignored;
          }
          _logStarterSet();
          return KeyEventResult.handled;
        },
        child: ListView(
          padding: desktopPadding,
          children: complete
              ? _desktopSummary()
              : [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_draft.plan.title, style: text.headlineMedium),
                            const SizedBox(height: 6),
                            Text(
                              '${_starter ? '2-set starter' : dayName(_draft.day)} · '
                              'Session started ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_draft.startedAt))}',
                              style: text.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (!_starter && _stage == _WorkoutStage.active)
                        OutlinedButton(
                          onPressed: _saving || _draft.completed == 0
                              ? null
                              : _confirmDesktopFinish,
                          child: const Text('Finish workout'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  WorkspaceColumns(
                    main: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: !_starter && _stage == _WorkoutStage.active
                          ? _fullWorkout(desktop: true)
                          : _body(),
                    ),
                    aside: _desktopWorkoutActions(),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _desktopWorkoutActions() {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showRest)
          _WorkoutCard(
            padding: EdgeInsets.zero,
            child: _RestBar(
              remaining: _restSeconds,
              onAdjust: _adjustRest,
              onSkip: _skipRest,
            ),
          )
        else if (_stage == _WorkoutStage.active)
          _WorkoutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _WorkoutCaption('REST TIMER'),
                const SizedBox(height: 12),
                Text('Ready to train', style: text.headlineMedium),
                const SizedBox(height: 12),
                Text(
                  'Rest starts automatically after a set is logged.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('−15s'),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('+15s'),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('Skip'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (_starter) ...[const SizedBox(height: 16), ..._footer()],
        if (_stage == _WorkoutStage.active || _stage == _WorkoutStage.rest) ...[
          const SizedBox(height: 20),
          _WorkoutCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('One set at a time.', style: text.titleLarge),
                const SizedBox(height: 10),
                Text(
                  _starter
                      ? 'Use Space or the log button to record the next set.'
                      : 'Click a set to mark it done. Click again to skip it, or once more to reset.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _saving ? null : _pauseDesktopWorkout,
                  child: const Text('Pause session'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _pauseDesktopWorkout() {
    _keepDraft();
    _handleBack();
  }

  Future<void> _confirmDesktopFinish() async {
    if (_draft.pending > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finish this workout?'),
          content: Text(
            'You logged ${_draft.completed} sets. The ${_draft.pending} unlogged sets will be excluded from your workout totals.',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep training'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Finish workout'),
            ),
          ],
        ),
      );
      if (!mounted || confirm != true) return;
    }
    await _save(allowPartial: true);
  }

  List<Widget> _desktopSummary() {
    final result = _result!;
    final exercises = _draft.exercises.where(
      (exercise) => exercise.completed > 0,
    );
    final text = Theme.of(context).textTheme;
    return [
      const _WorkoutCaption('✓  WORKOUT COMPLETE', success: true),
      const SizedBox(height: 8),
      Text('You showed up. You got stronger.', style: text.headlineMedium),
      const SizedBox(height: 8),
      Text(_draft.plan.title, style: text.bodyMedium),
      const SizedBox(height: 16),
      WorkspaceGrid(
        maxColumns: 4,
        minTileWidth: 198,
        children: [
          WorkspaceStat(result.volumeLabel, 'Total training volume'),
          WorkspaceStat(result.durationLabel, 'Workout duration'),
          WorkspaceStat(
            '${result.completed} / ${result.total}',
            'Sets completed',
          ),
          WorkspaceStat(
            '${exercises.length} / ${_draft.exercises.length}',
            'Exercises logged',
          ),
        ],
      ),
      const SizedBox(height: 16),
      WorkspaceColumns(
        main: _WorkoutCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Completed exercises', style: text.titleLarge),
              const SizedBox(height: 12),
              for (final exercise in exercises)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check, size: 18),
                  title: Text(exercise.exercise.name),
                  subtitle: Text(
                    '${exercise.completed} sets · ${exercise.sets.where((set) => set.isLogged).fold(0, (total, set) => total + set.reps)} reps',
                  ),
                  trailing: Text(
                    '${_amount(exercise.sets.where((set) => set.isLogged).fold(0.0, (total, set) => total + set.volume))} kg',
                  ),
                ),
            ],
          ),
        ),
        aside: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_starter) ...[
              SizedBox(
                height: 160,
                child: Image.asset(
                  'assets/images/pace-completion.webp',
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _WorkoutPrimary('Share session', onPressed: _shareDesktopSession),
            const SizedBox(height: 12),
            _WorkoutOutline('Back to workspace', onPressed: _backToDiscover),
          ],
        ),
      ),
    ];
  }

  Future<void> _shareDesktopSession() async {
    final result = _result!;
    final copy = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share your session'),
        content: Text(
          '${_draft.plan.title} · ${result.completed} sets · ${result.volumeLabel} · ${result.durationLabel}',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Copy summary'),
          ),
        ],
      ),
    );
    if (mounted && copy == true) await _copySummary();
  }
}
