import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/journey_model.dart';
import '../network/api_client.dart';
import '../network/api_parsers.dart';
import '../utils/app_logger.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../shared/models/shop.dart';

final journeyServiceProvider = Provider((ref) {
  return JourneyService(
    apiClient: ref.watch(apiClientProvider),
    authRepo: ref.watch(authRepositoryProvider),
  );
});

final journeysProvider = StreamProvider<List<JourneyModel>>((ref) {
  return ref.watch(journeyServiceProvider).getUserJourneys();
});

class JourneyService {
  final ApiClient _apiClient;

  JourneyService({
    required ApiClient apiClient,
    required AuthRepository authRepo,
  }) : _apiClient = apiClient;

  Future<String?> startJourney({
    required JourneyType type,
    required double startLat,
    required double startLng,
    String? startName,
    String? destinationName,
    double? destLat,
    double? destLng,
    List<String> tags = const [],
  }) async {
    try {
      // PRESERVED: backend journey start payload keys must remain unchanged.
      final res = await _apiClient.post(
        '/user/journeys/start',
        body: {
          'startName': startName ?? 'Current Location',
          'startLat': startLat,
          'startLng': startLng,
          'type': type.name,
          'tags': tags,
          'destinationName': destinationName,
          'destLat': destLat,
          'destLng': destLng,
        },
      );

      if (_isSuccess(res) && res['data'] != null) {
        await _apiClient.invalidateCacheByPrefix('journeys:');
        return res['data']['journeyId']?.toString();
      }
    } catch (e) {
      AppLogger.warning('Start journey failed', error: e);
    }
    return null;
  }

  Future<void> updateJourneyProgress({
    required String journeyId,
    required double currentLat,
    required double currentLng,
    required double distance,
    required int duration,
    List<String>? shopsEncountered,
  }) async {
    try {
      await _apiClient.post(
        '/user/journeys/$journeyId/progress',
        body: {
          'currentLat': currentLat,
          'currentLng': currentLng,
          'distance': distance,
          'duration': duration,
          'shopsEncountered': shopsEncountered ?? [],
        },
      );
    } catch (e) {
      AppLogger.warning('Journey progress update failed', error: e);
    }
  }

  Future<bool> endJourney({
    required String journeyId,
    required double endLat,
    required double endLng,
    String? endName,
    double? finalDistance,
    int? finalDuration,
    List<String>? shopsEncountered,
  }) async {
    try {
      await _apiClient.post(
        '/user/journeys/$journeyId/end',
        body: {
          'endName': endName ?? 'Destination',
          'endLat': endLat,
          'endLng': endLng,
          'distance': finalDistance ?? 0.0,
          'duration': finalDuration ?? 0,
          'shopsEncountered': shopsEncountered ?? const [],
        },
      );
      await _apiClient.invalidateCacheByPrefix('journeys:');
      return true;
    } catch (e) {
      AppLogger.warning('End journey failed', error: e);
      return false;
    }
  }

  Future<List<Shop>> getNearbyShops({
    required String journeyId,
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      return _apiClient.getParsed<List<Shop>>(
        '/user/journeys/$journeyId/near?lat=$lat&lng=$lng&radius=$radiusKm',
        parser: (response) => extractEnvelopeDataList(response)
            .map(parseJourneyNearbyShopJson)
            .where((shop) => shop.id.trim().isNotEmpty)
            .toList(growable: false),
        options: ApiReadOptions(
          cacheKey:
              'journey-nearby-shops:$journeyId:lat=${lat.toStringAsFixed(3)}:lng=${lng.toStringAsFixed(3)}:radius=${radiusKm.toStringAsFixed(1)}',
          ttl: const Duration(seconds: 30),
          decodeInBackground: true,
        ),
      );
    } catch (e) {
      AppLogger.warning('Fetch nearby shops failed', error: e);
      return const <Shop>[];
    }
  }

  Future<List<JourneyModel>> fetchUserJourneys({bool useCache = true}) async {
    try {
      return _apiClient.getParsed<List<JourneyModel>>(
        '/user/journeys',
        parser: (response) => extractEnvelopeDataList(
          response,
        ).map(JourneyModel.fromJson).toList(growable: false),
        options: useCache
            ? const ApiReadOptions(
                cacheKey: 'journeys:history',
                ttl: Duration(minutes: 5),
                decodeInBackground: true,
              )
            : const ApiReadOptions(
                decodeInBackground: true,
                dedupeInFlight: false,
              ),
      );
    } catch (_) {
      return const <JourneyModel>[];
    }
  }

  Stream<List<JourneyModel>> getUserJourneys() async* {
    yield await fetchUserJourneys();
  }

  bool _isSuccess(dynamic response) {
    if (response == null) return false;
    final success =
        response['success'] ??
        response['Success'] ??
        response['isSuccess'] ??
        response['IsSuccess'];
    return success == true || success.toString().toLowerCase() == 'true';
  }
}
