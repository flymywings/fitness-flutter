import 'package:fitness_app/app/providers.dart';
import 'package:fitness_app/domain/models/enums.dart';
import 'package:fitness_app/domain/models/models.dart';
import 'package:fitness_app/domain/repositories/repositories.dart';
import 'package:fitness_app/ui/screens/workout_rest_timer.dart';
import 'package:fitness_app/ui/screens/workout_screen.dart';
import 'package:fitness_app/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _plan = Plan(
  id: 93,
  title: 'Upper body A',
  durationWeeks: 6,
  difficulty: Difficulty.medium,
  isPublic: true,
  createdAt: DateTime(2026),
  category: Category.strength,
  creatorId: 'coach',
  creatorName: 'maya.moves',
);

const _bench = PlanExercise(
  exerciseId: 17,
  name: 'Barbell Bench Press',
  muscle: Muscle.chest,
  sets: 2,
  reps: 8,
  dayOfWeek: 2,
  sortOrder: 1,
  restSeconds: 90,
);

class _WorkoutRepository implements WorkoutRepository {
  final saved = <NewWorkoutLog>[];
  bool fail = false;

  @override
  Future<void> logWorkout(List<NewWorkoutLog> logs) async {
    if (fail) throw AppException('Workout could not be saved.');
    saved.addAll(logs);
  }

  @override
  Future<List<WorkoutLog>> getRecentLogs({int limit = 5}) async => [];
}

Future<void> _openWorkout(
  WidgetTester tester,
  _WorkoutRepository repository, {
  bool starter = false,
  bool launcher = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planExercisesProvider(_plan.id).overrideWith((ref) async => [_bench]),
        workoutRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: launcher
            ? Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkoutScreen(plan: _plan, starter: starter),
                        ),
                      ),
                      child: const Text('Open workout'),
                    ),
                  ),
                ),
              )
            : WorkoutScreen(plan: _plan, starter: starter),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (launcher) {
    await tester.tap(find.text('Open workout'));
    await tester.pumpAndSettle();
  }
}

void main() {
  test('rest deadlines account for missed seconds and clamp adjustments', () {
    final now = DateTime.utc(2026, 8, 18);
    final timer = WorkoutRestTimer()..start(now, 100);
    expect(timer.secondsRemaining(now), 90);
    final resumed = now.add(const Duration(seconds: 44, milliseconds: 500));
    expect(timer.secondsRemaining(resumed), 46);
    expect(timer.untilNextSecond(resumed), const Duration(milliseconds: 500));
    timer.adjust(resumed, -15);
    expect(timer.secondsRemaining(resumed), 31);
    expect(timer.secondsRemaining(now.add(const Duration(seconds: 76))), 0);
    expect(timer.untilNextSecond(now.add(const Duration(seconds: 76))), isNull);
    timer.adjust(resumed, 120);
    expect(timer.secondsRemaining(resumed), 90);
    timer.skip();
    expect(timer.secondsRemaining(resumed), 0);
    timer.adjust(resumed, 15);
    expect(timer.secondsRemaining(resumed), 15);
  });

  testWidgets('full workout excludes skipped sets and saves actual reps', (
    tester,
  ) async {
    final repository = _WorkoutRepository();
    await _openWorkout(tester, repository);

    expect(find.text('2 sets left'), findsOneWidget);
    expect(repository.saved, isEmpty);

    await tester.enterText(find.byType(TextField).first, '25');
    await tester.enterText(find.byType(TextField).at(1), '7');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.byTooltip('Set 1, ready'));
    await tester.pump();
    expect(find.text('Complete the final set'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Set 2, ready'));
    await tester.tap(find.byTooltip('Set 2, ready'));
    await tester.pump();
    await tester.tap(find.byTooltip('Set 2, logged'));
    await tester.pump();
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();

    expect(find.text('Session complete.'), findsOneWidget);
    expect(find.text('175 kg'), findsOneWidget);
    expect(find.text('1 of 2 · 1 skipped'), findsOneWidget);
    final log = repository.saved.single;
    expect(log.planId, _plan.id);
    expect(log.exerciseId, _bench.exerciseId);
    expect(log.setsDone, 1);
    expect(log.repsDone, 7);

    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Share to community'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Copy summary for a friend'));
    await tester.pumpAndSettle();
    expect(clipboard, contains('7 reps · 175 kg total volume'));
  });

  testWidgets(
    'starter resumes its rest and retains review after a save error',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final repository = _WorkoutRepository()..fail = true;
      await _openWorkout(tester, repository, starter: true, launcher: true);
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '40');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.text('Log set 1 · 40 kg × 8'));
      await tester.pumpAndSettle();

      final restValue = find.byKey(const ValueKey('workout-rest-seconds'));
      expect(tester.widget<Text>(restValue).data, '90');
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '+15s'))
            .onPressed,
        isNull,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.text('Open workout')),
      );
      expect(container.read(activeWorkoutProvider)?.setsDone, 1);
      await tester.tap(find.text('Open workout'));
      await tester.pumpAndSettle();
      expect(find.text('Take a breather.'), findsOneWidget);
      expect(find.text('Logged · 320 kg volume'), findsOneWidget);

      await tester.tap(find.text('−15s'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(restValue).data, '75');
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('READY FOR THE NEXT SET'), findsOneWidget);
      await tester.tap(find.text('+15s'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(restValue).data, '15');
      await tester.tap(find.text('Continue to set 2'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '45');
      await tester.enterText(find.byType(TextField).at(1), '9');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.text('Log set 2 · 45 kg × 9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish workout'));
      await tester.pumpAndSettle();

      expect(find.text('Ready to wrap up?'), findsOneWidget);
      expect(find.text('725 kg'), findsOneWidget);
      expect(repository.saved, isEmpty);
      await tester.tap(find.text('Finish & save'));
      await tester.pumpAndSettle();
      expect(find.text('Workout could not be saved.'), findsOneWidget);
      expect(find.text('You showed up.'), findsNothing);

      repository.fail = false;
      await tester.tap(find.text('Finish & save'));
      await tester.pumpAndSettle();
      expect(find.text('You showed up.'), findsOneWidget);
      expect(repository.saved.single.repsDone, 17);
      expect(container.read(activeWorkoutProvider), isNull);
      await tester.tap(find.text('Back to Discover'));
      await tester.pumpAndSettle();
      expect(find.text('Open workout'), findsOneWidget);
    },
  );
}
