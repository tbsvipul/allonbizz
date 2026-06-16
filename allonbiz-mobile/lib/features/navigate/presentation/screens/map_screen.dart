import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_image.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/network/base_api.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/services/preference_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/offer.dart';
import '../../../../shared/models/shop.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_glass.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../discover/presentation/screens/offer_detail_screen.dart';
import '../../../discover/presentation/screens/shop_detail_screen.dart';
import '../controllers/navigation_controller.dart';

enum _MapMarkerType { shop, offerGroup }

class _MapMarkerEntry {
  const _MapMarkerEntry.shop(this.shop)
    : offers = const <Offer>[],
      type = _MapMarkerType.shop;

  const _MapMarkerEntry.offerGroup(this.offers, {this.shop})
    : type = _MapMarkerType.offerGroup;

  final _MapMarkerType type;
  final Shop? shop;
  final List<Offer> offers;
}

final mapMarkerEntriesProvider = Provider<List<_MapMarkerEntry>>((ref) {
  final nearbyOffers = ref.watch(
    navigationControllerProvider.select((state) => state.offersOnRoute),
  );
  final nearbyShops = ref.watch(
    navigationControllerProvider.select((state) => state.nearbyShops),
  );

  return _buildMarkerEntries(
    nearbyOffers: nearbyOffers,
    nearbyShops: nearbyShops,
  );
});

