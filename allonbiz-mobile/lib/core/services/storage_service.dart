import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CachedResponseRecord {
  const CachedResponseRecord({required this.payload, required this.fetchedAt});

  final String payload;
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() {
    return {'payload': payload, 'fetchedAt': fetchedAt.millisecondsSinceEpoch};
  }

  factory CachedResponseRecord.fromJson(Map<String, dynamic> json) {
    final fetchedAtEpoch =
        (json['fetchedAt'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;

    return CachedResponseRecord(
      payload: json['payload']?.toString() ?? '',
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetchedAtEpoch),
    );
  }
}

/// Hive-based local storage service for offline data and preferences.
class StorageService {
  static const String _prefsBox = 'preferences';
  static const String _responsesBox = 'cached_offers';
  static const String _routesBox = 'cached_routes';

  final Box? _injectedPrefs;
  final Box? _injectedResponses;
  final Box? _injectedRoutes;

  StorageService({Box? prefs, Box? offers, Box? responseCache, Box? routes})
    : _injectedPrefs = prefs,
      _injectedResponses = responseCache ?? offers,
      _injectedRoutes = routes;

  /// Initialise Hive and open required boxes with encryption.
  static Future<void> init() async {
    await Hive.initFlutter();

    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString = await secureStorage.read(key: 'hive_key');

    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(key: 'hive_key', value: base64UrlEncode(key));
      encryptionKeyString = base64UrlEncode(key);
    }

    final key = base64Url.decode(encryptionKeyString);
    final cipher = HiveAesCipher(key);

    try {
      await Hive.openBox(_prefsBox, encryptionCipher: cipher);
      await Hive.openBox(_responsesBox, encryptionCipher: cipher);
      await Hive.openBox(_routesBox, encryptionCipher: cipher);
    } catch (_) {
      // If decryption fails (e.g. data is unencrypted), clear and reopen.
      await Hive.deleteBoxFromDisk(_prefsBox);
      await Hive.deleteBoxFromDisk(_responsesBox);
      await Hive.deleteBoxFromDisk(_routesBox);

      await Hive.openBox(_prefsBox, encryptionCipher: cipher);
      await Hive.openBox(_responsesBox, encryptionCipher: cipher);
      await Hive.openBox(_routesBox, encryptionCipher: cipher);
    }
  }

  Box get _prefs => _injectedPrefs ?? Hive.box(_prefsBox);
  Box get _responses => _injectedResponses ?? Hive.box(_responsesBox);
  Box get _routes => _injectedRoutes ?? Hive.box(_routesBox);

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

  /// Backend API Access Token.
  String? get backendAccessToken => _prefs.get('backendAccessToken');
  set backendAccessToken(String? value) {
    if (value == null) {
      _prefs.delete('backendAccessToken');
    } else {
      _prefs.put('backendAccessToken', value);
    }
  }

  /// Backend API Refresh Token.
  String? get backendRefreshToken => _prefs.get('backendRefreshToken');
  set backendRefreshToken(String? value) {
    if (value == null) {
      _prefs.delete('backendRefreshToken');
    } else {
      _prefs.put('backendRefreshToken', value);
    }
  }

  Map<String, dynamic>? get activeJourneySession {
    final raw = _prefs.get('activeJourneySession');
    if (raw is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(raw);
  }

  Future<void> saveActiveJourneySession(Map<String, dynamic> value) async {
    await _prefs.put('activeJourneySession', value);
  }

  Future<void> clearActiveJourneySession() async {
    await _prefs.delete('activeJourneySession');
  }

  Future<void> putCachedResponse(
    String key, {
    required String payload,
    required DateTime fetchedAt,
  }) async {
    await _responses.put(
      key,
      CachedResponseRecord(payload: payload, fetchedAt: fetchedAt).toJson(),
    );
  }

  CachedResponseRecord? getCachedResponse(String key) {
    final raw = _responses.get(key);
    if (raw is! Map) {
      return null;
    }

    try {
      return CachedResponseRecord.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> removeCachedResponse(String key) async {
    await _responses.delete(key);
  }

  Future<void> removeCachedResponsesWithPrefix(String prefix) async {
    final keys = _responses.keys
        .whereType<String>()
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);

    if (keys.isEmpty) {
      return;
    }

    await _responses.deleteAll(keys);
  }

  Future<void> clearCachedResponses() async {
    await _responses.clear();
  }

  /// Cache a route as JSON map.
  Future<void> cacheRoute(String routeId, Map<String, dynamic> route) async {
    await _routes.put(routeId, route);
  }

  /// Retrieve a cached route.
  Map<String, dynamic>? getCachedRoute(String routeId) {
    final raw = _routes.get(routeId);
    if (raw == null) {
      return null;
    }

    return Map<String, dynamic>.from(raw);
  }

  /// Clear all cached data.
  Future<void> clearAll() async {
    await _prefs.clear();
    await _responses.clear();
    await _routes.clear();
  }
}

/// Riverpod provider for StorageService.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
