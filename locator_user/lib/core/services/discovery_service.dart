import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discovery_model.dart';
import '../network/api_client.dart';

final discoveryServiceProvider = Provider((ref) {
  return DiscoveryService(apiClient: ref.watch(apiClientProvider));
});

class DiscoveryService {
  final ApiClient _apiClient;

  DiscoveryService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get('/categories');
      final items = _responseList(response);
      if (items.isNotEmpty) {
        final categories = _flattenCategories(items)
            .map((json) => CategoryModel.fromJson(json))
            .where((category) => category.label.trim().isNotEmpty)
            .toList();
        if (categories.isNotEmpty) {
          return categories;
        }
      }
      return const [];
    } catch (error) {
      debugPrint('API Categories Error: $error');
      return const [];
    }
  }

  Future<List<TagModel>> getTags() async {
    try {
      final response = await _apiClient.get('/public/tags');
      final items = _responseList(response);
      if (items.isNotEmpty) {
        return items
            .map((json) => TagModel.fromJson(Map<String, dynamic>.from(json)))
            .where((tag) => tag.name.trim().isNotEmpty)
            .toList();
      }
      return const [];
    } catch (error) {
      debugPrint('API Tags Error: $error');
      return const [];
    }
  }

  Future<void> addTag(TagModel tag) async {
    // Custom tags are only kept locally in the search UI.
    // A public tag creation API could be added in the future.
  }

  List<dynamic> _responseList(dynamic response) {
    final data = response?['data'] ?? response?['Data'];
    if (data is List) {
      return data;
    }
    return const [];
  }

  List<Map<String, dynamic>> _flattenCategories(List<dynamic> items) {
    final flattened = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item is! Map) continue;
      final json = Map<String, dynamic>.from(item);
      flattened.add(json);

      final children = json['children'] ?? json['Children'];
      if (children is List && children.isNotEmpty) {
        flattened.addAll(_flattenCategories(children));
      }
    }

    return flattened;
  }
}

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(discoveryServiceProvider).getCategories();
});

final tagsProvider = FutureProvider<List<TagModel>>((ref) {
  return ref.watch(discoveryServiceProvider).getTags();
});
