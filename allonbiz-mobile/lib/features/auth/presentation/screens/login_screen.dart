import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_status_banner.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_header.dart';

/// Sign-in screen with manual Email & Password, plus Google/Apple options.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _forgotPasswordMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    _clearError();
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  Future<void> _onForgotPassword() async {
    final result = await context.push<String?>(
      AppRoutes.forgotPassword,
      extra: _emailController.text.trim(),
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    setState(() => _forgotPasswordMessage = result);
  }

  void _clearError() {
    if (_forgotPasswordMessage != null) {
      setState(() => _forgotPasswordMessage = null);
    }
    if (ref.read(authControllerProvider).status == AuthStatus.error) {
      ref.read(authControllerProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final loginErrorMessage = _forgotPasswordMessage ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AbsorbPointer(
          absorbing: isLoading,
          child: GradientBackground(
            safeArea: true,
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
                        children: [
                          AuthHeader(
                            title: l10n.appName,
                            subtitle: l10n.welcomeBackShort,
                          ),
                          const SizedBox(height: 32),

                          if (loginErrorMessage != null) ...[
                            AppStatusBanner(
                              message: AuthErrorMapper.getMessage(
                                loginErrorMessage,
                                l10n,
                              ),
                              variant: AppStatusBannerVariant.error,
                              textStyle: textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                          ],

                          AppTextField.regular(
                                controller: _emailController,
                                label: l10n.email,
                                hint: l10n.emailHint,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.emailValidError;
                                  }
                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );
                                  return emailRegex.hasMatch(value.trim())
                                      ? null
                                      : l10n.emailValidError;
                                },
                                onChanged: (_) => _clearError(),
                              )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 16),

                          AppTextField.password(
                                controller: _passwordController,
                                label: l10n.password,
                                hint: l10n.passwordHint,
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                validator: (value) =>
                                    (value == null || value.length < 6)
                                    ? l10n.passwordValidError
                                    : null,
                                onChanged: (_) => _clearError(),
                              )
                              .animate()
                              .fadeIn(delay: 450.ms)
                              .slideY(begin: 0.1, end: 0),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading ? null : _onForgotPassword,
                              child: Text(
                                'Forgot Password?',
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms),

                          const SizedBox(height: 8),

                          SizedBox(
                                width: double.infinity,
                                child: AppButton.primary(
                                  label: l10n.login,
                                  isLoading: isLoading,
                                  onPressed: isLoading ? null : _onLogin,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 550.ms)
                              .slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 24),

                          TextButton(
                            onPressed: () => context.push(AppRoutes.register),
                            child: RichText(
                              text: TextSpan(
                                text: l10n.dontHaveAccountPrefix,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                children: [
                                  TextSpan(
                                    text: ' ${l10n.registerLink}',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 750.ms),
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
    );
  }
}
