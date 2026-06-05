import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_header.dart';
import '../../../../shared/widgets/app_status_banner.dart';

/// Registration screen with manual Email & Password.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authControllerProvider.notifier)
          .registerWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );
    }
  }

  void _clearError() {
    if (ref.read(authControllerProvider).status == AuthStatus.error) {
      ref.read(authControllerProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return PopScope(
      canPop: !isLoading,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AbsorbPointer(
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
                            title: l10n.createAccount,
                            subtitle:
                                '${l10n.joinAppPrefix}${l10n.appName}${l10n.joinAppSuffix}',
                          ),
                          const SizedBox(height: 32),

                          if (authState.status == AuthStatus.error &&
                              authState.errorMessage != null) ...[
                            AppStatusBanner(
                              message: AuthErrorMapper.getMessage(
                                authState.errorMessage,
                                l10n,
                              ),
                              variant: AppStatusBannerVariant.error,
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                          ],

                          AppTextField.regular(
                                controller: _nameController,
                                label: l10n.fullNameLabel,
                                hint: l10n.fullNameHint,
                                keyboardType: TextInputType.name,
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                validator: (value) =>
                                    value != null && value.length > 2
                                    ? null
                                    : l10n.fullNameValidError,
                                onChanged: (_) => _clearError(),
                              )
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 16),

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
                              .fadeIn(delay: 350.ms)
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
                                    value != null && value.length >= 6
                                    ? null
                                    : l10n.passwordValidError,
                                onChanged: (_) => _clearError(),
                              )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 32),

                          SizedBox(
                                width: double.infinity,
                                child: AppButton.primary(
                                  label: l10n.registerButton,
                                  isLoading: isLoading,
                                  onPressed: isLoading ? null : _onRegister,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 450.ms)
                              .slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 24),

                          TextButton(
                            onPressed: isLoading ? null : () => context.pop(),
                            child: RichText(
                              text: TextSpan(
                                text: l10n.alreadyHaveAccountPrefix,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                children: [
                                  TextSpan(
                                    text: l10n.loginLink,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms),
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
