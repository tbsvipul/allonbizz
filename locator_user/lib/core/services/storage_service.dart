import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hive-based local storage service for offline data and preferences.
class StorageService {
  static const String _prefsBox = 'preferences';
  static const String _offersBox = 'cached_offers';
  static const String _routesBox = 'cached_routes';

  final Box? _injectedPrefs;
  final Box? _injectedOffers;
  final Box? _injectedRoutes;

  StorageService({Box? prefs, Box? offers, Box? routes})
    : _injectedPrefs = prefs,
      _injectedOffers = offers,
      _injectedRoutes = routes;

  /// Initialise Hive and open required boxes with encryption.
  static Future<void> init() async {
    await Hive.initFlutter();

    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString = await secureStorage.read(key: 'hive_key');

    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'hive_key',
        value: base64UrlEncode(key),
      );
      encryptionKeyString = base64UrlEncode(key);
    }

    final key = base64Url.decode(encryptionKeyString);
    final cipher = HiveAesCipher(key);

    try {
      await Hive.openBox(_prefsBox, encryptionCipher: cipher);
      await Hive.openBox(_offersBox, encryptionCipher: cipher);
      await Hive.openBox(_routesBox, encryptionCipher: cipher);
    } catch (e) {
      // If decryption fails (e.g. data is unencrypted), clear and reopen
      await Hive.deleteBoxFromDisk(_prefsBox);
      await Hive.deleteBoxFromDisk(_offersBox);
      await Hive.deleteBoxFromDisk(_routesBox);
      
      await Hive.openBox(_prefsBox, encryptionCipher: cipher);
      await Hive.openBox(_offersBox, encryptionCipher: cipher);
      await Hive.openBox(_routesBox, encryptionCipher: cipher);
    }
  }

  // ── Preferences ───────────────────────────────────────────────

  Box get _prefs => _injectedPrefs ?? Hive.box(_prefsBox);

  /// Whether the user has completed onboarding.
  bool get hasSeenOnboarding =>
      _prefs.get('hasSeenOnboarding', defaultValue: false);
  set hasSeenOnboarding(bool value) => _prefs.put('hasSeenOnboarding', value);

  /// Whether dark mode is enabled.
  bool get isDarkMode => _prefs.get('isDarkMode', defaultValue: false);
  set isDarkMode(bool value) => _prefs.put('isDarkMode', value);

  /// Selected language code (e.g., 'en', 'hi').
  String get languageCode => _prefs.get('languageCode', defaultValue: 'en');
  set languageCode(String value) => _prefs.put('languageCode', value);

  /// Whether safety mode is enabled.
  bool get isSafetyMode => _prefs.get('isSafetyMode', defaultValue: false);
  set isSafetyMode(bool value) => _prefs.put('isSafetyMode', value);

  /// Whether notifications are enabled.
  bool get notificationsEnabled =>
      _prefs.get('notificationsEnabled', defaultValue: true);
  set notificationsEnabled(bool value) =>
      _prefs.put('notificationsEnabled', value);

  /// Whether background location tracking is enabled.
  bool get locationTrackingEnabled =>
      _prefs.get('locationTrackingEnabled', defaultValue: true);
  set locationTrackingEnabled(bool value) =>
      _prefs.put('locationTrackingEnabled', value);

  /// Last known latitude.
  double? get lastLatitude => _prefs.get('lastLatitude');
  set lastLatitude(double? value) => _prefs.put('lastLatitude', value);

  /// Last known longitude.
  double? get lastLongitude => _prefs.get('lastLongitude');
  set lastLongitude(double? value) => _prefs.put('lastLongitude', value);

  /// List of offer IDs already notified to user (to prevent spam).
  List<String> get notifiedOfferIds =>
      List<String>.from(_prefs.get('notifiedOfferIds', defaultValue: []));
  set notifiedOfferIds(List<String> value) =>
      _prefs.put('notifiedOfferIds', value);

  // ── Authentication ──────────────────────────────────────────────

  /// Backend API Access Token
  String? get backendAccessToken => _prefs.get('backendAccessToken');
  set backendAccessToken(String? value) {
    if (value == null) {
      _prefs.delete('backendAccessToken');
    } else {
      _prefs.put('backendAccessToken', value);
    }
  }

  /// Backend API Refresh Token
  String? get backendRefreshToken => _prefs.get('backendRefreshToken');
  set backendRefreshToken(String? value) {
    if (value == null) {
      _prefs.delete('backendRefreshToken');
    } else {
      _prefs.put('backendRefreshToken', value);
    }
  }

  // ── Cached Offers ─────────────────────────────────────────────

  Box get _offers => _injectedOffers ?? Hive.box(_offersBox);

  /// Cache a list of offers as JSON maps.
  Future<void> cacheOffers(List<Map<String, dynamic>> offers) async {
    await _offers.put('offers', offers);
  }

  /// Retrieve cached offers.
  List<Map<String, dynamic>> getCachedOffers() {
    final raw = _offers.get('offers');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  // ── Cached Routes ─────────────────────────────────────────────

  Box get _routes => _injectedRoutes ?? Hive.box(_routesBox);

  /// Cache a route as JSON map.
  Future<void> cacheRoute(String routeId, Map<String, dynamic> route) async {
    await _routes.put(routeId, route);
  }

  /// Retrieve a cached route.
  Map<String, dynamic>? getCachedRoute(String routeId) {
    final raw = _routes.get(routeId);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  // ── Clear ─────────────────────────────────────────────────────

  /// Clear all cached data.
  Future<void> clearAll() async {
    await _prefs.clear();
    await _offers.clear();
    await _routes.clear();
  }
}

/// Riverpod provider for StorageService.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