/// Navigate / Map Screen.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _defaultCenter = LatLng(19.0760, 72.8777);
  static const _defaultZoom = 13.0;

  late final MapController _mapController;
  ProviderSubscription<String?>? _errorSubscription;
  ProviderSubscription<Position?>? _locationSubscription;
  ProviderSubscription<int>? _recenterSubscription;
  ProviderSubscription<Offer?>? _selectedOfferSubscription;
  ProviderSubscription<Shop?>? _selectedShopSubscription;
  String? _lastCameraKey;
  bool _isOffersExpanded = false;
  final Set<String> _deselectedTags = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _bindListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locationState = ref.read(currentLocationProvider);
      if (locationState.position == null && !locationState.isLoading) {
        unawaited(
          ref
              .read(currentLocationProvider.notifier)
              .fetchCurrentLocation(
                requestPermission: false,
                resolvePlaceName: false,
              ),
        );
      } else if (locationState.position != null) {
        // Trigger discovery if location is already available
        final navState = ref.read(navigationControllerProvider);
        if (navState.currentRoute.isEmpty && !navState.isFreeRoam) {
          ref
              .read(navigationControllerProvider.notifier)
              .updateNearbyOffers(
                LatLng(
                  locationState.position!.latitude,
                  locationState.position!.longitude,
                ),
              );
        }
      }
    });
  }

  void _bindListeners() {
    _errorSubscription = ref.listenManual(
      navigationControllerProvider.select((state) => state.errorMessage),
      (previous, next) {
        if (next != null && mounted) {
          AppSnackbar.show(context, message: next, type: AppSnackbarType.error);
        }
      },
    );

    _locationSubscription = ref.listenManual(
      currentLocationProvider.select((state) => state.position),
      (previous, next) {
        final navigationState = ref.read(navigationControllerProvider);
        if (next != null &&
            !navigationState.isLoading &&
            !navigationState.hasActiveJourney) {
          ref
              .read(navigationControllerProvider.notifier)
              .updateNearbyOffers(LatLng(next.latitude, next.longitude));
        }
      },
    );

    _recenterSubscription = ref.listenManual(mapRecenterTriggerProvider, (
      previous,
      next,
    ) {
      final currentLocation = ref.read(currentLocationProvider).position;
      if (next == previous || currentLocation == null) {
        return;
      }
      _mapController.move(
        LatLng(currentLocation.latitude, currentLocation.longitude),
        15,
      );
    });

    _selectedOfferSubscription = ref.listenManual(
      navigationControllerProvider.select((state) => state.selectedOffer),
      (previous, next) {
        if (next != null) {
          _showOfferDetail(next);
        }
      },
    );

    _selectedShopSubscription = ref.listenManual(
      navigationControllerProvider.select((state) => state.selectedShop),
      (previous, next) {
        if (next != null) {
          _showShopDetailSheet(next.id);
        }
      },
    );
  }

  @override
  void dispose() {
    _errorSubscription?.close();
    _locationSubscription?.close();
    _recenterSubscription?.close();
    _selectedOfferSubscription?.close();
    _selectedShopSubscription?.close();
    _mapController.dispose();
    super.dispose();
  }

  void _syncCamera(List<LatLng> route, LatLng? focusPoint) {
    final nextKey = route.length >= 2
        ? '${route.first.latitude},${route.first.longitude}-'
              '${route.last.latitude},${route.last.longitude}-${route.length}'
        : '${focusPoint?.latitude},${focusPoint?.longitude}';

    if (_lastCameraKey == nextKey) return;
    _lastCameraKey = nextKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        if (route.length >= 2) {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(route),
              padding: const EdgeInsets.all(56),
            ),
          );
        } else if (focusPoint != null) {
          _mapController.move(focusPoint, 15);
        }
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Camera sync failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final route = ref.watch(
      navigationControllerProvider.select((state) => state.currentRoute),
    );

    final origin = ref.watch(
      navigationControllerProvider.select((state) => state.origin),
    );
    final destination = ref.watch(
      navigationControllerProvider.select((state) => state.destination),
    );
    final isJourneyActive = ref.watch(
      navigationControllerProvider.select((state) => state.hasActiveJourney),
    );
    final nearbyOffers = ref.watch(
      navigationControllerProvider.select((state) => state.offersOnRoute),
    );
    final selectedInterests = ref.watch(
      navigationControllerProvider.select((state) => state.selectedInterests),
    );
    final markerEntries = ref.watch(mapMarkerEntriesProvider);
    final currentLocation = ref.watch(
      currentLocationProvider.select((state) => state.position),
    );

    final currentPoint = currentLocation != null
        ? LatLng(currentLocation.latitude, currentLocation.longitude)
        : null;

    final mapFocus = origin ?? currentPoint ?? _defaultCenter;
    final hasActiveRoute = route.length >= 2 && destination != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navClearance = 30 + bottomInset;

    _syncCamera(route, mapFocus);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapFocus,
              initialZoom: _defaultZoom,
              maxZoom: 18.4,
              minZoom: 3.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-90, -180),
                  const LatLng(90, 180),
                ),
              ),
              onTap: (tapPosition, point) => FocusScope.of(context).unfocus(),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? BaseApi.darkTileUrl
                    : BaseApi.lightTileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.routent.locator',
                maxZoom: 19,
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              if (route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 9,
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                    Polyline(
                      points: route,
                      strokeWidth: 5,
                      color: AppColors.primary,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              if (isJourneyActive)
                MarkerLayer(
                  markers: [
                    ..._buildStaticMarkers(
                      markerEntries: markerEntries,
                      ref: ref,
                    ),
                    if (destination != null)
                      Marker(
                        point: destination,
                        width: 48,
                        height: 48,
                        alignment: Alignment.topCenter,
                        child:
                            Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.accent,
                                  size: 48,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.black.withValues(
                                        alpha: 0.38,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: -0.3),
                      ),
                  ],
                ),
              UserLocationMarkerLayer(hasActiveRoute: hasActiveRoute),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomRight,
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          EtaOverlayWidget(topPadding: topPadding),
          Positioned(
            right: AppDimensions.lg,
            bottom: AppDimensions.lg + navClearance,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.add_rounded,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                ),
                const SizedBox(height: AppDimensions.sm),
                _MapControlButton(
                  icon: Icons.remove_rounded,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                ),
                const SizedBox(height: AppDimensions.md),
                _MapControlButton(
                  icon: Icons.my_location_rounded,
                  color: AppColors.primary,
                  onPressed: () async {
                    if (currentPoint != null) {
                      _mapController.move(currentPoint, 15);
                    }
                    await ref
                        .read(currentLocationProvider.notifier)
                        .fetchCurrentLocation(
                          requestPermission: true,
                          resolvePlaceName: false,
                          forceRefresh: true,
                        );
                    final updatedState = ref.read(currentLocationProvider);
                    if (updatedState.position != null) {
                      _mapController.move(
                        LatLng(
                          updatedState.position!.latitude,
                          updatedState.position!.longitude,
                        ),
                        15,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          if (isJourneyActive && nearbyOffers.isNotEmpty && _isOffersExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isOffersExpanded = false),
                child: Container(color: Colors.transparent),
              ),
            ),

          if (isJourneyActive && nearbyOffers.isNotEmpty)
            Positioned(
              left: AppDimensions.md,
              bottom: AppDimensions.lg + navClearance,
              child: _buildOffersOverlay(
                context,
                nearbyOffers,
                selectedInterests,
              ),
            ),
        ],
      ),
    );
  }

  void _showOfferDetail(Offer offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.28),
      builder: (context) => _DraggableDetailSheet(
        childBuilder: (scrollController) => OfferDetailScreen(
          initialOffer: offer,
          isSheet: true,
          scrollController: scrollController,
        ),
      ),
    ).whenComplete(() {
      ref.read(navigationControllerProvider.notifier).selectOffer(null);
    });
  }

  Widget _buildOffersOverlay(
    BuildContext context,
    List<Offer> offers,
    List<String> userTags,
  ) {
    final activeTags = userTags
        .where((t) => !_deselectedTags.contains(t))
        .toList();

    var filteredOffers = offers;
    if (userTags.isNotEmpty) {
      filteredOffers = offers.where((offer) {
        if (offer.tags.isEmpty) return true;
        if (activeTags.isEmpty) return false;
        return offer.tags.any((t) => activeTags.contains(t));
      }).toList();
    }

    final sortedOffers = List<Offer>.from(filteredOffers);
    sortedOffers.sort((a, b) {
      final aMatches = a.tags.where((t) => activeTags.contains(t)).length;
      final bMatches = b.tags.where((t) => activeTags.contains(t)).length;
      return bMatches.compareTo(aMatches);
    });

    if (!_isOffersExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isOffersExpanded = true),
        child: GlassmorphicContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        duration: 1200.ms,
                        begin: const Offset(1, 1),
                        end: const Offset(2.5, 2.5),
                      )
                      .fadeOut(duration: 1200.ms),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Text(
                'OFFERS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.8, 0.8));
    }

    return GlassmorphicContainer(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Exclusive Offers',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.grey500,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            setState(() => _isOffersExpanded = false),
                      ),
                    ),
                  ],
                ),
              ),
              if (userTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: userTags.map((tag) {
                        final isSelected = !_deselectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _deselectedTags.add(tag);
                              } else {
                                _deselectedTags.remove(tag);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.grey400.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.grey600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                  itemCount: sortedOffers.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildOfferCard(sortedOffers[index], activeTags);
                  },
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildOfferCard(Offer offer, List<String> userTags) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTagKeys = userTags.map(_tagKey).toSet();
    final offerTags = _dedupeTags(offer.tags);
    final visibleTags = offerTags.take(4).toList(growable: false);

    return AppCard(
      onTap: () => _showOfferDetail(offer),
      padding: const EdgeInsets.all(12),
      elevation: 3,
      borderColor: colorScheme.primary.withValues(alpha: 0.16),
      gradient: LinearGradient(
        colors: [
          colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.74 : 0.70,
          ),
          colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.08),
          colorScheme.primaryContainer.withValues(alpha: isDark ? 0.08 : 0.14),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 80,
              height: 80,
              child:
                  (offer.imageUrl != null && offer.imageUrl!.trim().isNotEmpty)
                  ? AppImage.network(
                      offer.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: _buildOfferPlaceholder(),
                    )
                  : (offer.shopProfileImage != null &&
                        offer.shopProfileImage!.trim().isNotEmpty)
                  ? AppImage.network(
                      offer.shopProfileImage!,
                      fit: BoxFit.cover,
                      errorWidget: _buildOfferPlaceholder(),
                    )
                  : _buildOfferPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        offer.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.secondary,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            offer.rating != null
                                ? offer.rating!.toStringAsFixed(1)
                                : '0.0',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  offer.shopName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (visibleTags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...visibleTags.map(
                        (tag) => _buildRouteTagChip(
                          context,
                          tag,
                          isHighlighted:
                              activeTagKeys.isEmpty ||
                              activeTagKeys.contains(_tagKey(tag)),
                        ),
                      ),
                      if (offerTags.length > 4)
                        _buildRouteTagCountChip(context, offerTags.length - 4),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tagKey(String tag) => tag.trim().toLowerCase();

  List<String> _dedupeTags(Iterable<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final tag in tags) {
      final normalized = tag.trim();
      if (normalized.isEmpty) continue;
      if (seen.add(_tagKey(normalized))) {
        result.add(normalized);
      }
    }
    return result;
  }

  Widget _buildRouteTagChip(
    BuildContext context,
    String tag, {
    required bool isHighlighted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isHighlighted
        ? (isDark ? AppColors.secondaryLight : colorScheme.primary)
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: isDark ? 0.32 : 0.18),
                  colorScheme.primaryContainer.withValues(
                    alpha: isDark ? 0.20 : 0.24,
                  ),
                ],
              )
            : null,
        color: isHighlighted
            ? null
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isHighlighted ? colorScheme.primary : colorScheme.outline)
              .withValues(alpha: isHighlighted ? 0.26 : 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHighlighted ? Icons.sell_rounded : Icons.tag_rounded,
            size: 11,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTagCountChip(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildOfferPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: const Icon(
          Icons.shopping_cart_outlined,
          color: AppColors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showShopDetailSheet(String? shopId) {
    if (shopId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.28),
      builder: (context) => _DraggableDetailSheet(
        childBuilder: (scrollController) => ShopDetailScreen(
          shopId: shopId,
          isSheet: true,
          scrollController: scrollController,
        ),
      ),
    ).whenComplete(() {
      ref.read(navigationControllerProvider.notifier).selectShop(null);
    });
  }
}

class _DraggableDetailSheet extends StatelessWidget {
  const _DraggableDetailSheet({required this.childBuilder});

  static const double _initialSize = 0.92;
  static const double _minSize = 0.34;

  final Widget Function(ScrollController scrollController) childBuilder;

  @override
  Widget build(BuildContext context) {
    var hasDismissed = false;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (!hasDismissed &&
            notification.extent <= _minSize + 0.01 &&
            Navigator.of(context).canPop()) {
          hasDismissed = true;
          Navigator.of(context).pop();
        }
        return false;
      },
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: _initialSize,
        minChildSize: _minSize,
        maxChildSize: _initialSize,
        snap: true,
        snapSizes: const [_minSize, _initialSize],
        builder: (context, scrollController) {
          return GlassmorphicContainer(
            opacity: 0.97,
            blur: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: childBuilder(scrollController),
            ),
          );
        },
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassmorphicContainer(
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: color ?? colorScheme.onSurface, size: 24),
        ),
      ),
    );
  }
}

