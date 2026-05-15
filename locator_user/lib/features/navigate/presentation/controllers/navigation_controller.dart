import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/route_service.dart';
import '../../../../shared/models/offer.dart';
import '../../../discover/data/repositories/deals_repository.dart';
import '../../../../core/services/journey_service.dart';
import '../../../../core/models/journey_model.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/utils/background_executor.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/shop.dart';
import '../../../discover/data/repositories/shops_repository.dart';

/// State of the navigation feature.
class NavigationState {
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
  final bool isOffersSheetOpen;

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
    this.isOffersSheetOpen = false,
  });

  NavigationState copyWith({
    List<LatLng>? currentRoute,
    List<Offer>? offersOnRoute,
    bool? isLoading,
    String? destinationName,
    LatLng? origin,
    LatLng? destination,
    String? errorMessage,
    String? distanceText,
    String? durationText,
    bool? isFreeRoam,
    List<String>? selectedInterests,
    String? searchText,
    String? currentJourneyId,
    Shop? selectedShop,
    Offer? selectedOffer,
    bool? isOffersSheetOpen,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      offersOnRoute: offersOnRoute ?? this.offersOnRoute,
      isLoading: isLoading ?? this.isLoading,
      destinationName: destinationName ?? this.destinationName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      errorMessage: errorMessage ?? this.errorMessage,
      distanceText: distanceText ?? this.distanceText,
      durationText: durationText ?? this.durationText,
      isFreeRoam: isFreeRoam ?? this.isFreeRoam,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      searchText: searchText ?? this.searchText,
      currentJourneyId: currentJourneyId ?? this.currentJourneyId,
      selectedShop: selectedShop ?? this.selectedShop,
      selectedOffer: selectedOffer ?? this.selectedOffer,
      isOffersSheetOpen: isOffersSheetOpen ?? this.isOffersSheetOpen,
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
        _buildOfferPool(origin),
      ]);

      final result = results[0] as RouteResult;
      final offersList = allOffers ?? (results[1] as List<Offer>);

      final onRoute = await _routeService.getOffersAlongRoute(
        result.points,
        offersList,
        bufferDistance: buffer,
      );

      // Filter on-route offers by interests/query
      final List<Offer> filteredOnRoute = _filterOffersLocally(
        offers: onRoute,
        interests: interests,
        query: interestQuery,
      );

      final snappedOrigin = result.points.isNotEmpty ? result.points.first : origin;
      final snappedDestination = result.points.isNotEmpty ? result.points.last : destination;

      state = state.copyWith(
        currentRoute: result.points,
        origin: snappedOrigin,        // Snapped to road network
        destination: snappedDestination, // Snapped to road network
        distanceText: result.distance,
        durationText: result.duration,
        offersOnRoute: filteredOnRoute,
        isLoading: false,
      );

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
      destination: null,
      destinationName: null,
      currentRoute: [],
      errorMessage: null,
    );

    if (currentPosition != null) {
      unawaited(_journeyService.startJourney(
        type: JourneyType.freeRoam,
        startLat: currentPosition.latitude,
        startLng: currentPosition.longitude,
        startName: 'Free Roam Start',
        tags: [...interests, if (query != null && query.isNotEmpty) query],
      ).then((journeyId) {
        if (mounted) {
          state = state.copyWith(currentJourneyId: journeyId);
        }
      }));

      await updateNearbyOffers(currentPosition);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Filters offers based on radius (configurable) and interests.
  Future<void> updateNearbyOffers(LatLng position) async {
    final buffer = _ref.read(discoveryRadiusProvider);
    final allOffers = await _buildOfferPool(position);

    if (state.currentRoute.isNotEmpty && !state.isFreeRoam) {
      final onRoute = await _routeService.getOffersAlongRoute(
        state.currentRoute,
        allOffers,
        bufferDistance: buffer,
      );

      state = state.copyWith(
        offersOnRoute: _filterOffersLocally(
          offers: onRoute,
          interests: state.selectedInterests,
          query: state.searchText,
        ),
        isLoading: false,
      );
      return;
    }

    final List<Offer> filtered = await runInBackground(() {
      return _filterOffersInIsolate(
        offers: allOffers,
        position: position,
        buffer: buffer,
        selectedInterests: state.selectedInterests,
        searchText: state.searchText,
      );
    });

    state = state.copyWith(offersOnRoute: filtered, isLoading: false);
  }

  /// Static helper for Isolate-based filtering to keep main thread responsive.
  static List<Offer> _filterOffersInIsolate({
    required List<Offer> offers,
    required LatLng position,
    required double buffer,
    required List<String> selectedInterests,
    String? searchText,
  }) {
    final List<Offer> filtered = [];
    final routeService = RouteService();

    for (final offer in offers) {
      final distance = routeService.calculateDistance(
        position.latitude,
        position.longitude,
        offer.latitude,
        offer.longitude,
      );

      if (distance > buffer) continue;

      bool matches = true;
      if (selectedInterests.isNotEmpty ||
          (searchText != null && searchText.isNotEmpty)) {
        matches = _matchesOfferFilters(
          offer: offer,
          interests: selectedInterests,
          query: searchText,
        );
      }

      if (matches) {
        filtered.add(offer);
      }
    }
    return filtered;
  }

  /// Clear current navigation state.
  void clearRoute({LatLng? endPosition}) {
    final journeyId = state.currentJourneyId;
    if (journeyId != null) {
      LatLng? finalPos = endPosition;
      if (finalPos == null) {
        final currentPos = _ref.read(currentLocationProvider).position;
        if (currentPos != null) {
          finalPos = LatLng(currentPos.latitude, currentPos.longitude);
        }
      }

      if (finalPos != null) {
        _journeyService.endJourney(
          journeyId: journeyId,
          endLat: finalPos.latitude,
          endLng: finalPos.longitude,
          endName: state.isFreeRoam ? 'Free Roam End' : state.destinationName,
        );
      }
    }
    state = NavigationState();
  }

  /// Helper to filter offers by interests and query locally.
  List<Offer> _filterOffersLocally({
    required List<Offer> offers,
    required List<String> interests,
    String? query,
  }) {
    if (interests.isEmpty && (query == null || query.isEmpty)) return offers;

    return offers.where((offer) {
      return _matchesOfferFilters(
        offer: offer,
        interests: interests,
        query: query,
      );
    }).toList();
  }

  Future<List<Offer>> _buildOfferPool(LatLng anchor) async {
    List<Offer> apiOffers = const [];
    try {
      apiOffers = await _dealsRepository
          .getOffers(lat: anchor.latitude, lng: anchor.longitude)
          .first;
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
}

/// Configurable discovery radius in meters.
final discoveryRadiusProvider = StateProvider<double>(
  (ref) => 1000.0,
); // 1km default

/// Signal provider used by external navigation widgets without direct MapController access to command a physical camera repositioning back to the user's current GPS coordinates.
final mapRecenterTriggerProvider = StateProvider<int>((ref) => 0);

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
