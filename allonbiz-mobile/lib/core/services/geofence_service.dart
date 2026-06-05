import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/offer.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import '../utils/app_logger.dart';

/// Monitoring service to trigger notifications when user is near a deal / geofence.
class GeofenceService {
  final LocationService _location;
  final NotificationService _notifications;
  final StorageService _storage;
  StreamSubscription<Position>? _positionSub;

  // Track notified IDs and timestamps to avoid spamming within the same stream update
  // and to enforce the 24-hour cooldown period.
  final Map<String, int> _notifiedTimestamps = {};

  GeofenceService({
    required LocationService location,
    required NotificationService notifications,
    required StorageService storage,
  }) : _location = location,
       _notifications = notifications,
       _storage = storage {
    // Sync with persisted storage timestamps
    _notifiedTimestamps.addAll(_storage.notifiedOfferTimestamps);

    // Migrate old IDs if they exist and don't have a timestamp yet
    final oldIds = _storage.notifiedOfferIds;
    bool needsSave = false;
    for (final id in oldIds) {
      if (!_notifiedTimestamps.containsKey(id)) {
        _notifiedTimestamps[id] = DateTime.now().millisecondsSinceEpoch;
        needsSave = true;
      }
    }
    if (needsSave) {
      _storage.notifiedOfferTimestamps = _notifiedTimestamps;
    }
  }

  /// Start monitoring user location for nearby deals.
  Future<void> startMonitoring(List<Offer> activeOffers) async {
    if (activeOffers.isEmpty) {
      await stopMonitoring();
      return;
    }

    final hasPermission = await _location.checkPermission();
    if (!hasPermission) return;

    await _positionSub?.cancel();
    // Increase distanceFilter to 100m for better background battery efficiency
    _positionSub = _location
        .getPositionStream(distanceFilter: 100)
        .listen(
          (pos) async {
            try {
              // PERF: moved distance checks off the main thread.
              await _checkNearbyDealsIsolate(pos, activeOffers);
            } catch (e) {
              AppLogger.warning('Geofence monitoring error', error: e);
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
      'notifiedTimestamps': _notifiedTimestamps,
      'now': DateTime.now().millisecondsSinceEpoch,
    });

    if (notifiedIds.isNotEmpty) {
      bool hasChanged = false;
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final match in notifiedIds) {
        final offer = offers.firstWhere((o) => o.id == match['id']);
        final distance = match['distance'] as double;

        final lastTime = _notifiedTimestamps[offer.id] ?? 0;
        if (now - lastTime >= 86400000) {
          _notifiedTimestamps[offer.id] = now;
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
        _storage.notifiedOfferTimestamps = _notifiedTimestamps;
      }
    }
  }
}

/// Standalone function for Isolate/Compute.
List<Map<String, dynamic>> _checkDistancesTask(Map<String, dynamic> data) {
  final Position pos = data['pos'];
  final List<Offer> offers = data['offers'];
  final Map<String, int> notifiedTimestamps = data['notifiedTimestamps'];
  final int now = data['now'];

  final List<Map<String, dynamic>> results = [];

  for (final offer in offers) {
    if (notifiedTimestamps.containsKey(offer.id)) {
      final lastNotified = notifiedTimestamps[offer.id]!;
      // 24 hours = 86400000 ms
      if (now - lastNotified < 86400000) {
        continue;
      }
    }

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
