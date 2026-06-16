import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum AppTextFieldVariant { regular, password, search, multiline }

/// Universal standard text field with premium focus animation.
class AppTextField extends StatefulWidget {
  const AppTextField._({
    required this.variant,
    required this.controller,
    this.label,
    this.hint,
    this.focusNode,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
  });

  final AppTextFieldVariant variant;
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool readOnly;

  const factory AppTextField.regular({
    required TextEditingController controller,
    String? label,
    String? hint,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool readOnly,
  }) = _AppTextFieldRegular;

  const factory AppTextField.password({
    required TextEditingController controller,
    String? label,
    String? hint,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    TextInputAction? textInputAction,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) = _AppTextFieldPassword;

  const factory AppTextField.search({
    required TextEditingController controller,
    String? hint,
    FocusNode? focusNode,
    Widget? suffixIcon,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) = _AppTextFieldSearch;

  const factory AppTextField.multiline({
    required TextEditingController controller,
    String? label,
    String? hint,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool readOnly,
  }) = _AppTextFieldMultiline;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _internalFocusNode;
  bool _obscureText = true;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFocus = oldWidget.focusNode ?? _internalFocusNode;
    final newFocus = widget.focusNode ?? _internalFocusNode;
    if (oldFocus != newFocus) {
      oldFocus.removeListener(_handleFocusChanged);
      newFocus.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.variant == AppTextFieldVariant.password;
    final isSearch = widget.variant == AppTextFieldVariant.search;
    final isMultiline = widget.variant == AppTextFieldVariant.multiline;
    final hasFocus = _effectiveFocusNode.hasFocus;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && !isSearch) ...[
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: textTheme.labelMedium!.copyWith(
              color: hasFocus
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
            child: Text(widget.label!),
          ),
          const SizedBox(height: AppDimensions.xs),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              isSearch ? AppDimensions.radiusXl : AppDimensions.radiusLg,
            ),
            boxShadow: hasFocus
                ? AppColors.glow(
                    isSearch ? AppColors.secondary : colorScheme.primary,
                  )
                : [
                    BoxShadow(
                      color: AppColors.black.withValues(
                        alpha: isDark ? 0.16 : 0.035,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _effectiveFocusNode,
            obscureText: isPassword && _obscureText,
            keyboardType: isMultiline
                ? TextInputType.multiline
                : (widget.keyboardType ??
                      (isPassword
                          ? TextInputType.visiblePassword
                          : TextInputType.text)),
            textInputAction: isMultiline
                ? TextInputAction.newline
                : (widget.textInputAction ?? TextInputAction.next),
            maxLines: isMultiline ? 4 : 1,
            readOnly: widget.readOnly,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.58),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: isSearch
                  ? Icon(Icons.search_rounded, color: colorScheme.primary)
                  : widget.prefixIcon,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    )
                  : widget.suffixIcon,
              filled: true,
              fillColor: isSearch
                  ? (isDark
                        ? AppColors.glassDark
                        : AppColors.white.withValues(alpha: 0.88))
                  : (isDark
                        ? AppColors.surfaceElevatedDark.withValues(alpha: 0.86)
                        : AppColors.white.withValues(alpha: 0.92)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isSearch ? AppDimensions.radiusXl : AppDimensions.radiusLg,
                ),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isSearch ? AppDimensions.radiusXl : AppDimensions.radiusLg,
                ),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isSearch ? AppDimensions.radiusXl : AppDimensions.radiusLg,
                ),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isSearch ? AppDimensions.radiusXl : AppDimensions.radiusLg,
                ),
                borderSide: BorderSide(color: colorScheme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isSearch ? AppDimensions.radiusXl : AppDimensions.radiusLg,
                ),
                borderSide: BorderSide(color: colorScheme.error, width: 1.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppTextFieldRegular extends AppTextField {
  const _AppTextFieldRegular({
    required super.controller,
    super.label,
    super.hint,
    super.focusNode,
    super.validator,
    super.prefixIcon,
    super.suffixIcon,
    super.keyboardType,
    super.textInputAction,
    super.onChanged,
    super.onSubmitted,
    super.readOnly = false,
  }) : super._(variant: AppTextFieldVariant.regular);
}

class _AppTextFieldPassword extends AppTextField {
  const _AppTextFieldPassword({
    required super.controller,
    super.label,
    super.hint,
    super.focusNode,
    super.validator,
    super.prefixIcon,
    super.textInputAction,
    super.onChanged,
    super.onSubmitted,
  }) : super._(variant: AppTextFieldVariant.password);
}

class _AppTextFieldSearch extends AppTextField {
  const _AppTextFieldSearch({
    required super.controller,
    super.hint,
    super.focusNode,
    super.suffixIcon,
    super.onChanged,
    super.onSubmitted,
  }) : super._(variant: AppTextFieldVariant.search);
}

class _AppTextFieldMultiline extends AppTextField {
  const _AppTextFieldMultiline({
    required super.controller,
    super.label,
    super.hint,
    super.focusNode,
    super.validator,
    super.onChanged,
    super.onSubmitted,
    super.readOnly = false,
  }) : super._(variant: AppTextFieldVariant.multiline);
}
