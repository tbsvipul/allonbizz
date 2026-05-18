import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.photonBaseUrl,
    required this.osrmBaseUrl,
    required this.lightTileUrl,
    required this.darkTileUrl,
    required this.backgroundTrackingEnabled,
  });

  final String apiBaseUrl;
  final String photonBaseUrl;
  final String osrmBaseUrl;
  final String lightTileUrl;
  final String darkTileUrl;
  final bool backgroundTrackingEnabled;

  static Future<void> load() async {
    await dotenv.load(fileName: 'assets/env/.env');
  }

  factory AppConfig.fromEnv() {
    return AppConfig(
      apiBaseUrl: _normalizeBaseUrl(
        dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5247/api/v1',
      ),
      photonBaseUrl: _normalizeBaseUrl(
        dotenv.env['PHOTON_BASE_URL'] ?? 'https://photon.komoot.io',
      ),
      osrmBaseUrl: _normalizeBaseUrl(
        dotenv.env['OSRM_BASE_URL'] ?? 'https://router.project-osrm.org',
      ),
      lightTileUrl:
          dotenv.env['LIGHT_TILE_URL'] ??
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      darkTileUrl:
          dotenv.env['DARK_TILE_URL'] ??
          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      backgroundTrackingEnabled:
          (dotenv.env['BACKGROUND_TRACKING_ENABLED'] ?? 'true').toLowerCase() ==
          'true',
    );
  }

  static String _normalizeBaseUrl(String input) =>
      input.replaceAll(RegExp(r'/$'), '');
}
