import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/models/journey_model.dart';

final journeysRepositoryProvider = Provider<JourneysRepository>((ref) {
  return JourneysRepository(apiClient: ref.watch(apiClientProvider));
});

class JourneysRepository {
  final ApiClient _apiClient;

  JourneysRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<String> startJourney({
    required String type,
    required double startLat,
    required double startLng,
    String? startName,
    String? destinationName,
    double? destLat,
    double? destLng,
    List<String> tags = const [],
  }) async {
    try {
      final response = await _apiClient.post(
        '/user/journeys/start',
        body: {
          'startName': startName ?? 'Current Location',
          'startLat': startLat,
          'startLng': startLng,
          'type': type,
          'tags': tags,
          'destinationName': destinationName,
          'destLat': destLat,
          'destLng': destLng,
        },
      );
      final data = response['data'];
      if (data == null || data['journeyId'] == null) throw const DatabaseFailure('Failed to start journey');
      return data['journeyId'].toString();
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<void> updateProgress({
    required String journeyId,
    required double lat,
    required double lng,
    required double distance,
    required int duration,
  }) async {
    try {
      await _apiClient.post(
        '/user/journeys/$journeyId/progress',
        body: {
          'currentLat': lat,
          'currentLng': lng,
          'distance': distance,
          'duration': duration,
        },
      );
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<void> endJourney({
    required String journeyId,
    required double lat,
    required double lng,
    String? name,
    double? distance,
    int? duration,
  }) async {
    try {
      await _apiClient.post(
        '/user/journeys/$journeyId/end',
        body: {
          'endName': name ?? 'Destination',
          'endLat': lat,
          'endLng': lng,
          'distance': distance ?? 0.0,
          'duration': duration ?? 0,
        },
      );
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<ApiPage<JourneyModel>> getJourneys({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _apiClient.get('/user/journeys?pageNumber=$page&pageSize=$pageSize');
      return ApiPage.fromJson(response, (json) => JourneyModel.fromJson(json as Map<String, dynamic>));
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }

  Future<List<dynamic>> getNearbyShops(String journeyId, double lat, double lng) async {
    try {
      final response = await _apiClient.get('/user/journeys/$journeyId/near?lat=$lat&lng=$lng');
      return response['data'] ?? [];
    } on ServerFailure catch (e) {
      throw DatabaseFailure(e.message);
    }
  }
}
