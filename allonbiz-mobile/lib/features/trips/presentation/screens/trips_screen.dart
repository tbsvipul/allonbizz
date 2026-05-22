import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_stat_item.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/widgets/profile_vertical_divider_widget.dart';
import '../../../../core/services/journey_service.dart';
import '../../../../core/models/journey_model.dart';

/// User's past journeys and trip statistics.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).user;
    final journeysAsync = ref.watch(journeysProvider);

    final String tripsCount = '${user?.totalTrips ?? 0}';
    final String totalDistance =
        '${(user?.totalKm ?? 0.0).toStringAsFixed(1)} km';
    final String totalSaved =
        '\$${(user?.totalSaved ?? 0.0).toStringAsFixed(2)}';

    // AppBar title is managed by MainLayout based on current index.

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      children: [
        // Stats Header
        Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: AppSurface(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AppStatItem(label: l10n.trips, value: tripsCount),
                const ProfileVerticalDividerWidget(),
                AppStatItem(label: l10n.distance, value: totalDistance),
                const ProfileVerticalDividerWidget(),
                AppStatItem(label: l10n.totalSaved, value: totalSaved),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),

        AppSectionHeader(title: l10n.pastJourneys),

        Expanded(
          child: journeysAsync.when(
            data: (journeys) {
              if (journeys.isEmpty) {
                return _buildEmptyState(l10n, theme);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.lg),
                itemExtent:
                    88, // Optimization: Avoid layout measurements during scroll
                itemCount: journeys.length,
                itemBuilder: (context, index) {
                  final journey = journeys[index];
                  final isDestination = journey.type == JourneyType.destination;
                  final baseColor = isDestination
                      ? colorScheme.primary
                      : colorScheme.secondary;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.md),
                    child: AppSurface(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: baseColor.withValues(alpha: 0.1),
                          child: Icon(
                            isDestination
                                ? Icons.navigation_rounded
                                : Icons.explore_rounded,
                            color: baseColor,
                          ),
                        ),
                        title: Text(
                          journey.endName ?? journey.startName ?? 'Journey',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat.yMMMd().format(journey.startTimeDate)} • ${(journey.distance / 1000).toStringAsFixed(1)} km',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Text(
                          '${(journey.duration / 60).toInt()} m',
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text(err.toString())),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            l10n.noPastJourneys,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
