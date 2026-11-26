library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import 'create_screen.dart';
import 'desktop_workspace.dart';
import 'home_plans_profile.dart';
import 'pace_plan_widgets.dart';
import 'plan_detail.dart';
import 'profile_settings.dart' show SettingsScreen;

/// Bottom navigation: Home, Discover, Create, Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _query = ValueNotifier('');
  final _librarySection = ValueNotifier(LibrarySection.public);
  Plan? _openPlan;
  Plan? _copyingPlan;

  void _select(int index) => setState(() {
    _index = index;
    _openPlan = null;
    _copyingPlan = null;
  });

  void _closeSubpage() => setState(() {
    if (_copyingPlan != null) {
      _copyingPlan = null;
    } else {
      _openPlan = null;
    }
  });

  @override
  void dispose() {
    _query.dispose();
    _librarySection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppTokens.desktop(context)) return _desktop();
    return Scaffold(
      body: IndexedStack(
        index: _index < 4 ? _index : 3,
        children: [
          HomeScreen(onCreate: () => _select(2), onDiscover: () => _select(1)),
          const PlansScreen(),
          const CreateScreen(),
          ProfileScreen(
            onCreate: () => _select(2),
            onDiscover: () => _select(1),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index < 4 ? _index : 3,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.add), label: 'Create'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _desktop() => PopScope(
    canPop: _openPlan == null && _copyingPlan == null,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _closeSubpage();
    },
    child: Scaffold(
      body: Row(
        children: [
          _WorkspaceSidebar(selected: _index, onSelect: _select),
          Expanded(
            child: Column(
              children: [
                _WorkspaceHeader(
                  title: _copyingPlan != null
                      ? 'Copy plan'
                      : _openPlan != null
                      ? 'Plan detail'
                      : _destinations[_index].$1,
                  onSearch: (text) {
                    _query.value = text;
                    _select(1);
                  },
                  onProfile: () => _select(3),
                ),
                Expanded(
                  child: DesktopWorkspaceNavigation(
                    onOpenPlan: (plan) => setState(() => _openPlan = plan),
                    onCopyPlan: (plan) => setState(() => _copyingPlan = plan),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Offstage(
                          offstage: _openPlan != null,
                          child: ExcludeFocus(
                            excluding: _openPlan != null,
                            child: _DesktopTabs(
                              index: _index,
                              onSelect: _select,
                              query: _query,
                              librarySection: _librarySection,
                            ),
                          ),
                        ),
                        if (_copyingPlan case final plan?)
                          CreateScreen(copyFrom: plan, onCancel: _closeSubpage)
                        else if (_openPlan case final plan?)
                          PlanDetailScreen(
                            key: ValueKey(plan.id),
                            plan: plan,
                            onBackToDiscover: () => _select(1),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

const _destinations = [
  ('Home', Icons.home_outlined),
  ('Discover', Icons.search),
  ('Create Plan', Icons.add),
  ('Profile', Icons.person_outline),
  ('My Plans', Icons.description_outlined),
  ('Settings', Icons.settings_outlined),
];

class _DesktopTabs extends StatelessWidget {
  const _DesktopTabs({
    required this.index,
    required this.onSelect,
    required this.query,
    required this.librarySection,
  });
  final int index;
  final ValueChanged<int> onSelect;
  final ValueNotifier<String> query;
  final ValueNotifier<LibrarySection> librarySection;

  void _openLibrary(LibrarySection section) {
    librarySection.value = section;
    onSelect(4);
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: index,
    children: [
      HomeScreen(
        onCreate: () => onSelect(2),
        onDiscover: () => onSelect(1),
        onLibrary: () => _openLibrary(LibrarySection.saved),
      ),
      PlansScreen(desktopQuery: query),
      CreateScreen(
        onViewSavedPlans: () => _openLibrary(LibrarySection.public),
        onCancel: () => onSelect(0),
      ),
      ProfileScreen(
        onCreate: () => onSelect(2),
        onDiscover: () => onSelect(1),
        onLibrary: () => _openLibrary(LibrarySection.public),
        onSavedPlans: () => _openLibrary(LibrarySection.saved),
        onSettings: () => onSelect(5),
      ),
      DesktopLibrary(
        onCreate: () => onSelect(2),
        onDiscover: () => onSelect(1),
        section: librarySection,
      ),
      const SettingsScreen(),
    ],
  );
}

class _WorkspaceSidebar extends ConsumerWidget {
  const _WorkspaceSidebar({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 240,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PACE',
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const PaceLabel('Find your stride'),
                  const SizedBox(height: 20),
                  for (final index in [0, 1, 2, 4, 3, 5])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        selected: selected == index,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 48),
                            backgroundColor: selected == index
                                ? AppTokens.error.withValues(alpha: .14)
                                : Colors.transparent,
                            side: BorderSide(
                              color: selected == index
                                  ? AppTokens.error
                                  : Colors.transparent,
                            ),
                          ),
                          onPressed: () => onSelect(index),
                          child: Row(
                            children: [
                              Icon(_destinations[index].$2, size: 22),
                              const SizedBox(width: 14),
                              Flexible(
                                child: Text(
                                  _destinations[index].$1,
                                  style: text.bodyLarge?.copyWith(
                                    color: selected == index
                                        ? AppTokens.textPrimary
                                        : AppTokens.textSecondary,
                                    fontWeight: selected == index
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (user != null) ...[
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 6),
                      onTap: () => onSelect(3),
                      leading: PaceAvatar(user.username, size: 38),
                      title: Text(
                        user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text('Personal workspace'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends ConsumerWidget {
  const _WorkspaceHeader({
    required this.title,
    required this.onSearch,
    required this.onProfile,
  });
  final String title;
  final ValueChanged<String> onSearch;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider).value?.username;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (MediaQuery.sizeOf(context).width >= 1280) ...[
            SizedBox(
              width: 344,
              child: TextField(
                onSubmitted: onSearch,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search plans',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Notifications'),
                content: const Text('Notifications are unavailable.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            child: const Text('Notifications'),
          ),
          if (name != null)
            TextButton(
              onPressed: onProfile,
              child: Row(
                children: [
                  PaceAvatar(name, size: 34),
                  const SizedBox(width: 8),
                  Text(name),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
