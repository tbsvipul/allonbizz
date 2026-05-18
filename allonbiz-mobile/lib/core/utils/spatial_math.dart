import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';

Future<List<OfferSummary>> filterOffersAlongRoute(
  List<GeoPoint> routePoints,
  List<OfferSummary> offers,
  double radiusKm,
) async {
  if (routePoints.isEmpty || offers.isEmpty) {
    return offers;
  }

  final result = await compute(_filterOffersAlongRoute, {
    'routePoints': routePoints.map((item) => item.toJson()).toList(),
    'offers': offers.map((item) => item.toJson()).toList(),
    'radiusKm': radiusKm,
  });

  return (result as List<dynamic>)
      .map((item) => OfferSummary.fromJson(item as Map<String, dynamic>))
      .toList();
}

List<Map<String, dynamic>> _filterOffersAlongRoute(
  Map<String, dynamic> payload,
) {
  final routePoints = (payload['routePoints'] as List<dynamic>)
      .map((item) => GeoPoint.fromJson(item as Map<String, dynamic>))
      .toList();
  final offers = (payload['offers'] as List<dynamic>)
      .map((item) => OfferSummary.fromJson(item as Map<String, dynamic>))
      .toList();
  final radiusKm = (payload['radiusKm'] as num).toDouble();

  final minLat =
      routePoints.map((item) => item.latitude).reduce(min) - radiusKm / 111.0;
  final maxLat =
      routePoints.map((item) => item.latitude).reduce(max) + radiusKm / 111.0;
  final minLng =
      routePoints.map((item) => item.longitude).reduce(min) - radiusKm / 111.0;
  final maxLng =
      routePoints.map((item) => item.longitude).reduce(max) + radiusKm / 111.0;

  final filtered = offers.where((offer) {
    final point = offer.point;
    if (point == null) {
      return false;
    }
    if (point.latitude < minLat ||
        point.latitude > maxLat ||
        point.longitude < minLng ||
        point.longitude > maxLng) {
      return false;
    }

    for (var index = 0; index < routePoints.length; index += 3) {
      if (_distanceKm(routePoints[index], point) <= radiusKm) {
        return true;
      }
    }

    return _distanceKm(routePoints.last, point) <= radiusKm;
  }).toList();

  return filtered.map((item) => item.toJson()).toList();
}

double distanceMeters(GeoPoint a, GeoPoint b) => _distanceKm(a, b) * 1000;

double _distanceKm(GeoPoint a, GeoPoint b) {
  const earthRadius = 6371.0;
  final dLat = _radians(b.latitude - a.latitude);
  final dLon = _radians(b.longitude - a.longitude);
  final lat1 = _radians(a.latitude);
  final lat2 = _radians(b.latitude);
  final haversine =
      sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
  return earthRadius * 2 * atan2(sqrt(haversine), sqrt(1 - haversine));
}

double _radians(double degrees) => degrees * pi / 180;
