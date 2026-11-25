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

void main() {
  testWidgets('landing -> login error -> login -> home -> plans -> workout',
      (t) async {
    await t.pumpWidget(const ProviderScope(child: FitnessApp()));
    await settle(t);
    expect(find.text('Fitness App'), findsOneWidget);

    await t.tap(find.text('Login'));
    await t.pumpAndSettle();

    // Empty submit shows a readable error, not a raw server message.
    await t.tap(find.text('Submit'));
    await settle(t);
    expect(find.text('Enter your email and password.'), findsOneWidget);

    await t.enterText(find.byType(TextField).at(0), 'john@seed.test');
    await t.enterText(find.byType(TextField).at(1), 'Password123!');
    await t.tap(find.text('Submit'));
    await settle(t);

    expect(find.text('john_doe69'), findsOneWidget);
    expect(find.text('Saved Plans'), findsOneWidget);

    await t.tap(find.text('Plans').last);
    await settle(t);
    expect(find.text('Fat Burn Circuit'), findsOneWidget);
    // Other users' private plans are hidden.
    expect(find.text('Deload Week (Private)'), findsNothing);

    await t.tap(find.text('Fat Burn Circuit'));
    await settle(t);
    expect(find.text('Active Workout'), findsOneWidget);
    expect(find.text('Burpee'), findsOneWidget);

    await t.tap(find.text('Set 1').first);
    await t.pump();
    expect(find.textContaining('1 / '), findsOneWidget);
  });

  testWidgets('app runs on fake data when no keys are provided', (t) async {
    expect(AppConfig.useFake, isTrue);
  });
}

