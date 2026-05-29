import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import 'app_surface.dart';

/// Thin semantic wrapper over [AppSurface] for standard card content.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.md),
    this.margin,
    this.onTap,
    this.elevation = AppDimensions.elevationNone,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double elevation;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: padding,
      margin: margin,
      onTap: onTap,
      elevation: elevation,
      borderColor: borderColor,
      child: child,
    );
  }
}
