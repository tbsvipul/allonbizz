import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BaseApi {
  BaseApi._();

  static const String _backendFallbackWeb = 'http://localhost:5247/api/v1';
  static const String _backendFallbackNative = 'http://192.168.1.189:5247/api/v1';
  static const String _placesFallbackNative = 'http://192.168.1.189:5000/api/v1';
  static const String _nominatimFallback =
      'https://nominatim.openstreetmap.org';
  static const String _osrmFallback = 'https://router.project-osrm.org';
  static const String _lightTileFallback =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const String _darkTileFallback =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static String get backendBaseUrl => resolveAppBaseUrl(
    dotenv.env['API_BASE_URL'],
    fallbackUrl: kIsWeb ? _backendFallbackWeb : _backendFallbackNative,
  );

  static String get placesBaseUrl => resolveAppBaseUrl(
    dotenv.env['PLACES_API_BASE_URL'],
    fallbackUrl: _placesFallbackNative,
  );

  static List<String> get candidatePlacesBaseUrls {
    final urls = <String>{backendBaseUrl, placesBaseUrl};
    return urls.where((url) => url.isNotEmpty).toList(growable: false);
  }

  static String get nominatimBaseUrl => resolveExternalUrl(
    dotenv.env['NOMINATIM_BASE_URL'],
    fallbackUrl: _nominatimFallback,
  );

  static String get nominatimSearchUrl => '$nominatimBaseUrl/search';

  static String get nominatimReverseUrl => '$nominatimBaseUrl/reverse';

  static String get osrmBaseUrl => resolveExternalUrl(
    dotenv.env['OSRM_BASE_URL'],
    fallbackUrl: _osrmFallback,
  );

  static String get lightTileUrl =>
      dotenv.env['LIGHT_TILE_URL']?.trim().isNotEmpty == true
      ? dotenv.env['LIGHT_TILE_URL']!.trim()
      : _lightTileFallback;

  static String get darkTileUrl =>
      dotenv.env['DARK_TILE_URL']?.trim().isNotEmpty == true
      ? dotenv.env['DARK_TILE_URL']!.trim()
      : _darkTileFallback;

  static String resolveAppBaseUrl(
    String? rawUrl, {
    required String fallbackUrl,
  }) {
    final configuredUrl = rawUrl?.trim();
    if (configuredUrl == null || configuredUrl.isEmpty) {
      return normalizeUrl(fallbackUrl);
    }
    return normalizeUrl(configuredUrl);
  }

  static String resolveExternalUrl(
    String? rawUrl, {
    required String fallbackUrl,
  }) {
    final configuredUrl = rawUrl?.trim();
    if (configuredUrl == null || configuredUrl.isEmpty) {
      return normalizeUrl(fallbackUrl);
    }
    return normalizeUrl(configuredUrl);
  }

  static String normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return _trimTrailingSlash(trimmed);
    }

    if (kIsWeb && uri.host == '10.0.2.2') {
      return _trimTrailingSlash(uri.replace(host: 'localhost').toString());
    }

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        isLoopbackHost(uri.host)) {
      return _trimTrailingSlash(uri.replace(host: '10.0.2.2').toString());
    }

    return _trimTrailingSlash(trimmed);
  }

  static bool isLoopbackHost(String host) {
    final normalized = host.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0';
  }

  static bool isTrustedDevelopmentHost(String host) {
    final normalized = host.trim().toLowerCase();
    return normalized == '10.0.2.2' || 
           isLoopbackHost(normalized) || 
           normalized.startsWith('192.168.');
  }

  static String _trimTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
