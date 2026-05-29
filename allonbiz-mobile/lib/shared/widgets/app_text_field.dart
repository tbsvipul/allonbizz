import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

enum AppTextFieldVariant { regular, password, search, multiline }

/// Universal standard Text Field implementation.
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
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.variant == AppTextFieldVariant.password;
    final isSearch = widget.variant == AppTextFieldVariant.search;
    final isMultiline = widget.variant == AppTextFieldVariant.multiline;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && !isSearch) ...[
          Text(
            widget.label!,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
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
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(
                color: isSearch
                    ? Colors.transparent
                    : colorScheme.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(
                color: isSearch
                    ? Colors.transparent
                    : colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: colorScheme.error),
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
