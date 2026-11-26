library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/screens/auth_screens.dart';
import '../ui/screens/main_shell.dart';
import '../ui/theme/app_theme.dart';
import 'providers.dart';

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PACE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) {
        if (AppTokens.desktop(context)) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              visualDensity: VisualDensity.standard,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              scaffoldBackgroundColor: AppTokens.chrome,
              appBarTheme: theme.appBarTheme.copyWith(
                backgroundColor: AppTokens.chrome,
              ),
            ),
            child: child!,
          );
        }
        return ColoredBox(
          color: AppTokens.chrome,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: child,
            ),
          ),
        );
      },
      home: const AuthGate(),
    );
  }
}

/// Shows the app when signed in, the landing page otherwise.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LandingScreen(),
      data: (id) => id == null ? const LandingScreen() : const MainShell(),
    );
  }
}