List<Marker> _buildStaticMarkers({
  required List<_MapMarkerEntry> markerEntries,
  required WidgetRef ref,
}) {
  final markers = <Marker>[];
  for (final entry in markerEntries) {
    if (entry.type == _MapMarkerType.shop) {
      final shop = entry.shop!;
      markers.add(
        Marker(
          point: LatLng(shop.latitude, shop.longitude),
          width: 60,
          height: 60,
          child: _MapPin(
            color: _shopMarkerColor(shop),
            imageUrl: shop.primaryImageUrl,
            fallbackIcon: Icons.storefront_rounded,
            onTap: () {
              ref
                  .read(navigationControllerProvider.notifier)
                  .selectShop(shop.id);
            },
          ),
        ),
      );
      continue;
    }

    final groupedOffers = entry.offers;
    final firstOffer = groupedOffers.first;
    final matchedShop = entry.shop;
    final markerColor = matchedShop != null
        ? _shopMarkerColor(matchedShop)
        : _offerMarkerColor(firstOffer);
    final markerImageUrl =
        matchedShop?.primaryImageUrl ?? firstOffer.shopProfileImage;
    final fallbackIcon = matchedShop != null
        ? Icons.storefront_rounded
        : Icons.local_offer_rounded;

    markers.add(
      Marker(
        point: LatLng(firstOffer.latitude, firstOffer.longitude),
        width: 60,
        height: 60,
        child: _MapPin(
          color: markerColor,
          imageUrl: markerImageUrl,
          fallbackIcon: fallbackIcon,
          onTap: () {
            if (matchedShop != null) {
              ref
                  .read(navigationControllerProvider.notifier)
                  .selectShop(matchedShop.id);
              return;
            }
            if (groupedOffers.length > 1) {
              ref
                  .read(navigationControllerProvider.notifier)
                  .selectShop(firstOffer.shopId);
            } else {
              ref
                  .read(navigationControllerProvider.notifier)
                  .selectOffer(firstOffer);
            }
          },
        ),
      ),
    );
  }

  return markers;
}

