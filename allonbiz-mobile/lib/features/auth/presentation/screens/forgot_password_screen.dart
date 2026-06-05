import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/failures.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_status_banner.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repositories/auth_repository.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_header.dart';

enum _ForgotPasswordStep { requestOtp, resetPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ForgotPasswordStep _step = _ForgotPasswordStep.requestOtp;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isResetStep => _step == _ForgotPasswordStep.resetPassword;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail?.trim() ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
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

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (otp.isEmpty) {
      return 'OTP is required.';
    }
    if (otp.length < 6) {
      return 'Enter the 6-digit OTP.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != _newPasswordController.text.trim()) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    if (_isResetStep) {
      final emailError = _validateEmail(_emailController.text);
      if (emailError != null) {
        setState(() => _errorMessage = emailError);
        return;
      }
    } else if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(_emailController.text.trim());

      if (!mounted) return;

      setState(() => _step = _ForgotPasswordStep.resetPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isResend
                ? 'A new OTP has been sent to your email.'
                : 'OTP sent. Enter it below to reset your password.',
          ),
        ),
      );
    } on AuthFailure catch (error) {
      if (!mounted) return;
      if (error.code == 'user-not-found') {
        context.pop(error.code);
        return;
      }
      _setError(error);
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

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final resetToken = await repository.verifyPasswordResetOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );
      await repository.resetPassword(
        token: resetToken,
        newPassword: _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      await AppDialog.show<void>(
        context,
        title: 'Password Reset',
        message:
            'Your password has been reset successfully. Please sign in with your new password.',
        confirmLabel: 'OK',
      );

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

  void _editEmail() {
    setState(() {
      _step = _ForgotPasswordStep.requestOtp;
      _errorMessage = null;
      _otpController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Forgot Password'), centerTitle: true),
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AbsorbPointer(
            absorbing: _isLoading,
            child: GradientBackground(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: GlassmorphicContainer(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthHeader(
                                title: _isResetStep
                                    ? 'Reset your password'
                                    : 'Recover your account',
                                subtitle: _isResetStep
                                    ? 'Enter the OTP from your email and choose a new password.'
                                    : 'We will send a one-time password to your email address.',
                                showIcon: false,
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
                              AppTextField.regular(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'Enter your email address',
                                readOnly: _isResetStep,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: _isResetStep
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                validator: _validateEmail,
                                onChanged: (_) => _clearError(),
                              ),
                              if (_isResetStep) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.16,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.mark_email_read_outlined,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Check your email for the 6-digit OTP.',
                                          style: textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _editEmail,
                                    child: const Text('Use a different email'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppTextField.regular(
                                  controller: _otpController,
                                  label: 'OTP',
                                  hint: 'Enter 6-digit OTP',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  prefixIcon: Icon(
                                    Icons.password_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  validator: _validateOtp,
                                  onChanged: (_) => _clearError(),
                                ),
                                const SizedBox(height: 16),
                                AppTextField.password(
                                  controller: _newPasswordController,
                                  label: 'New Password',
                                  hint: 'Enter your new password',
                                  textInputAction: TextInputAction.next,
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  validator: _validatePassword,
                                  onChanged: (_) => _clearError(),
                                ),
                                const SizedBox(height: 16),
                                AppTextField.password(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  hint: 'Re-enter your new password',
                                  textInputAction: TextInputAction.done,
                                  prefixIcon: Icon(
                                    Icons.lock_reset_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  validator: _validateConfirmPassword,
                                  onChanged: (_) => _clearError(),
                                  onSubmitted: (_) => _resetPassword(),
                                ),
                              ],
                              const SizedBox(height: 24),
                              AppButton.primary(
                                label: _isResetStep
                                    ? 'Reset Password'
                                    : 'Send OTP',
                                isLoading: _isLoading,
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (_isResetStep) {
                                          _resetPassword();
                                        } else {
                                          _sendOtp();
                                        }
                                      },
                              ),
                              if (_isResetStep) ...[
                                const SizedBox(height: 12),
                                AppButton.outlined(
                                  label: 'Resend OTP',
                                  onPressed: _isLoading
                                      ? null
                                      : () => _sendOtp(isResend: true),
                                ),
                              ],
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => context.pop(),
                                child: const Text('Back to Login'),
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
    );
  }
}
