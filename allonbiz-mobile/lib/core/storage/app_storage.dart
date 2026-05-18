import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_models.dart';

class AppStorage {
  static const _keyName = 'hive_key';
  static const _authBoxName = 'auth_box';
  static const _preferencesBoxName = 'preferences_box';
  static const _cacheBoxName = 'cache_box';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _initialized = false;
  late Box<dynamic> _authBox;
  late Box<dynamic> _preferencesBox;
  late Box<dynamic> _cacheBox;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await Hive.initFlutter();
    final cipher = HiveAesCipher(await _resolveEncryptionKey());
    _authBox = await _openEncryptedBox(_authBoxName, cipher);
    _preferencesBox = await _openEncryptedBox(_preferencesBoxName, cipher);
    _cacheBox = await _openEncryptedBox(_cacheBoxName, cipher);
    _initialized = true;
  }

  Future<List<int>> _resolveEncryptionKey() async {
    final stored = await _secureStorage.read(key: _keyName);
    if (stored != null && stored.isNotEmpty) {
      return base64Decode(stored);
    }

    final generated = Hive.generateSecureKey();
    await _secureStorage.write(key: _keyName, value: base64Encode(generated));
    return generated;
  }

  Future<Box<dynamic>> _openEncryptedBox(
    String name,
    HiveAesCipher cipher,
  ) async {
    try {
      return await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    }
  }

  AuthTokens? readTokens() {
    final raw = _authBox.get('tokens');
    if (raw is Map) {
      return AuthTokens.fromJson(raw);
    }
    return null;
  }

  Future<void> writeTokens(AuthTokens tokens) =>
      _authBox.put('tokens', tokens.toJson());

  Future<void> clearTokens() => _authBox.delete('tokens');

  bool get hasSeenOnboarding =>
      _preferencesBox.get('hasSeenOnboarding', defaultValue: false) == true;

  Future<void> setHasSeenOnboarding(bool value) =>
      _preferencesBox.put('hasSeenOnboarding', value);

  UserPreferences readPreferences() {
    final raw = _preferencesBox.get('userPreferences');
    return raw is Map ? UserPreferences.fromJson(raw) : const UserPreferences();
  }

  Future<void> writePreferences(UserPreferences preferences) =>
      _preferencesBox.put('userPreferences', preferences.toJson());

  List<String> readNotifiedOfferIds() => (List<dynamic>.from(
    _cacheBox.get('notifiedOfferIds', defaultValue: const <dynamic>[]),
  )).map((item) => item.toString()).toList();

  Future<void> writeNotifiedOfferIds(List<String> ids) =>
      _cacheBox.put('notifiedOfferIds', ids);

  Future<void> clearNotifiedOfferIds() => _cacheBox.delete('notifiedOfferIds');

  JourneySession? readActiveJourney() =>
      _readCachedObject('activeJourney', (map) => JourneySession.fromJson(map));

  Future<void> writeActiveJourney(JourneySession? journey) =>
      _writeCachedObject('activeJourney', journey?.toJson());

  RoutePlan? readCachedRoute() =>
      _readCachedObject('cachedRoute', (map) => RoutePlan.fromJson(map));

  Future<void> writeCachedRoute(RoutePlan? routePlan) =>
      _writeCachedObject('cachedRoute', routePlan?.toJson());

  GeoPoint? readLastKnownLocation() =>
      _readCachedObject('lastKnownLocation', (map) => GeoPoint.fromJson(map));

  Future<void> writeLastKnownLocation(GeoPoint? location) =>
      _writeCachedObject('lastKnownLocation', location?.toJson());

  List<OfferSummary> readCachedOffers() =>
      _readCachedList('cachedOffers', (map) => OfferSummary.fromJson(map));

  Future<void> writeCachedOffers(List<OfferSummary> offers) => _writeCachedList(
    'cachedOffers',
    offers.map((item) => item.toJson()).toList(),
  );

  List<SavedItem> readCachedSavedItems() =>
      _readCachedList('cachedSavedItems', (map) => SavedItem.fromJson(map));

  Future<void> writeCachedSavedItems(List<SavedItem> items) => _writeCachedList(
    'cachedSavedItems',
    items.map((item) => item.toJson()).toList(),
  );

  List<UserNotificationItem> readCachedNotifications() => _readCachedList(
    'cachedNotifications',
    (map) => UserNotificationItem.fromJson(map),
  );

  Future<void> writeCachedNotifications(List<UserNotificationItem> items) =>
      _writeCachedList(
        'cachedNotifications',
        items.map((item) => item.toJson()).toList(),
      );

  Future<void> clearJourneyCache() async {
    await writeActiveJourney(null);
    await writeCachedRoute(null);
    await writeCachedOffers(const []);
    await clearNotifiedOfferIds();
  }

  T? _readCachedObject<T>(
    String key,
    T Function(Map<dynamic, dynamic> map) parser,
  ) {
    final raw = _cacheBox.get(key);
    if (raw is Map) {
      return parser(raw);
    }
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return parser(decoded);
      }
    }
    return null;
  }

  List<T> _readCachedList<T>(
    String key,
    T Function(Map<dynamic, dynamic> map) parser,
  ) {
    final raw = _cacheBox.get(key);
    if (raw is List) {
      return raw.whereType<Map>().map((item) => parser(item)).toList();
    }
    return const [];
  }

  Future<void> _writeCachedObject(
    String key,
    Map<String, dynamic>? value,
  ) async {
    if (value == null) {
      await _cacheBox.delete(key);
      return;
    }

    await _cacheBox.put(key, value);
  }

  Future<void> _writeCachedList(String key, List<Map<String, dynamic>> value) =>
      _cacheBox.put(key, value);
}
