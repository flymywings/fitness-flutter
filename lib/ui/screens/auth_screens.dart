/// PACE welcome, sign-in, and account creation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const _accessPadding = EdgeInsets.symmetric(horizontal: AppTokens.space5);

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (AppTokens.desktop(context)) {
      return _DesktopAccess(
        welcome: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Make progress your routine.', style: text.headlineMedium),
            const SizedBox(height: 14),
            Text(
              'Create workout plans, discover community routines, and stay focused through every session.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final feature in const [
              'Build and organize your workouts',
              'Log sets with a live rest timer',
              'Discover plans from your community',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Create account',
              onPressed: () => Navigator.of(context).push(_registerRoute()),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(_loginRoute()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppTokens.actionHeight),
              ),
              child: const Text('Log in'),
            ),
          ],
        ),
      );
    }
    return _AccessPage(
      welcome: true,
      backdrop: 'assets/images/pace-welcome.webp',
      builder: (height) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.space4),
          const _PaceWordmark(size: 126),
          const Text(
            'TRAIN WITH INTENT',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSmall,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: (height - 650).clamp(24.0, 144.0)),
          const _PlanPreview(),
          const SizedBox(height: AppTokens.space4),
          Text('Your next rep.\nYour next level.', style: text.headlineMedium),
          const SizedBox(height: AppTokens.space2),
          Text('Build plans. Train. Share progress.', style: text.bodyMedium),
          const SizedBox(height: AppTokens.space5),
          PrimaryButton(
            label: 'Log in',
            onPressed: () => Navigator.of(context).push(_loginRoute()),
          ),
          const SizedBox(height: AppTokens.space4),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(_registerRoute()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppTokens.actionHeight),
              textStyle: const TextStyle(
                fontFamily: AppTokens.fontFamily,
                fontSize: AppTokens.fontBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Create account'),
          ),
          const SizedBox(height: AppTokens.space4),
        ],
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AuthForm();
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AuthForm(creatingAccount: true);
}

MaterialPageRoute<void> _loginRoute() =>
    MaterialPageRoute(builder: (_) => const LoginScreen());

MaterialPageRoute<void> _registerRoute() =>
    MaterialPageRoute(builder: (_) => const RegisterScreen());

class _AuthForm extends ConsumerStatefulWidget {
  const _AuthForm({this.creatingAccount = false});

  final bool creatingAccount;

  @override
  ConsumerState<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<_AuthForm> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _numberPattern = RegExp(r'[0-9]');
  static const _passwordRule = 'Use 8+ characters, including a number.';

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _validateFields = false;
  String? _error;

  bool get _creatingAccount => widget.creatingAccount;

  String? get _nameError =>
      _creatingAccount && _name.text.trim().isEmpty ? 'Enter your name.' : null;

  String? get _emailError {
    final value = _email.text.trim();
    if (value.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(value)) return 'Enter a valid email address.';
    return null;
  }

