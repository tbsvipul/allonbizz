import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/journey_model.dart';
import '../../../../core/extensions/navigation_x.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../trips/data/repositories/journeys_repository.dart';
import '../../../profile/presentation/widgets/journey_card.dart';

final homeRecentJourneysProvider = FutureProvider<List<JourneyModel>>((ref) {
  return ref
      .watch(journeysRepositoryProvider)
      .getRecentJourneys(limit: 3, completedOnly: true);
});

/// Recent journeys block rendered on the home screen.
class HomeRecentJourneysSection extends ConsumerWidget {
  const HomeRecentJourneysSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(homeRecentJourneysProvider)
        .when(
          data: (journeys) {
            if (journeys.isEmpty) {
              return const _EmptyRecentJourneysSection();
            }

            return Padding(
              padding: const EdgeInsets.only(top: AppDimensions.xl),
              child: Column(
                children: [
                  const AppSectionHeader(
                    title: 'Recent Journeys',
                    icon: Icons.route_rounded,
                    padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                    ),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < journeys.length;
                          index++
                        ) ...[
                          JourneyCard(
                            journey: journeys[index],
                            compact: true,
                            onTap: journeys[index].id == null
                                ? null
                                : () => context.pushTo(
                                    AppRoutes.journeyDetail.replaceFirst(
                                      ':id',
                                      journeys[index].id!,
                                    ),
                                    extra: journeys[index],
                                  ),
                          ),
                          if (index < journeys.length - 1)
                            const SizedBox(height: AppDimensions.sm),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.only(top: AppDimensions.xl),
            child: AppErrorWidget(
              title: 'Unable to load journeys',
              message: 'Please try again to refresh your recent trips.',
              onRetry: () => ref.invalidate(homeRecentJourneysProvider),
            ),
          ),
        );
  }
}

class _EmptyRecentJourneysSection extends StatelessWidget {
  const _EmptyRecentJourneysSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.xl),
      child: Column(
        children: [
          const AppSectionHeader(
            title: 'Recent Journeys',
            icon: Icons.route_rounded,
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg),
          ),
          const SizedBox(height: AppDimensions.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            child: AppSurface(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No journeys yet',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Your recent journeys will appear here after you start navigating.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
