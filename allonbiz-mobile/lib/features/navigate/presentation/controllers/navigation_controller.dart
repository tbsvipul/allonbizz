import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/route_service.dart';
import '../../../../shared/models/offer.dart';
import '../../../discover/data/repositories/deals_repository.dart';
import '../../../../core/services/journey_service.dart';
import '../../../../core/models/journey_model.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/background_executor.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/shop.dart';
import '../../../discover/data/repositories/shops_repository.dart';

/// State of the navigation feature.
class NavigationState {
  static const Object _unset = Object();

  final List<LatLng> currentRoute;
  final List<Offer> offersOnRoute;
  final bool isLoading;
  final String? destinationName;
  final LatLng? origin;
  final LatLng? destination;
  final String? errorMessage;

  final String? distanceText;
  final String? durationText;
  final bool isFreeRoam;
  final List<String> selectedInterests;
  final String? searchText;
  final String? currentJourneyId;
  final Shop? selectedShop;
  final Offer? selectedOffer;
  final List<Shop> nearbyShops;
  final bool isOffersSheetOpen;
  final double trackedDistanceMeters;
  final int trackedDurationSeconds;
  final LatLng? lastProgressPosition;
  final DateTime? journeyStartedAt;

  NavigationState({
    this.currentRoute = const [],
    this.offersOnRoute = const [],
    this.isLoading = false,
    this.destinationName,
    this.origin,
    this.destination,
    this.errorMessage,
    this.distanceText,
    this.durationText,
    this.isFreeRoam = false,
    this.selectedInterests = const [],
    this.searchText,
    this.currentJourneyId,
    this.selectedShop,
    this.selectedOffer,
    this.nearbyShops = const [],
    this.isOffersSheetOpen = false,
    this.trackedDistanceMeters = 0,
    this.trackedDurationSeconds = 0,
    this.lastProgressPosition,
    this.journeyStartedAt,
  });

  NavigationState copyWith({
    List<LatLng>? currentRoute,
    List<Offer>? offersOnRoute,
    bool? isLoading,
    Object? destinationName = _unset,
    Object? origin = _unset,
    Object? destination = _unset,
    Object? errorMessage = _unset,
    Object? distanceText = _unset,
    Object? durationText = _unset,
    bool? isFreeRoam,
    List<String>? selectedInterests,
    Object? searchText = _unset,
    Object? currentJourneyId = _unset,
    Object? selectedShop = _unset,
    Object? selectedOffer = _unset,
    List<Shop>? nearbyShops,
    bool? isOffersSheetOpen,
    double? trackedDistanceMeters,
    int? trackedDurationSeconds,
    Object? lastProgressPosition = _unset,
    Object? journeyStartedAt = _unset,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      offersOnRoute: offersOnRoute ?? this.offersOnRoute,
      isLoading: isLoading ?? this.isLoading,
      destinationName: identical(destinationName, _unset)
          ? this.destinationName
          : destinationName as String?,
      origin: identical(origin, _unset) ? this.origin : origin as LatLng?,
      destination: identical(destination, _unset)
          ? this.destination
          : destination as LatLng?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      distanceText: identical(distanceText, _unset)
          ? this.distanceText
          : distanceText as String?,
      durationText: identical(durationText, _unset)
          ? this.durationText
          : durationText as String?,
      isFreeRoam: isFreeRoam ?? this.isFreeRoam,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      searchText: identical(searchText, _unset)
          ? this.searchText
          : searchText as String?,
      currentJourneyId: identical(currentJourneyId, _unset)
          ? this.currentJourneyId
          : currentJourneyId as String?,
      selectedShop: identical(selectedShop, _unset)
          ? this.selectedShop
          : selectedShop as Shop?,
      selectedOffer: identical(selectedOffer, _unset)
          ? this.selectedOffer
          : selectedOffer as Offer?,
      nearbyShops: nearbyShops ?? this.nearbyShops,
      isOffersSheetOpen: isOffersSheetOpen ?? this.isOffersSheetOpen,
      trackedDistanceMeters:
          trackedDistanceMeters ?? this.trackedDistanceMeters,
      trackedDurationSeconds:
          trackedDurationSeconds ?? this.trackedDurationSeconds,
      lastProgressPosition: identical(lastProgressPosition, _unset)
          ? this.lastProgressPosition
          : lastProgressPosition as LatLng?,
      journeyStartedAt: identical(journeyStartedAt, _unset)
          ? this.journeyStartedAt
          : journeyStartedAt as DateTime?,
    );
  }
}

