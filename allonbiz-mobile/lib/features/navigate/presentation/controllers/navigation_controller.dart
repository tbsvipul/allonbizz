import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/models/journey_model.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/services/journey_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/route_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/places_service.dart';
import '../../../../core/utils/background_executor.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/shop.dart';
import '../../../../shared/models/offer.dart';
import '../../../discover/data/repositories/shops_repository.dart';
import '../../../discover/data/repositories/deals_repository.dart';

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

  bool get hasActiveJourney =>
      currentJourneyId != null || isFreeRoam || currentRoute.isNotEmpty;

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
class NavigationController extends Notifier<NavigationState> {
  late RouteService _routeService;
  late DealsRepository _dealsRepository;
  late JourneyService _journeyService;
  late ShopsRepository _shopsRepository;
  late NotificationService _notificationService;
  late StorageService _storageService;
  StreamSubscription<Position>? _liveTrackingSubscription;
  int _nearbyOffersRequestId = 0;
  bool _isDisposed = false;
  LatLng? _lastApiFetchPosition;
  LatLng? _lastProgressSyncPosition;

  @override
  NavigationState build() {
    ref.onDispose(() {
      _isDisposed = true;
      _liveTrackingSubscription?.cancel();
    });
    _routeService = RouteService();
    _dealsRepository = ref.read(dealsRepositoryProvider);
    _journeyService = ref.read(journeyServiceProvider);
    _shopsRepository = ref.read(shopsRepositoryProvider);
    _notificationService = ref.read(notificationServiceProvider);
    _storageService = ref.read(storageServiceProvider);

    Future.microtask(() => restoreActiveJourneyState());
    return NavigationState();
  }

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

  Future<void> restoreActiveJourneyState({bool forceSync = false}) async {
    // PRESERVED: active-journey restore and notification resume must stay in sync
    // with router redirects and persisted session state.
    if (!forceSync) {
      final storedSession = _storageService.activeJourneySession;
      if (storedSession != null) {
        _applyStoredJourneySession(storedSession);
        unawaited(_startLiveJourneyTracking());
        await _notificationService.startJourneyTracking(
          title: _buildActiveJourneyNotificationTitle(state),
          body: _buildActiveJourneyNotificationBody(state),
        );
      }
    }

    final journeys = await _journeyService.fetchUserJourneys(
      useCache: !forceSync,
    );
    JourneyModel? activeJourney;
    for (final journey in journeys) {
      if (!journey.isCompleted) {
        activeJourney = journey;
        break;
      }
    }

    if (activeJourney == null) {
      if (forceSync || !state.hasActiveJourney) {
        await _clearActiveJourneySession();
        if (state.currentRoute.isEmpty) {
          state = state.copyWith(
            currentJourneyId: null,
            destinationName: null,
            origin: null,
            destination: null,
            searchText: null,
            selectedInterests: const <String>[],
            trackedDistanceMeters: 0,
            trackedDurationSeconds: 0,
            lastProgressPosition: null,
            journeyStartedAt: null,
            isFreeRoam: false,
          );
        }
      }
      return;
    }

    _applyJourneyState(
      activeJourney,
      selectedInterests: state.selectedInterests,
      searchText: state.searchText,
      preserveExistingRoute: state.currentJourneyId == activeJourney.id,
    );
    unawaited(_startLiveJourneyTracking());
    await _persistActiveJourneySession();
    await _notificationService.startJourneyTracking(
      title: _buildActiveJourneyNotificationTitle(state),
      body: _buildActiveJourneyNotificationBody(state),
    );
  }

