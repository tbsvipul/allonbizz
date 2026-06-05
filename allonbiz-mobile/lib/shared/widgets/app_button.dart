import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger, icon }

/// Universal premium app button for standardized UI interactions.
class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled =>
      !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    if (widget.variant == AppButtonVariant.icon) {
      return _buildIconButton(context);
    }

    if (widget.variant == AppButtonVariant.text) {
      return SizedBox(
        width: widget.width,
        height: 48,
        child: TextButton(
          onPressed: _enabled ? widget.onPressed : null,
          style: _buttonStyle(context),
          child: _buildChild(context),
        ),
      );
    }

    if (widget.variant == AppButtonVariant.outlined) {
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: AppDimensions.xxxl + AppDimensions.xs,
        child: OutlinedButton(
          onPressed: _enabled ? widget.onPressed : null,
          style: _buttonStyle(context),
          child: _buildChild(context),
        ),
      );
    }

    return _buildGradientButton(context);
  }

  Widget _buildGradientButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppDimensions.radiusLg);
    final isDanger = widget.variant == AppButtonVariant.danger;
    final gradient = isDanger
        ? LinearGradient(
            colors: [
              colorScheme.error,
              colorScheme.error.withValues(alpha: 0.78),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : widget.variant == AppButtonVariant.secondary
        ? AppColors.dealGradient
        : AppColors.primaryGradient;

    return Semantics(
      button: true,
      enabled: _enabled,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            scale: _pressed ? 0.985 : 1,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _enabled ? 1 : 0.54,
              child: Container(
                width: widget.width ?? double.infinity,
                height: AppDimensions.xxxl + AppDimensions.xs,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: radius,
                  boxShadow: _enabled
                      ? AppColors.glow(
                          isDanger ? colorScheme.error : colorScheme.primary,
                        )
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: radius,
                  child: InkWell(
                    onTap: _enabled ? widget.onPressed : null,
                    borderRadius: radius,
                    child: Center(
                      child: _buildChild(context, forceLight: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppDimensions.radiusLg);

    return AnimatedScale(
      duration: const Duration(milliseconds: 130),
      scale: _pressed ? 0.94 : 1,
      child: Container(
        width: widget.width ?? 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.78),
          borderRadius: radius,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.75),
          ),
          boxShadow: AppColors.softShadow(colorScheme.primary),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: _enabled ? widget.onPressed : null,
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: _enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
            borderRadius: radius,
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(widget.icon, color: colorScheme.primary, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(BuildContext context, {bool forceLight = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = forceLight ? AppColors.white : colorScheme.primary;
    final foreground =
        widget.variant == AppButtonVariant.secondary && forceLight
        ? AppColors.ink
        : textColor;

    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: foreground),
          const SizedBox(width: AppDimensions.xs),
        ],
        if (widget.label != null)
          Flexible(
            child: Text(
              widget.label!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  ButtonStyle _buttonStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800);

    switch (widget.variant) {
      case AppButtonVariant.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.55)),
          textStyle: textStyle,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        );
      case AppButtonVariant.text:
        return TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textStyle,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        );
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
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
