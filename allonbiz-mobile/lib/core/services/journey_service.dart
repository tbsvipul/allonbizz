import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journey_model.dart';
import '../network/api_client.dart';
import '../network/api_parsers.dart';
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
    } catch (_) {
      // Return a temporary local ID if needed? For now, just return null if fail.
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
      debugPrint('Journey progress update failed: $e');
    }
  }

  Future<void> endJourney({
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
    } catch (e) {
      debugPrint('End journey failed: $e');
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
            .map(parseShopJson)
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
      debugPrint('Fetch nearby shops failed: $e');
      return const <Shop>[];
    }
  }

  Stream<List<JourneyModel>> getUserJourneys() async* {
    try {
      final response = await _apiClient.get('/user/journeys');
      if (_isSuccess(response) && response['data'] != null) {
        final List<dynamic> list = response['data'];
        yield list.map((json) => JourneyModel.fromJson(json)).toList();
      } else {
        yield [];
      }
    } catch (_) {
      yield [];
    }
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