List<_MapMarkerEntry> _buildMarkerEntries({
  required List<Offer> nearbyOffers,
  required List<Shop> nearbyShops,
}) {
  final shopGroups = <String, List<Offer>>{};
  for (final offer in nearbyOffers) {
    final key = offer.shopId ?? offer.shopName;
    shopGroups.putIfAbsent(key, () => <Offer>[]).add(offer);
  }
  final shopsById = <String, Shop>{
    for (final shop in nearbyShops)
      if (shop.id.trim().isNotEmpty) shop.id.trim(): shop,
  };
  final shopsByName = <String, Shop>{
    for (final shop in nearbyShops)
      if (shop.name.trim().isNotEmpty) shop.name.trim().toLowerCase(): shop,
  };

  final markers = <_MapMarkerEntry>[];
  for (final shop in nearbyShops) {
    final shopId = shop.id.trim();
    if (shopId.isEmpty || (shop.latitude == 0 && shop.longitude == 0)) {
      continue;
    }
    if (shopGroups.containsKey(shopId) && shopGroups[shopId]!.isNotEmpty) {
      continue;
    }
    markers.add(_MapMarkerEntry.shop(shop));
  }

  for (final group in shopGroups.entries) {
    final offers = group.value;
    if (offers.isEmpty) {
      continue;
    }
    final matchedShop =
        shopsById[group.key] ??
        shopsByName[offers.first.shopName.trim().toLowerCase()];
    markers.add(_MapMarkerEntry.offerGroup(offers, shop: matchedShop));
  }

  return markers;
}

