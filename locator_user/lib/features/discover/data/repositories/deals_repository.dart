import '../../../../shared/models/offer.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dealsRepositoryProvider = Provider<DealsRepository>((ref) {
  return DealsRepository(apiClient: ref.watch(apiClientProvider));
});

final dealsProvider = StreamProvider<List<Offer>>((ref) {
  return ref.watch(dealsRepositoryProvider).getOffers();
});

final dealsByCategoryProvider = StreamProvider.family<List<Offer>, String>((
  ref,
  category,
) {
  return ref.watch(dealsRepositoryProvider).getOffersByCategory(category);
});

/// Repository for handling all deal-related data operations via the custom backend API.
class DealsRepository {
  DealsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Fetches all active offers.
  Stream<List<Offer>> getOffers({double? lat, double? lng}) async* {
    try {
      final queryParams = lat != null && lng != null
          ? '?lat=$lat&lng=$lng'
          : '';
      final response = await _apiClient.get('/user/offers/nearby$queryParams');
      if (response != null &&
          response['success'] == true &&
          response['data'] != null) {
        final List<dynamic> list = response['data'];
        final offers = list.map((json) => Offer.fromJson(json)).toList();
        yield offers;
      } else {
        yield const [];
      }
    } catch (_) {
      yield const [];
    }
  }

  /// Fetches active offers by category.
  Stream<List<Offer>> getOffersByCategory(String category) async* {
    try {
      final response = await _apiClient.get('/user/offers/nearby?category=$category');
      if (response != null &&
          response['success'] == true &&
          response['data'] != null) {
        final List<dynamic> list = response['data'];
        final offers = list.map((json) => Offer.fromJson(json)).toList();
        if (offers.isNotEmpty) {
          yield offers;
          return;
        }
      }
      yield const [];
    } catch (_) {
      yield const [];
    }
  }

  /// Redeems an offer for a user.
  Future<void> redeemOffer(String userId, Offer offer) async {
    try {
      final response = await _apiClient.post('/user/offer/${offer.id}/redeem');

      if (response == null || response['success'] != true) {
        throw const ServerFailure('Redemption failed', 500);
      }
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

}
