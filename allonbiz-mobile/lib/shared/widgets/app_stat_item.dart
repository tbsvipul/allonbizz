import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A reusable widget for label/value pairs as seen in statistics or details.
class AppStatItem extends StatelessWidget {
  const AppStatItem({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:
              valueStyle ??
              AppTextStyles.titleSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
