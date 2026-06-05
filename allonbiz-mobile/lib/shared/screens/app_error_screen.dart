import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_glass.dart';

class AppErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppErrorScreen({
    super.key,
    this.title = 'Oops!',
    this.message = 'Something went wrong while processing your request.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        safeArea: true,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: GlassmorphicContainer(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 64,
                  ),
                ),
                const SizedBox(height: AppDimensions.xxl),
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.md),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.xxxl),
                if (onRetry != null)
                  AppButton.primary(
                    label: 'Try Again',
                    onPressed: onRetry!,
                    icon: Icons.refresh_rounded,
                  )
                else
                  AppButton.secondary(
                    label: 'Go Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icons.arrow_back_rounded,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