/// Controller for navigation logic and map data.
class NavigationController extends StateNotifier<NavigationState> {
  final RouteService _routeService;
  final DealsRepository _dealsRepository;
  final JourneyService _journeyService;
  final ShopsRepository _shopsRepository;
  final Ref _ref;
  StreamSubscription<Position>? _liveTrackingSubscription;
  int _nearbyOffersRequestId = 0;

  NavigationController(
    this._routeService,
    this._dealsRepository,
    this._journeyService,
    this._shopsRepository,
    this._ref,
  ) : super(NavigationState());

  void selectOffer(Offer? offer) {
    state = state.copyWith(
      selectedOffer: offer,
      selectedShop: null,
      isOffersSheetOpen: offer != null,
    );
  }

  Future<void> selectShop(String? shopId) async {
    if (shopId == null) {
      state = state.copyWith(selectedShop: null);
      return;
    }

    state = state.copyWith(isLoading: true);
    final shop = await _shopsRepository.getShopDetail(shopId);
    state = state.copyWith(
      selectedShop: shop,
      selectedOffer: null,
      isLoading: false,
    );
  }

  void toggleOffersSheet(bool open) {
    state = state.copyWith(isOffersSheetOpen: open);
  }

  /// Sets a new [destination] and fetches a route from [origin].
  Future<void> setDestination(
    LatLng origin,
    LatLng destination,
    String name, {
    String? startName,
    List<Offer>? allOffers,
    List<String> interests = const [],
    String? interestQuery,
  }) async {
    final buffer = _ref.read(discoveryRadiusProvider);
    state = state.copyWith(
      isLoading: true,
      destinationName: name,
      origin: origin,
      destination: destination,
      errorMessage: null,
      isFreeRoam: false,
      selectedInterests: interests,
      searchText: interestQuery,
      trackedDistanceMeters: 0,
      trackedDurationSeconds: 0,
      lastProgressPosition: origin,
      journeyStartedAt: DateTime.now(),
    );

    try {
      // Parallelize route fetching and offer pooling
      final results = await Future.wait([
        _routeService.getRoutePolyline(origin, destination).timeout(
          const Duration(seconds: 15),
          onTimeout: () => RouteResult(
            points: _routeService.getFallbackPath(origin, destination),
            distance: '--- km',
            duration: '--- min',
          ),
        ),
        _buildOfferPool(origin, interests: interests),
      ]);

      final result = results[0] as RouteResult;
      final offersList = allOffers ?? (results[1] as List<Offer>);

      final onRoute = await _routeService.getOffersAlongRoute(
        result.points,
        offersList,
        bufferDistance: buffer,
      );

      // Interest/tag filtering is handled by the API; keep only query refinement here.
      final List<Offer> filteredOnRoute = _filterOffersLocally(
        offers: onRoute,
        query: interestQuery,
      );

      final snappedOrigin = result.points.isNotEmpty ? result.points.first : origin;
      final snappedDestination = result.points.isNotEmpty ? result.points.last : destination;

      state = state.copyWith(
        currentRoute: result.points,
        origin: snappedOrigin,
        destination: snappedDestination,
        distanceText: result.distance,
        durationText: result.duration,
        offersOnRoute: filteredOnRoute,
        nearbyShops: _deriveShopsFromOffers(filteredOnRoute),
        isLoading: false,
      );

      _startLiveJourneyTracking();

      // Start journey via API asynchronously without blocking UI update
      unawaited(_journeyService.startJourney(
        type: JourneyType.destination,
        startLat: snappedOrigin.latitude,
        startLng: snappedOrigin.longitude,
        startName: startName,
        destinationName: name,
        destLat: snappedDestination.latitude,
        destLng: snappedDestination.longitude,
        tags: interests,
      ).then((journeyId) {
        if (mounted) {
          state = state.copyWith(currentJourneyId: journeyId);
          if (journeyId != null) {
            unawaited(updateNearbyOffers(snappedOrigin));
          }
        }
      }).catchError((e) {
        debugPrint('Failed to start journey on backend: $e');
      }));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not calculate route. Using visual fallback.',
        distanceText: '--- km',
        durationText: '--- min',
      );
    }
  }

  /// Starts a free roam journey without a destination.
  Future<void> startFreeRoam({
    List<String> interests = const [],
    String? query,
    LatLng? currentPosition,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isFreeRoam: true,
      selectedInterests: interests,
      searchText: query,
      origin: currentPosition,
      destination: null,
      destinationName: null,
      currentRoute: [],
      nearbyShops: const [],
      errorMessage: null,
      trackedDistanceMeters: 0,
      trackedDurationSeconds: 0,
      lastProgressPosition: currentPosition,
      journeyStartedAt: DateTime.now(),
    );

    if (currentPosition != null) {
      _startLiveJourneyTracking();
      unawaited(_journeyService.startJourney(
        type: JourneyType.freeRoam,
        startLat: currentPosition.latitude,
        startLng: currentPosition.longitude,
        startName: 'Free Roam Start',
        tags: [...interests, if (query != null && query.isNotEmpty) query],
      ).then((journeyId) {
        if (mounted) {
          state = state.copyWith(currentJourneyId: journeyId);
          if (journeyId != null) {
            unawaited(updateNearbyOffers(currentPosition));
          }
        }
      }));

      await updateNearbyOffers(currentPosition);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Filters offers based on radius (configurable) and interests.
  Future<void> updateNearbyOffers(LatLng position) async {
    final requestId = ++_nearbyOffersRequestId;
    final buffer = _ref.read(discoveryRadiusProvider);
    final selectedInterests = List<String>.from(state.selectedInterests);
    final searchText = state.searchText;
    final isFreeRoam = state.isFreeRoam;
    final journeyId = state.currentJourneyId;
    final effectiveRadiusKm = ((buffer / 1000).clamp(2.0, 5.0)).toDouble();
    final nearbyShopsFuture = journeyId != null
        ? _journeyService.getNearbyShops(
            journeyId: journeyId,
            lat: position.latitude,
            lng: position.longitude,
            radiusKm: effectiveRadiusKm,
          )
        : Future<List<Shop>>.value(const <Shop>[]);
    final results = await Future.wait<Object>([
      _buildOfferPool(
        position,
        interests: selectedInterests,
        radiusKm: isFreeRoam ? effectiveRadiusKm : null,
      ),
      nearbyShopsFuture,
    ]);
    final allOffers = results[0] as List<Offer>;
    final nearbyShops = _mergeNearbyShops(
      derivedShops: _deriveShopsFromOffers(allOffers),
      apiShops: results[1] as List<Shop>,
    );
    if (!mounted || requestId != _nearbyOffersRequestId) {
      return;
    }
    final progressSnapshot = _nextJourneyProgress(position);

    if (state.currentRoute.isNotEmpty && !state.isFreeRoam) {
      final onRoute = await _routeService.getOffersAlongRoute(
        state.currentRoute,
        allOffers,
        bufferDistance: buffer,
      );
      if (!mounted || requestId != _nearbyOffersRequestId) {
        return;
      }

      final filteredOnRoute = _filterOffersLocally(
        offers: onRoute,
        query: searchText,
      );
      final routeShops = _mergeNearbyShops(
        derivedShops: _deriveShopsFromOffers(filteredOnRoute),
        apiShops: nearbyShops,
      );
      state = state.copyWith(
        offersOnRoute: filteredOnRoute,
        nearbyShops: routeShops,
        isLoading: false,
        trackedDistanceMeters: progressSnapshot.distanceMeters,
        trackedDurationSeconds: progressSnapshot.durationSeconds,
        lastProgressPosition: progressSnapshot.position,
      );
      _sendJourneyProgress(
        position: position,
        distanceMeters: progressSnapshot.distanceMeters,
        durationSeconds: progressSnapshot.durationSeconds,
      );
      return;
    }

    final List<Offer> filtered =
        searchText != null && searchText.trim().isNotEmpty
        ? await runInBackground(() {
            return _filterOffersInIsolate(
              offers: allOffers,
              searchText: searchText,
            );
          })
        : allOffers;
    if (!mounted || requestId != _nearbyOffersRequestId) {
      return;
    }

    state = state.copyWith(
      offersOnRoute: filtered,
      nearbyShops: nearbyShops,
      isLoading: false,
      trackedDistanceMeters: progressSnapshot.distanceMeters,
      trackedDurationSeconds: progressSnapshot.durationSeconds,
      lastProgressPosition: progressSnapshot.position,
    );
    _sendJourneyProgress(
      position: position,
      distanceMeters: progressSnapshot.distanceMeters,
      durationSeconds: progressSnapshot.durationSeconds,
    );
  }

  /// Static helper for Isolate-based filtering to keep main thread responsive.
  static List<Offer> _filterOffersInIsolate({
    required List<Offer> offers,
    String? searchText,
  }) {
    if (searchText == null || searchText.trim().isEmpty) {
      return offers;
    }

    return offers.where((offer) {
      return _matchesOfferFilters(
        offer: offer,
        interests: const <String>[],
        query: searchText,
      );
    }).toList(growable: false);
  }

  /// Clear current navigation state.
  void clearRoute({LatLng? endPosition}) {
    final journeyId = state.currentJourneyId;
    final navigationSnapshot = state;
    final progressSnapshot = _resolveFinalProgressSnapshot(
      navigationSnapshot,
      explicitEndPosition: endPosition,
    );
    final finalPosition = progressSnapshot.position;
    final finalDistance = _resolveFinalDistanceMeters(
      navigationSnapshot,
      finalPosition,
      progressSnapshot.distanceMeters,
    );
    final finalDuration = _resolveFinalDurationSeconds(
      navigationSnapshot,
      progressSnapshot.durationSeconds,
    );

    if (journeyId != null) {
      unawaited(
        _journeyService.endJourney(
          journeyId: journeyId,
          endLat: finalPosition.latitude,
          endLng: finalPosition.longitude,
          endName: _resolveJourneyEndName(navigationSnapshot),
          finalDistance: finalDistance,
          finalDuration: finalDuration,
          shopsEncountered: _collectEncounteredShops(navigationSnapshot),
        ),
      );
    }
    unawaited(_stopLiveJourneyTracking());
    state = NavigationState();
  }

  Future<void> _startLiveJourneyTracking() async {
    await _stopLiveJourneyTracking();

    try {
      _liveTrackingSubscription = _ref
          .read(locationServiceProvider)
          .getPositionStream(
            distanceFilter: 10,
            accuracy: LocationAccuracy.high,
          )
          .listen(
            (position) {
              if (!mounted) return;

              _ref.read(currentLocationProvider.notifier).setPosition(position);
              unawaited(
                updateNearbyOffers(
                  LatLng(position.latitude, position.longitude),
                ),
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Live journey tracking failed: $error');
            },
          );
    } catch (error) {
      debugPrint('Unable to start live journey tracking: $error');
    }
  }

  Future<void> _stopLiveJourneyTracking() async {
    await _liveTrackingSubscription?.cancel();
    _liveTrackingSubscription = null;
  }

  /// Query-only refinement. Interest/tag filtering is handled by the API.
  List<Offer> _filterOffersLocally({
    required List<Offer> offers,
    String? query,
  }) {
    if (query == null || query.isEmpty) return offers;

    return offers.where((offer) {
      return _matchesOfferFilters(
        offer: offer,
        interests: const <String>[],
        query: query,
      );
    }).toList();
  }

  Future<List<Offer>> _buildOfferPool(
    LatLng anchor, {
    List<String> interests = const [],
    double? radiusKm,
  }) async {
    List<Offer> apiOffers = const [];
    try {
      apiOffers = await _dealsRepository.fetchOffers(
        lat: anchor.latitude,
        lng: anchor.longitude,
        radiusKm: radiusKm,
        tags: interests,
      );
    } catch (_) {
      apiOffers = const [];
    }

    return _dedupeOffers([
      ...apiOffers,
    ]);
  }

  List<Offer> _dedupeOffers(List<Offer> offers) {
    final ids = <String>{};
    return offers.where((offer) => ids.add(offer.id)).toList();
  }

  List<Shop> _deriveShopsFromOffers(List<Offer> offers) {
    final shopsById = <String, Shop>{};

    for (final offer in offers) {
      final shopId = offer.shopId?.trim();
      if (shopId == null || shopId.isEmpty) {
        continue;
      }

      shopsById.putIfAbsent(
        shopId,
        () => Shop(
          id: shopId,
          name: offer.shopName,
          address: offer.shopAddress,
          imageUrl: offer.imageUrl,
          latitude: offer.latitude,
          longitude: offer.longitude,
        ),
      );
    }

    return shopsById.values.toList(growable: false);
  }

  List<Shop> _mergeNearbyShops({
    required List<Shop> derivedShops,
    required List<Shop> apiShops,
  }) {
    final shopsById = <String, Shop>{};

    for (final shop in derivedShops) {
      final shopId = shop.id.trim();
      if (shopId.isEmpty) {
        continue;
      }
      shopsById[shopId] = shop;
    }

    for (final shop in apiShops) {
      final shopId = shop.id.trim();
      if (shopId.isEmpty) {
        continue;
      }
      shopsById[shopId] = shop;
    }

    return shopsById.values.toList(growable: false);
  }

  List<String> _collectEncounteredShops(NavigationState snapshot) {
    final encountered = <String>{};

    for (final offer in snapshot.offersOnRoute) {
      final key = (offer.shopId ?? offer.shopName).trim();
      if (key.isNotEmpty) {
        encountered.add(key);
      }
    }

    for (final shop in snapshot.nearbyShops) {
      final key = (shop.id.isNotEmpty ? shop.id : shop.name).trim();
      if (key.isNotEmpty) {
        encountered.add(key);
      }
    }

    return encountered.toList(growable: false);
  }

  _JourneyProgressSnapshot _nextJourneyProgress(LatLng position) {
    final startedAt = state.journeyStartedAt;
    final lastPosition = state.lastProgressPosition;
    var distanceMeters = state.trackedDistanceMeters;

    if (lastPosition != null) {
      final segmentDistance = _routeService.calculateDistance(
        lastPosition.latitude,
        lastPosition.longitude,
        position.latitude,
        position.longitude,
      );
      if (segmentDistance.isFinite && segmentDistance > 3) {
        distanceMeters += segmentDistance;
      }
    }

    final durationSeconds = startedAt == null
        ? state.trackedDurationSeconds
        : DateTime.now().difference(startedAt).inSeconds;

    return _JourneyProgressSnapshot(
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      position: position,
    );
  }

  _JourneyProgressSnapshot _resolveFinalProgressSnapshot(
    NavigationState snapshot, {
    LatLng? explicitEndPosition,
  }) {
    LatLng? finalPosition = explicitEndPosition;

    if (finalPosition == null) {
      final currentPos = _ref.read(currentLocationProvider).position;
      if (currentPos != null) {
        finalPosition = LatLng(currentPos.latitude, currentPos.longitude);
      }
    }

    finalPosition ??=
        snapshot.lastProgressPosition ?? snapshot.destination ?? snapshot.origin;

    if (finalPosition == null) {
      return _JourneyProgressSnapshot(
        distanceMeters: snapshot.trackedDistanceMeters,
        durationSeconds: snapshot.trackedDurationSeconds,
        position: snapshot.origin ?? const LatLng(0, 0),
      );
    }

    return _nextJourneyProgress(finalPosition);
  }

  double _resolveFinalDistanceMeters(
    NavigationState snapshot,
    LatLng? finalPosition,
    double candidateDistance,
  ) {
    var effectiveDistance = candidateDistance > 0
        ? candidateDistance
        : snapshot.trackedDistanceMeters;

    if (effectiveDistance > 0) {
      return effectiveDistance;
    }

    if (!snapshot.isFreeRoam && snapshot.currentRoute.length >= 2) {
      final routeDistance = _estimatePolylineDistance(snapshot.currentRoute);
      if (routeDistance > 0) {
        return routeDistance;
      }
    }

    if (snapshot.origin != null && finalPosition != null) {
      final directDistance = _routeService.calculateDistance(
        snapshot.origin!.latitude,
        snapshot.origin!.longitude,
        finalPosition.latitude,
        finalPosition.longitude,
      );
      if (directDistance.isFinite && directDistance > 3) {
        return directDistance;
      }
    }

    return 0;
  }

  int _resolveFinalDurationSeconds(
    NavigationState snapshot,
    int candidateDuration,
  ) {
    if (candidateDuration > 0) {
      return candidateDuration;
    }

    if (snapshot.trackedDurationSeconds > 0) {
      return snapshot.trackedDurationSeconds;
    }

    if (snapshot.journeyStartedAt != null) {
      final elapsed = DateTime.now()
          .difference(snapshot.journeyStartedAt!)
          .inSeconds;
      if (elapsed > 0) {
        return elapsed;
      }
    }

    return 0;
  }

  double _estimatePolylineDistance(List<LatLng> points) {
    var distanceMeters = 0.0;

    for (var index = 1; index < points.length; index++) {
      distanceMeters += _routeService.calculateDistance(
        points[index - 1].latitude,
        points[index - 1].longitude,
        points[index].latitude,
        points[index].longitude,
      );
    }

    return distanceMeters;
  }

  String _resolveJourneyEndName(NavigationState snapshot) {
    if (snapshot.isFreeRoam) {
      return 'Free Roam End';
    }

    final destinationName = snapshot.destinationName?.trim();
    if (destinationName != null && destinationName.isNotEmpty) {
      return destinationName;
    }

    final searchText = snapshot.searchText?.trim();
    if (searchText != null && searchText.isNotEmpty) {
      return searchText;
    }

    return 'Destination';
  }

  void _sendJourneyProgress({
    required LatLng position,
    required double distanceMeters,
    required int durationSeconds,
  }) {
    final journeyId = state.currentJourneyId;
    if (journeyId == null) return;

    unawaited(
      _journeyService.updateJourneyProgress(
        journeyId: journeyId,
        currentLat: position.latitude,
        currentLng: position.longitude,
        distance: distanceMeters,
        duration: durationSeconds,
        shopsEncountered: _collectEncounteredShops(state),
      ),
    );
  }

  static bool _matchesOfferFilters({
    required Offer offer,
    required List<String> interests,
    String? query,
  }) {
    final normalizedInterests = interests
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toList();
    final normalizedQuery = query?.trim().toLowerCase();
    final searchTokens = <String>[
      offer.title,
      offer.description,
      offer.category,
      offer.shopName,
      offer.shopAddress ?? '',
      ...offer.tags,
    ].map((value) => value.toLowerCase()).toList();
    final interestMatch = normalizedInterests.isNotEmpty &&
        normalizedInterests.any((interest) {
          return searchTokens.any((token) => token.contains(interest));
        });
    final queryMatch = normalizedQuery != null &&
        normalizedQuery.isNotEmpty &&
        searchTokens.any((token) => token.contains(normalizedQuery));

    if (normalizedInterests.isNotEmpty && normalizedQuery != null) {
      return interestMatch || queryMatch;
    }
    if (normalizedInterests.isNotEmpty) {
      return interestMatch;
    }
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      return queryMatch;
    }
    return true;
  }

  @override
  void dispose() {
    _liveTrackingSubscription?.cancel();
    super.dispose();
  }
}

/// Configurable discovery radius in meters.
final discoveryRadiusProvider = StateProvider<double>(
  (ref) => 1000.0,
); // 1km default

/// Signal provider used by external navigation widgets without direct MapController access to command a physical camera repositioning back to the user's current GPS coordinates.
final mapRecenterTriggerProvider = StateProvider<int>((ref) => 0);

class _JourneyProgressSnapshot {
  const _JourneyProgressSnapshot({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.position,
  });

  final double distanceMeters;
  final int durationSeconds;
  final LatLng position;
}

/// Navigation status provider.
final navigationControllerProvider =
    StateNotifierProvider<NavigationController, NavigationState>((ref) {
      return NavigationController(
    RouteService(),
    ref.read(dealsRepositoryProvider),
    ref.read(journeyServiceProvider),
    ref.read(shopsRepositoryProvider),
    ref,
  );
});
