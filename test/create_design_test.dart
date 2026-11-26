import 'package:fitness_app/app/app.dart';
import 'package:fitness_app/app/providers.dart';
import 'package:fitness_app/data/fake/fake_store.dart';
import 'package:fitness_app/domain/models/models.dart';
import 'package:fitness_app/ui/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder field(String label) => find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is AppTextField && widget.label == label,
    ),
    matching: find.byType(TextField),
  );

  testWidgets('creating a plan persists the exercise day and custom rest', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeStore.seeded()
      ..setCurrentUser('a0000000-0000-0000-0000-000000000001');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fakeStoreProvider.overrideWithValue(store)],
        child: const FitnessApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Plan name'), 'Mobile rest check');
    await tester.ensureVisible(find.text('Add exercise'));
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();

    expect(find.text('60'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<Exercise>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Rest (in seconds)'), '75');
    await tester.tap(find.text('Add to Monday'));
    await tester.pumpAndSettle();

    expect(find.text('Plan exercises'), findsOneWidget);
    expect(find.text('3 sets × 12 reps · 75s rest'), findsOneWidget);
    await tester.tap(find.text('Save plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    final plan = store.plans.singleWhere((p) => p.title == 'Mobile rest check');
    final exercise = store.exercisesOf(plan.id).single;
    expect(exercise.dayOfWeek, 2);
    expect(exercise.restSeconds, 75);
  });
}
