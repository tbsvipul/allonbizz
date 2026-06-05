import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import 'app_glass.dart';

/// A reusable section header with title, optional icon, and optional action.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.onActionPressed,
    this.actionLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.xs),
              child: PremiumIconBadge(
                icon: icon!,
                color: iconColor ?? colorScheme.primary,
                size: 38,
                iconSize: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          if (onActionPressed != null && actionLabel != null)
            TextButton(
              onPressed: onActionPressed,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: colorScheme.primary,
              ),
              child: Text(
                actionLabel!,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