  String? get _passwordError {
    final value = _password.text;
    if (value.isEmpty) return 'Enter your password.';
    if (_creatingAccount &&
        (value.runes.length < 8 || !_numberPattern.hasMatch(value))) {
      return _passwordRule;
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fieldChanged(String _) {
    if (_validateFields || _error != null) setState(() => _error = null);
  }

  Future<void> _submit() async {
    if (_loading) return;
    final valid =
        _nameError == null && _emailError == null && _passwordError == null;
    setState(() {
      _validateFields = true;
      _loading = valid;
      _error = null;
    });
    if (!valid) return;

    FocusScope.of(context).unfocus();
    try {
      final auth = ref.read(authRepositoryProvider);
      final email = _email.text.trim();
      final password = _password.text;
      if (_creatingAccount) {
        final result = await auth.signUp(
          email: email,
          password: password,
          username: _name.text.trim(),
        );
        if (!mounted) return;
        if (result == SignUpResult.confirmEmail) {
          TextInput.finishAutofillContext();
          showSnack(
            context,
            'Check your email to confirm your account, then log in.',
          );
          Navigator.of(context).pushReplacement(_loginRoute());
          return;
        }
      } else {
        await auth.signIn(email: email, password: password);
        if (!mounted) return;
      }
      // The workspace can load before Supabase finishes creating the profile.
      ref.invalidate(profileProvider);
      TextInput.finishAutofillContext();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendly(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final desktop = AppTokens.desktop(context);
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: _AccessPage(
        backdrop: _creatingAccount
            ? 'assets/images/pace-register.webp'
            : 'assets/images/pace-login.webp',
        builder: (_) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!desktop) ...[
                  const SizedBox(height: AppTokens.space4),
                  const Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: _PaceWordmark(size: 88),
                      ),
                      Positioned(left: 0, top: 6, child: BackButton()),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space4),
                ],
                Text(
                  _creatingAccount
                      ? 'Create account'
                      : desktop
                      ? 'Welcome back.'
                      : 'Welcome back',
                  style: text.headlineMedium,
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  _creatingAccount
                      ? 'A stronger routine starts here.'
                      : desktop
                      ? 'Pick up where you left off.'
                      : 'Your next session is waiting.',
                  style: text.bodyMedium,
                ),
                SizedBox(height: desktop ? AppTokens.space4 : AppTokens.space6),
                if (_creatingAccount) ...[
                  AppTextField(
                    label: 'Name',
                    hint: 'Your name',
                    controller: _name,
                    errorText: _validateFields ? _nameError : null,
                    enabled: !_loading,
                    onChanged: _fieldChanged,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                  ),
                  SizedBox(
                    height: desktop ? AppTokens.space3 : AppTokens.space5,
                  ),
                ],
                AppTextField(
                  label: desktop ? 'Email address' : 'Email',
                  hint: 'you@email.com',
                  controller: _email,
                  errorText: _validateFields ? _emailError : null,
                  enabled: !_loading,
                  onChanged: _fieldChanged,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                SizedBox(height: desktop ? AppTokens.space3 : AppTokens.space5),
                AppTextField(
                  label: 'Password',
                  hint: _creatingAccount ? 'At least 8 characters' : null,
                  helperText: _creatingAccount ? _passwordRule : null,
                  controller: _password,
                  errorText: _validateFields ? _passwordError : null,
                  enabled: !_loading,
                  onChanged: _fieldChanged,
                  obscure: !_showPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  autofillHints: [
                    _creatingAccount
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  suffixIcon: IconButton(
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                    onPressed: _loading
                        ? null
                        : () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                if (!_creatingAccount) ...[
                  const SizedBox(height: AppTokens.space2),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () => showSnack(
                              context,
                              'Password reset is unavailable in PACE.',
                            ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: AppTokens.fontSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppTokens.space3),
                  Semantics(liveRegion: true, child: ErrorMessage(_error!)),
                ],
                SizedBox(
                  height: _creatingAccount
                      ? AppTokens.space5
                      : AppTokens.space2,
                ),
                PrimaryButton(
                  label: _creatingAccount ? 'Create account' : 'Log in',
                  onPressed: _submit,
                  loading: _loading,
                  loadingLabel: _creatingAccount
                      ? 'Creating account…'
                      : 'Logging in…',
                ),
                const SizedBox(height: AppTokens.space6),
              ],
            ),
            Column(
              children: [
                Text(
                  _creatingAccount
                      ? 'Already have an account?'
                      : 'New to PACE?',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                          _creatingAccount ? _loginRoute() : _registerRoute(),
                        ),
                  child: Text(
                    _creatingAccount ? 'Log in' : 'Register now',
                    style: const TextStyle(
                      fontSize: AppTokens.fontBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessPage extends StatelessWidget {
  const _AccessPage({
    required this.builder,
    required this.backdrop,
    this.welcome = false,
  });

  final Widget Function(double availableHeight) builder;
  final String backdrop;
  final bool welcome;

  @override
  Widget build(BuildContext context) => AppTokens.desktop(context)
      ? _DesktopAccess(child: builder(MediaQuery.sizeOf(context).height))
      : Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: LayoutBuilder(
                  builder: (context, constraints) => CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PositionedDirectional(
                              top: welcome ? 48 : 0,
                              start: 0,
                              end: 0,
                              height: welcome ? 510 : 235,
                              child: _GymBackdrop(
                                asset: backdrop,
                                welcome: welcome,
                              ),
                            ),
                            Padding(
                              padding: _accessPadding,
                              child: builder(constraints.maxHeight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
}

class _DesktopAccess extends StatelessWidget {
  const _DesktopAccess({required this.child, this.welcome = false});
  final Widget child;
  final bool welcome;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
          children: [
            Row(
              children: [
                Text(
                  'PACE',
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: welcome
                      ? () => Navigator.of(context).push(_loginRoute())
                      : () =>
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                  child: Text(welcome ? 'Log in' : 'Back to welcome'),
                ),
              ],
            ),
            const SizedBox(height: 35),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'BUILT FOR YOUR NEXT CHAPTER',
                        style: text.bodySmall?.copyWith(
                          color: AppTokens.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        welcome
                            ? 'Find your plan.\nBuild your momentum.'
                            : 'Your training.\nAll in one place.',
                        style: text.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Plan with purpose, train with focus, and see how far you can go. Your next stronger day starts here.',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radius),
                        child: Image.asset(
                          'assets/images/pace-training.webp',
                          height: MediaQuery.sizeOf(context).height >= 850
                              ? 344
                              : 252,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -.25),
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          for (final item in const [
                            ('PLAN', 'Routines that fit you'),
                            ('TRAIN', 'Every set accounted for'),
                            ('GROW', 'Progress you can see'),
                          ])
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.$1,
                                    style: text.bodySmall?.copyWith(
                                      color: AppTokens.textPrimary,
                                    ),
                                  ),
                                  Text(item.$2, style: text.bodySmall),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 64),
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: AppTokens.surface,
                      border: Border.all(color: AppTokens.border),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GymBackdrop extends StatelessWidget {
  const _GymBackdrop({required this.asset, required this.welcome});

  final String asset;
  final bool welcome;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Opacity(
        opacity: welcome ? .85 : .48,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: welcome ? Alignment.topCenter : const Alignment(0, .35),
          excludeFromSemantics: true,
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [.3, 1],
            colors: [Colors.transparent, AppTokens.background],
          ),
        ),
      ),
    ],
  );
}

class _PaceWordmark extends StatelessWidget {
  const _PaceWordmark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      'PACE',
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: -size * .06,
      ),
    ),
  );
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TODAY’S PLAN",
              style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTokens.space1),
            Text('Stronger, set by set.', style: text.titleLarge),
            const SizedBox(height: AppTokens.space2),
            const _PlanPreviewSet(number: 1, completed: true),
            const _PlanPreviewSet(number: 2, completed: true),
            const _PlanPreviewSet(number: 3),
          ],
        ),
      ),
    );
  }
}

class _PlanPreviewSet extends StatelessWidget {
  const _PlanPreviewSet({required this.number, this.completed = false});

  final int number;
  final bool completed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: completed ? AppTokens.success : AppTokens.background,
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        child: completed
            ? Icon(
                Icons.check,
                size: 20,
                color: AppTokens.background,
                semanticLabel: 'Set $number complete',
              )
            : Text(
                '$number',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      const SizedBox(width: AppTokens.space4),
      Expanded(
        child: Text(
          completed ? '8 reps × 40 kg' : 'Next set · You’ve got this',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: completed ? AppTokens.textPrimary : AppTokens.textSecondary,
          ),
        ),
      ),
    ],
  );
}
