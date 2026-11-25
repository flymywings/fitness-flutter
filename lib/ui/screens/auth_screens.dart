/// Landing, Login and Register.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.local_fire_department,
                  size: 56, color: AppTokens.primary),
              const SizedBox(height: AppTokens.space3),
              Text('Fitness App',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppTokens.space5),
              PrimaryButton(
                label: 'Login',
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
              const SizedBox(height: AppTokens.space3),
              PrimaryButton(
                label: 'Register',
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      if (!mounted) return;
      // AuthGate swaps to the main app; remove Login/Landing from the stack.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendly(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.space5),
          children: [
            Text('Login', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppTokens.space5),
            AppTextField(
              label: 'Email',
              hint: 'johndoe@email.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: AppTokens.space4),
            AppTextField(
              label: 'Password',
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              autofillHints: const [AutofillHints.password],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTokens.space3),
              ErrorMessage(_error!),
            ],
            const SizedBox(height: AppTokens.space4),
            PrimaryButton(
                label: 'Submit', onPressed: _submit, loading: _loading),
            const SizedBox(height: AppTokens.space3),
            Row(
              children: [
                Text('No account yet?',
                    style: Theme.of(context).textTheme.bodyMedium),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text('Register now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_email, _password, _username, _height, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final h = double.tryParse(_height.text.trim());
    final w = double.tryParse(_weight.text.trim());
    if (_email.text.trim().isEmpty ||
        _password.text.isEmpty ||
        _username.text.trim().isEmpty) {
      setState(() => _error = 'Fill in email, password and username.');
      return;
    }
    if (h == null || w == null || h <= 0 || w <= 0) {
      setState(() => _error = 'Enter your height and weight as numbers.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(authRepositoryProvider).signUp(
            email: _email.text,
            password: _password.text,
            username: _username.text.trim(),
            heightCm: h,
            weightKg: w,
          );
      if (!mounted) return;
      if (res == SignUpResult.confirmEmail) {
        showSnack(context,
            'Check your email to confirm your account, then log in.');
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendly(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.space5),
          children: [
            Text('Register',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppTokens.space5),
            AppTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next),
            const SizedBox(height: AppTokens.space4),
            AppTextField(
                label: 'Password',
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.next),
            const SizedBox(height: AppTokens.space4),
            AppTextField(
                label: 'Username',
                controller: _username,
                textInputAction: TextInputAction.next),
            const SizedBox(height: AppTokens.space4),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                      label: 'Height (cm)',
                      controller: _height,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: AppTextField(
                      label: 'Weight (kg)',
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit()),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTokens.space3),
              ErrorMessage(_error!),
            ],
            const SizedBox(height: AppTokens.space4),
            PrimaryButton(
                label: 'Create account',
                onPressed: _submit,
                loading: _loading),
          ],
        ),
      ),
    );
  }
}
