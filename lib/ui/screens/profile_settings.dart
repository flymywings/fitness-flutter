import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/plan_preferences.dart';
import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'desktop_workspace.dart';
import 'pace_plan_widgets.dart';
import 'plan_detail.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.onCreate,
    this.onDiscover,
    this.onLibrary,
    this.onSavedPlans,
    this.onSettings,
  });

  final VoidCallback? onCreate;
  final VoidCallback? onDiscover;
  final VoidCallback? onLibrary;
  final VoidCallback? onSavedPlans;
  final VoidCallback? onSettings;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showPublic = true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final logs = ref.watch(recentLogsProvider);
    final plans = ref.watch(plansProvider(null));
    final saved = ref.watch(savedPlansProvider);
    final userId = ref.watch(authStateProvider).value;
    final text = Theme.of(context).textTheme;
    if (AppTokens.desktop(context)) {
      final activity = logs.value ?? const <WorkoutLog>[];
      final stats = TrainingStats.fromLogs(activity, DateTime.now());
      final myPlans = (plans.value ?? const <Plan>[]).where(
        (p) => p.creatorId == userId,
      );
      final visible = myPlans.where((plan) => plan.isPublic == _showPublic);
      return ListView(
        padding: desktopPadding,
        children: [
          AsyncBody<AppUser?>(
            value: profile,
            onRetry: () => ref.invalidate(profileProvider),
            isEmpty: (user) => user == null,
            emptyMessage: 'Profile not found.',
            builder: (user) => PacePanel(
              outline: true,
              child: Row(
                children: [
                  Expanded(child: _ProfileIdentity(user: user!)),
                  if (widget.onSettings != null)
                    OutlinedButton(
                      onPressed: widget.onSettings,
                      child: const Text('Settings'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          WorkspaceGrid(
            minTileWidth: 200,
            children: [
              WorkspaceStat('${stats.days}', 'Recent training days'),
              WorkspaceStat(
                '${activity.fold(0, (total, log) => total + log.totalSetsDone)}',
                'Sets in recent activity',
              ),
              WorkspaceStat(
                '${stats.streak} ${stats.streak == 1 ? 'day' : 'days'}',
                'Current streak',
                highlight: stats.streak > 0,
              ),
            ],
          ),
          const SizedBox(height: 16),
          WorkspaceColumns(
            main: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('My plans', style: text.titleLarge)),
                    if (widget.onLibrary != null)
                      TextButton(
                        onPressed: widget.onLibrary,
                        child: const Text('Manage plans'),
                      ),
                  ],
                ),
                SizedBox(
                  width: 400,
                  child: PaceSegment<bool>(
                    options: const {true: 'Public', false: 'Private'},
                    selected: _showPublic,
                    onChanged: (value) => setState(() => _showPublic = value),
                  ),
                ),
                const SizedBox(height: 16),
                AsyncBody<List<Plan>>(
                  value: plans,
                  onRetry: () => ref.invalidate(plansProvider(null)),
                  builder: (_) => visible.isEmpty
                      ? PaceEmptyCard(
                          icon: Icons.description_outlined,
                          title:
                              'No ${_showPublic ? 'public' : 'private'} plans yet.',
                          message: 'Your routines and progress will live here.',
                          buttonLabel: 'Create a plan',
                          onAction: widget.onCreate,
                        )
                      : WorkspaceGrid(
                          maxColumns: 2,
                          minTileWidth: 246,
                          children: [
                            for (final plan in visible)
                              CommunityPlanCard(
                                plan: plan,
                                onTap: () => openPlanDetail(
                                  context,
                                  plan,
                                  onBackToDiscover: widget.onDiscover,
                                ),
                                action: OutlinedButton(
                                  onPressed: () => openPlanDetail(
                                    context,
                                    plan,
                                    onBackToDiscover: widget.onDiscover,
                                  ),
                                  child: const Text('View plan'),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
            aside: PacePanel(
              outline: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Saved plans', style: text.titleLarge),
                  const SizedBox(height: 12),
                  AsyncBody<List<Plan>>(
                    value: saved,
                    onRetry: () => ref.invalidate(savedPlansProvider),
                    builder: (items) => items.isEmpty
                        ? Text('No saved plans yet.', style: text.bodyMedium)
                        : Column(
                            children: [
                              for (final plan in items.take(3))
                                _ProfilePlanRow(
                                  plan: plan,
                                  saved: true,
                                  onDiscover: widget.onDiscover,
                                ),
                            ],
                          ),
                  ),
                  if (widget.onSavedPlans != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: widget.onSavedPlans,
                      child: const Text('View saved plans'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: pagePadding,
        children: [
          Row(
            children: [
              Expanded(child: Text('Profile', style: text.headlineMedium)),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AsyncBody<AppUser?>(
            value: profile,
            onRetry: () => ref.invalidate(profileProvider),
            isEmpty: (user) => user == null,
            emptyMessage: 'Profile not found.',
            builder: (user) => _ProfileIdentity(user: user!),
          ),
          const SizedBox(height: 12),
          AsyncBody<List<WorkoutLog>>(
            value: logs,
            onRetry: () => ref.invalidate(recentLogsProvider),
            builder: (items) => _ProfileStats(
              stats: TrainingStats.fromLogs(items, DateTime.now()),
            ),
          ),
          const SizedBox(height: 12),
          Text('My plans', style: text.titleLarge),
          const SizedBox(height: 8),
          PaceSegment<bool>(
            options: const {true: 'Public', false: 'Private'},
            selected: _showPublic,
            onChanged: (value) => setState(() => _showPublic = value),
          ),
          const SizedBox(height: 8),
          AsyncBody<List<Plan>>(
            value: plans,
            onRetry: () => ref.invalidate(plansProvider(null)),
            builder: (items) => _MyPlans(
              plans: [
                for (final plan in items)
                  if (plan.creatorId == userId) plan,
              ],
              showPublic: _showPublic,
              onCreate: widget.onCreate,
              onDiscover: widget.onDiscover,
            ),
          ),
          const SizedBox(height: 12),
          Text('Saved plans', style: text.titleLarge),
          const SizedBox(height: 8),
          AsyncBody<List<Plan>>(
            value: saved,
            onRetry: () => ref.invalidate(savedPlansProvider),
            builder: (items) => items.isEmpty
                ? PacePanel(
                    child: Text('No saved plans yet.', style: text.bodyMedium),
                  )
                : Column(
                    children: [
                      for (final plan in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ProfilePlanRow(
                            plan: plan,
                            saved: true,
                            onDiscover: widget.onDiscover,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = user.username.trim();
    return Row(
      children: [
        PaceAvatar(name, size: 72, square: true),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: text.titleLarge?.copyWith(fontSize: 24)),
              if (RegExp(r'^@?[\w.]+$').hasMatch(name)) ...[
                const SizedBox(height: 4),
                Text(planHandle(name), style: text.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.stats});
  final TrainingStats stats;

  @override
  Widget build(BuildContext context) => PacePanel(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ProfileStat(value: stats.days, label: 'recent training days'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ProfileStat(
            value: stats.streak,
            label: 'day streak',
            color: AppTokens.success,
          ),
        ),
      ],
    ),
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label, this.color});
  final int value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('$value', style: text.headlineMedium?.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, style: text.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

class _MyPlans extends StatelessWidget {
  const _MyPlans({
    required this.plans,
    required this.showPublic,
    this.onCreate,
    this.onDiscover,
  });
  final List<Plan> plans;
  final bool showPublic;
  final VoidCallback? onCreate;
  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context) {
    final visible = plans.where((plan) => plan.isPublic == showPublic);
    if (visible.isEmpty) {
      return PaceEmptyCard(
        icon: Icons.description_outlined,
        title: plans.isEmpty
            ? 'Make your first plan'
            : 'No ${showPublic ? 'public' : 'private'} plans yet',
        message: plans.isEmpty
            ? 'Your routines and progress will live here.'
            : showPublic
            ? 'Plans you publish to Discover appear here.'
            : 'Plans you keep private appear here.',
        buttonLabel: 'Create a plan',
        onAction: onCreate,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final plan in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ProfilePlanRow(plan: plan, onDiscover: onDiscover),
          ),
        if (!showPublic && onCreate != null)
          OutlinedButton(
            onPressed: onCreate,
            child: const Text('Create a plan'),
          ),
      ],
    );
  }
}

class _ProfilePlanRow extends StatelessWidget {
  const _ProfilePlanRow({
    required this.plan,
    this.saved = false,
    this.onDiscover,
  });
  final Plan plan;
  final bool saved;
  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PacePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => openPlanDetail(context, plan, onBackToDiscover: onDiscover),
      child: Row(
        children: [
          Icon(saved ? Icons.bookmark_border : Icons.description_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  saved
                      ? '${planHandle(plan.creatorName)} · ${planDuration(plan)} · ${plan.category.label}'
                      : '${plan.isPublic ? 'Public' : 'Private'} · ${plan.category.label} · ${planDuration(plan)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loggingOut = false;
  bool _savingPrivacy = false;

  Future<void> _signOut() async {
    setState(() => _loggingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) showSnack(context, friendly(error));
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _showInfo(String title, String detail) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePlanPrivacy(bool isPublic, String userId) async {
    final selection = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default plan privacy'),
        children: [
          for (final option in const {true: 'Public', false: 'Private'}.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(option.key),
              child: Row(
                children: [
                  Expanded(child: Text(option.value)),
                  if (option.key == isPublic) const Icon(Icons.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (!mounted || selection == null || selection == isPublic) return;
    setState(() => _savingPrivacy = true);
    try {
      await setDefaultPlanPublic(userId, selection);
      if (mounted) ref.invalidate(defaultPlanPublicProvider);
    } catch (error) {
      if (mounted) showSnack(context, friendly(error));
    } finally {
      if (mounted) setState(() => _savingPrivacy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final auth = ref.watch(authRepositoryProvider);
    final email = auth.currentUserEmail;
    final userId = auth.currentUserId;
    final planPublic = ref.watch(defaultPlanPublicProvider).value;
    final text = Theme.of(context).textTheme;

    if (AppTokens.desktop(context)) {
      return ListView(
        padding: desktopPadding,
        children: [
          Text('Make PACE work for you.', style: text.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Manage your training preferences and account.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          WorkspaceColumns(
            main: PacePanel(
              outline: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Profile details', style: text.titleLarge),
                  const SizedBox(height: 16),
                  Text('Profile name', style: text.bodySmall),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: ValueKey(profile.value?.username),
                    initialValue: profile.value?.username ?? '',
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  Text('Email address', style: text.bodySmall),
                  const SizedBox(height: 6),
                  TextFormField(initialValue: email ?? '', readOnly: true),
                ],
              ),
            ),
            aside: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PacePanel(
                  outline: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Training preferences', style: text.titleLarge),
                      const SizedBox(height: 12),
                      const _SettingsRow(
                        title: 'Weight units',
                        value: 'Kilograms (kg)',
                      ),
                      const _SettingsRow(
                        title: 'Default rest duration',
                        value: '${PlanExercise.defaultRestSeconds} seconds',
                      ),
                      _SettingsRow(
                        title: 'Default plan privacy',
                        value: planPublic == null
                            ? null
                            : planPublic
                            ? 'Public'
                            : 'Private',
                        onTap:
                            planPublic == null ||
                                userId == null ||
                                _savingPrivacy
                            ? null
                            : () => _changePlanPrivacy(planPublic, userId),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PacePanel(
                  outline: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Notifications & privacy', style: text.titleLarge),
                      const SizedBox(height: 8),
                      const _SettingsRow(
                        title: 'Notifications',
                        value: 'Unavailable',
                      ),
                      _SettingsRow(
                        title: 'Privacy & security',
                        onTap: () => _showInfo(
                          'Privacy & security',
                          'Public plans are listed in Discover. You can choose Private when you create a plan.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _loggingOut ? null : _signOut,
                  child: Text(_loggingOut ? 'Logging out…' : 'Log out'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: pagePadding,
          children: [
            PacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    profile.value?.username ?? 'Account',
                    style: text.titleLarge,
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 4),
                    Text(email, style: text.bodyMedium),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const PaceLabel('Preferences'),
            const SizedBox(height: 8),
            const _SettingsRow(title: 'Notifications', value: 'Unavailable'),
            const SizedBox(height: 8),
            _SettingsRow(
              title: 'Default plan privacy',
              value: switch (planPublic) {
                true => 'Public',
                false => 'Private',
                null => null,
              },
              onTap: planPublic == null || userId == null || _savingPrivacy
                  ? null
                  : () => _changePlanPrivacy(planPublic, userId),
            ),
            const SizedBox(height: 8),
            const _SettingsRow(title: 'Weight units', value: 'Kilograms (kg)'),
            const SizedBox(height: 12),
            const PaceLabel('Account & support'),
            const SizedBox(height: 8),
            _SettingsRow(
              title: 'Privacy & security',
              onTap: () => _showInfo(
                'Privacy & security',
                'Public plans are listed in Discover. You can choose Private when you create a plan.',
              ),
            ),
            const SizedBox(height: 8),
            _SettingsRow(
              title: 'Help & feedback',
              onTap: () => _showInfo(
                'Help & feedback',
                'In-app support is currently unavailable.',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loggingOut ? null : _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.error,
                side: const BorderSide(color: AppTokens.error),
                minimumSize: const Size(0, AppTokens.actionHeight),
              ),
              child: Text(_loggingOut ? 'Logging out…' : 'Log out'),
            ),
            const SizedBox(height: 8),
            Text(
              'PACE · Version 1.0',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.title, this.value, this.onTap});
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PacePanel(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(title, style: text.bodyLarge)),
          if (value case final value?) ...[
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Text(
                value,
                style: text.bodySmall,
                textAlign: TextAlign.end,
              ),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ],
      ),
    );
  }
}
