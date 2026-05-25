import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/journey_model.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/services/preference_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/offer.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../discover/data/repositories/deals_repository.dart';
import '../../../profile/presentation/widgets/journey_card.dart';
import '../../../trips/data/repositories/journeys_repository.dart';
import '../../data/repositories/home_repository.dart';
import '../widgets/deal_section_widget.dart';
import '../widgets/navigate_card_widget.dart';
import '../widgets/quick_action_widget.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_routes.dart';

final homeRecentJourneysProvider = FutureProvider<List<JourneyModel>>((ref) {
  return ref
      .watch(journeysRepositoryProvider)
      .getRecentJourneys(limit: 1, completedOnly: true);
});

/// Home screen - Tab 1.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ProviderSubscription<AsyncValue<List<Offer>>>? _dealsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initGeofencing());

      final locationState = ref.read(currentLocationProvider);
      if (locationState.position == null && !locationState.isLoading) {
        unawaited(
          ref
              .read(currentLocationProvider.notifier)
              .fetchCurrentLocation(requestPermission: false),
        );
      }
    });
  }

  @override
  void dispose() {
    _dealsSubscription?.close();
    super.dispose();
  }

  Future<void> _initGeofencing() async {
    final isTrackingEnabled = ref.read(locationTrackingEnabledProvider);
    if (!isTrackingEnabled) return;

    final geofencer = ref.read(geofenceServiceProvider);

    _dealsSubscription ??= ref.listenManual(dealsProvider, (previous, next) {
      if (next.hasValue) {
        geofencer.startMonitoring(next.value!);
      }
    });

    final currentDeals = ref.read(dealsProvider);
    if (currentDeals.hasValue) {
      await geofencer.startMonitoring(currentDeals.value!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: AppDimensions.md)),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
          sliver: SliverToBoxAdapter(
            child: NavigateCardWidget(
              l10n: l10n,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.xl),
            child: Consumer(
              builder: (context, ref, child) {
                return ref
                    .watch(categoriesProvider)
                    .when(
                      data: (categories) {
                        if (categories.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.lg,
                          ),
                          child: Row(
                            children: [
                              for (
                                var index = 0;
                                index < categories.length;
                                index++
                              ) ...[
                                QuickActionWidget(
                                  icon: categories[index].icon,
                                  label: categories[index].label,
                                  color: categories[index].color,
                                  onTap: () {},
                                ),
                                if (index < categories.length - 1)
                                  const SizedBox(width: AppDimensions.lg),
                              ],
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 85,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    );
              },
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Consumer(
            builder: (context, ref, child) {
              return ref
                  .watch(homeOffersProvider)
                  .when(
                    data: (deals) => DealSectionWidget(
                      title: l10n.bestDealsNearby,
                      icon: Icons.local_offer_rounded,
                      iconColor: Theme.of(context).colorScheme.primary,
                      deals: deals,
                      l10n: l10n,
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppDimensions.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => Center(child: Text(err.toString())),
                  );
            },
          ),
        ),

        SliverToBoxAdapter(
          child: Consumer(
            builder: (context, ref, child) {
              final journeysAsync = ref.watch(homeRecentJourneysProvider);

              return journeysAsync.when(
                data: (journeys) {
                  if (journeys.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: AppDimensions.xl),
                    child: Column(
                      children: [
                        const AppSectionHeader(
                          title: 'Latest Journey',
                          icon: Icons.route_rounded,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.lg,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.lg,
                          ),
                          child: Column(
                            children: journeys
                                .map(
                                  (journey) => JourneyCard(
                                    journey: journey,
                                    compact: true,
                                    onTap: journey.id == null
                                        ? null
                                        : () => context.push(
                                            AppRoutes.journeyDetail.replaceFirst(':id', journey.id!),
                                            extra: journey,
                                          ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }
}
