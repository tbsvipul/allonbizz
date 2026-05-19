import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/network/base_api.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/offer.dart';
import '../../../../shared/models/shop.dart';
import '../../../discover/presentation/screens/offer_detail_screen.dart';
import '../../../discover/presentation/screens/shop_detail_screen.dart';
import '../controllers/navigation_controller.dart';
import '../../../../shared/widgets/app_button.dart';

/// Navigate / Map Screen.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _defaultCenter = LatLng(19.0760, 72.8777);
  static const _defaultZoom = 13.0;

  late final MapController _mapController;
  String? _lastCameraKey;
  bool _isOffersExpanded = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationState = ref.read(currentLocationProvider);
      if (locationState.position == null && !locationState.isLoading) {
        unawaited(
          ref.read(currentLocationProvider.notifier).fetchCurrentLocation(
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

  @override
  void dispose() {
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
      } catch (_) {
        // Ignore camera sync errors caused by transient map lifecycle timing.
      }
    });
  }

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
  Widget build(BuildContext context) {
    super.build(context);
    final route = ref.watch(
      navigationControllerProvider.select((state) => state.currentRoute),
    );
    final isLoading = ref.watch(
      navigationControllerProvider.select((state) => state.isLoading),
    );
    final destinationName = ref.watch(
      navigationControllerProvider.select((state) => state.destinationName),
    );
    final origin = ref.watch(
      navigationControllerProvider.select((state) => state.origin),
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
      navigationControllerProvider.select(
        (state) => state.isFreeRoam || state.currentRoute.isNotEmpty,
      ),
    );
    final selectedInterests = ref.watch(
      navigationControllerProvider.select((state) => state.selectedInterests),
    );
    final searchText = ref.watch(
      navigationControllerProvider.select((state) => state.searchText),
    );
    final nearbyOffers = ref.watch(
      navigationControllerProvider.select((state) => state.offersOnRoute),
    );
    final nearbyShops = ref.watch(
      navigationControllerProvider.select((state) => state.nearbyShops),
    );
    final currentLocation = ref.watch(
      currentLocationProvider.select((state) => state.position),
    );

    ref.listen(
      navigationControllerProvider.select((state) => state.errorMessage),
          (previous, next) {
        if (next != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    ref.listen(currentLocationProvider.select((state) => state.position), (
        previous,
        next,
        ) {
      if (next != null && !isLoading && !isJourneyActive) {
        ref
            .read(navigationControllerProvider.notifier)
            .updateNearbyOffers(LatLng(next.latitude, next.longitude));
      }
    });

    final currentPoint = currentLocation != null
        ? LatLng(currentLocation.latitude, currentLocation.longitude)
        : null;

    ref.listen(mapRecenterTriggerProvider, (prev, next) {
      if (next != prev && currentPoint != null) {
        _mapController.move(currentPoint, 15);
      }
    });

    ref.listen(navigationControllerProvider.select((s) => s.selectedOffer), (prev, next) {
      if (next != null) {
        _showOfferDetail(next);
      }
    });

    ref.listen(navigationControllerProvider.select((s) => s.selectedShop), (prev, next) {
      if (next != null) {
        _showShopDetailSheet(next.id);
      }
    });

    final mapFocus = origin ?? currentPoint ?? _defaultCenter;
    final hasActiveRoute = route.length >= 2 && destination != null;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

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
                userAgentPackageName: 'com.allonbiz.locator',
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
              MarkerLayer(
                markers: _buildMarkers(
                  currentPoint: currentPoint,
                  origin: origin,
                  destination: destination,
                  isFreeRoam: isFreeRoam,
                  hasActiveRoute: hasActiveRoute,
                  nearbyOffers: nearbyOffers,
                  nearbyShops: nearbyShops,
                  ref: ref,
                ),
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomRight,
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),
        Positioned(
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
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Icon(
                        isLoading
                            ? Icons.hourglass_bottom_rounded
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
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.grey900,
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
        ),
        Positioned(
          right: AppDimensions.lg,
          bottom: 120,
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
                  await ref.read(currentLocationProvider.notifier).fetchCurrentLocation(
                    requestPermission: true,
                    resolvePlaceName: false,
                    forceRefresh: true,
                  );
                  final updatedState = ref.read(currentLocationProvider);
                  if (updatedState.position != null) {
                    _mapController.move(
                      LatLng(updatedState.position!.latitude, updatedState.position!.longitude),
                      15,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        if (nearbyOffers.isNotEmpty && _isOffersExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isOffersExpanded = false),
              child: Container(color: Colors.transparent),
            ),
          ),

        if (nearbyOffers.isNotEmpty)
          Positioned(
            left: AppDimensions.md,
            bottom: 120,
            child: _buildOffersOverlay(context, nearbyOffers),
          ),

        Positioned(
          left: AppDimensions.lg,
          right: AppDimensions.lg,
          bottom: AppDimensions.lg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasActiveRoute || isFreeRoam)
                AppButton.danger(
                  label: isFreeRoam ? 'End Exploration' : l10n.endJourney,
                  onPressed: () {
                    ref
                        .read(navigationControllerProvider.notifier)
                        .clearRoute();
                  },
                  icon: Icons.close_rounded,
                  width: 180,
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
            ],
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardDark
              : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: OfferDetailScreen(initialOffer: offer, isSheet: true),
        ),
      ),
    );
  }

  Widget _buildOffersOverlay(BuildContext context, List<Offer> offers) {
    if (!_isOffersExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isOffersExpanded = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE8F5E9), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                      color: const Color(0xFF00C853).withValues(alpha: 0.5),
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
                      color: Color(0xFF00C853),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Text(
                'OFFERS',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
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

    return Container(
      width: MediaQuery.of(context).size.width * 0.72,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xff57b32c), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Text(
                  'Exclusive Offers',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _isOffersExpanded = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: offers.length,
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildOfferCard(offers[index]);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildOfferCard(Offer offer) {
    return InkWell(
      onTap: () => _showOfferDetail(offer),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xff57b32c), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 22 / 10,
                child: offer.imageUrl != null && offer.imageUrl!.isNotEmpty
                    ? Image.network(
                  offer.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildOfferPlaceholder(),
                )
                    : _buildOfferPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      offer.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '5',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, color: Colors.orange.shade800, size: 32),
            const SizedBox(height: 4),
            Text(
              'Online Shopping',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShopDetailSheet(String? shopId) {
    if (shopId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardDark
              : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ShopDetailScreen(shopId: shopId),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: AppColors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: color ?? (isDark ? AppColors.white : AppColors.grey800),
            size: 24,
          ),
        ),
      ),
    );
  }
}


List<Marker> _buildMarkers({
  required LatLng? currentPoint,
  required LatLng? origin,
  required LatLng? destination,
  required bool isFreeRoam,
  required bool hasActiveRoute,
  required List<Offer> nearbyOffers,
  required List<Shop> nearbyShops,
  required WidgetRef ref,
}) {
  final markers = <Marker>[];

  if (currentPoint != null) {
    markers.add(
      Marker(
        point: currentPoint,
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!hasActiveRoute) ...[
              for (int i = 0; i < 3; i++)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
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
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (origin != null && origin != currentPoint) {
    markers.add(
      Marker(
        point: origin,
        width: 24,
        height: 24,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
          ),
        ),
      ),
    );
  }

  if (destination != null) {
    markers.add(
      Marker(
        point: destination,
        width: 36,
        height: 44,
        child: const Icon(
          Icons.location_on_rounded,
          color: AppColors.error,
          size: 36,
        ),
      ),
    );
  }

  final shopMarkerIds = <String>{};
  for (final shop in nearbyShops) {
    final shopId = shop.id.trim();
    if (shopId.isEmpty) {
      continue;
    }
    if (shop.latitude == 0 && shop.longitude == 0) {
      continue;
    }

    shopMarkerIds.add(shopId);
    markers.add(
      Marker(
        point: LatLng(shop.latitude, shop.longitude),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () {
            ref.read(navigationControllerProvider.notifier).selectShop(shop.id);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.storefront_rounded,
                color: AppColors.accent,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  final Map<String, List<Offer>> shopGroups = {};
  for (final offer in nearbyOffers) {
    final key = offer.shopId ?? offer.shopName;
    shopGroups.putIfAbsent(key, () => []).add(offer);
  }

  for (final entry in shopGroups.entries) {
    final groupedOffers = entry.value;
    final firstOffer = groupedOffers.first;
    final shopId = firstOffer.shopId?.trim();

    if (shopId != null && shopId.isNotEmpty && shopMarkerIds.contains(shopId)) {
      continue;
    }

    markers.add(
      Marker(
        point: LatLng(firstOffer.latitude, firstOffer.longitude),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () {
            if (groupedOffers.length > 1) {
              ref.read(navigationControllerProvider.notifier).selectShop(firstOffer.shopId);
            } else {
              ref.read(navigationControllerProvider.notifier).selectOffer(firstOffer);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: firstOffer.shopId != null ? AppColors.accent : AppColors.primary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                firstOffer.shopId != null ? Icons.storefront_rounded : Icons.local_offer_rounded,
                color: firstOffer.shopId != null ? AppColors.accent : AppColors.primary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  return markers;
}
