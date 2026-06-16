import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../controllers/auth_controller.dart';

/// Animated splash screen with logo and route line animation.
class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();
    // Navigate after animation completes, if session is already resolved
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      setState(() => _animationComplete = true);
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (!_animationComplete) return;
    final authState = ref.read(authControllerProvider);
    if (authState.hasResolvedSession) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to navigate if animation is already complete
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasResolvedSession && _animationComplete) {
        widget.onComplete();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo icon
            Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/tranperentlogo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            // App name and tagline removed as requested

            const SizedBox(height: 48),

            // Animated route line with dots
            SizedBox(
              width: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: index == 2 ? 14 : 10,
                          height: index == 2 ? 14 : 10,
                          decoration: BoxDecoration(
                            color: index == 2
                                ? AppColors.secondary
                                : AppColors.white.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: index == 2
                                ? Border.all(color: AppColors.white, width: 2)
                                : null,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (1000 + index * 150).ms, duration: 300.ms)
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        delay: (1000 + index * 150).ms,
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
