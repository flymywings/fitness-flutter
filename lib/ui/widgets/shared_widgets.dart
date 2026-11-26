/// Reusable widgets. They read only from AppTokens / Theme, never hardcode styles.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../theme/app_theme.dart';

/// Main call-to-action button. Shows a spinner while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.loadingLabel,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: loading
            ? FilledButton.styleFrom(
                disabledBackgroundColor: AppTokens.primaryPressed,
                disabledForegroundColor: AppTokens.onPrimary,
              ).copyWith(
                backgroundColor: const WidgetStatePropertyAll(
                  AppTokens.primaryPressed,
                ),
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTokens.onPrimary,
                ),
              ),
              const SizedBox(width: AppTokens.space2),
            ] else if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: AppTokens.space2),
            ],
            Flexible(
              child: Text(
                loading ? loadingLabel ?? label : label,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled text input.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.suffixIcon,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: AppTokens.space2),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            helperText: helperText,
            errorText: errorText,
            errorMaxLines: 3,
            constraints: const BoxConstraints(
              minHeight: AppTokens.actionHeight,
            ),
          ),
        ),
      ],
    );
  }
}

/// Readable error text (never dark-on-dark).
class ErrorMessage extends StatelessWidget {
  const ErrorMessage(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: AppTokens.error, size: 18),
        const SizedBox(width: AppTokens.space2),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppTokens.error,
              fontSize: AppTokens.fontSmall,
            ),
          ),
        ),
      ],
    );
  }
}

String friendly(Object e) =>
    e is AppException ? e.message : 'Something went wrong. Try again.';

/// Centered empty-state message.
class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppTokens.textSecondary),
            const SizedBox(height: AppTokens.space3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state with a retry button.
class ErrorState extends StatelessWidget {
  const ErrorState(this.error, {super.key, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorMessage(friendly(error)),
            const SizedBox(height: AppTokens.space3),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// Handles loading / error / empty / data for any async provider value.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
    this.isEmpty,
    this.emptyMessage = 'Nothing here yet.',
  });
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppTokens.space5),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorState(e, onRetry: onRetry),
      data: (d) =>
          (isEmpty?.call(d) ?? false) ? EmptyState(emptyMessage) : builder(d),
    );
  }
}

/// Category filter chip.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.space2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(
            horizontal: AppTokens.desktop(context) ? 28 : 18,
          ),
          decoration: BoxDecoration(
            color: selected ? AppTokens.textPrimary : AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: selected ? AppTokens.textPrimary : AppTokens.controlBorder,
            ),
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppTokens.background : AppTokens.textPrimary,
                fontSize: AppTokens.fontSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card for one plan. Optional bookmark button when [onSave] is given.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.saved = false,
    this.onSave,
  });
  final Plan plan;
  final VoidCallback onTap;
  final bool saved;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: Material(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.space4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: AppTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.category.label,
                        style: const TextStyle(
                          color: AppTokens.primary,
                          fontSize: AppTokens.fontSmall,
                        ),
                      ),
                    ),
                    if (!plan.isPublic) ...[
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: AppTokens.textSecondary,
                      ),
                      const SizedBox(width: AppTokens.space1),
                    ],
                    Text(
                      plan.difficulty.db,
                      style: text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (onSave != null)
                      IconButton(
                        tooltip: saved ? 'Saved' : 'Save plan',
                        onPressed: saved ? null : onSave,
                        icon: Icon(
                          saved ? Icons.bookmark : Icons.bookmark_border,
                          color: saved
                              ? AppTokens.primary
                              : AppTokens.textSecondary,
                        ),
                      ),
                  ],
                ),
                Text(plan.title, style: text.titleLarge),
                const SizedBox(height: AppTokens.space1),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppTokens.textSecondary,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Text('${plan.durationWeeks} weeks', style: text.bodySmall),
                  ],
                ),
                const SizedBox(height: AppTokens.space1),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppTokens.textSecondary,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Flexible(
                      child: Text(plan.creatorName, style: text.bodySmall),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle button for one set in the active workout.
class SetToggleButton extends StatelessWidget {
  const SetToggleButton({
    super.key,
    required this.label,
    required this.done,
    required this.onTap,
  });
  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      label: '$label ${done ? 'completed' : 'not completed'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 84,
            minHeight: AppTokens.minTap,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3),
          decoration: BoxDecoration(
            color: done ? AppTokens.primary : AppTokens.surfaceAlt,
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border.all(
              color: done ? AppTokens.primary : AppTokens.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: done ? AppTokens.onPrimary : AppTokens.textSecondary,
              ),
              const SizedBox(width: AppTokens.space2),
              Text(
                label,
                style: const TextStyle(
                  color: AppTokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section heading.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppTokens.space4,
      bottom: AppTokens.space3,
    ),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
