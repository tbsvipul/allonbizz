import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/shop.dart';

final shopsRepositoryProvider = Provider<ShopsRepository>((ref) {
  return ShopsRepository(apiClient: ref.watch(apiClientProvider));
});

class ShopsRepository {
  final ApiClient _apiClient;

  ShopsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Shop> getShopDetail(String shopId) async {
    try {
      final response = await _apiClient.get('/user/shops/$shopId');
      final data = response['data'];
      if (data == null) throw const DatabaseFailure('Shop data missing');
      return Shop.fromJson(data);
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }
}
