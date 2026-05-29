import 'package:flutter/widgets.dart';

import 'app_dimensions.dart';

/// Reusable edge insets and gap widgets built from [AppDimensions].
abstract final class AppSpacing {
  static const EdgeInsets screenPadding = EdgeInsets.all(AppDimensions.lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(AppDimensions.md);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: AppDimensions.lg,
  );
  static const EdgeInsets dialogPadding = EdgeInsets.all(AppDimensions.xl);
  static const EdgeInsets inputContent = EdgeInsets.symmetric(
    horizontal: AppDimensions.md,
    vertical: AppDimensions.md,
  );

  static const SizedBox gapXs = SizedBox(height: AppDimensions.xs);
  static const SizedBox gapSm = SizedBox(height: AppDimensions.sm);
  static const SizedBox gapMd = SizedBox(height: AppDimensions.md);
  static const SizedBox gapLg = SizedBox(height: AppDimensions.lg);
  static const SizedBox gapXl = SizedBox(height: AppDimensions.xl);
}
