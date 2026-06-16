import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_parsers.dart';
import '../../../../shared/models/offer.dart';

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  return OffersRepository(apiClient: ref.watch(apiClientProvider));
});

class OffersRepository {
  OffersRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static const Duration _offersTtl = Duration(seconds: 90);
  static const Duration _detailTtl = Duration(minutes: 10);

  final ApiClient _apiClient;

  Future<List<Offer>> getNearbyOffers({
    required double lat,
    required double lng,
  }) async {
    try {
      final endpoint = '/user/offers/nearby?lat=$lat&lng=$lng';
      return _apiClient.getParsed<List<Offer>>(
        endpoint,
        parser: parseOffersEnvelope,
        options: ApiReadOptions(
          cacheKey:
              'offers:nearby:lat=${lat.toStringAsFixed(3)}:lng=${lng.toStringAsFixed(3)}',
          ttl: _offersTtl,
          decodeInBackground: true,
        ),
      );
    } on ServerFailure catch (error) {
      throw DatabaseFailure(error.message);
    }
  }

  Future<Offer> getOfferDetail(String offerId) async {
    try {
      return _apiClient.getObject<Offer>(
        '/user/offer/$offerId',
        parser: parseOfferJson,
        options: ApiReadOptions(
          cacheKey: 'offer-detail:$offerId',
          ttl: _detailTtl,
          decodeInBackground: true,
        ),
      );
    } on ServerFailure catch (error) {
      throw DatabaseFailure(error.message);
    }
  }

  Future<void> saveOffer(String offerId) async {
    try {
      await _apiClient.post(
        '/user/favourites',
        body: {'offerId': offerId},
      );
      await _invalidateOfferCaches(offerId);
    } on ServerFailure catch (error) {
      throw DatabaseFailure(error.message);
    }
  }



  Future<void> rateOffer(String offerId, int rating, String? comment) async {
    try {
      await _apiClient.post(
        '/user/offer/$offerId/rate',
        body: {'rating': rating, 'comment': comment},
      );
      await _invalidateOfferCaches(offerId);
    } on ServerFailure catch (error) {
      throw DatabaseFailure(error.message);
    }
  }

  Future<List<dynamic>> getOfferReviews(String offerId) async {
    try {
      final response = await _apiClient.get('/reviews?offerId=$offerId');
      return response['data'] ?? [];
    } on ServerFailure catch (error) {
      throw DatabaseFailure(error.message);
    }
  }

  Future<void> _invalidateOfferCaches(String offerId) async {
    await Future.wait([
      _apiClient.invalidateCacheByPrefix('offers:'),
      _apiClient.invalidateCacheByPrefix('home:'),
      _apiClient.invalidateCacheByPrefix('shop-detail:'),
      _apiClient.invalidateCacheKey('offer-detail:$offerId'),
    ]);
  }
}
