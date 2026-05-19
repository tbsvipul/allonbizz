import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

enum AppDialogVariant { confirm, info, error, custom }

/// Unified global Dialog dispatcher. No standard builder boilerplate required at call site.
abstract final class AppDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String message,
    AppDialogVariant variant = AppDialogVariant.info,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    Widget? customContent,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: variant != AppDialogVariant.error,
      builder: (_) => _AppDialogWidget(
        title: title,
        message: message,
        variant: variant,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        customContent: customContent,
      ),
    );
  }
}

class _AppDialogWidget extends StatelessWidget {
  const _AppDialogWidget({
    required this.title,
    required this.message,
    required this.variant,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.customContent,
  });

  final String title;
  final String message;
  final AppDialogVariant variant;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final Widget? customContent;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (variant) {
      case AppDialogVariant.confirm:
      case AppDialogVariant.custom:
        icon = Icons.help_outline_rounded;
        iconColor = AppColors.primary;
        break;
      case AppDialogVariant.info:
        icon = Icons.info_outline_rounded;
        iconColor = AppColors.grey700;
        break;
      case AppDialogVariant.error:
        icon = Icons.error_outline_rounded;
        iconColor = AppColors.error;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      backgroundColor: AppColors.white,
      elevation: AppDimensions.elevationLg,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimensions.iconXl, color: iconColor),
            const SizedBox(height: AppDimensions.md),
            Text(
              title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey700,
              ),
              textAlign: TextAlign.center,
            ),
            if (customContent != null) ...[
              const SizedBox(height: AppDimensions.lg),
              customContent!,
            ],
            const SizedBox(height: AppDimensions.xl),
            Row(
              children: [
                if (variant == AppDialogVariant.confirm ||
                    cancelLabel != null) ...[
                  Expanded(
                    child: AppButton.outlined(
                      label: cancelLabel ?? 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                ],
                Expanded(
                  child: variant == AppDialogVariant.error
                      ? AppButton.danger(
                          label: confirmLabel ?? 'OK',
                          onPressed: () {
                            if (onConfirm != null) onConfirm!();
                            Navigator.of(context).pop();
                          },
                        )
                      : AppButton.primary(
                          label: confirmLabel ?? 'OK',
                          onPressed: () {
                            if (onConfirm != null) onConfirm!();
                            Navigator.of(context).pop();
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
