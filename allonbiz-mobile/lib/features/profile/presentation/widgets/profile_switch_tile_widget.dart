import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/app_glass.dart';

class ProfileSwitchTileWidget extends StatelessWidget {
  const ProfileSwitchTileWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.xs),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs,
        ),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            PremiumIconBadge(icon: icon, size: 42, iconSize: 20),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: colorScheme.primary,
              activeTrackColor: colorScheme.primary.withValues(alpha: 0.32),
            ),
          ],
        ),
      ),
    );
  }
}
