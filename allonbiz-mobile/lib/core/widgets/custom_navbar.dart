import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/navigate/presentation/controllers/navigation_controller.dart';
import '../../features/home/presentation/widgets/interests_dialog_widget.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isJourneyActive = ref.watch(
      navigationControllerProvider.select(
        (s) => s.isFreeRoam || s.currentRoute.isNotEmpty,
      ),
    );

    return Container(
      height:
          110, // Increased height to accommodate the floating button within bounds
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          RepaintBoundary(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.grey800 : AppColors.grey200,
                    width: 1,
                  ),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
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
                    const SizedBox(width: 60), // Space for center button
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
          ),
          // Center floating button
          Positioned(
            top: 0, // Top of the 110h container
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (isJourneyActive) {
                  ref.read(navigationControllerProvider.notifier).clearRoute();
                } else {
                  _showInterestsDialog(context);
                }
              },
              child: Semantics(
                label: isJourneyActive ? 'Close Journey' : 'Start Journey',
                button: true,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isJourneyActive ? AppColors.error : AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isJourneyActive ? AppColors.error : AppColors.primary).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isJourneyActive ? Icons.close_rounded : Icons.navigation_rounded,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? AppColors.primary
        : (isDark ? AppColors.grey400 : AppColors.grey600);

    return InkResponse(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      containedInkWell: true,
      highlightShape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(isActive ? activeIcon : icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
