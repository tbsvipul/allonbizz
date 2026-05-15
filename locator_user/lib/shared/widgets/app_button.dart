import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger, icon }

/// Universal App Button for standardized UI interactions.
class AppButton extends StatelessWidget {
  const AppButton._({
    required this.variant,
    this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
  });

  final AppButtonVariant variant;
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double? width;

  const factory AppButton.primary({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isDisabled,
    double? width,
  }) = _AppButtonPrimary;

  const factory AppButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isDisabled,
    double? width,
  }) = _AppButtonSecondary;

  const factory AppButton.outlined({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isDisabled,
    double? width,
  }) = _AppButtonOutlined;

  const factory AppButton.text({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isDisabled,
    double? width,
  }) = _AppButtonText;

  const factory AppButton.danger({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading,
    bool isDisabled,
    double? width,
  }) = _AppButtonDanger;

  const factory AppButton.icon({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading,
    bool isDisabled,
    double? width,
  }) = _AppButtonIcon;

  @override
  Widget build(BuildContext context) {
    if (variant == AppButtonVariant.icon && icon != null) {
      return IconButton(
        onPressed: (isDisabled || isLoading) ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        color: Theme.of(context).colorScheme.primary,
      );
    }

    final Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  variant == AppButtonVariant.primary ||
                      variant == AppButtonVariant.danger
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              if (label != null)
                Flexible(child: Text(label!, overflow: TextOverflow.ellipsis)),
            ],
          );

    final ButtonStyle style = _getButtonStyle(context);

    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: variant == AppButtonVariant.outlined
          ? OutlinedButton(
              onPressed: (isDisabled || isLoading) ? null : onPressed,
              style: style,
              child: child,
            )
          : variant == AppButtonVariant.text
          ? TextButton(
              onPressed: (isDisabled || isLoading) ? null : onPressed,
              style: style,
              child: child,
            )
          : ElevatedButton(
              onPressed: (isDisabled || isLoading) ? null : onPressed,
              style: style,
              child: child,
            ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          textStyle: textStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          elevation: 0,
          textStyle: textStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        );
      case AppButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          elevation: 0,
          textStyle: textStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        );
      case AppButtonVariant.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          textStyle: textStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        );
      case AppButtonVariant.text:
        return TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        );
      case AppButtonVariant.icon:
        return TextButton.styleFrom();
    }
  }
}

class _AppButtonPrimary extends AppButton {
  const _AppButtonPrimary({
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
  }) : super._(variant: AppButtonVariant.primary);
}

class _AppButtonSecondary extends AppButton {
  const _AppButtonSecondary({
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
  }) : super._(variant: AppButtonVariant.secondary);
}

class _AppButtonOutlined extends AppButton {
  const _AppButtonOutlined({
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
  }) : super._(variant: AppButtonVariant.outlined);
}

class _AppButtonText extends AppButton {
  const _AppButtonText({
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
  }) : super._(variant: AppButtonVariant.text);
}

class _AppButtonDanger extends AppButton {
  const _AppButtonDanger({
    required super.label,
    required super.onPressed,
    super.icon,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
  }) : super._(variant: AppButtonVariant.danger);
}

class _AppButtonIcon extends AppButton {
  const _AppButtonIcon({
    required super.icon,
    required super.onPressed,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
  }) : super._(variant: AppButtonVariant.icon);
}
