import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.statusText});

  final String statusText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surface,
              theme.colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.26),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.radar,
                  size: 58,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'allonbiz',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const _pages = [
    (
      'Smart route planning',
      'Find a destination fast, then map the best corridor for discovery.',
      Icons.route_rounded,
    ),
    (
      'Deals along the way',
      'allonbiz spots nearby offers, categories, and merchants as you move.',
      Icons.local_offer_rounded,
    ),
    (
      'Track every journey',
      'Keep private trip history, alerts, and savings synced for offline use.',
      Icons.insights_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider).completeOnboarding();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _pageIndex = value),
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.$3, size: 72),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          item.$1,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.$2,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: _pageIndex == index ? 26 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: _pageIndex == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () async {
                  if (_pageIndex == _pages.length - 1) {
                    await ref.read(authControllerProvider).completeOnboarding();
                    if (context.mounted) {
                      context.go('/login');
                    }
                    return;
                  }
                  await _pageController.nextPage(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                  );
                },
                child: Text(
                  _pageIndex == _pages.length - 1 ? 'Get started' : 'Next',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sign in to continue your journey history, saved offers, and live discovery.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 30),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (value) =>
                              (value == null || !value.contains('@'))
                              ? 'Enter a valid email address.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscureText = !_obscureText),
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.length < 8)
                              ? 'Password must be at least 8 characters.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: auth.loading ? null : _submit,
                            child: Text(
                              auth.loading ? 'Signing in...' : 'Login',
                            ),
                          ),
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(authControllerProvider)
          .login(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (_) {}
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Valid email required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: _validateStrongPassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                validator: (value) => value != _passwordController.text
                    ? 'Passwords do not match.'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: auth.loading ? null : _submit,
                  child: Text(
                    auth.loading ? 'Creating account...' : 'Register',
                  ),
                ),
              ),
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  auth.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(authControllerProvider)
          .register(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (_) {}
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recover account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(authControllerProvider)
                              .forgotPassword(_emailController.text);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Recovery instructions were sent if the account exists.',
                                ),
                              ),
                            );
                          }
                        } catch (_) {}
                      },
                child: const Text('Send recovery link'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(authControllerProvider)
                            .sendOtp(_emailController.text);
                        if (context.mounted) {
                          context.push(
                            '/verify-otp?email=${Uri.encodeComponent(_emailController.text)}',
                          );
                        }
                      } catch (_) {}
                    },
              child: const Text('Use OTP instead'),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail ?? '',
  );
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'OTP'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        try {
                          final token = await ref
                              .read(authControllerProvider)
                              .verifyOtp(
                                email: _emailController.text,
                                otp: _otpController.text,
                              );
                          if (context.mounted) {
                            context.go(
                              '/reset-password?token=${Uri.encodeComponent(token)}',
                            );
                          }
                        } catch (_) {}
                      },
                child: const Text('Verify and continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _tokenController = TextEditingController(
    text: widget.initialToken ?? '',
  );
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: 'Reset token'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        final passwordError = _validateStrongPassword(
                          _passwordController.text,
                        );
                        if (passwordError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(passwordError)),
                          );
                          return;
                        }
                        if (_passwordController.text !=
                            _confirmController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Passwords do not match.'),
                            ),
                          );
                          return;
                        }
                        try {
                          await ref
                              .read(authControllerProvider)
                              .resetPassword(
                                token: _tokenController.text,
                                newPassword: _passwordController.text,
                              );
                          if (context.mounted) {
                            context.go('/login');
                          }
                        } catch (_) {}
                      },
                child: const Text('Update password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _validateStrongPassword(String? value) {
  final password = value?.trim() ?? '';
  if (password.length < 8) {
    return 'Password must be at least 8 characters.';
  }

  final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
  final hasLowerCase = password.contains(RegExp(r'[a-z]'));
  final hasDigit = password.contains(RegExp(r'\d'));

  if (!hasUpperCase || !hasLowerCase || !hasDigit) {
    return 'Use upper-case, lower-case, and a number.';
  }

  return null;
}
