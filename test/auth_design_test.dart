import 'package:fitness_app/ui/screens/auth_screens.dart';
import 'package:fitness_app/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('access links work on a compact viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const LandingScreen()),
      ),
    );

    final logIn = find.widgetWithText(FilledButton, 'Log in');
    await tester.ensureVisible(logIn);
    await tester.pump();
    await tester.tap(logIn);
    await tester.pumpAndSettle();

    final register = find.text('Register now');
    await tester.ensureVisible(register);
    await tester.pump();
    await tester.tap(register);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets('malformed login email is flagged on its field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'alex@');
    await tester.enterText(fields.last, 'Password123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final email = tester.widget<TextField>(fields.first);
    expect(email.decoration?.errorText, 'Enter a valid email address.');
    await tester.enterText(fields.first, 'alex@example.com');
    await tester.pump();
    expect(
      tester.widget<TextField>(fields.first).decoration?.errorText,
      isNull,
    );
  });

  testWidgets('password visibility can be toggled without losing input', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
      ),
    );

    final password = find.byType(TextField).last;
    await tester.enterText(password, 'Password123');
    expect(tester.widget<TextField>(password).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isFalse);
    expect(tester.widget<TextField>(password).controller?.text, 'Password123');
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(tester.widget<TextField>(password).obscureText, isTrue);
  });

  testWidgets('sign-up disallows passwords without a number', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const RegisterScreen()),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Alex Morgan');
    await tester.enterText(fields.at(1), 'alex@example.com');
    await tester.enterText(fields.at(2), 'Password');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      tester.widget<TextField>(fields.last).decoration?.errorText,
      isNotNull,
    );
  });

  testWidgets(
    'sign-up reports progress and locks its fields during submission',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const RegisterScreen(),
          ),
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Alex Morgan');
      await tester.enterText(fields.at(1), 'alex@example.com');
      await tester.enterText(fields.at(2), 'Password123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Creating account…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widgetList<TextField>(fields)
            .every((field) => field.enabled == false),
        isTrue,
      );

      await tester.pump(const Duration(milliseconds: 300));
    },
  );
}
