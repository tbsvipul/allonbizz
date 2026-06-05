import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium app background with subtle radial glows and theme-aware gradients.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.padding,
    this.safeArea = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.appBackgroundDark
            : AppColors.appBackgroundLight,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -110,
            right: -90,
            child: _GlowOrb(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              size: 260,
              opacity: isDark ? 0.12 : 0.10,
            ),
          ),
          Positioned(
            left: -130,
            bottom: -120,
            child: _GlowOrb(
              color: AppColors.secondary,
              size: 300,
              opacity: isDark ? 0.12 : 0.16,
            ),
          ),
          safeArea ? SafeArea(child: content) : content,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable glassmorphic container for cards, overlays, sheets, and nav chrome.
class GlassmorphicContainer extends StatelessWidget {
  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 18,
    this.opacity,
    this.borderColor,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
    this.width,
    this.height,
    this.constraints,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double? opacity;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Clip clipBehavior;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius =
        borderRadius ?? BorderRadius.circular(AppDimensions.radiusXl);
    final fill = (isDark ? AppColors.glassDark : AppColors.surfaceElevatedLight)
        .withValues(alpha: opacity ?? (isDark ? 0.84 : 0.94));
    final resolvedBorder =
        borderColor ??
        (isDark
            ? AppColors.outlineDark
            : AppColors.white.withValues(alpha: 0.92));

    final glass = ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            gradient: AppColors.glassHighlight,
            borderRadius: radius,
            border: Border.all(color: resolvedBorder),
            boxShadow: isDark ? null : AppColors.softShadow(AppColors.primary),
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );

    Widget sizedGlass = SizedBox(width: width, height: height, child: glass);
    if (constraints != null) {
      sizedGlass = ConstrainedBox(constraints: constraints!, child: sizedGlass);
    }

    final interactive = onTap == null
        ? sizedGlass
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: sizedGlass,
            ),
          );

    return margin == null
        ? interactive
        : Padding(padding: margin!, child: interactive);
  }
}

class PremiumIconBadge extends StatelessWidget {
  const PremiumIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedColor = color ?? colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            resolvedColor.withValues(alpha: 0.16),
            AppColors.secondary.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: resolvedColor, size: iconSize),
    );
  }
}
