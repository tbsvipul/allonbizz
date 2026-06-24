/// Stable storage and cache keys. Do not rename without migration.
abstract final class StorageKeys {
  static const String prefsBox = 'preferences';
  static const String responsesBox = 'cached_offers';
  static const String routesBox = 'cached_routes';
  static const String hiveKey = 'hive_key';

  static const String hasSeenOnboarding = 'hasSeenOnboarding';
  static const String isDarkMode = 'isDarkMode';
  static const String languageCode = 'languageCode';
  static const String isSafetyMode = 'isSafetyMode';
  static const String notificationsEnabled = 'notificationsEnabled';
  static const String locationTrackingEnabled = 'locationTrackingEnabled';
  static const String lastLatitude = 'lastLatitude';
  static const String lastLongitude = 'lastLongitude';
  static const String notifiedOfferIds = 'notifiedOfferIds';
  static const String notifiedOfferTimestamps = 'notifiedOfferTimestamps';
  static const String notifiedShopIds = 'notifiedShopIds';
  static const String notifiedShopTimestamps = 'notifiedShopTimestamps';
  static const String backendAccessToken = 'backendAccessToken';
  static const String backendRefreshToken = 'backendRefreshToken';
  static const String activeJourneySession = 'activeJourneySession';
  static const String locationMarker = 'locationMarker';
  static const String searchHistory = 'searchHistory';
}
