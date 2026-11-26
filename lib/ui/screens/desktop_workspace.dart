import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'pace_plan_widgets.dart';
import 'plan_detail.dart';

const desktopPadding = EdgeInsets.fromLTRB(32, 28, 32, 32);
const desktopGap = 24.0;

class DesktopWorkspaceNavigation extends InheritedWidget {
  const DesktopWorkspaceNavigation({
    super.key,
    required super.child,
    required this.onOpenPlan,
    required this.onCopyPlan,
  });

  final ValueChanged<Plan> onOpenPlan;
  final ValueChanged<Plan> onCopyPlan;

  static DesktopWorkspaceNavigation? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DesktopWorkspaceNavigation>();

  @override
  bool updateShouldNotify(DesktopWorkspaceNavigation oldWidget) => false;
}

class WorkspaceGrid extends StatelessWidget {
  const WorkspaceGrid({
    super.key,
    required this.children,
    this.maxColumns = 3,
    this.minTileWidth = 280,
  });

  final List<Widget> children;
  final int maxColumns;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          ((constraints.maxWidth + desktopGap) / (minTileWidth + desktopGap))
              .floor()
              .clamp(1, maxColumns);
      final width =
          (constraints.maxWidth - desktopGap * (columns - 1)) / columns;
      return Wrap(
        spacing: desktopGap,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class WorkspaceColumns extends StatelessWidget {
  const WorkspaceColumns({super.key, required this.main, required this.aside});
  final Widget main;
  final Widget aside;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 680) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            main,
            const SizedBox(height: desktopGap),
            aside,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: main),
          const SizedBox(width: desktopGap),
          Expanded(child: aside),
        ],
      );
    },
  );
}

class WorkspaceStat extends StatelessWidget {
  const WorkspaceStat(
    this.value,
    this.label, {
    super.key,
    this.highlight = false,
  });
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PacePanel(
      outline: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            value,
            style: text.headlineMedium?.copyWith(
              color: highlight ? AppTokens.success : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: text.bodySmall),
        ],
      ),
    );
  }
}

enum LibrarySection { public, private, saved }

class DesktopLibrary extends ConsumerWidget {
  const DesktopLibrary({
    super.key,
    required this.onCreate,
    required this.onDiscover,
    required this.section,
  });
  final VoidCallback onCreate;
  final VoidCallback onDiscover;
  final ValueNotifier<LibrarySection> section;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ValueListenableBuilder(
    valueListenable: section,
    builder: (context, selected, _) => _library(context, ref, selected),
  );

  Widget _library(
    BuildContext context,
    WidgetRef ref,
    LibrarySection selectedSection,
  ) {
    final all = ref.watch(plansProvider(null));
    final saved = ref.watch(savedPlansProvider);
    final user = ref.watch(authStateProvider).value;
    final mine = (all.value ?? const <Plan>[]).where(
      (p) => p.creatorId == user,
    );
    final public = mine.where((p) => p.isPublic).toList();
    final private = mine.where((p) => !p.isPublic).toList();
    final plans = switch (selectedSection) {
      LibrarySection.public => public,
      LibrarySection.private => private,
      LibrarySection.saved => saved.value ?? const <Plan>[],
    };
    final selectedSource = selectedSection == LibrarySection.saved
        ? saved
        : all;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: desktopPadding,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your training library.', style: text.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Plans you created and routines worth coming back to.',
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 176,
              child: PrimaryButton(
                label: 'Create plan',
                icon: Icons.add,
                onPressed: onCreate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: PaceSegment<LibrarySection>(
              options: {
                LibrarySection.public: 'Public · ${public.length}',
                LibrarySection.private: 'Private · ${private.length}',
                LibrarySection.saved: 'Saved · ${saved.value?.length ?? 0}',
              },
              selected: selectedSection,
              onChanged: (value) => section.value = value,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AsyncBody<List<Plan>>(
          value: selectedSource,
          onRetry: () {
            if (selectedSection == LibrarySection.saved) {
              ref.invalidate(savedPlansProvider);
            } else {
              ref.invalidate(plansProvider(null));
            }
          },
          builder: (_) => plans.isEmpty
              ? PaceEmptyCard(
                  icon: Icons.bookmark_border,
                  title: 'No ${selectedSection.name} plans yet',
                  message: selectedSection == LibrarySection.saved
                      ? 'Save community plans from Discover to see them here.'
                      : 'Create a plan to start building your library.',
                  buttonLabel: selectedSection == LibrarySection.saved
                      ? 'Discover plans'
                      : 'Create a plan',
                  onAction: selectedSection == LibrarySection.saved
                      ? onDiscover
                      : onCreate,
                )
              : WorkspaceGrid(
                  maxColumns: 2,
                  children: [
                    for (final plan in plans)
                      CommunityPlanCard(
                        plan: plan,
                        onTap: () => openPlanDetail(
                          context,
                          plan,
                          onBackToDiscover: onDiscover,
                        ),
                        action: selectedSection == LibrarySection.saved
                            ? null
                            : OutlinedButton(
                                onPressed: () => openPlanDetail(
                                  context,
                                  plan,
                                  onBackToDiscover: onDiscover,
                                ),
                                child: const Text('View plan'),
                              ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        PacePanel(
          outline: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedSection == LibrarySection.private
                    ? 'Private plans'
                    : 'Shared with the community',
                style: text.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                selectedSection == LibrarySection.private
                    ? 'Keep drafts in your library while you refine them.'
                    : 'Public plans appear in Discover and can be saved by other users.',
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
