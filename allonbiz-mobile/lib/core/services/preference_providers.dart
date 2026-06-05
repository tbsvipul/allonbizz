import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
      return NotificationsEnabledNotifier(ref.watch(storageServiceProvider));
    });

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  final StorageService _storage;
  NotificationsEnabledNotifier(this._storage)
    : super(_storage.notificationsEnabled);

  void toggle(bool value) {
    _storage.notificationsEnabled = value;
    state = value;
  }
}

final locationTrackingEnabledProvider =
    StateNotifierProvider<LocationTrackingEnabledNotifier, bool>((ref) {
      return LocationTrackingEnabledNotifier(ref.watch(storageServiceProvider));
    });

class LocationTrackingEnabledNotifier extends StateNotifier<bool> {
  final StorageService _storage;
  LocationTrackingEnabledNotifier(this._storage)
    : super(_storage.locationTrackingEnabled);

  void toggle(bool value) {
    _storage.locationTrackingEnabled = value;
    state = value;
  }
}

final locationMarkerProvider =
    StateNotifierProvider<LocationMarkerNotifier, String>((ref) {
      return LocationMarkerNotifier(ref.watch(storageServiceProvider));
    });

class LocationMarkerNotifier extends StateNotifier<String> {
  final StorageService _storage;
  LocationMarkerNotifier(this._storage) : super(_storage.locationMarker);

  void setMarker(String value) {
    _storage.locationMarker = value;
    state = value;
  }
}
