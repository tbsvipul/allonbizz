import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_bar_binding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/journey_model.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../discover/data/repositories/shops_repository.dart';
import '../../../trips/data/repositories/journeys_repository.dart';
import '../widgets/journey_card.dart';

final journeyDetailProvider = FutureProvider.family<JourneyModel, String>((
  ref,
  journeyId,
) {
  return ref.watch(journeysRepositoryProvider).getJourneyDetail(journeyId);
});

final encounteredShopLabelsProvider = FutureProvider.autoDispose
    .family<List<String>, EncounteredShopLabelsArgs>((ref, args) async {
      if (args.entries.isEmpty) {
        return const <String>[];
      }

      final shopsRepository = ref.watch(shopsRepositoryProvider);
      final resolvedEntries = await Future.wait(
        args.entries.map(
          (entry) => _resolveEncounteredShopLabel(shopsRepository, entry),
        ),
      );
      final resolvedLabels = <String>[];
      final seenLabels = <String>{};

      for (final label in resolvedEntries) {
        if (label.isEmpty) {
          continue;
        }

        final dedupeKey = label.toLowerCase();
        if (seenLabels.add(dedupeKey)) {
          resolvedLabels.add(label);
        }
      }

      return resolvedLabels;
    });

@immutable
class EncounteredShopLabelsArgs {
  EncounteredShopLabelsArgs(List<String> entries)
    : entries = List.unmodifiable(entries);

  final List<String> entries;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EncounteredShopLabelsArgs &&
            listEquals(other.entries, entries);
  }

  @override
  int get hashCode => Object.hashAll(entries);
}

Future<String> _resolveEncounteredShopLabel(
  ShopsRepository shopsRepository,
  String rawValue,
) async {
  final normalizedValue = rawValue.trim();
  if (normalizedValue.isEmpty) {
    return '';
  }

  if (!_looksLikeShopId(normalizedValue)) {
    return normalizedValue;
  }

  try {
    final shop = await shopsRepository.getShopDetail(normalizedValue);
    final shopName = shop.name.trim();
    return shopName.isEmpty ? normalizedValue : shopName;
  } catch (_) {
    return normalizedValue;
  }
}

bool _looksLikeShopId(String value) {
  if (value.contains(RegExp(r'\s'))) {
    return false;
  }

  if (value.toLowerCase().startsWith('shop-')) {
    return true;
  }

  if (RegExp(r'^\d+$').hasMatch(value)) {
    return true;
  }

  if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(value)) {
    return true;
  }

  if (RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value)) {
    return true;
  }

  return value.length >= 16 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);
}

class JourneyDetailScreen extends ConsumerStatefulWidget {
  const JourneyDetailScreen({
    super.key,
    required this.journeyId,
    this.initialJourney,
  });

  final String journeyId;
  final JourneyModel? initialJourney;

  @override
  ConsumerState<JourneyDetailScreen> createState() =>
      _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends ConsumerState<JourneyDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final journeyAsync = ref.watch(journeyDetailProvider(widget.journeyId));

    return AppBarBinding(
      config: AppBarConfig(
        title: const Text('Journey Details'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.grey50,
        body: journeyAsync.when(
          data: (journey) => _JourneyDetailContent(journey: journey),
          loading: () {
            if (widget.initialJourney != null) {
              return _JourneyDetailContent(
                journey: widget.initialJourney!,
                isRefreshing: true,
              );
            }

            return const Center(child: AppLoader.inline());
          },
          error: (error, stackTrace) {
            if (widget.initialJourney != null) {
              return _JourneyDetailContent(
                journey: widget.initialJourney!,
                errorMessage:
                    'Showing saved summary. Full detail could not be loaded.',
              );
            }

            return AppErrorWidget(
              title: 'Unable to load journey details',
              message: 'Please try again to fetch the latest journey summary.',
              onRetry: () =>
                  ref.invalidate(journeyDetailProvider(widget.journeyId)),
            );
          },
        ),
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
          child: _EncounteredShopsList(
            shopsEncountered: journey.shopsEncountered,
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
    return AppCard(
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

class _EncounteredShopsList extends ConsumerWidget {
  const _EncounteredShopsList({required this.shopsEncountered});

  final List<String> shopsEncountered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (shopsEncountered.isEmpty) {
      return Text(
        'No shops were recorded on this journey.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
      );
    }

    final labelsAsync = ref.watch(
      encounteredShopLabelsProvider(
        EncounteredShopLabelsArgs(shopsEncountered),
      ),
    );

    return labelsAsync.when(
      data: _buildRows,
      loading: () => const Center(child: AppLoader.inline(size: 24)),
      error: (_, _) => _buildRows(shopsEncountered),
    );
  }

  Widget _buildRows(List<String> labels) {
    return Column(
      children: labels
          .map(
            (shop) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
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
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: accentColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
