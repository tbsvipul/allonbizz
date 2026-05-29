import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';

/// Shared decoration helpers for commonly repeated containers.
abstract final class AppDecorations {
  static BorderRadius get radiusMd =>
      BorderRadius.circular(AppDimensions.radiusMd);
  static BorderRadius get radiusLg =>
      BorderRadius.circular(AppDimensions.radiusLg);
  static BorderRadius get radiusXl =>
      BorderRadius.circular(AppDimensions.radiusXl);

  static BoxDecoration statusBanner({
    required Color color,
    double alpha = 0.1,
    double radius = AppDimensions.radiusMd,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration tagPill({
    required Color backgroundColor,
    Color? borderColor,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor == null ? null : Border.all(color: borderColor),
    );
  }

  static BoxDecoration mediaHeaderAvatar(Color backgroundColor) {
    return BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static const LinearGradient offerPlaceholderGradient = LinearGradient(
    colors: [Color(0xFFFFF3E0), Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const BoxDecoration pulseDot = BoxDecoration(
    color: Color(0xFF00C853),
    shape: BoxShape.circle,
  );

  static const BoxDecoration emptyCircle = BoxDecoration(
    color: AppColors.grey100,
    shape: BoxShape.circle,
  );
}
