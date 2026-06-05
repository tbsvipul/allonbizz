import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_glass.dart';

/// 4-page swipeable onboarding experience.
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  List<_OnboardingPage> _getPages(AppLocalizations l10n) => [
    _OnboardingPage(
      icon: Icons.navigation_rounded,
      color: AppColors.primary,
      title: l10n.onboardingTitle1,
      description: l10n.onboardingDesc1,
    ),
    _OnboardingPage(
      icon: Icons.local_offer_rounded,
      color: AppColors.secondary,
      title: l10n.onboardingTitle2,
      description: l10n.onboardingDesc2,
    ),
    _OnboardingPage(
      icon: Icons.savings_rounded,
      color: AppColors.accent,
      title: l10n.onboardingTitle3,
      description: l10n.onboardingDesc3,
    ),
    _OnboardingPage(
      icon: Icons.view_in_ar_rounded,
      color: AppColors.error,
      title: l10n.onboardingTitle4,
      description: l10n.onboardingDesc4,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(l10n);
    final isLast = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        safeArea: true,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton.text(
                  label: l10n.skip,
                  onPressed: widget.onComplete,
                  width: 80,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) {
                  if (mounted) setState(() => _currentPage = i);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlassmorphicContainer(
                              padding: const EdgeInsets.all(34),
                              borderRadius: BorderRadius.circular(42),
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      page.color.withValues(alpha: 0.18),
                                      AppColors.secondary.withValues(
                                        alpha: 0.08,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  page.icon,
                                  size: 80,
                                  color: page.color,
                                ),
                              ),
                            )
                            .animate(key: ValueKey(index))
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1, 1),
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(duration: 300.ms),
                        const SizedBox(height: 48),
                        Text(
                              page.title,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.4,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate(key: ValueKey('title_$index'))
                            .fadeIn(delay: 200.ms, duration: 400.ms),
                        const SizedBox(height: 16),
                        Text(
                              page.description,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate(key: ValueKey('desc_$index'))
                            .fadeIn(delay: 350.ms, duration: 400.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: pages.length,
                    effect: const ExpandingDotsEffect(
                      dotColor: AppColors.grey300,
                      activeDotColor: AppColors.primary,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton.primary(
                    label: isLast ? l10n.getStarted : l10n.next,
                    width: double.infinity,
                    onPressed: () {
                      if (isLast) {
                        widget.onComplete();
                      } else {
                        _controller.nextPage(
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String description;
}
