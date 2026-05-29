import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';

/// State for the current user location.
class CurrentLocationState {
  static const Object _unset = Object();

  final Position? position;
  final String? placeName;
  final bool isLoading;
  final String? errorMessage;

  const CurrentLocationState({
    this.position,
    this.placeName,
    this.isLoading = false,
    this.errorMessage,
  });

  CurrentLocationState copyWith({
    Object? position = _unset,
    Object? placeName = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return CurrentLocationState(
      position: identical(position, _unset)
          ? this.position
          : position as Position?,
      placeName: identical(placeName, _unset)
          ? this.placeName
          : placeName as String?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// Provider to manage the user's current GPS location and its geocoded address.
class CurrentLocationNotifier extends StateNotifier<CurrentLocationState> {
  final LocationService _locationService;
  final Ref _ref;

  CurrentLocationNotifier(this._locationService, this._ref)
    : super(const CurrentLocationState());

  /// Fetches the user's current GPS coordinates and reverse-geocodes them.
  Future<void> fetchCurrentLocation({
    bool requestPermission = true,
    bool resolvePlaceName = true,
    bool forceRefresh = false,
  }) async {
    // Avoid redundant fetches if already loading
    if (state.isLoading) return;
    if (!forceRefresh &&
        state.position != null &&
        (!resolvePlaceName || (state.placeName?.trim().isNotEmpty ?? false))) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final position = await _locationService.getCurrentPosition(
        requestPermission: requestPermission,
        preferLastKnown: !forceRefresh,
      );

      if (position != null) {
        state = state.copyWith(
          position: position,
          isLoading: resolvePlaceName,
          errorMessage: null,
        );

        if (!resolvePlaceName) {
          state = state.copyWith(isLoading: false);
          return;
        }

        unawaited(_resolvePlaceName(position));
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: requestPermission ? 'Could not access location' : null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: requestPermission
            ? 'Unable to fetch your current location right now.'
            : null,
      );
    }
  }

  Future<void> _resolvePlaceName(Position position) async {
    String placeName = state.placeName ?? 'My Location';

    try {
      final suggestion = await _ref
          .read(placesServiceProvider)
          .reverseGeocode(position.latitude, position.longitude);
      if (suggestion != null) {
        placeName = suggestion.name;
      }
    } catch (_) {
      // Keep the current fallback label when reverse geocoding fails.
    }

    if (!mounted) return;

    state = state.copyWith(
      position: position,
      placeName: placeName,
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Manually update the place name (e.g. if the user picks a specific spot).
  void updatePlaceName(String name) {
    state = state.copyWith(placeName: name);
  }

  /// Push a live GPS position update without triggering reverse geocoding.
  void setPosition(Position position, {String? placeName}) {
    state = state.copyWith(
      position: position,
      placeName: placeName ?? state.placeName,
      isLoading: false,
      errorMessage: null,
    );
  }
}

/// Global provider for CurrentLocationState.
final currentLocationProvider =
    StateNotifierProvider<CurrentLocationNotifier, CurrentLocationState>((ref) {
      final locationService = ref.watch(locationServiceProvider);
      return CurrentLocationNotifier(locationService, ref);
    });
