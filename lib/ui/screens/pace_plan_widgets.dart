import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const pagePadding = EdgeInsets.fromLTRB(24, 16, 24, 24);

String planDuration(Plan plan) =>
    '${plan.durationWeeks} ${plan.durationWeeks == 1 ? 'week' : 'weeks'}';

String planHandle(String username) =>
    username.startsWith('@') ? username : '@$username';

String workoutCount(int count) =>
    '$count ${count == 1 ? 'workout' : 'workouts'}';

class TrainingStats {
  const TrainingStats._({
    required this.days,
    required this.streak,
    required this.thisWeek,
  });

  factory TrainingStats.fromLogs(List<WorkoutLog> logs, DateTime now) {
    final today = DateUtils.dateOnly(now);
    final firstOfWeek = DateUtils.addDaysToDate(today, 1 - today.weekday);
    final days = {
      for (final log in logs)
        if (log.totalSetsDone > 0) DateUtils.dateOnly(log.loggedAt),
    }..removeWhere((day) => day.isAfter(today));
    var streak = 0;
    var day = days.contains(today) ? today : DateUtils.addDaysToDate(today, -1);
    while (days.contains(day)) {
      streak++;
      day = DateUtils.addDaysToDate(day, -1);
    }
    return TrainingStats._(
      days: days.length,
      streak: streak,
      thisWeek: days.where((day) => !day.isBefore(firstOfWeek)).length,
    );
  }

  final int days;
  final int streak;
  final int thisWeek;
}

class PacePanel extends StatelessWidget {
  const PacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.outline = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool outline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTokens.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      side: outline
          ? const BorderSide(color: AppTokens.border)
          : BorderSide.none,
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class PaceLabel extends StatelessWidget {
  const PaceLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: .2),
  );
}

class PaceSegment<T> extends StatelessWidget {
  const PaceSegment({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => PacePanel(
    outline: true,
    padding: const EdgeInsets.all(5),
    child: Row(
      children: [
        for (final option in options.entries)
          Expanded(
            child: Semantics(
              selected: option.key == selected,
              button: true,
              child: Material(
                color: option.key == selected
                    ? AppTokens.textPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTokens.radius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(option.key),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      option.value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: option.key == selected
                            ? AppTokens.background
                            : AppTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class PaceAvatar extends StatelessWidget {
  const PaceAvatar(this.name, {super.key, this.size = 40, this.square = false});

  final String name;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .replaceFirst(RegExp(r'^@'), '')
        .split(RegExp(r'\s+'));
    final initials = [
      for (final word in words.take(2))
        if (word.isNotEmpty) word.characters.first.toUpperCase(),
    ].join();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surfaceAlt,
          border: Border.all(color: AppTokens.border),
          borderRadius: BorderRadius.circular(square ? 16 : size / 2),
        ),
        child: initials.isEmpty
            ? const Icon(Icons.person_outline)
            : Text(
                initials,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: size * .38),
              ),
      ),
    );
  }
}

class TrainingArt extends StatelessWidget {
  const TrainingArt({
    super.key,
    required this.iconSize,
    this.asset = 'assets/images/pace-training.webp',
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final double iconSize;
  final String asset;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: double.infinity,
    height: double.infinity,
    fit: fit,
    alignment: alignment,
    excludeFromSemantics: true,
    errorBuilder: (context, error, stackTrace) => ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(.55, -.28),
            radius: 1.15,
            colors: [AppTokens.border, AppTokens.surface, AppTokens.background],
          ),
        ),
        child: Center(
          child: Transform.rotate(
            angle: -.32,
            child: Icon(
              Icons.fitness_center_outlined,
              size: iconSize,
              color: AppTokens.textSecondary.withValues(alpha: .36),
            ),
          ),
        ),
      ),
    ),
  );
}

class PaceEmptyCard extends StatelessWidget {
  const PaceEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PacePanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, color: AppTokens.textSecondary),
          const SizedBox(height: 12),
          Text(title, style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
          if (onAction != null) ...[
            const SizedBox(height: 16),
            PrimaryButton(label: buttonLabel, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class CommunityPlanCard extends StatelessWidget {
  const CommunityPlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.showDate = false,
    this.action,
  });

  final Plan plan;
  final VoidCallback? onTap;
  final bool showDate;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final date = MaterialLocalizations.of(context)
        .formatShortDate(plan.createdAt);
    final count = plan.saveCount;
    final author = planHandle(plan.creatorName);
    return PacePanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.title, style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${plan.category.label} · ${plan.difficulty.label} · ${planDuration(plan)}',
            style: text.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              PaceAvatar(plan.creatorName),
              const SizedBox(width: 8),
              Expanded(child: Text(showDate ? '$author · $date' : author)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (count != null) ...[
                const Icon(
                  Icons.bookmark_border,
                  color: AppTokens.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$count ${count == 1 ? 'save' : 'saves'}',
                    style: text.bodySmall,
                  ),
                ),
              ] else
                const Spacer(),
              SizedBox(width: 105, child: action ?? PlanSaveButton(plan: plan)),
            ],
          ),
        ],
      ),
    );
  }
}

class PlanSaveButton extends ConsumerStatefulWidget {
  const PlanSaveButton({super.key, required this.plan});

  final Plan plan;

  @override
  ConsumerState<PlanSaveButton> createState() => _PlanSaveButtonState();
}

class _PlanSaveButtonState extends ConsumerState<PlanSaveButton> {
  bool _saving = false;

  Future<void> _toggle(bool saved) async {
    setState(() => _saving = true);
    final repository = ref.read(planRepositoryProvider);
    try {
      if (saved) {
        await repository.unsavePlan(widget.plan.id);
      } else {
        await repository.savePlan(widget.plan.id);
      }
      if (!mounted) return;
      ref.invalidate(savedPlansProvider);
      ref.invalidate(plansProvider);
      if (saved) {
        showSnack(context, 'Plan removed from your library');
      } else {
        showPaceSuccess(context, 'Plan saved to your library');
      }
    } catch (error) {
      if (mounted) showSnack(context, friendly(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedPlans = ref.watch(savedPlansProvider);
    final saved =
        savedPlans.value?.any((plan) => plan.id == widget.plan.id) ?? false;
    final canSave = !_saving && savedPlans.asData != null;
    return OutlinedButton(
      onPressed: canSave ? () => _toggle(saved) : null,
      child: _saving
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(saved ? 'Saved' : 'Save'),
    );
  }
}

void showPaceSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          side: const BorderSide(color: AppTokens.success),
        ),
        content: Row(
          children: [
            const Icon(Icons.check, color: AppTokens.success),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: AppTokens.success),
              ),
            ),
          ],
        ),
      ),
    );
}