  /// Sets a new [destination] and fetches a route from [origin].
  Future<bool> setDestination(
    LatLng origin,
    LatLng destination,
    String name, {
    String? startName,
    List<Offer>? allOffers,
    List<String> interests = const [],
    String? interestQuery,
  }) async {
    await restoreActiveJourneyState(forceSync: true);
    if (state.hasActiveJourney) {
      state = state.copyWith(
        errorMessage: 'Finish your active journey before starting a new one.',
      );
      return false;
    }

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
        _routeService
            .getRoutePolyline(origin, destination)
            .timeout(
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

      // Bypass route distance filtering so all nearby offers show up on the map
      final List<Offer> filteredOnRoute = _filterOffersLocally(
        offers: offersList,
        query: interestQuery,
      );

      final snappedOrigin = result.points.isNotEmpty
          ? result.points.first
          : origin;
      final snappedDestination = result.points.isNotEmpty
          ? result.points.last
          : destination;
      final startedAt = DateTime.now();
      final journeyId = await _journeyService.startJourney(
        type: JourneyType.destination,
        startLat: snappedOrigin.latitude,
        startLng: snappedOrigin.longitude,
        startName: startName,
        destinationName: name,
        destLat: snappedDestination.latitude,
        destLng: snappedDestination.longitude,
        tags: interests,
      );

      if (journeyId == null) {
        state = NavigationState(
          errorMessage:
              'Unable to save this journey right now. Please try again.',
        );
        return false;
      }

      state = state.copyWith(
        currentRoute: result.points,
        origin: snappedOrigin,
        destination: snappedDestination,
        currentJourneyId: journeyId,
        destinationName: name,
        distanceText: result.distance,
        durationText: result.duration,
        offersOnRoute: filteredOnRoute,
        nearbyShops: _deriveShopsFromOffers(filteredOnRoute),
        isLoading: false,
        isFreeRoam: false,
        selectedInterests: interests,
        searchText: interestQuery,
        trackedDistanceMeters: 0,
        trackedDurationSeconds: 0,
        lastProgressPosition: snappedOrigin,
        journeyStartedAt: startedAt,
        errorMessage: null,
      );

      await _persistActiveJourneySession();
      await _startLiveJourneyTracking();
      await _notificationService.startJourneyTracking(
        title: _buildActiveJourneyNotificationTitle(state),
        body: _buildActiveJourneyNotificationBody(state),
      );
      unawaited(updateNearbyOffers(snappedOrigin));
      return true;
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Start destination journey error',
        error: e,
        stackTrace: stackTrace,
      );
      state = NavigationState(
        errorMessage:
            'Could not start this journey right now. Please try again.',
      );
      return false;
    }
  }

  /// Starts a free roam journey without a destination.
  Future<bool> startFreeRoam({
    List<String> interests = const [],
    String? query,
    LatLng? currentPosition,
  }) async {
    await restoreActiveJourneyState(forceSync: true);
    if (state.hasActiveJourney) {
      state = state.copyWith(
        errorMessage: 'Finish your active journey before starting a new one.',
      );
      return false;
    }

    var effectivePosition = currentPosition;
    if (effectivePosition == null) {
      await ref
          .read(currentLocationProvider.notifier)
          .fetchCurrentLocation(
            requestPermission: true,
            resolvePlaceName: false,
            forceRefresh: true,
          );
      final resolvedPosition = ref.read(currentLocationProvider).position;
      if (resolvedPosition != null) {
        effectivePosition = LatLng(
          resolvedPosition.latitude,
          resolvedPosition.longitude,
        );
      }
    }

    if (effectivePosition == null) {
      state = NavigationState(
        errorMessage: 'Current location is required to start exploring nearby.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      isFreeRoam: false,
      selectedInterests: interests,
      searchText: query,
      origin: effectivePosition,
      destination: null,
      destinationName: null,
      currentRoute: [],
      offersOnRoute: const [],
      nearbyShops: const [],
      distanceText: null,
      durationText: null,
      errorMessage: null,
      trackedDistanceMeters: 0,
      trackedDurationSeconds: 0,
      lastProgressPosition: effectivePosition,
      journeyStartedAt: null,
    );

    try {
      final startedAt = DateTime.now();

      String resolvedStartName = 'Free Roam Start';
      try {
        final suggestion = await ref
            .read(placesServiceProvider)
            .reverseGeocode(
              effectivePosition.latitude,
              effectivePosition.longitude,
            );
        if (suggestion != null && suggestion.name.trim().isNotEmpty) {
          resolvedStartName = suggestion.name.trim();
        }
      } catch (_) {
        // Fallback to default
      }

      final journeyId = await _journeyService.startJourney(
        type: JourneyType.freeRoam,
        startLat: effectivePosition.latitude,
        startLng: effectivePosition.longitude,
        startName: resolvedStartName,
        tags: [...interests, if (query != null && query.isNotEmpty) query],
      );

      if (journeyId == null) {
        state = NavigationState(
          errorMessage:
              'Unable to save this exploration journey right now. Please try again.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isFreeRoam: true,
        currentJourneyId: journeyId,
        journeyStartedAt: startedAt,
        lastProgressPosition: effectivePosition,
      );

      await _persistActiveJourneySession();
      await _startLiveJourneyTracking();
      await _notificationService.startJourneyTracking(
        title: _buildActiveJourneyNotificationTitle(state),
        body: _buildActiveJourneyNotificationBody(state),
      );
      await updateNearbyOffers(effectivePosition);
      return true;
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Start free roam error',
        error: e,
        stackTrace: stackTrace,
      );
      state = NavigationState(
        errorMessage: 'Unable to start exploration right now.',
      );
      return false;
    }
  }

  /// Filters offers based on radius (configurable) and interests.
  Future<void> updateNearbyOffers(LatLng position) async {
    final requestId = ++_nearbyOffersRequestId;
    final buffer = ref.read(discoveryRadiusProvider);
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
    if (_isDisposed || requestId != _nearbyOffersRequestId) {
      return;
    }
    final progressSnapshot = _nextJourneyProgress(position);

    if (state.currentRoute.isNotEmpty && !state.isFreeRoam) {
      // Bypass route distance filtering to match random journey behavior
      final filteredOnRoute = _filterOffersLocally(
        offers: allOffers,
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
      await _syncActiveJourneyTracking();
      _sendJourneyProgress(
        position: position,
        distanceMeters: progressSnapshot.distanceMeters,
        durationSeconds: progressSnapshot.durationSeconds,
      );
      unawaited(_checkAndNotifyNearbyShops(position, routeShops));
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
    if (_isDisposed || requestId != _nearbyOffersRequestId) {
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
    await _syncActiveJourneyTracking();
    _sendJourneyProgress(
      position: position,
      distanceMeters: progressSnapshot.distanceMeters,
      durationSeconds: progressSnapshot.durationSeconds,
    );
    unawaited(_checkAndNotifyNearbyShops(position, nearbyShops));
  }

  Future<void> _checkAndNotifyNearbyShops(
    LatLng currentPosition,
    List<Shop> shops,
  ) async {
    final notifiedTimestamps = _storageService.notifiedShopTimestamps;
    bool hasChanged = false;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Migrate old ones if necessary
    final oldIds = _storageService.notifiedShopIds;
    for (final id in oldIds) {
      if (!notifiedTimestamps.containsKey(id)) {
        notifiedTimestamps[id] = now;
        hasChanged = true;
      }
    }

    for (final shop in shops) {
      if (notifiedTimestamps.containsKey(shop.id)) {
        final lastNotified = notifiedTimestamps[shop.id]!;
        if (now - lastNotified < 86400000) {
          continue;
        }
      }

      final dist = const Distance().as(
        LengthUnit.Meter,
        currentPosition,
        LatLng(shop.latitude, shop.longitude),
      );

      if (dist <= 200) {
        notifiedTimestamps[shop.id] = now;
        hasChanged = true;

        await _notificationService.showNotification(
          id: shop.id.hashCode & 0x7FFFFFFF,
          title: 'Nearby Shop! 🏬',
          body: '${shop.name} is just ${dist.toInt()}m away',
          payload: '/shop-detail/${shop.id}',
        );
      }
    }

    if (hasChanged) {
      _storageService.notifiedShopTimestamps = notifiedTimestamps;
    }
  }

  /// Static helper for Isolate-based filtering to keep main thread responsive.
  static List<Offer> _filterOffersInIsolate({
    required List<Offer> offers,
    String? searchText,
  }) {
    if (searchText == null || searchText.trim().isEmpty) {
      return offers;
    }

    return offers
        .where((offer) {
          return _matchesOfferFilters(
            offer: offer,
            interests: const <String>[],
            query: searchText,
          );
        })
        .toList(growable: false);
  }

  /// Clear current navigation state.
  Future<void> clearRoute({LatLng? endPosition}) async {
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
      final endName = await _resolveJourneyEndName(
        navigationSnapshot,
        finalPosition,
      );
      final ended = await _journeyService.endJourney(
        journeyId: journeyId,
        endLat: finalPosition.latitude,
        endLng: finalPosition.longitude,
        endName: endName,
        finalDistance: finalDistance,
        finalDuration: finalDuration,
        shopsEncountered: _collectEncounteredShops(navigationSnapshot),
      );
      if (!ended) {
        state = state.copyWith(
          errorMessage:
              'Unable to complete the current journey right now. Please try again.',
        );
        return;
      }
    }
    await _stopLiveJourneyTracking();
    await _clearActiveJourneySession();
    _lastApiFetchPosition = null;
    _lastProgressSyncPosition = null;
    state = NavigationState();
  }

  Future<void> _startLiveJourneyTracking() async {
    await _stopLiveJourneyTracking();

    _lastApiFetchPosition = null;
    _lastProgressSyncPosition = null;

    try {
      _liveTrackingSubscription = ref
          .read(locationServiceProvider)
          .getPositionStream(
            distanceFilter: 10,
            accuracy: LocationAccuracy.high,
          )
          .listen(
            (position) {
              if (_isDisposed) return;

              ref.read(currentLocationProvider.notifier).setPosition(position);
              final currentLatLng = LatLng(
                position.latitude,
                position.longitude,
              );

              bool shouldFetchOffers = false;
              if (_lastApiFetchPosition == null) {
                shouldFetchOffers = true;
              } else {
                final dist = const Distance().as(
                  LengthUnit.Meter,
                  _lastApiFetchPosition!,
                  currentLatLng,
                );
                if (dist >= 200) {
                  shouldFetchOffers = true;
                }
              }

              if (shouldFetchOffers) {
                _lastApiFetchPosition = currentLatLng;
                unawaited(updateNearbyOffers(currentLatLng));
              } else {
                _syncProgressLocally(currentLatLng);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              AppLogger.warning(
                'Live journey tracking failed',
                error: error,
                stackTrace: stackTrace,
              );
            },
          );
    } catch (error) {
      AppLogger.warning('Unable to start live journey tracking', error: error);
    }
  }

  void _syncProgressLocally(LatLng position) {
    final progressSnapshot = _nextJourneyProgress(position);
    state = state.copyWith(
      trackedDistanceMeters: progressSnapshot.distanceMeters,
      trackedDurationSeconds: progressSnapshot.durationSeconds,
      lastProgressPosition: progressSnapshot.position,
    );
    unawaited(_syncActiveJourneyTracking());

    bool shouldSyncProgress = false;
    if (_lastProgressSyncPosition == null) {
      shouldSyncProgress = true;
    } else {
      final dist = const Distance().as(
        LengthUnit.Meter,
        _lastProgressSyncPosition!,
        position,
      );
      if (dist >= 100) {
        shouldSyncProgress = true;
      }
    }

    if (shouldSyncProgress) {
      _lastProgressSyncPosition = position;
      _sendJourneyProgress(
        position: position,
        distanceMeters: progressSnapshot.distanceMeters,
        durationSeconds: progressSnapshot.durationSeconds,
      );
    }
  }

  Future<void> _stopLiveJourneyTracking() async {
    await _liveTrackingSubscription?.cancel();
    _liveTrackingSubscription = null;
  }

  void _applyStoredJourneySession(Map<String, dynamic> raw) {
    final journeyId = raw['journeyId']?.toString();
    if (journeyId == null || journeyId.trim().isEmpty) {
      return;
    }

    final origin = _readLatLng(
      latitude: raw['originLat'],
      longitude: raw['originLng'],
    );
    final destination = _readLatLng(
      latitude: raw['destinationLat'],
      longitude: raw['destinationLng'],
    );
    final lastPosition = _readLatLng(
      latitude: raw['lastProgressLat'],
      longitude: raw['lastProgressLng'],
    );

    state = state.copyWith(
      currentJourneyId: journeyId,
      isFreeRoam: raw['isFreeRoam'] == true,
      destinationName: raw['destinationName']?.toString(),
      origin: origin,
      destination: destination,
      searchText: raw['searchText']?.toString(),
      selectedInterests:
          (raw['selectedInterests'] as List<dynamic>?)?.cast<String>() ??
          const [],
      currentRoute: raw['currentRoute'] != null
          ? (raw['currentRoute'] as List<dynamic>).map((p) {
              final map = p as Map;
              return LatLng(
                (map['lat'] as num).toDouble(),
                (map['lng'] as num).toDouble(),
              );
            }).toList()
          : const <LatLng>[],
      trackedDistanceMeters: raw['trackedDistanceMeters'] as double? ?? 0.0,
      trackedDurationSeconds: _readInt(raw['trackedDurationSeconds']),
      lastProgressPosition: lastPosition ?? origin,
      journeyStartedAt: _readDateTime(raw['journeyStartedAt']),
    );
  }

  void _applyJourneyState(
    JourneyModel journey, {
    required List<String> selectedInterests,
    required String? searchText,
    required bool preserveExistingRoute,
  }) {
    final origin = LatLng(journey.startLat, journey.startLng);
    final destination = journey.endLat != null && journey.endLng != null
        ? LatLng(journey.endLat!, journey.endLng!)
        : null;
    final lastPoint = journey.pathPoints.isNotEmpty
        ? LatLng(
            journey.pathPoints.last.latitude,
            journey.pathPoints.last.longitude,
          )
        : origin;

    state = state.copyWith(
      currentJourneyId: journey.id,
      isFreeRoam: journey.type == JourneyType.freeRoam,
      destinationName: preserveExistingRoute && state.destinationName != null
          ? state.destinationName
          : journey.endName ?? journey.startName,
      origin: origin,
      destination: preserveExistingRoute && state.destination != null
          ? state.destination
          : destination,
      currentRoute: preserveExistingRoute
          ? state.currentRoute
          : const <LatLng>[],
      searchText: preserveExistingRoute ? state.searchText : searchText,
      selectedInterests: journey.tags.isNotEmpty
          ? journey.tags
          : selectedInterests,
      trackedDistanceMeters: journey.distance,
      trackedDurationSeconds: journey.duration,
      lastProgressPosition: lastPoint,
      journeyStartedAt: journey.startTimeDate,
      errorMessage: null,
    );
  }

  Future<void> _syncActiveJourneyTracking() async {
    if (!state.hasActiveJourney || state.currentJourneyId == null) {
      return;
    }

    await _persistActiveJourneySession();
    await _notificationService.updateJourneyTracking(
      title: _buildActiveJourneyNotificationTitle(state),
      body: _buildActiveJourneyNotificationBody(state),
    );
  }

  Future<void> _persistActiveJourneySession() async {
    final journeyId = state.currentJourneyId;
    if (journeyId == null || journeyId.trim().isEmpty) {
      await _storageService.clearActiveJourneySession();
      return;
    }

    await _storageService.saveActiveJourneySession({
      'journeyId': journeyId,
      'isFreeRoam': state.isFreeRoam,
      'destinationName': state.destinationName,
      'originLat': state.origin?.latitude,
      'originLng': state.origin?.longitude,
      'destinationLat': state.destination?.latitude,
      'destinationLng': state.destination?.longitude,
      'searchText': state.searchText,
      'selectedInterests': state.selectedInterests,
      'currentRoute': state.currentRoute
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'trackedDistanceMeters': state.trackedDistanceMeters,
      'trackedDurationSeconds': state.trackedDurationSeconds,
      'lastProgressLat': state.lastProgressPosition?.latitude,
      'lastProgressLng': state.lastProgressPosition?.longitude,
      'journeyStartedAt': state.journeyStartedAt?.toIso8601String(),
    });
  }

  Future<void> _clearActiveJourneySession() async {
    await _storageService.clearActiveJourneySession();
    await _notificationService.stopJourneyTracking();
  }

  String _buildActiveJourneyNotificationTitle(NavigationState snapshot) {
    if (snapshot.isFreeRoam) {
      return 'Exploration Active';
    }

    final destinationName = snapshot.destinationName?.trim();
    if (destinationName != null && destinationName.isNotEmpty) {
      return 'Journey to $destinationName';
    }

    return 'Journey Active';
  }

  String _buildActiveJourneyNotificationBody(NavigationState snapshot) {
    final distanceLabel =
        '${(snapshot.trackedDistanceMeters / 1000).toStringAsFixed(1)} km';
    final durationLabel = _formatDurationMinutes(
      snapshot.trackedDurationSeconds,
    );

    if (snapshot.isFreeRoam) {
      return 'Exploring nearby • $distanceLabel • $durationLabel';
    }

    final destinationName = snapshot.destinationName?.trim();
    if (destinationName != null && destinationName.isNotEmpty) {
      return '$destinationName • $distanceLabel • $durationLabel';
    }

    return 'Tracking in progress • $distanceLabel • $durationLabel';
  }

  String _formatDurationMinutes(int seconds) {
    final totalMinutes = (seconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours <= 0) {
      return '$minutes min';
    }

    return '${hours}h ${minutes}m';
  }

  LatLng? _readLatLng({required Object? latitude, required Object? longitude}) {
    final lat = _readDoubleOrNull(latitude);
    final lng = _readDoubleOrNull(longitude);
    if (lat == null || lng == null) {
      return null;
    }

    return LatLng(lat, lng);
  }

  DateTime? _readDateTime(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  double? _readDoubleOrNull(Object? raw) {
    if (raw is num) {
      return raw.toDouble();
    }

    return double.tryParse(raw?.toString() ?? '');
  }

  int _readInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }

    return int.tryParse(raw?.toString() ?? '') ?? 0;
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

    return _dedupeOffers([...apiOffers]);
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
          shopProfileImage: offer.shopProfileImage,
          latitude: offer.latitude,
          longitude: offer.longitude,
          isOpen: offer.shopIsOpen ?? false,
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
      final key = _preferredEncounteredShopLabel(
        name: offer.shopName,
        fallbackId: offer.shopId,
      );
      if (key.isNotEmpty) {
        encountered.add(key);
      }
    }

    for (final shop in snapshot.nearbyShops) {
      final key = _preferredEncounteredShopLabel(
        name: shop.name,
        fallbackId: shop.id,
      );
      if (key.isNotEmpty) {
        encountered.add(key);
      }
    }

    return encountered.toList(growable: false);
  }

  String _preferredEncounteredShopLabel({
    required String? name,
    required String? fallbackId,
  }) {
    final normalizedName = name?.trim() ?? '';
    if (normalizedName.isNotEmpty) {
      final lowerName = normalizedName.toLowerCase();
      if (lowerName != 'unknown shop' && lowerName != 'local shop') {
        return normalizedName;
      }
    }

    return fallbackId?.trim() ?? '';
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
      final currentPos = ref.read(currentLocationProvider).position;
      if (currentPos != null) {
        finalPosition = LatLng(currentPos.latitude, currentPos.longitude);
      }
    }

    finalPosition ??=
        snapshot.lastProgressPosition ??
        snapshot.destination ??
        snapshot.origin;

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

  Future<String> _resolveJourneyEndName(
    NavigationState snapshot,
    LatLng finalPosition,
  ) async {
    if (snapshot.isFreeRoam) {
      try {
        final suggestion = await ref
            .read(placesServiceProvider)
            .reverseGeocode(finalPosition.latitude, finalPosition.longitude);
        if (suggestion != null && suggestion.name.trim().isNotEmpty) {
          return suggestion.name.trim();
        }
      } catch (_) {
        // Fallback
      }
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
    final interestMatch =
        normalizedInterests.isNotEmpty &&
        normalizedInterests.any((interest) {
          return searchTokens.any((token) => token.contains(interest));
        });
    final queryMatch =
        normalizedQuery != null &&
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
    NotifierProvider<NavigationController, NavigationState>(
      NavigationController.new,
    );