Color _shopMarkerColor(Shop shop) {
  return shop.isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
}

Color _offerMarkerColor(Offer offer) {
  final isOpen = offer.shopIsOpen;
  if (isOpen == null) {
    return AppColors.accent;
  }
  return isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.color,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.onTap,
  });

  final Color color;
  final String? imageUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 3.1415926535897932 / 4,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23),
                  bottomLeft: Radius.circular(23),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? AppImage.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: Center(
                      child: Icon(fallbackIcon, color: color, size: 20),
                    ),
                  )
                : Center(child: Icon(fallbackIcon, color: color, size: 20)),
          ),
        ],
      ),
    );
  }
}

class UserLocationMarkerLayer extends ConsumerWidget {
  final bool hasActiveRoute;

  const UserLocationMarkerLayer({super.key, required this.hasActiveRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.watch(
      currentLocationProvider.select((state) => state.position),
    );
    final markerName = ref.watch(locationMarkerProvider);

    if (currentLocation == null) return const SizedBox.shrink();

    final currentPoint = LatLng(
      currentLocation.latitude,
      currentLocation.longitude,
    );

    return MarkerLayer(
      markers: [
        Marker(
          point: currentPoint,
          width: 60,
          height: 60,
          child: markerName == 'ripple'
              ? RepaintBoundary(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!hasActiveRoute) ...[
                        for (int i = 0; i < 3; i++)
                          Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .scale(
                                delay: (i * 700).ms,
                                duration: 2100.ms,
                                begin: const Offset(1, 1),
                                end: const Offset(3.0, 3.0),
                                curve: Curves.decelerate,
                              )
                              .fadeOut(
                                delay: (i * 700).ms,
                                duration: 2100.ms,
                                curve: Curves.decelerate,
                              ),
                      ],
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Image.asset(
                  'assets/images/location_marker/$markerName',
                  width: 60,
                  height: 60,
                ),
        ),
      ],
    );
  }
}

class EtaOverlayWidget extends ConsumerWidget {
  final double topPadding;

