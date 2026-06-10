import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_parsers.dart';
import '../../../../core/services/current_location_provider.dart';
import '../../../home/data/repositories/home_repository.dart';
import '../../../../shared/models/offer.dart';

final dealsRepositoryProvider = Provider<DealsRepository>((ref) {
  return DealsRepository(apiClient: ref.watch(apiClientProvider));
});

final dealsProvider = StreamProvider<List<Offer>>((ref) {
  final position = ref.watch(
    currentLocationProvider.select((location) => location.position),
  );
  if (position == null) {
    return Stream.value(const <Offer>[]);
  }

  return ref
      .watch(dealsRepositoryProvider)
      .watchOffers(lat: position.latitude, lng: position.longitude);
});

final featuredDealsProvider = StreamProvider<List<Offer>>((ref) {
  final position = ref.watch(
    currentLocationProvider.select((location) => location.position),
  );
  final repository = ref.watch(dealsRepositoryProvider);

  if (position == null) {
    return ref.watch(homeRepositoryProvider).watchRecommendedOffers();
  }

  return repository.watchOffers(
    lat: position.latitude,
    lng: position.longitude,
  );
});

final dealsByCategoryProvider = StreamProvider.family<List<Offer>, String>((
  ref,
  category,
) {
  return ref.watch(dealsRepositoryProvider).watchOffers(category: category);
});

/// Repository for handling all deal-related data operations via the custom backend API.
class DealsRepository {
  DealsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static const Duration _offersTtl = Duration(seconds: 90);

  final ApiClient _apiClient;

  Future<List<Offer>> fetchOffers({
    double? lat,
    double? lng,
    double? radiusKm,
    String? category,
    List<String> tags = const [],
  }) {
    final endpoint = _buildNearbyOffersEndpoint(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      category: category,
      tags: tags,
    );

    return _apiClient.getParsed<List<Offer>>(
      endpoint,
      parser: parseOffersEnvelope,
      options: ApiReadOptions(
        cacheKey: _buildNearbyOffersCacheKey(
          lat: lat,
          lng: lng,
          radiusKm: radiusKm,
          category: category,
          tags: tags,
        ),
        ttl: _offersTtl,
        decodeInBackground: true,
      ),
    );
  }

  Stream<List<Offer>> watchOffers({
    double? lat,
    double? lng,
    double? radiusKm,
    String? category,
    List<String> tags = const [],
  }) {
    final endpoint = _buildNearbyOffersEndpoint(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      category: category,
      tags: tags,
    );

    return _apiClient.watchParsed<List<Offer>>(
      endpoint,
      parser: parseOffersEnvelope,
      options: ApiReadOptions(
        cacheKey: _buildNearbyOffersCacheKey(
          lat: lat,
          lng: lng,
          radiusKm: radiusKm,
          category: category,
          tags: tags,
        ),
        ttl: _offersTtl,
        decodeInBackground: true,
      ),
    );
  }

  Future<List<Offer>> fetchOffersByCategory(String category) {
    return fetchOffers(category: category);
  }

  Stream<List<Offer>> watchOffersByCategory(String category) {
    return watchOffers(category: category);
  }



  Future<void> _invalidateOfferCaches(String offerId) async {
    await Future.wait([
      _apiClient.invalidateCacheByPrefix('offers:'),
      _apiClient.invalidateCacheByPrefix('home:'),
      _apiClient.invalidateCacheByPrefix('shop-detail:'),
      _apiClient.invalidateCacheKey('offer-detail:$offerId'),
    ]);
  }

  String _buildNearbyOffersEndpoint({
    double? lat,
    double? lng,
    double? radiusKm,
    String? category,
    List<String> tags = const [],
  }) {
    final normalizedTags = _normalizeTags(tags);
    final queryParts = <String>[
      if (lat != null) 'lat=$lat',
      if (lng != null) 'lng=$lng',
      if (radiusKm != null) 'radius=$radiusKm',
      if (category != null && category.trim().isNotEmpty)
        'category=${Uri.encodeQueryComponent(category.trim())}',
      for (final tag in normalizedTags) 'tags=${Uri.encodeQueryComponent(tag)}',
    ];
    final query = queryParts.isEmpty ? '' : '?${queryParts.join('&')}';
    return '/user/offers/nearby$query';
  }

  String _buildNearbyOffersCacheKey({
    double? lat,
    double? lng,
    double? radiusKm,
    String? category,
    List<String> tags = const [],
  }) {
    final normalizedTags = _normalizeTags(tags);
    final buffer = StringBuffer('offers:nearby');
    if (lat != null) {
      buffer.write(':lat=${lat.toStringAsFixed(3)}');
    }
    if (lng != null) {
      buffer.write(':lng=${lng.toStringAsFixed(3)}');
    }
    if (radiusKm != null) {
      buffer.write(':radius=${radiusKm.toStringAsFixed(3)}');
    }
    final trimmedCategory = category?.trim();
    if (trimmedCategory != null && trimmedCategory.isNotEmpty) {
      buffer.write(':category=${trimmedCategory.toLowerCase()}');
    }
    if (normalizedTags.isNotEmpty) {
      buffer.write(':tags=${normalizedTags.join(",").toLowerCase()}');
    }
    return buffer.toString();
  }

  List<String> _normalizeTags(List<String> tags) {
    return tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }
}
