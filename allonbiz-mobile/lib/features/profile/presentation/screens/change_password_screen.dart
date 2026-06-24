import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/failures.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/utils/auth_error_mapper.dart';
import '../../../../core/widgets/app_bar_binding.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_status_banner.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _setError(Object error) {
    if (error is Failure) {
      setState(() => _errorMessage = error.message);
      return;
    }

    setState(() => _errorMessage = error.toString());
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required.';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.trim().length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password.';
    }
    if (value != _newPasswordController.text.trim()) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _currentPasswordController.text.trim(),
            newPassword: _newPasswordController.text.trim(),
          );

      if (!mounted) return;

      await AppDialog.show<void>(
        context,
        title: 'Password Changed',
        message:
            'Your password has been changed successfully. Please sign in again.',
        confirmLabel: 'OK',
      );

      if (!mounted) return;

      await ref.read(authControllerProvider.notifier).signOut();

      if (!mounted) return;
      context.go(AppRoutes.login);
    } on Failure catch (error) {
      if (!mounted) return;
      _setError(error);
    } catch (error) {
      if (!mounted) return;
      _setError(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_isLoading,
      child: AppBarBinding(
        config: AppBarConfig(
          title: const Text('Change Password'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: GradientBackground(
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 140 + MediaQuery.of(context).padding.bottom),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: GlassmorphicContainer(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Update your password',
                                  style: textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'For security, you will be signed out after changing your password.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (_errorMessage != null) ...[
                                  AppStatusBanner(
                                    message: AuthErrorMapper.getMessage(
                                      _errorMessage,
                                      l10n,
                                    ),
                                    variant: AppStatusBannerVariant.error,
                                    textStyle: textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                AppTextField.password(
                                  controller: _currentPasswordController,
                                  label: 'Current Password',
                                  hint: 'Enter your current password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  validator: _validateCurrentPassword,
                                  onChanged: (_) => _clearError(),
                                ),
                                const SizedBox(height: 16),
                                AppTextField.password(
                                  controller: _newPasswordController,
                                  label: 'New Password',
                                  hint: 'Enter your new password',
                                  prefixIcon: Icon(
                                    Icons.lock_reset_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  validator: _validateNewPassword,
                                  onChanged: (_) => _clearError(),
                                ),
                                const SizedBox(height: 16),
                                AppTextField.password(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  hint: 'Re-enter your new password',
                                  prefixIcon: Icon(
                                    Icons.verified_user_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  validator: _validateConfirmPassword,
                                  onChanged: (_) => _clearError(),
                                  onSubmitted: (_) => _changePassword(),
                                ),
                                const SizedBox(height: 24),
                                AppButton.primary(
                                  label: 'Change Password',
                                  isLoading: _isLoading,
                                  onPressed: _isLoading
                                      ? null
                                      : () => _changePassword(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
}
