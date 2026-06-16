import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_parsers.dart';
import '../../../../shared/models/shop.dart';

final shopsRepositoryProvider = Provider<ShopsRepository>((ref) {
  return ShopsRepository(apiClient: ref.watch(apiClientProvider));
});

class ShopsRepository {
  ShopsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static const Duration _detailTtl = Duration(minutes: 10);

  final ApiClient _apiClient;

  Future<Shop> getShopDetail(String shopId) async {
    try {
      return _apiClient.getParsed<Shop>(
        '/user/shops/$shopId',
        parser: parseShopEnvelope,
        options: ApiReadOptions(
          cacheKey: 'shop-detail:$shopId',
          ttl: _detailTtl,
          decodeInBackground: true,
        ),
      );
    } on ServerFailure catch (error) {
      throw DatabaseFailure(error.message);
    }
  }

  Future<void> saveShop(String shopId) async {
    try {
      await _apiClient.post(
        '/user/favourites',
        body: {'shopId': shopId},
      );
      await _invalidateShopCaches(shopId);
    } on ServerFailure catch (error) {
      throw DatabaseFailure(error.message);
    }
  }

  Future<void> _invalidateShopCaches(String shopId) async {
    await Future.wait([
      _apiClient.invalidateCacheKey('shop-detail:$shopId'),
    ]);
  }
}
