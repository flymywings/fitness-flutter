import 'package:fitness_app/app/app.dart';
import 'package:fitness_app/app/providers.dart';
import 'package:fitness_app/data/fake/fake_store.dart';
import 'package:fitness_app/ui/screens/workout_screen.dart';
import 'package:fitness_app/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const capture = Key('pace-capture');

  void setReferenceViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> loadHero(WidgetTester tester, String name) async {
    final context = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(
      () => precacheImage(AssetImage('assets/images/pace-$name.webp'), context),
    );
    await tester.pump();
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final inter = FontLoader('Inter');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
    }
    await inter.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('PACE access screens at the 390 × 844 reference viewport', (
    tester,
  ) async {
    setReferenceViewport(tester);
    await tester.pumpWidget(
      const RepaintBoundary(
        key: capture,
        child: ProviderScope(child: FitnessApp()),
      ),
    );
    await tester.pumpAndSettle();
    await loadHero(tester, 'welcome');
    final screen = find.byKey(capture);
    await expectLater(screen, matchesGoldenFile('goldens/pace-welcome.png'));

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    await loadHero(tester, 'login');
    await expectLater(screen, matchesGoldenFile('goldens/pace-login.png'));
  });

  testWidgets('plan editor at the reference viewport', (tester) async {
    setReferenceViewport(tester);
    final store = FakeStore.seeded()
      ..setCurrentUser('a0000000-0000-0000-0000-000000000001');
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: ProviderScope(
          overrides: [fakeStoreProvider.overrideWithValue(store)],
          child: const FitnessApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(capture),
      matchesGoldenFile('goldens/pace-create.png'),
    );
  });

  testWidgets('starter intro at the reference viewport', (tester) async {
    setReferenceViewport(tester);
    final store = FakeStore.seeded()
      ..setCurrentUser('a0000000-0000-0000-0000-000000000001');
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: ProviderScope(
          overrides: [fakeStoreProvider.overrideWithValue(store)],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: WorkoutScreen(plan: store.plans.first, starter: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await loadHero(tester, 'starter');
    await expectLater(
      find.byKey(capture),
      matchesGoldenFile('goldens/pace-starter.png'),
    );
  });
}
