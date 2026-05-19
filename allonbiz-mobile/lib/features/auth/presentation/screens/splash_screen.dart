import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Animated splash screen with logo and route line animation.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after animation completes
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo icon
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    size: 64,
                    color: AppColors.white,
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

            const SizedBox(height: 24),

            // App name
            Text(
                  'allonbiz',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 500.ms),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Navigate smarter. Discover deals.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white.withValues(alpha: 0.85),
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 500.ms),

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
