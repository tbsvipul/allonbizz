import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../core/services/current_location_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/offer.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(apiClient: ref.watch(apiClientProvider));
});

final homeOffersProvider = FutureProvider<List<Offer>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  final location = ref.watch(currentLocationProvider);

  if (location.position == null) {
    // If no location yet, we might fetch without lat/lng or wait
    return repo.getRecommendedOffers();
  }
  return repo.getNearbyOffers(
    location.position!.latitude,
    location.position!.longitude,
  );
});

final homeTagsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  final data = await repo.getHomeData();
  return data['featuredTags'] ?? data['FeaturedTags'] ?? [];
});

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> getHomeData({double? lat, double? lng}) async {
    try {
      final query = lat != null && lng != null ? '?lat=$lat&lng=$lng' : '';
      final response = await _apiClient.get('/user/home$query');
      return response['data'] ?? {};
    } catch (e) {
      Logger().e('Failed to fetch home data: $e');
      return {};
    }
  }

  Future<List<Offer>> getNearbyOffers(double lat, double lng) async {
    final data = await getHomeData(lat: lat, lng: lng);
    return _mapHomeDataToOffers(data);
  }

  Future<List<Offer>> getRecommendedOffers() async {
    final data = await getHomeData();
    return _mapHomeDataToOffers(data);
  }

  List<Offer> _mapHomeDataToOffers(Map<String, dynamic> data) {
    final List<Offer> mappedOffers = [];

    final nearbyShops = data['nearbyShops'] as List? ?? data['NearbyShops'] as List? ?? [];
    for (var shop in nearbyShops) {
      mappedOffers.add(Offer.fromJson(shop));
    }

    final recommended = data['recommendedOffers'] as List? ?? data['RecommendedOffers'] as List? ?? [];
    for (var rec in recommended) {
      mappedOffers.add(Offer.fromJson(rec));
    }

    return mappedOffers;
  }
}
