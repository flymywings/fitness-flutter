import 'package:fitness_app/app/app.dart';
import 'package:fitness_app/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle(WidgetTester t) async {
  // Fake repos use a short delay; pump past it.
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(target);
    await tester.pump();
  }
  await tester.tap(target);
}

void main() {
  testWidgets(
    'welcome -> login error -> login -> home -> discover -> workout',
    (t) async {
      await t.pumpWidget(const ProviderScope(child: FitnessApp()));
      await settle(t);
      expect(find.text('PACE'), findsOneWidget);

      await tapVisible(t, find.text('Log in'));
      await t.pumpAndSettle();

      final logIn = find.widgetWithText(FilledButton, 'Log in');
      await tapVisible(t, logIn);
      await settle(t);
      expect(find.text('Enter your email address.'), findsOneWidget);

      await t.enterText(find.byType(TextField).at(0), 'john@seed.test');
      await t.enterText(find.byType(TextField).at(1), 'Password123!');
      await tapVisible(t, logIn);
      await settle(t);

      expect(find.text('Saved Plans'), findsOneWidget);

      await t.tap(find.text('Discover').last);
      await settle(t);

      await tapVisible(t, find.text('Strength'));
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search by goal, plan or coach',
      );
      await t.scrollUntilVisible(
        search,
        -160,
        scrollable: find.byType(Scrollable).first,
      );
      // Other users' private plans are hidden.
      await t.enterText(search, 'Deload Week');
      await settle(t);
      expect(find.text('No plans found'), findsOneWidget);
      expect(find.text('Deload Week (Private)'), findsNothing);

      await t.enterText(search, 'Fat Burn');
      await settle(t);
      final plan = find.text('Fat Burn Circuit');
      await tapVisible(t, plan);
      await settle(t);

      await t.tap(find.text('Start workout'));
      await settle(t);
      expect(find.text('Fat Burn Circuit'), findsOneWidget);
      expect(find.text('Burpee'), findsOneWidget);

      final firstSet = find.byTooltip('Set 1, ready').first;
      await tapVisible(t, firstSet);
      await t.pump();
      expect(find.text('1 / 8 sets completed · 0 skipped'), findsOneWidget);
    },
  );

  testWidgets('registration and profile work without height or weight', (
    t,
  ) async {
    await t.pumpWidget(const ProviderScope(child: FitnessApp()));
    await settle(t);
    final createFromWelcome = find.widgetWithText(
      OutlinedButton,
      'Create account',
    );
    await tapVisible(t, createFromWelcome);
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField).at(0), 'Alex Morgan');
    await t.enterText(find.byType(TextField).at(1), 'new@seed.test');
    await t.enterText(find.byType(TextField).at(2), 'Password123!');
    final createAccount = find.widgetWithText(FilledButton, 'Create account');
    await tapVisible(t, createAccount);
    await settle(t);

    expect(find.text('Saved Plans'), findsOneWidget);
    await t.tap(find.text('Profile'));
    await settle(t);
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('Height'), findsNothing);
    expect(find.text('Weight'), findsNothing);
  });

  testWidgets('app runs on fake data when no keys are provided', (t) async {
    expect(AppConfig.useFake, isTrue);
  });
}
