import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A standardized card container with consistent shadows and interaction states.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 4,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackRadius = BorderRadius.circular(AppDimensions.radiusLg);

    final surfaceColor =
        backgroundColor ?? (isDark ? AppColors.cardDark : AppColors.white);
    final borderCol =
        borderColor ?? (isDark ? AppColors.grey800 : AppColors.grey100);

    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: borderRadius ?? fallbackRadius,
        border: Border.all(color: borderCol),
        boxShadow: isDark || elevation == 0
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 1.5),
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? fallbackRadius,
          child: content,
        ),
      );
    }

    return margin != null ? Padding(padding: margin!, child: content) : content;
  }
}