  const EtaOverlayWidget({super.key, required this.topPadding});

  String _buildEtaText(
    AppLocalizations l10n, {
    required bool isLoading,
    required bool hasActiveRoute,
    required String? duration,
    required String? distance,
  }) {
    if (isLoading) return l10n.calculatingRoute;
    if (hasActiveRoute) {
      return '${duration ?? '--- min'} \u2022 ${distance ?? '--- km'}';
    }
    return l10n.tapSearchRoute;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(
      navigationControllerProvider.select((state) => state.currentRoute),
    );
    final isLoading = ref.watch(
      navigationControllerProvider.select((state) => state.isLoading),
    );
    final destinationName = ref.watch(
      navigationControllerProvider.select((state) => state.destinationName),
    );
    final destination = ref.watch(
      navigationControllerProvider.select((state) => state.destination),
    );
    final distance = ref.watch(
      navigationControllerProvider.select((state) => state.distanceText),
    );
    final duration = ref.watch(
      navigationControllerProvider.select((state) => state.durationText),
    );
    final isFreeRoam = ref.watch(
      navigationControllerProvider.select((state) => state.isFreeRoam),
    );
    final isJourneyActive = ref.watch(
      navigationControllerProvider.select((state) => state.hasActiveJourney),
    );
    final selectedInterests = ref.watch(
      navigationControllerProvider.select((state) => state.selectedInterests),
    );
    final searchText = ref.watch(
      navigationControllerProvider.select((state) => state.searchText),
    );

    final hasActiveRoute = route.length >= 2 && destination != null;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: topPadding + AppDimensions.sm,
      left: AppDimensions.md,
      right: AppDimensions.md,
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        elevation: 2,
        shadowColor: AppColors.black.withValues(alpha: 0.12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: () => context.push(AppRoutes.search),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    isLoading
                        ? Icons.hourglass_bottom_rounded
                        : isJourneyActive
                        ? Icons.directions_walk_rounded
                        : Icons.navigation_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildEtaText(
                          l10n,
                          isLoading: isLoading,
                          hasActiveRoute: hasActiveRoute,
                          duration: duration,
                          distance: distance,
                        ),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark ? AppColors.white : AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isFreeRoam)
                        Text(
                          [
                                if (selectedInterests.isNotEmpty)
                                  selectedInterests.join(', '),
                                if (searchText != null) '"$searchText"',
                              ].join(' • ').isEmpty
                              ? 'Exploring Nearby'
                              : 'Nearby: ${[if (selectedInterests.isNotEmpty) selectedInterests.join(', '), if (searchText != null) '"$searchText"'].join(' • ')}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (isJourneyActive && !hasActiveRoute)
                        Text(
                          destinationName?.isNotEmpty == true
                              ? 'Active journey in progress'
                              : 'Journey tracking is active',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (destinationName != null &&
                          destinationName.isNotEmpty)
                        Text(
                          destinationName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.2),
    );
  }
}
