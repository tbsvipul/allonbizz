import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppSnackbarType { success, error, info, warning }

/// Unified global Snackbar dispatcher avoiding messy ScaffoldMessenger calls directly in UI.
abstract final class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Cannot act reliably without an active Scaffold
    if (!context.mounted) return;

    final scaffold = ScaffoldMessenger.maybeOf(context);
    if (scaffold == null) return;

    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(type), color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: _getColor(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        elevation: 6,
        duration: duration,
      ),
    );
  }

  static Color _getColor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return AppColors.success;
      case AppSnackbarType.error:
        return AppColors.error;
      case AppSnackbarType.info:
        return AppColors.grey800;
      case AppSnackbarType.warning:
        return AppColors.warning;
    }
  }

  static IconData _getIcon(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle_rounded;
      case AppSnackbarType.error:
        return Icons.error_rounded;
      case AppSnackbarType.info:
        return Icons.info_rounded;
      case AppSnackbarType.warning:
        return Icons.warning_rounded;
    }
  }
}
