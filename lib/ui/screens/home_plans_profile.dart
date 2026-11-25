/// Home, Plans and Profile tabs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'workout_screen.dart';

void openWorkout(BuildContext context, Plan plan) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => WorkoutScreen(plan: plan)));

String _fmtDate(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final logs = ref.watch(recentLogsProvider);
    final saved = ref.watch(savedPlansProvider);
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(recentLogsProvider);
          ref.invalidate(savedPlansProvider);
          await ref.read(savedPlansProvider.future).catchError((_) => <Plan>[]);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.space4),
          children: [
            Text('WELCOME BACK', style: text.bodyMedium),
            Text(profile.value?.username ?? '', style: text.headlineMedium),
            const SectionTitle('Recent Activity'),
            AsyncBody<List<WorkoutLog>>(
              value: logs,
              onRetry: () => ref.invalidate(recentLogsProvider),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'No activity yet. Finish a workout to see it here.',
              builder: (items) => Column(
                children: [
                  for (final l in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.fitness_center,
                          color: AppTokens.primary),
                      title:
                          Text(l.exerciseName, style: text.bodyLarge),
                      subtitle: Text(
                          '${l.totalSetsDone} sets · ${l.totalRepsDone} reps · ${_fmtDate(l.loggedAt)}',
                          style: text.bodySmall),
                    ),
                ],
              ),
            ),
            const SectionTitle('Saved Plans'),
            AsyncBody<List<Plan>>(
              value: saved,
              onRetry: () => ref.invalidate(savedPlansProvider),
              isEmpty: (d) => d.isEmpty,
              emptyMessage:
                  'No saved plans yet. Tap the bookmark on a plan in Plans.',
              builder: (items) => Column(
                children: [
                  for (final p in items)
                    PlanCard(plan: p, onTap: () => openWorkout(context, p)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});
  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  Category? _category;

  Future<void> _save(Plan p) async {
    try {
      await ref.read(planRepositoryProvider).savePlan(p.id);
      ref.invalidate(savedPlansProvider);
      if (mounted) showSnack(context, 'Saved "${p.title}"');
    } catch (e) {
      if (mounted) showSnack(context, friendly(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider(_category));
    final savedIds =
        (ref.watch(savedPlansProvider).value ?? const <Plan>[])
            .map((p) => p.id)
            .toSet();
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.space4, AppTokens.space4, AppTokens.space4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plans', style: text.headlineMedium),
                const SizedBox(height: AppTokens.space1),
                Text('Tap any routine to start tracking your sets.',
                    style: text.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          SizedBox(
            height: AppTokens.minTap,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
              children: [
                CategoryChip(
                    label: 'All',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null)),
                for (final c in Category.values)
                  CategoryChip(
                      label: c.label,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c)),
              ],
            ),
          ),
          Expanded(
            child: AsyncBody<List<Plan>>(
              value: plans,
              onRetry: () => ref.invalidate(plansProvider(_category)),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'No plans in this category yet.',
              builder: (items) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(plansProvider(_category));
                  await ref
                      .read(plansProvider(_category).future)
                      .catchError((_) => <Plan>[]);
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  children: [
                    for (final p in items)
                      PlanCard(
                        plan: p,
                        saved: savedIds.contains(p.id),
                        onSave: () => _save(p),
                        onTap: () => openWorkout(context, p),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          Text('Profile', style: text.headlineMedium),
          const SizedBox(height: AppTokens.space4),
          AsyncBody<AppUser?>(
            value: profile,
            onRetry: () => ref.invalidate(profileProvider),
            isEmpty: (u) => u == null,
            emptyMessage: 'Profile not found.',
            builder: (u) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(u!.username, style: text.titleLarge),
                  subtitle:
                      Text('Joined ${_fmtDate(u.createdAt)}', style: text.bodySmall),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.height),
                  title: Text('${u.heightCm.toStringAsFixed(0)} cm',
                      style: text.bodyLarge),
                  subtitle: Text('Height', style: text.bodySmall),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text('${u.weightKg.toStringAsFixed(1)} kg',
                      style: text.bodyLarge),
                  subtitle: Text('Weight', style: text.bodySmall),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          PrimaryButton(
            label: 'Sign out',
            icon: Icons.logout,
            onPressed: () async {
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (e) {
                if (context.mounted) showSnack(context, friendly(e));
              }
            },
          ),
        ],
      ),
    );
  }
}
