import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/offer.dart';

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  return OffersRepository(apiClient: ref.watch(apiClientProvider));
});

class OffersRepository {
  final ApiClient _apiClient;

  OffersRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Offer>> getNearbyOffers({required double lat, required double lng}) async {
    try {
      final response = await _apiClient.get('/user/offers/nearby?lat=$lat&lng=$lng');
      final data = response['data'];
      if (data is List) {
        return data.map((e) => Offer.fromJson(e)).toList();
      }
      return [];
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<Offer> getOfferDetail(String offerId) async {
    try {
      final response = await _apiClient.get('/user/offer/$offerId');
      final data = response['data'];
      if (data == null) throw const DatabaseFailure('Offer not found');
      return Offer.fromJson(data);
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<void> saveOffer(String offerId) async {
    try {
      await _apiClient.post('/user/offer/$offerId/save');
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<void> redeemOffer(String offerId) async {
    try {
      await _apiClient.post('/user/offer/$offerId/redeem');
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<void> rateOffer(String offerId, int rating, String? comment) async {
    try {
      await _apiClient.post('/user/offer/$offerId/rate', body: {
        'rating': rating,
        'comment': comment,
      });
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<List<dynamic>> getOfferReviews(String offerId) async {
    try {
      final response = await _apiClient.get('/reviews?offerId=$offerId');
      return response['data'] ?? [];
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }
}
