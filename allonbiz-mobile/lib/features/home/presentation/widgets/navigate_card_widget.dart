import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/extensions/navigation_x.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../navigate/presentation/controllers/navigation_controller.dart';

class NavigateCardWidget extends ConsumerWidget {
  const NavigateCardWidget({super.key, required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(currentLocationProvider);
    final navigationState = ref.watch(navigationControllerProvider);
    final hasActiveJourney = navigationState.hasActiveJourney;
    final theme = Theme.of(context);

    return GlassmorphicContainer(
      onTap: () => context.pushTo(
        hasActiveJourney ? AppRoutes.navigate : AppRoutes.search,
      ),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasActiveJourney ? l10n.endJourney : l10n.startJourney,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasActiveJourney
                        ? (navigationState.isFreeRoam
                              ? 'Exploration is active in the background.'
                              : 'Your active trip is still running.')
                        : l10n.discoverDealsDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  // Mini route preview
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            hasActiveJourney
                                ? (navigationState
                                              .destinationName
                                              ?.isNotEmpty ==
                                          true
                                      ? navigationState.destinationName!
                                      : navigationState.isFreeRoam
                                      ? 'Exploring Nearby'
                                      : 'Journey in progress')
                                : (locationState.placeName ??
                                      l10n.fetchingLocation),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasActiveJourney
                              ? (navigationState.isFreeRoam ? 'Active' : 'Open')
                              : '?',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (hasActiveJourney) {
                  ref.read(navigationControllerProvider.notifier).clearRoute();
                } else {
                  context.pushTo(AppRoutes.search);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentLight, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: AppColors.glow(AppColors.accent),
                ),
                child: Icon(
                  hasActiveJourney
                      ? Icons.stop_rounded
                      : Icons.navigation_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
