import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_decorations.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

enum AppStatusBannerVariant { info, success, warning, error }

/// Shared compact banner for inline status and form feedback.
class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    super.key,
    required this.message,
    this.variant = AppStatusBannerVariant.info,
    this.icon,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.textStyle,
  });

  final String message;
  final AppStatusBannerVariant variant;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;

  Color get _color {
    switch (variant) {
      case AppStatusBannerVariant.success:
        return AppColors.success;
      case AppStatusBannerVariant.warning:
        return AppColors.warning;
      case AppStatusBannerVariant.error:
        return AppColors.error;
      case AppStatusBannerVariant.info:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (variant) {
      case AppStatusBannerVariant.success:
        return Icons.check_circle_outline_rounded;
      case AppStatusBannerVariant.warning:
        return Icons.warning_amber_rounded;
      case AppStatusBannerVariant.error:
        return Icons.error_outline_rounded;
      case AppStatusBannerVariant.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Container(
      padding: padding,
      decoration: AppDecorations.statusBanner(
        color: _color,
        radius: AppDimensions.radiusLg,
      ).copyWith(boxShadow: AppColors.glow(_color)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? _icon, color: _color, size: 20),
          const SizedBox(width: AppDimensions.xs),
          Expanded(
            child: Text(
              message,
              style:
                  textStyle?.copyWith(color: _color) ??
                  AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );

    if (margin == null) {
      return content;
    }

    return Padding(padding: margin!, child: content);
  }
}
