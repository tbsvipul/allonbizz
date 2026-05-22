import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/journey_model.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../trips/data/repositories/journeys_repository.dart';
import '../widgets/journey_card.dart';

final journeyDetailProvider = FutureProvider.family<JourneyModel, String>((
  ref,
  journeyId,
) {
  return ref.watch(journeysRepositoryProvider).getJourneyDetail(journeyId);
});

class JourneyDetailScreen extends ConsumerWidget {
  const JourneyDetailScreen({
    super.key,
    required this.journeyId,
    this.initialJourney,
  });

  final String journeyId;
  final JourneyModel? initialJourney;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsync = ref.watch(journeyDetailProvider(journeyId));

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.grey50,
      appBar: AppBar(title: const Text('Journey Details'), centerTitle: true),
      body: journeyAsync.when(
        data: (journey) => _JourneyDetailContent(journey: journey),
        loading: () {
          if (initialJourney != null) {
            return _JourneyDetailContent(
              journey: initialJourney!,
              isRefreshing: true,
            );
          }

          return const Center(child: AppLoader.inline());
        },
        error: (error, stackTrace) {
          if (initialJourney != null) {
            return _JourneyDetailContent(
              journey: initialJourney!,
              errorMessage:
                  'Showing saved summary. Full detail could not be loaded.',
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Text(
                'Unable to load journey details.\n$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JourneyDetailContent extends StatelessWidget {
  const _JourneyDetailContent({
    required this.journey,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final JourneyModel journey;
  final bool isRefreshing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final pathPoints = journey.pathPoints;
    final hasDestination = journey.endLat != null && journey.endLng != null;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      children: [
        if (isRefreshing)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLoader.inline(size: 24),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Loading latest journey details...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        if (errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(
              errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        JourneyCard(journey: journey, showTapHint: false),
        _DetailSection(
          title: 'Overview',
          child: Column(
            children: [
              _DetailRow(label: 'Status', value: journeyStatusLabel(journey)),
              _DetailRow(label: 'Type', value: journeyTypeLabel(journey)),
              _DetailRow(
                label: 'Started',
                value: formatJourneyDateTime(journey.startTimeDate),
              ),
              _DetailRow(
                label: 'Ended',
                value: journey.endTimeDate != null
                    ? formatJourneyDateTime(journey.endTimeDate!)
                    : 'Still in progress',
              ),
              _DetailRow(
                label: 'Recorded route points',
                value: '${pathPoints.length}',
              ),
            ],
          ),
        ),
        _DetailSection(
          title: 'Locations',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LocationDetailBlock(
                title: 'Start',
                name: journey.startName ?? 'Unknown start',
                coordinates: formatJourneyCoordinates(
                  journey.startLat,
                  journey.startLng,
                ),
                accentColor: AppColors.primary,
                timeLabel: formatJourneyDateTime(journey.startTimeDate),
              ),
              const SizedBox(height: AppDimensions.md),
              _LocationDetailBlock(
                title: 'End',
                name:
                    journey.endName ??
                    (journey.isCompleted ? 'Destination' : 'Not reached yet'),
                coordinates: hasDestination
                    ? formatJourneyCoordinates(journey.endLat!, journey.endLng!)
                    : 'Coordinates not available',
                accentColor: AppColors.error,
                timeLabel: journey.endTimeDate != null
                    ? formatJourneyDateTime(journey.endTimeDate!)
                    : 'Still in progress',
              ),
            ],
          ),
        ),
        if (journey.tags.isNotEmpty)
          _DetailSection(
            title: 'Tags',
            child: Wrap(
              spacing: AppDimensions.xs,
              runSpacing: AppDimensions.xs,
              children: journey.tags
                  .map(
                    (tag) => _InfoChip(icon: Icons.sell_outlined, label: tag),
                  )
                  .toList(growable: false),
            ),
          ),
        _DetailSection(
          title: 'Shops Encountered',
          child: journey.shopsEncountered.isEmpty
              ? Text(
                  'No shops were recorded on this journey.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                )
              : Column(
                  children: journey.shopsEncountered
                      .map(
                        (shop) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDimensions.sm,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.storefront_outlined,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: AppDimensions.sm),
                              Expanded(
                                child: Text(
                                  shop,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        _DetailSection(
          title: 'Route Trace',
          child: pathPoints.isEmpty
              ? Text(
                  'Detailed route breadcrumbs are not available for this journey.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppDimensions.xs,
                      runSpacing: AppDimensions.xs,
                      children: [
                        _InfoChip(
                          icon: Icons.flag_circle_outlined,
                          label:
                              'First: ${formatJourneyCoordinates(pathPoints.first.latitude, pathPoints.first.longitude)}',
                        ),
                        _InfoChip(
                          icon: Icons.outlined_flag_rounded,
                          label:
                              'Last: ${formatJourneyCoordinates(pathPoints.last.latitude, pathPoints.last.longitude)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),
                    ...pathPoints
                        .take(8)
                        .toList(growable: false)
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppDimensions.sm,
                            ),
                            child: _DetailRow(
                              label: 'Point ${entry.key + 1}',
                              value: formatJourneyCoordinates(
                                entry.value.latitude,
                                entry.value.longitude,
                              ),
                            ),
                          ),
                        ),
                    if (pathPoints.length > 8)
                      Padding(
                        padding: const EdgeInsets.only(top: AppDimensions.xs),
                        child: Text(
                          '${pathPoints.length - 8} more route points were recorded.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppDimensions.xl),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _LocationDetailBlock extends StatelessWidget {
  const _LocationDetailBlock({
    required this.title,
    required this.name,
    required this.coordinates,
    required this.accentColor,
    required this.timeLabel,
  });

  final String title;
  final String name;
  final String coordinates;
  final Color accentColor;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            name,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            coordinates,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            timeLabel,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: AppDimensions.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
