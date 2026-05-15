import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';

/// State for the current user location.
class CurrentLocationState {
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
    Position? position,
    String? placeName,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CurrentLocationState(
      position: position ?? this.position,
      placeName: placeName ?? this.placeName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
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
  Future<void> fetchCurrentLocation() async {
    // Avoid redundant fetches if already loading
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        // Reverse geocode via Photon API
        String placeName = 'My Location';
        try {
          final suggestion = await _ref
              .read(placesServiceProvider)
              .reverseGeocode(position.latitude, position.longitude);
          if (suggestion != null) {
            placeName = suggestion.name;
          }
        } catch (_) {
          // Fallback to "My Location" if reverse geocoding fails
        }

        state = CurrentLocationState(
          position: position,
          placeName: placeName,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Could not access location',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Manually update the place name (e.g. if the user picks a specific spot).
  void updatePlaceName(String name) {
    state = state.copyWith(placeName: name);
  }
}

/// Global provider for CurrentLocationState.
final currentLocationProvider =
    StateNotifierProvider<CurrentLocationNotifier, CurrentLocationState>((ref) {
      final locationService = ref.watch(locationServiceProvider);
      return CurrentLocationNotifier(locationService, ref);
    });
