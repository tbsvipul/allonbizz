import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/offer.dart';
import '../widgets/home_offers_section.dart';
import '../widgets/home_recent_journeys_section.dart';
import '../widgets/navigate_card_widget.dart';

/// Home screen - Tab 1.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  ProviderSubscription<AsyncValue<List<Offer>>>? _dealsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();

      final locationState = ref.read(currentLocationProvider);
      if (locationState.position == null && !locationState.isLoading) {
        unawaited(
          ref
              .read(currentLocationProvider.notifier)
              .fetchCurrentLocation(requestPermission: true),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(currentLocationProvider.notifier)
          .fetchCurrentLocation(
            requestPermission: false,
            resolvePlaceName: false,
            forceRefresh: true,
          );
    }
  }

  Future<void> _requestPermissions() async {
    // Request notification and base location permissions together
    await [Permission.notification, Permission.location].request();

    // If location is granted, request background location for tracking
    if (await Permission.location.isGranted) {
      await Permission.locationAlways.request();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dealsSubscription?.close();
    super.dispose();
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
        SliverToBoxAdapter(child: HomeOffersSection(l10n: l10n)),
        SliverToBoxAdapter(child: const HomeRecentJourneysSection()),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: 178 + MediaQuery.of(context).padding.bottom,
          ),
        ),
      ],
    );
  }
}
