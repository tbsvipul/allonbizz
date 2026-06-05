import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A standardized premium card container with soft depth and press feedback.
class AppSurface extends StatefulWidget {
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
    this.gradient,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;
  final Gradient? gradient;
  final Clip clipBehavior;

  @override
  State<AppSurface> createState() => _AppSurfaceState();
}

class _AppSurfaceState extends State<AppSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final fallbackRadius = BorderRadius.circular(AppDimensions.radiusLg);
    final radius = widget.borderRadius ?? fallbackRadius;

    final surfaceColor =
        widget.backgroundColor ??
        (isDark
            ? AppColors.surfaceElevatedDark
            : AppColors.surfaceElevatedLight);
    final borderCol =
        widget.borderColor ??
        (isDark ? AppColors.outlineDark : AppColors.outlineLight);

    final content = AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.985 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: widget.padding,
        clipBehavior: widget.clipBehavior,
        decoration: BoxDecoration(
          color: widget.gradient == null ? surfaceColor : null,
          gradient: widget.gradient,
          borderRadius: radius,
          border: Border.all(color: borderCol.withValues(alpha: 0.85)),
          boxShadow: isDark || widget.elevation == 0
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.18),
                    blurRadius: widget.elevation * 3,
                    offset: Offset(0, widget.elevation),
                  ),
                ]
              : AppColors.softShadow(colorScheme.primary),
        ),
        child: widget.child,
      ),
    );

    final wrapped = widget.onTap == null
        ? content
        : MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: radius,
                  child: content,
                ),
              ),
            ),
          );

    return widget.margin == null
        ? wrapped
        : Padding(padding: widget.margin!, child: wrapped);
  }
}
