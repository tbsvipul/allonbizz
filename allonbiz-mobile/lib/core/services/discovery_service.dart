import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discovery_model.dart';
import '../network/api_client.dart';
import '../network/api_parsers.dart';

final discoveryServiceProvider = Provider((ref) {
  return DiscoveryService(apiClient: ref.watch(apiClientProvider));
});

class DiscoveryService {
  DiscoveryService({required ApiClient apiClient}) : _apiClient = apiClient;

  static const Duration _taxonomyTtl = Duration(hours: 12);

  final ApiClient _apiClient;

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      return _apiClient.getParsed<List<CategoryModel>>(
        '/categories',
        parser: parseCategoriesEnvelope,
        options: const ApiReadOptions(
          cacheKey: 'categories',
          ttl: _taxonomyTtl,
          decodeInBackground: true,
        ),
      );
    } catch (error) {
      debugPrint('API Categories Error: $error');
      return const [];
    }
  }

  Stream<List<CategoryModel>> watchCategories() {
    return _apiClient.watchParsed<List<CategoryModel>>(
      '/categories',
      parser: parseCategoriesEnvelope,
      options: const ApiReadOptions(
        cacheKey: 'categories',
        ttl: _taxonomyTtl,
        decodeInBackground: true,
      ),
    );
  }

  Future<List<TagModel>> fetchTags() async {
    try {
      return _apiClient.getParsed<List<TagModel>>(
        '/public/tags',
        parser: parseTagsEnvelope,
        options: const ApiReadOptions(
          cacheKey: 'tags',
          ttl: _taxonomyTtl,
          decodeInBackground: true,
        ),
      );
    } catch (error) {
      debugPrint('API Tags Error: $error');
      return const [];
    }
  }

  Stream<List<TagModel>> watchTags() {
    return _apiClient.watchParsed<List<TagModel>>(
      '/public/tags',
      parser: parseTagsEnvelope,
      options: const ApiReadOptions(
        cacheKey: 'tags',
        ttl: _taxonomyTtl,
        decodeInBackground: true,
      ),
    );
  }

  Future<TagModel?> addTag(String name) async {
    try {
      final response = await _apiClient.post(
        '/public/tags',
        body: {'name': name, 'type': 'public'},
      );
      final envelope = asJsonMap(response);
      final data = envelope['data'] ?? envelope['Data'];
      if (data != null) {
        return parseTagJson(asJsonMap(data));
      }
    } catch (error) {
      debugPrint('API Add Tag Error: $error');
    }
    return null;
  }
}

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(discoveryServiceProvider).watchCategories();
});

final tagsProvider = StreamProvider<List<TagModel>>((ref) {
  return ref.watch(discoveryServiceProvider).watchTags();
});
