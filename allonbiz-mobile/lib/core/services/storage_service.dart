import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_keys.dart';

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
    String? encryptionKeyString = await secureStorage.read(
      key: StorageKeys.hiveKey,
    );

    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: StorageKeys.hiveKey,
        value: base64UrlEncode(key),
      );
      encryptionKeyString = base64UrlEncode(key);
    }

    final key = base64Url.decode(encryptionKeyString);
    final cipher = HiveAesCipher(key);

    try {
      await Hive.openBox(StorageKeys.prefsBox, encryptionCipher: cipher);
      await Hive.openBox(StorageKeys.responsesBox, encryptionCipher: cipher);
      await Hive.openBox(StorageKeys.routesBox, encryptionCipher: cipher);
    } catch (_) {
      // Close any boxes that might have opened successfully before deleting
      if (Hive.isBoxOpen(StorageKeys.prefsBox)) await Hive.box(StorageKeys.prefsBox).close();
      if (Hive.isBoxOpen(StorageKeys.responsesBox)) await Hive.box(StorageKeys.responsesBox).close();
      if (Hive.isBoxOpen(StorageKeys.routesBox)) await Hive.box(StorageKeys.routesBox).close();

      // If decryption fails (e.g. data is unencrypted), clear and reopen.
      await Hive.deleteBoxFromDisk(StorageKeys.prefsBox);
      await Hive.deleteBoxFromDisk(StorageKeys.responsesBox);
      await Hive.deleteBoxFromDisk(StorageKeys.routesBox);

      await Hive.openBox(StorageKeys.prefsBox, encryptionCipher: cipher);
      await Hive.openBox(StorageKeys.responsesBox, encryptionCipher: cipher);
      await Hive.openBox(StorageKeys.routesBox, encryptionCipher: cipher);
    }
  }

  Box get _prefs => _injectedPrefs ?? Hive.box(StorageKeys.prefsBox);
  Box get _responses =>
      _injectedResponses ?? Hive.box(StorageKeys.responsesBox);
  Box get _routes => _injectedRoutes ?? Hive.box(StorageKeys.routesBox);

  /// Whether the user has completed onboarding.
  bool get hasSeenOnboarding =>
      _prefs.get(StorageKeys.hasSeenOnboarding, defaultValue: false);
  set hasSeenOnboarding(bool value) =>
      _prefs.put(StorageKeys.hasSeenOnboarding, value);

  /// Whether dark mode is enabled.
  bool get isDarkMode =>
      _prefs.get(StorageKeys.isDarkMode, defaultValue: false);
  set isDarkMode(bool value) => _prefs.put(StorageKeys.isDarkMode, value);

  /// Selected language code (e.g., 'en', 'hi').
  String get languageCode =>
      _prefs.get(StorageKeys.languageCode, defaultValue: 'en');
  set languageCode(String value) => _prefs.put(StorageKeys.languageCode, value);

  /// Whether safety mode is enabled.
  bool get isSafetyMode =>
      _prefs.get(StorageKeys.isSafetyMode, defaultValue: false);
  set isSafetyMode(bool value) => _prefs.put(StorageKeys.isSafetyMode, value);

  /// Whether notifications are enabled.
  bool get notificationsEnabled =>
      _prefs.get(StorageKeys.notificationsEnabled, defaultValue: true);
  set notificationsEnabled(bool value) =>
      _prefs.put(StorageKeys.notificationsEnabled, value);

  /// Whether background location tracking is enabled.
  bool get locationTrackingEnabled =>
      _prefs.get(StorageKeys.locationTrackingEnabled, defaultValue: true);
  set locationTrackingEnabled(bool value) =>
      _prefs.put(StorageKeys.locationTrackingEnabled, value);

  /// Chosen location marker. 'ripple' is default.
  String get locationMarker =>
      _prefs.get(StorageKeys.locationMarker, defaultValue: 'ripple');
  set locationMarker(String value) =>
      _prefs.put(StorageKeys.locationMarker, value);

  /// Last known latitude.
  double? get lastLatitude => _prefs.get(StorageKeys.lastLatitude);
  set lastLatitude(double? value) =>
      _prefs.put(StorageKeys.lastLatitude, value);

  /// Last known longitude.
  double? get lastLongitude => _prefs.get(StorageKeys.lastLongitude);
  set lastLongitude(double? value) =>
      _prefs.put(StorageKeys.lastLongitude, value);

  List<String> get notifiedOfferIds => List<String>.from(
    _prefs.get(StorageKeys.notifiedOfferIds, defaultValue: []),
  );
  set notifiedOfferIds(List<String> value) =>
      _prefs.put(StorageKeys.notifiedOfferIds, value);

  /// Map of offer IDs to timestamp (millisecondsSinceEpoch) of when they were last notified.
  Map<String, int> get notifiedOfferTimestamps {
    final raw = _prefs.get(
      StorageKeys.notifiedOfferTimestamps,
      defaultValue: {},
    );
    if (raw is! Map) return {};
    return Map<String, int>.from(raw);
  }

  set notifiedOfferTimestamps(Map<String, int> value) =>
      _prefs.put(StorageKeys.notifiedOfferTimestamps, value);

  /// List of shop IDs already notified to user (to prevent spam).
  List<String> get notifiedShopIds => List<String>.from(
    _prefs.get(StorageKeys.notifiedShopIds, defaultValue: []),
  );
  set notifiedShopIds(List<String> value) =>
      _prefs.put(StorageKeys.notifiedShopIds, value);

  /// Map of shop IDs to timestamp (millisecondsSinceEpoch) of when they were last notified.
  Map<String, int> get notifiedShopTimestamps {
    final raw = _prefs.get(
      StorageKeys.notifiedShopTimestamps,
      defaultValue: {},
    );
    if (raw is! Map) return {};
    return Map<String, int>.from(raw);
  }

  set notifiedShopTimestamps(Map<String, int> value) =>
      _prefs.put(StorageKeys.notifiedShopTimestamps, value);

  /// Backend API Access Token.
  String? get backendAccessToken => _prefs.get(StorageKeys.backendAccessToken);
  set backendAccessToken(String? value) {
    if (value == null) {
      _prefs.delete(StorageKeys.backendAccessToken);
    } else {
      _prefs.put(StorageKeys.backendAccessToken, value);
    }
  }

  /// Backend API Refresh Token.
  String? get backendRefreshToken =>
      _prefs.get(StorageKeys.backendRefreshToken);
  set backendRefreshToken(String? value) {
    if (value == null) {
      _prefs.delete(StorageKeys.backendRefreshToken);
    } else {
      _prefs.put(StorageKeys.backendRefreshToken, value);
    }
  }

  Map<String, dynamic>? get activeJourneySession {
    final raw = _prefs.get(StorageKeys.activeJourneySession);
    if (raw is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(raw);
  }

  Future<void> saveActiveJourneySession(Map<String, dynamic> value) async {
    await _prefs.put(StorageKeys.activeJourneySession, value);
  }

  Future<void> clearActiveJourneySession() async {
    await _prefs.delete(StorageKeys.activeJourneySession);
  }

  List<Map<String, dynamic>> get searchHistory {
    final raw = _prefs.get(StorageKeys.searchHistory, defaultValue: []);
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  set searchHistory(List<Map<String, dynamic>> value) =>
      _prefs.put(StorageKeys.searchHistory, value);

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
