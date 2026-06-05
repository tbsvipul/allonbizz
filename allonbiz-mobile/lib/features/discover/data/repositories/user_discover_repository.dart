import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_discover_response.dart';

final userDiscoverRepositoryProvider = Provider<UserDiscoverRepository>((ref) {
  return UserDiscoverRepository(apiClient: ref.watch(apiClientProvider));
});

final userDiscoverProvider =
    StreamProvider.family<UserDiscoverResponse, UserDiscoverQuery>((
      ref,
      query,
    ) {
      ref.keepAlive();
      return ref.watch(userDiscoverRepositoryProvider).watchDiscover(query);
    });

class UserDiscoverRepository {
  UserDiscoverRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  static const Duration _discoverTtl = Duration(seconds: 45);

  final ApiClient _apiClient;

  Future<UserDiscoverResponse> fetchDiscover(UserDiscoverQuery query) {
    try {
      return _apiClient.getParsed<UserDiscoverResponse>(
        _buildEndpoint(query),
        parser: UserDiscoverResponse.fromEnvelope,
        options: ApiReadOptions(
          cacheKey: query.cacheKey,
          ttl: _discoverTtl,
          decodeInBackground: true,
        ),
      );
    } on ServerFailure catch (error) {
      throw DatabaseFailure(error.message);
    }
  }

  Stream<UserDiscoverResponse> watchDiscover(UserDiscoverQuery query) {
    return _apiClient.watchParsed<UserDiscoverResponse>(
      _buildEndpoint(query),
      parser: UserDiscoverResponse.fromEnvelope,
      options: ApiReadOptions(
        cacheKey: query.cacheKey,
        ttl: _discoverTtl,
        decodeInBackground: true,
      ),
    );
  }

  String _buildEndpoint(UserDiscoverQuery query) {
    final parts = <String>[
      if (query.search != null && query.search!.trim().isNotEmpty)
        'q=${Uri.encodeQueryComponent(query.search!.trim())}',
      if (query.categoryId != null && query.categoryId!.trim().isNotEmpty)
        'categoryId=${Uri.encodeQueryComponent(query.categoryId!.trim())}',
      if (query.category != null && query.category!.trim().isNotEmpty)
        'category=${Uri.encodeQueryComponent(query.category!.trim())}',
      for (final tag in query.tags) 'tags=${Uri.encodeQueryComponent(tag)}',
      if (query.lat != null) 'lat=${query.lat}',
      if (query.lng != null) 'lng=${query.lng}',
      if (query.radiusKm != null) 'radiusKm=${query.radiusKm}',
      'limit=${query.limit}',
      'includeTaxonomy=${query.includeTaxonomy}',
    ];

    return '/user/discover${parts.isEmpty ? '' : '?${parts.join('&')}'}';
  }
}
