import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../shared/models/offer.dart';
import '../network/base_api.dart';
import '../utils/app_logger.dart';
import '../utils/background_executor.dart';

/// Request payload for isolate computation to avoid passing separate params
class _OfferFilterPayload {
  final List<Map<String, double>> routePoints;
  final List<Map<String, dynamic>> offersData;
  final double bufferDistance;

  _OfferFilterPayload(this.routePoints, this.offersData, this.bufferDistance);
}

class RouteResult {
  final List<LatLng> points;
  final String distance;
  final String duration;

  RouteResult({
    required this.points,
    required this.distance,
    required this.duration,
  });
}

/// Service responsible for fetching routes and detecting offers along them.
/// Uses the free OSRM API (https://router.project-osrm.org).
class RouteService {
  /// Fetch a driving route from OSRM (free, no API key).
  Future<RouteResult> getRoutePolyline(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      // PRESERVED: keep OSRM route contract and fallback behavior unchanged.
      // OSRM format: /route/v1/driving/lng,lat;lng,lat
      final url = Uri.parse(
        '${BaseApi.osrmBaseUrl}/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final List<LatLng> points = coordinates.map((coord) {
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          return RouteResult(
            points: points,
            distance: _formatDistance(distanceMeters),
            duration: _formatDuration(durationSeconds),
          );
        }
      }

      // Fallback
      return RouteResult(
        points: getFallbackPath(origin, destination),
        distance: '--- km',
        duration: '--- min',
      );
    } catch (e) {
      AppLogger.warning('RouteService error', error: e);
      return RouteResult(
        points: getFallbackPath(origin, destination),
        distance: '--- km',
        duration: '--- min',
      );
    }
  }

  /// Format distance in meters to human readable string.
  static String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  /// Format duration in seconds to human readable string.
  static String _formatDuration(double seconds) {
    final mins = (seconds / 60).round();
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remainMins = mins % 60;
      return '$hours h $remainMins min';
    }
    return '$mins min';
  }

  /// Generates a zigzag path to simulate road following visually when API fails
  List<LatLng> getFallbackPath(LatLng start, LatLng end) {
    final List<LatLng> path = [start];

    final double midLat = (start.latitude + end.latitude) / 2;
    final double midLng = (start.longitude + end.longitude) / 2;

    path.add(LatLng(midLat + 0.005, midLng - 0.002));
    path.add(LatLng(midLat - 0.005, midLng + 0.005));

    path.add(end);
    return path;
  }

  /// Calculates distance between two points in meters.
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Detects which [offers] are within [bufferDistance] (in meters) of the [route].
  /// PERF: moved to isolate — was blocking main thread heavily on O(N*M) calculation
  Future<List<Offer>> getOffersAlongRoute(
    List<LatLng> route,
    List<Offer> allOffers, {
    double bufferDistance = 500,
  }) async {
    if (route.isEmpty || allOffers.isEmpty) return [];

    final payload = _OfferFilterPayload(
      route.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      allOffers.map((o) => o.toJson()).toList(),
      bufferDistance,
    );

    final resultList = await runInBackground(
      () => _filterOffersInIsolate(payload),
    );

    return resultList
        .map((data) => Offer.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// Top-level function executed inside the Isolate.
  static List<Map<String, dynamic>> _filterOffersInIsolate(
    _OfferFilterPayload payload,
  ) {
    if (payload.routePoints.isEmpty) return [];

    double minLat = payload.routePoints[0]['lat']!;
    double maxLat = payload.routePoints[0]['lat']!;
    double minLng = payload.routePoints[0]['lng']!;
    double maxLng = payload.routePoints[0]['lng']!;

    for (var point in payload.routePoints) {
      if (point['lat']! < minLat) minLat = point['lat']!;
      if (point['lat']! > maxLat) maxLat = point['lat']!;
      if (point['lng']! < minLng) minLng = point['lng']!;
      if (point['lng']! > maxLng) maxLng = point['lng']!;
    }

    final latPadding = payload.bufferDistance / 111000.0;
    final lngPadding = payload.bufferDistance / (111000.0 * 0.9);

    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    final List<Map<String, dynamic>> matches = [];
    // Increase sampling density: check every 3rd point if route is long, instead of every 10th.
    final step = (payload.routePoints.length > 30)
        ? (payload.routePoints.length / 30).round().clamp(1, 4)
        : 1;

    for (final offerData in payload.offersData) {
      final oLat = (offerData['latitude'] as num).toDouble();
      final oLng = (offerData['longitude'] as num).toDouble();

      if (oLat < minLat || oLat > maxLat || oLng < minLng || oLng > maxLng) {
        continue;
      }

      bool isNear = false;
      for (int i = 0; i < payload.routePoints.length; i += step) {
        final point = payload.routePoints[i];
        final distance = Geolocator.distanceBetween(
          point['lat']!,
          point['lng']!,
          oLat,
          oLng,
        );
        if (distance <= payload.bufferDistance) {
          isNear = true;
          break;
        }
      }

      if (isNear) {
        matches.add(offerData);
      }
    }

    return matches;
  }
}
