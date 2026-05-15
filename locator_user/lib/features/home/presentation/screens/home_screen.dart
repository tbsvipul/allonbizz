import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/services/discovery_service.dart';
import 'package:locator/l10n/app_localizations.dart';
import '../../data/repositories/home_repository.dart';
import '../../../discover/data/repositories/deals_repository.dart';
import '../widgets/quick_action_widget.dart';
import '../widgets/navigate_card_widget.dart';
import '../widgets/deal_section_widget.dart';
import '../../../../core/services/preference_providers.dart';

/// Home screen – Tab 1.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGeofencing();
      ref.read(currentLocationProvider.notifier).fetchCurrentLocation();
    });
  }

  Future<void> _initGeofencing() async {
    final isTrackingEnabled = ref.read(locationTrackingEnabledProvider);
    if (!isTrackingEnabled) return;

    final geofencer = ref.read(geofenceServiceProvider);

    // Listen to real deals for geofencing
    ref.listenManual(dealsProvider, (previous, next) {
      if (next.hasValue) {
        geofencer.startMonitoring(next.value!);
      }
    });

    // Initial start if already loaded
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

        // ── Navigate Card ──────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
          sliver: SliverToBoxAdapter(
            child: NavigateCardWidget(
              l10n: l10n,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ),
        ),

        // ── Quick Actions ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.xl),
            child: Consumer(
              builder: (context, ref, child) {
                return ref.watch(categoriesProvider).when(
                  data: (categories) {
                    final quickActions = categories.take(4).toList();
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.lg,
                      ),
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < quickActions.length;
                            index++
                          ) ...[
                            QuickActionWidget(
                              icon: quickActions[index].icon,
                              label: quickActions[index].label,
                              color: quickActions[index].color,
                              onTap: () {},
                            ),
                            if (index < quickActions.length - 1)
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

        // ── Best Deals Nearby ──────────────────────────────────
        SliverToBoxAdapter(
          child: Consumer(
            builder: (context, ref, child) {
              return ref.watch(homeOffersProvider).when(
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

        // ── Spacing for floaters ──────────────────────────────
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }
}
