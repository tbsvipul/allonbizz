import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/journey_model.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_surface.dart';

class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.journey,
    this.onTap,
    this.showTapHint = true,
    this.compact = false,
  });

  final JourneyModel journey;
  final VoidCallback? onTap;
  final bool showTapHint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactJourneyCard(
        journey: journey,
        onTap: onTap,
        showTapHint: showTapHint,
      );
    }

    return AppSurface(
      onTap: onTap,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      borderColor: AppColors.grey200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppDimensions.xs,
                  runSpacing: AppDimensions.xs,
                  children: [
                    _JourneyPill(
                      label: journeyTypeLabel(journey),
                      color: AppColors.primary,
                    ),
                    _JourneyPill(
                      label: journeyStatusLabel(journey),
                      color: journey.isCompleted
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                formatJourneyDateTime(journey.startTimeDate),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey500,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          _LocationRow(
            icon: Icons.radio_button_checked_rounded,
            color: AppColors.primary,
            label: journey.startName ?? 'Unknown start',
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 11,
              top: AppDimensions.xs,
              bottom: AppDimensions.xs,
            ),
            child: Container(width: 1, height: 18, color: AppColors.grey300),
          ),
          _LocationRow(
            icon: Icons.location_on_rounded,
            color: AppColors.error,
            label:
                journey.endName ??
                (journey.type == JourneyType.freeRoam
                    ? 'Free roam end'
                    : 'Destination pending'),
          ),
          const Divider(height: AppDimensions.xxl),
          Row(
            children: [
              Expanded(
                child: _JourneyStat(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: formatJourneyDistance(journey.distance),
                ),
              ),
              Expanded(
                child: _JourneyStat(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: formatJourneyDuration(journey.duration),
                ),
              ),
              Expanded(
                child: _JourneyStat(
                  icon: Icons.storefront_outlined,
                  label: 'Shops',
                  value: '${journey.shopsEncountered.length}',
                ),
              ),
            ],
          ),
          if (journey.tags.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            Wrap(
              spacing: AppDimensions.xs,
              runSpacing: AppDimensions.xs,
              children: journey.tags
                  .take(4)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (showTapHint && onTap != null) ...[
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                Text(
                  'Tap to view full details',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactJourneyCard extends StatelessWidget {
  const _CompactJourneyCard({
    required this.journey,
    this.onTap,
    required this.showTapHint,
  });

  final JourneyModel journey;
  final VoidCallback? onTap;
  final bool showTapHint;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      borderColor: AppColors.grey200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LocationRow(
            icon: Icons.radio_button_checked_rounded,
            color: AppColors.primary,
            label: journey.startName ?? 'Unknown start',
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 11,
              top: AppDimensions.xs,
              bottom: AppDimensions.xs,
            ),
            child: Container(width: 1, height: 18, color: AppColors.grey300),
          ),
          _LocationRow(
            icon: Icons.location_on_rounded,
            color: AppColors.error,
            label:
                journey.endName ??
                (journey.type == JourneyType.freeRoam
                    ? 'Free roam end'
                    : 'Destination pending'),
          ),
          const SizedBox(height: AppDimensions.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Duration',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  formatJourneyDuration(journey.duration),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (showTapHint && onTap != null) ...[
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                Text(
                  'Tap to view full details',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _JourneyPill extends StatelessWidget {
  const _JourneyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _JourneyStat extends StatelessWidget {
  const _JourneyStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.grey500),
        const SizedBox(height: AppDimensions.xs),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

String journeyTypeLabel(JourneyModel journey) {
  return journey.type == JourneyType.destination ? 'Navigation' : 'Free Roam';
}

String journeyStatusLabel(JourneyModel journey) {
  if (journey.status.trim().isNotEmpty) {
    final normalized = journey.status.trim().toLowerCase();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  return journey.isCompleted ? 'Completed' : 'In Progress';
}

String formatJourneyDateTime(DateTime value) {
  return DateFormat('MMM dd, yyyy - hh:mm a').format(value.toLocal());
}

String formatJourneyDistance(double meters) {
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String formatJourneyDuration(int seconds) {
  final totalMinutes = (seconds / 60).round();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours <= 0) {
    return '$minutes min';
  }

  return '${hours}h ${minutes}m';
}

String formatJourneyCoordinates(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}
