import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';

final favouritesRepositoryProvider = Provider<FavouritesRepository>((ref) {
  return FavouritesRepository(apiClient: ref.watch(apiClientProvider));
});

class FavouritesRepository {
  final ApiClient _apiClient;

  FavouritesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<dynamic>> getFavourites() async {
    try {
      final response = await _apiClient.get('/user/favourites');
      return response['data'] ?? [];
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<void> toggleFavourite({String? shopId, String? offerId}) async {
    try {
      await _apiClient.post('/user/favourites', body: {
        'shopId': ?shopId,
        'offerId': ?offerId,
      });
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }
}
