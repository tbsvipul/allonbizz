import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/offer.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Monitoring service to trigger notifications when user is near a deal / geofence.
class GeofenceService {
  final LocationService _location;
  final NotificationService _notifications;
  final StorageService _storage;
  StreamSubscription<Position>? _positionSub;

  // Track notified IDs to avoid spamming within the same stream update
  final Set<String> _currentNotifiedIds = {};

  GeofenceService({
    required LocationService location,
    required NotificationService notifications,
    required StorageService storage,
  }) : _location = location,
       _notifications = notifications,
       _storage = storage {
    // Sync with persisted storage IDs
    _currentNotifiedIds.addAll(_storage.notifiedOfferIds);
  }

  /// Start monitoring user location for nearby deals.
  Future<void> startMonitoring(List<Offer> activeOffers) async {
    final hasPermission = await _location.checkPermission();
    if (!hasPermission) return;

    await _positionSub?.cancel();
    // Increase distanceFilter to 100m for better background battery efficiency
    _positionSub = _location
        .getPositionStream(distanceFilter: 100)
        .listen(
          (pos) async {
            try {
              // Move heavy calculation to an isolate to avoid blocking main thread
              await _checkNearbyDealsIsolate(pos, activeOffers);
            } catch (e) {
              debugPrint('Geofence error: $e');
            }
          },
          onError: (e) {
            // Handle stream errors (e.g. permission revoked while running) gracefully
            stopMonitoring();
          },
        );
  }

  /// Stop monitoring.
  Future<void> stopMonitoring() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  /// Isolate wrapper for distance checks to offload main thread.
  Future<void> _checkNearbyDealsIsolate(
    Position currentPos,
    List<Offer> offers,
  ) async {
    // Parallelize calculations to avoid blocking UI during high load.
    final notifiedIds = await compute(_checkDistancesTask, {
      'pos': currentPos,
      'offers': offers,
      'alreadyNotified': _currentNotifiedIds.toList(),
    });

    if (notifiedIds.isNotEmpty) {
      bool hasChanged = false;
      for (final match in notifiedIds) {
        final offer = offers.firstWhere((o) => o.id == match['id']);
        final distance = match['distance'] as double;

        if (!_currentNotifiedIds.contains(offer.id)) {
          _currentNotifiedIds.add(offer.id);
          hasChanged = true;
          await _notifications.showNotification(
            id: offer.id.hashCode & 0x7FFFFFFF,
            title: 'Nearby Deal! 🔥',
            body:
                '${offer.title} is just ${distance.toInt()}m away at ${offer.shopName}',
            payload: '/offer-detail?id=${offer.id}',
          );
        }
      }
      if (hasChanged) {
        _storage.notifiedOfferIds = _currentNotifiedIds.toList();
      }
    }
  }
}

/// Standalone function for Isolate/Compute.
List<Map<String, dynamic>> _checkDistancesTask(Map<String, dynamic> data) {
  final Position pos = data['pos'];
  final List<Offer> offers = data['offers'];
  final List<String> alreadyNotified = data['alreadyNotified'];

  final List<Map<String, dynamic>> results = [];

  for (final offer in offers) {
    if (alreadyNotified.contains(offer.id)) continue;

    final dist = LocationService.calculateDistance(
      pos.latitude,
      pos.longitude,
      offer.latitude,
      offer.longitude,
    );

    if (dist <= 200) {
      results.add({'id': offer.id, 'distance': dist});
    }
  }
  return results;
}

/// Provider for GeofenceService.
final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  final location = ref.watch(locationServiceProvider);
  final notifications = ref.watch(notificationServiceProvider);
  final storage = ref.watch(storageServiceProvider);

  final service = GeofenceService(
    location: location,
    notifications: notifications,
    storage: storage,
  );

  // CRITICAL: Ensure monitoring stops when the provider is disposed
  ref.onDispose(() => service.stopMonitoring());

  return service;
});
