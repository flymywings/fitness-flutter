import 'package:fitness_app/app/plan_preferences.dart';
import 'package:fitness_app/app/providers.dart';
import 'package:fitness_app/ui/screens/home_plans_profile.dart';
import 'package:fitness_app/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> mountTab(WidgetTester tester, Widget tab) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final login = container
      .read(authRepositoryProvider)
      .signIn(email: 'john@seed.test', password: 'Password123!');
  await tester.pump(const Duration(milliseconds: 300));
  await login;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: tab),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('Discover filters plans and opens a plan before a workout', (
    tester,
  ) async {
    await mountTab(tester, const PlansScreen());
    expect(find.text('Discover'), findsOneWidget);

    final search = find.byType(TextField);
    await tester.enterText(search, 'Marathon on Mars');
    await tester.pumpAndSettle();
    expect(find.text('No plans found'), findsOneWidget);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    await tester.enterText(search, 'Fat Burn');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Fat Burn Circuit'));
    await tester.tap(find.text('Fat Burn Circuit'));
    await tester.pumpAndSettle();
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('Copy & edit'), findsOneWidget);
    expect(find.byTooltip('Share plan'), findsOneWidget);
    expect(find.byTooltip('Report plan'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Plan saved to your library'), findsOneWidget);

    String? copied;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.tap(find.byTooltip('Share plan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Copy plan details'));
    await tester.tap(find.text('Copy plan details'));
    await tester.pumpAndSettle();
    expect(copied, contains('Fat Burn Circuit'));
    expect(copied, contains('Burpee'));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Report plan'));
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(OutlinedButton, 'Submit report');
    expect(tester.widget<OutlinedButton>(submit).enabled, isFalse);
    await tester.tap(find.text('Spam or misleading content'));
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(submit).enabled, isFalse);
  });

  testWidgets('Settings saves the signed-in account’s default plan privacy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = await mountTab(tester, const ProfileScreen());
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('john@seed.test'), findsOneWidget);
    await tester.tap(find.text('Default plan privacy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Private'));
    await tester.pumpAndSettle();
    expect(find.text('Private'), findsOneWidget);
    expect(container.read(defaultPlanPublicProvider).value, isFalse);
  });
}
