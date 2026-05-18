import 'package:flutter/foundation.dart';

import '../../core/models/app_models.dart';
import '../../core/storage/app_storage.dart';

class PreferencesController extends ChangeNotifier {
  PreferencesController(this._storage)
    : _preferences = _storage.isInitialized
          ? _storage.readPreferences()
          : const UserPreferences();

  final AppStorage _storage;
  UserPreferences _preferences;

  UserPreferences get preferences => _preferences;

  Future<void> setDarkMode(bool value) =>
      _update(_preferences.copyWith(darkMode: value));

  Future<void> setNotificationsEnabled(bool value) =>
      _update(_preferences.copyWith(notificationsEnabled: value));

  Future<void> setBackgroundTrackingEnabled(bool value) =>
      _update(_preferences.copyWith(backgroundTrackingEnabled: value));

  Future<void> setDiscoveryRadius(double value) =>
      _update(_preferences.copyWith(discoveryRadiusKm: value));

  Future<void> setLanguage(String value) =>
      _update(_preferences.copyWith(language: value));

  Future<void> _update(UserPreferences next) async {
    _preferences = next;
    await _storage.writePreferences(next);
    notifyListeners();
  }
}
