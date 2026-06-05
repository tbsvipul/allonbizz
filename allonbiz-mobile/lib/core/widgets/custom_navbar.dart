import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/widgets/interests_dialog_widget.dart';
import '../../features/navigate/presentation/controllers/navigation_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_glass.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class CustomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    final isJourneyActive = ref.watch(
      navigationControllerProvider.select(
        (s) => s.isFreeRoam || s.currentRoute.isNotEmpty,
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.md,
          0,
          AppDimensions.md,
          AppDimensions.sm,
        ),
        child: SizedBox(
          height: 92,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GlassmorphicContainer(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  borderRadius: BorderRadius.circular(30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavBarItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: l10n.navHome,
                        isActive: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                      _NavBarItem(
                        icon: Icons.location_on_outlined,
                        activeIcon: Icons.location_on_rounded,
                        label: l10n.navNavigate,
                        isActive: currentIndex == 1,
                        onTap: () {
                          onTap(1);
                          ref.read(mapRecenterTriggerProvider.notifier).state++;
                        },
                      ),
                      const SizedBox(width: 72),
                      _NavBarItem(
                        icon: Icons.search_outlined,
                        activeIcon: Icons.search_rounded,
                        label: l10n.navDiscover,
                        isActive: currentIndex == 2,
                        onTap: () => onTap(2),
                      ),
                      _NavBarItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person_rounded,
                        label: l10n.navMe,
                        isActive: currentIndex == 3,
                        onTap: () => onTap(3),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -2,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (isJourneyActive) {
                      ref
                          .read(navigationControllerProvider.notifier)
                          .clearRoute();
                    } else {
                      _showInterestsDialog(context);
                    }
                  },
                  child: Semantics(
                    label: isJourneyActive ? 'Close Journey' : 'Start Journey',
                    button: true,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        gradient: isJourneyActive
                            ? LinearGradient(
                                colors: [
                                  colorScheme.error,
                                  colorScheme.error.withValues(alpha: 0.74),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  AppColors.accentLight,
                                  AppColors.accent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface.withValues(alpha: 0.86),
                          width: 5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isJourneyActive
                                        ? colorScheme.error
                                        : AppColors.accent)
                                    .withValues(alpha: 0.18),
                            blurRadius: 18,
                            spreadRadius: -6,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        isJourneyActive
                            ? Icons.close_rounded
                            : Icons.navigation_rounded,
                        color: isJourneyActive
                            ? colorScheme.onError
                            : AppColors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInterestsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const InterestsDialogWidget(),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.22),
                          colorScheme.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: color,
                size: isActive ? 26 : 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
