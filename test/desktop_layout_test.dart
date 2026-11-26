import 'package:fitness_app/app/app.dart';
import 'package:fitness_app/app/providers.dart';
import 'package:fitness_app/data/fake/fake_store.dart';
import 'package:fitness_app/domain/models/models.dart';
import 'package:fitness_app/ui/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<FakeStore> launch(
    WidgetTester tester,
    Size size, {
    bool signedIn = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = FakeStore.seeded();
    if (signedIn) store.setCurrentUser('a0000000-0000-0000-0000-000000000001');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fakeStoreProvider.overrideWithValue(store)],
        child: const FitnessApp(),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Finder input(String label) => find.descendant(
    of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
    matching: find.byType(TextField),
  );

  for (final size in const [
    Size(1024, 700),
    Size(1440, 900),
    Size(1920, 1080),
  ]) {
    testWidgets('desktop workspace reflows at ${size.width.toInt()} px', (
      tester,
    ) async {
      await launch(tester, size);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('My Plans'), findsOneWidget);
      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();
      expect(find.text('Your training library.'), findsOneWidget);
      expect(find.text('Body Weights Only'), findsOneWidget);
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      expect(find.text('Find your next training block.'), findsOneWidget);
      expect(find.text('All plans'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('desktop signs in from the split access page', (tester) async {
    await launch(tester, const Size(1440, 900), signedIn: false);
    expect(find.text('Find your plan.\nBuild your momentum.'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back.'), findsOneWidget);
    await tester.enterText(input('Email address'), 'john@seed.test');
    await tester.enterText(input('Password'), FakeStore.seedPassword);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('My Plans'), findsOneWidget);
  });

  testWidgets('desktop plan dialog edits rest and saves the draft', (
    tester,
  ) async {
    final store = await launch(tester, const Size(1440, 900));
    await tester.tap(find.text('Create Plan'));
    await tester.pumpAndSettle();
    await tester.enterText(input('Plan name'), 'Desktop routine');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Exercise>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(input('Rest (in seconds)'), '75');
    await tester.tap(find.widgetWithText(FilledButton, 'Save exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save plan'));
    await tester.pumpAndSettle();
    final plan = store.plans.singleWhere(
      (plan) => plan.title == 'Desktop routine',
    );
    expect(store.exercisesOf(plan.id).single.restSeconds, 75);
    expect(find.text('✓  Plan saved'), findsOneWidget);
  });

  testWidgets('desktop guided workout logs the next set with Space', (
    tester,
  ) async {
    await launch(tester, const Size(1440, 900));
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upper Lower Compound Lifts').first);
    await tester.pumpAndSettle();
    expect(find.text('Plan detail'), findsOneWidget);
    expect(find.text('My Plans'), findsOneWidget);
    await tester.tap(find.text('Copy & Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Copy plan'), findsOneWidget);
    expect(find.text('My Plans'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Plan detail'), findsOneWidget);
    await tester.tap(find.text('Try the 2-set starter'));
    await tester.pumpAndSettle();
    expect(find.text('Workout in progress'), findsOneWidget);
    expect(find.text('My Plans'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Start session'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Continue to set 2'), findsOneWidget);
  });

  testWidgets('desktop can confirm and save a partial full workout', (
    tester,
  ) async {
    final store = await launch(tester, const Size(1440, 900));
    final count = store.logs.length;
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upper Lower Compound Lifts').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Set 1, ready').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Finish workout'));
    await tester.pumpAndSettle();
    expect(find.text('Finish this workout?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Finish workout'));
    await tester.pumpAndSettle();
    expect(find.text('Workout complete'), findsOneWidget);
    expect(store.logs.length, count + 1);
    expect(store.logs.last.$2.totalSetsDone, 1);
    await tester.tap(find.text('Back to workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Find your next training block.'), findsOneWidget);
  });
}
