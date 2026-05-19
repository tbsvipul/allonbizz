import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper around the Geolocator package for location services.
class LocationService {
  /// Check if location services are enabled and permissions granted.
  Future<bool> checkPermission({bool requestIfNeeded = false}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (requestIfNeeded && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// Request location permission explicitly.
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  Future<Position?> getLastKnownPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Get current position.
  Future<Position?> getCurrentPosition({
    bool requestPermission = true,
    bool preferLastKnown = true,
  }) async {
    try {
      final hasPermission = await checkPermission(
        requestIfNeeded: requestPermission,
      );
      if (!hasPermission) return null;

      if (preferLastKnown) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return lastKnown;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Balanced for battery
          distanceFilter: 25, // Reduce UI jitter
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Stream position updates for live navigation.
  Stream<Position> getPositionStream({
    int distanceFilter = 25,
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calculate distance between two points (in meters) using pure Dart (Haversine).
  /// Safe for isolates.
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a =
        0.5 -
        math.cos((endLat - startLat) * p) / 2 +
        math.cos(startLat * p) *
            math.cos(endLat * p) *
            (1 - math.cos((endLng - startLng) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  /// Calculate distance using Geolocator (Native).
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}

/// Riverpod provider for LocationService.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
