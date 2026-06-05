import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';
import 'app_glass.dart';

/// Clean and generic widget for missing data screens (lists, tabs, etc).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.imagePath,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? imagePath;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: GlassmorphicContainer(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath != null)
                Image.asset(imagePath!, height: 160)
              else
                Container(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentLight, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: AppColors.glow(AppColors.accent),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 24,
                    color: AppColors.white,
                  ),
                ),
              const SizedBox(height: AppDimensions.md),
              Icon(icon, size: 56, color: colorScheme.primary),
              const SizedBox(height: AppDimensions.lg),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppDimensions.xl),
                AppButton.primary(
                  label: actionLabel!,
                  onPressed: onAction,
                  width: 220,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
