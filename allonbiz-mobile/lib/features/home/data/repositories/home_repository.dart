import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_parsers.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/offer.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(apiClient: ref.watch(apiClientProvider));
});

final homeOffersProvider = StreamProvider<List<Offer>>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  final position = ref.watch(
    currentLocationProvider.select((location) => location.position),
  );
  final isLocationLoading = ref.watch(
    currentLocationProvider.select((location) => location.isLoading),
  );

  if (position == null) {
    if (isLocationLoading) {
      return Stream.value(const <Offer>[]);
    }
    return repo.watchRecommendedOffers();
  }

  return repo.watchNearbyOffers(position.latitude, position.longitude);
});

final homeTagsProvider = StreamProvider<List<dynamic>>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.watchHomeData().map((data) {
    return data['categories'] ?? data['Categories'] ?? [];
  });
});

class HomeRepository {
  HomeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static const Duration _homeTtl = Duration(seconds: 90);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getHomeData({double? lat, double? lng}) async {
    try {
      final endpoint = _buildHomeEndpoint(lat: lat, lng: lng);
      return _apiClient.getParsed<Map<String, dynamic>>(
        endpoint,
        parser: extractEnvelopeDataMap,
        options: ApiReadOptions(
          cacheKey: _buildHomeCacheKey(lat: lat, lng: lng),
          ttl: _homeTtl,
          decodeInBackground: true,
        ),
      );
    } catch (error) {
      AppLogger.error('Failed to fetch home data', error: error);
      return {};
    }
  }

  Stream<Map<String, dynamic>> watchHomeData({double? lat, double? lng}) {
    final endpoint = _buildHomeEndpoint(lat: lat, lng: lng);
    return _apiClient.watchParsed<Map<String, dynamic>>(
      endpoint,
      parser: extractEnvelopeDataMap,
      options: ApiReadOptions(
        cacheKey: _buildHomeCacheKey(lat: lat, lng: lng),
        ttl: _homeTtl,
        decodeInBackground: true,
      ),
    );
  }

  Future<List<Offer>> getNearbyOffers(double lat, double lng) {
    final endpoint = _buildHomeEndpoint(lat: lat, lng: lng);
    return _apiClient.getParsed<List<Offer>>(
      endpoint,
      parser: parseRecommendedOffersFromHomeResponse,
      options: ApiReadOptions(
        cacheKey: _buildHomeCacheKey(lat: lat, lng: lng),
        ttl: _homeTtl,
        decodeInBackground: true,
      ),
    );
  }

  Stream<List<Offer>> watchNearbyOffers(double lat, double lng) {
    final endpoint = _buildHomeEndpoint(lat: lat, lng: lng);
    return _apiClient.watchParsed<List<Offer>>(
      endpoint,
      parser: parseRecommendedOffersFromHomeResponse,
      options: ApiReadOptions(
        cacheKey: _buildHomeCacheKey(lat: lat, lng: lng),
        ttl: _homeTtl,
        decodeInBackground: true,
      ),
    );
  }

  Future<List<Offer>> getRecommendedOffers() {
    return _apiClient.getParsed<List<Offer>>(
      _buildHomeEndpoint(),
      parser: parseRecommendedOffersFromHomeResponse,
      options: const ApiReadOptions(
        cacheKey: 'home:recommended',
        ttl: _homeTtl,
        decodeInBackground: true,
      ),
    );
  }

  Stream<List<Offer>> watchRecommendedOffers() {
    return _apiClient.watchParsed<List<Offer>>(
      _buildHomeEndpoint(),
      parser: parseRecommendedOffersFromHomeResponse,
      options: const ApiReadOptions(
        cacheKey: 'home:recommended',
        ttl: _homeTtl,
        decodeInBackground: true,
      ),
    );
  }

  String _buildHomeEndpoint({double? lat, double? lng}) {
    final query = lat != null && lng != null ? '?lat=$lat&lng=$lng' : '';
    return '/user/home$query';
  }

  String _buildHomeCacheKey({double? lat, double? lng}) {
    if (lat == null || lng == null) {
      return 'home:recommended';
    }

    return 'home:lat=${lat.toStringAsFixed(3)}:lng=${lng.toStringAsFixed(3)}';
  }
}
