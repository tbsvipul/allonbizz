import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/models/journey_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';

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
      if (data == null || data['journeyId'] == null) {
        throw const DatabaseFailure('Failed to start journey');
      }
      return data['journeyId'].toString();
    } on ServerFailure catch (e, stack) {
      AppLogger.error('Error starting journey', error: e, stackTrace: stack);
      throw DatabaseFailure(e.message);
    } catch (e, stack) {
      AppLogger.error('Unexpected error starting journey', error: e, stackTrace: stack);
      throw const DatabaseFailure('Unexpected error starting journey');
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
    } on ServerFailure catch (e, stack) {
      AppLogger.error('Error updating journey progress', error: e, stackTrace: stack);
      throw DatabaseFailure(e.message);
    } catch (e, stack) {
      AppLogger.error('Unexpected error updating journey progress', error: e, stackTrace: stack);
      throw const DatabaseFailure('Unexpected error updating journey progress');
    }
  }

  Future<void> endJourney({
    required String journeyId,
    required double lat,
    required double lng,
    String? name,
    double? distance,
    int? duration,
    List<String>? shopsEncountered,
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
          'shopsEncountered': shopsEncountered ?? const [],
        },
      );
    } on ServerFailure catch (e, stack) {
      AppLogger.error('Error ending journey (destination)', error: e, stackTrace: stack);
      throw DatabaseFailure(e.message);
    } catch (e, stack) {
      AppLogger.error('Unexpected error ending journey', error: e, stackTrace: stack);
      throw const DatabaseFailure('Unexpected error ending journey');
    }
  }

  Future<ApiPage<JourneyModel>> getJourneys({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final journeys = await getJourneyHistory();
      final safePage = page < 1 ? 1 : page;
      final safePageSize = pageSize < 1 ? 10 : pageSize;
      final startIndex = (safePage - 1) * safePageSize;
      final endIndex = startIndex + safePageSize > journeys.length
          ? journeys.length
          : startIndex + safePageSize;

      final items = startIndex >= journeys.length
          ? const <JourneyModel>[]
          : journeys.sublist(startIndex, endIndex);
      final totalPages = journeys.isEmpty
          ? 0
          : (journeys.length / safePageSize).ceil();

      return ApiPage<JourneyModel>(
        items: items,
        pagination: PaginationMeta(
          page: safePage,
          pageSize: safePageSize,
          totalCount: journeys.length,
          totalPages: totalPages,
          hasNextPage: startIndex + safePageSize < journeys.length,
          hasPreviousPage: safePage > 1,
        ),
      );
    } on ServerFailure catch (e, stack) {
      AppLogger.error('Error getting journeys', error: e, stackTrace: stack);
      throw DatabaseFailure(e.message);
    } catch (e, stack) {
      AppLogger.error('Unexpected error getting journeys', error: e, stackTrace: stack);
      throw const DatabaseFailure('Unexpected error getting journeys');
    }
  }

  Future<List<JourneyModel>> getJourneyHistory() async {
    try {
      return _apiClient.getList<JourneyModel>(
        '/user/journeys',
        parser: JourneyModel.fromJson,
        options: const ApiReadOptions(
          cacheKey: 'journeys:history',
          ttl: Duration(minutes: 5),
          decodeInBackground: true,
        ),
      );
    } on ServerFailure catch (e, stack) {
      AppLogger.error('Error getting journey history', error: e, stackTrace: stack);
      throw DatabaseFailure(e.message);
    } catch (e, stack) {
      AppLogger.error('Unexpected error getting journey history', error: e, stackTrace: stack);
      throw const DatabaseFailure('Unexpected error getting journey history');
    }
  }

  Future<List<JourneyModel>> getRecentJourneys({
    int limit = 3,
    bool completedOnly = false,
  }) async {
    if (limit <= 0) {
      return const <JourneyModel>[];
    }

    final journeys = await getJourneyHistory();
    final filteredJourneys = completedOnly
        ? journeys.where((journey) => journey.isCompleted)
        : journeys;
    return filteredJourneys.take(limit).toList(growable: false);
  }

  Future<JourneyModel?> getActiveJourney() async {
    final journeys = await getJourneyHistory();
    for (final journey in journeys) {
      if (!journey.isCompleted) {
        return journey;
      }
    }

    return null;
  }

  Future<JourneyModel> getJourneyDetail(String journeyId) async {
    try {
      return _apiClient.getObject<JourneyModel>(
        '/user/journeys/$journeyId',
        parser: JourneyModel.fromJson,
        options: ApiReadOptions(
          cacheKey: 'journey-detail:$journeyId',
          ttl: const Duration(minutes: 5),
          decodeInBackground: true,
        ),
      );
    } on ServerFailure catch (e, stack) {
      AppLogger.error('Error getting journey detail', error: e, stackTrace: stack);
      throw DatabaseFailure(e.message);
    } catch (e, stack) {
      AppLogger.error('Unexpected error getting journey detail', error: e, stackTrace: stack);
      throw const DatabaseFailure('Unexpected error getting journey detail');
    }
  }

  Future<List<dynamic>> getNearbyShops(
    String journeyId,
    double lat,
    double lng,
  ) async {
    try {
      final response = await _apiClient.get(
        '/user/journeys/$journeyId/near?lat=$lat&lng=$lng',
      );
      return response['data'] ?? [];
    } on ServerFailure catch (e, stack) {
      AppLogger.error('Error getting nearby shops', error: e, stackTrace: stack);
      throw DatabaseFailure(e.message);
    } catch (e, stack) {
      AppLogger.error('Unexpected error getting nearby shops', error: e, stackTrace: stack);
      throw const DatabaseFailure('Unexpected error getting nearby shops');
    }
  }
}
