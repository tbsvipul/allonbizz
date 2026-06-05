import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_glass.dart';

class CatTileWidget extends StatelessWidget {
  const CatTileWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tileWidth = (MediaQuery.sizeOf(context).width * 0.62)
        .clamp(220.0, 280.0)
        .toDouble();

    return Semantics(
      label: label,
      button: true,
      child: GlassmorphicContainer(
        onTap: onTap,
        width: tileWidth,
        padding: const EdgeInsets.all(AppDimensions.md),
        borderRadius: BorderRadius.circular(22),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.xs),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    AppColors.secondary.withValues(alpha: 0.10),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, color: color, size: AppDimensions.iconMd),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
