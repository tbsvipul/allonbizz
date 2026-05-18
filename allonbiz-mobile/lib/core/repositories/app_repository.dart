import 'dart:math';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../network/api_client.dart';

class AppRepository {
  AppRepository({required ApiClient apiClient, required AppConfig config})
    : _apiClient = apiClient,
      _photonDio = Dio(
        BaseOptions(
          baseUrl: config.photonBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      ),
      _osrmDio = Dio(
        BaseOptions(
          baseUrl: config.osrmBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

  final ApiClient _apiClient;
  final Dio _photonDio;
  final Dio _osrmDio;

  Future<UserHomeData> getHome({double? lat, double? lng}) async {
    final payload = await _apiClient.getData(
      '/user/home',
      queryParameters: {
        ...?lat != null ? {'lat': lat} : null,
        ...?lng != null ? {'lng': lng} : null,
      },
    );
    return UserHomeData.fromJson(Map<String, dynamic>.from(payload as Map));
  }

  Future<SavingsSummary> getSavings() async {
    final payload = await _apiClient.getData('/user/savings');
    return SavingsSummary.fromJson(Map<String, dynamic>.from(payload as Map));
  }

  Future<LoyaltySummary> getLoyalty() async {
    final payload = await _apiClient.getData('/user/loyalty/wallet');
    return LoyaltySummary.fromJson(Map<String, dynamic>.from(payload as Map));
  }

  Future<List<CategorySummary>> getCategories() async {
    final payload = await _apiClient.getData(
      '/categories',
      authenticated: false,
    );
    return (payload as List<dynamic>)
        .map(
          (item) =>
              CategorySummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<TagItem>> getPublicTags() async {
    final payload = await _apiClient.getData(
      '/public/tags',
      authenticated: false,
    );
    return (payload as List<dynamic>)
        .map((item) => TagItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<OfferSummary>> getTrendingOffers() async {
    final payload = await _apiClient.getData(
      '/offers/trending',
      authenticated: false,
    );
    return (payload as List<dynamic>)
        .map(
          (item) =>
              OfferSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<SavedItem>> getSavedItems() async {
    final payload = await _apiClient.getData('/user/favourites');
    return (payload as List<dynamic>)
        .map(
          (item) => SavedItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<UserNotificationItem>> getNotifications() async {
    final payload = await _apiClient.getData('/user/notifications');
    final page = Map<String, dynamic>.from(payload as Map);
    final items = page['data'] as List<dynamic>? ?? const [];
    return items
        .map(
          (item) => UserNotificationItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> markNotificationRead(String notificationId) =>
      _apiClient.postData('/user/notifications/$notificationId/read');

  Future<List<JourneySession>> getJourneys() async {
    final payload = await _apiClient.getData('/user/journeys');
    return (payload as List<dynamic>)
        .map(
          (item) =>
              JourneySession.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<JourneyDetail> getJourneyDetail(String journeyId) async {
    final payload = await _apiClient.getData('/user/journeys/$journeyId');
    return JourneyDetail.fromJson(Map<String, dynamic>.from(payload as Map));
  }

  Future<OfferDetail> getOfferDetail(String offerId) async {
    final payload = await _apiClient.getData('/user/offer/$offerId');
    return OfferDetail.fromJson(Map<String, dynamic>.from(payload as Map));
  }

  Future<ShopDetail> getShopDetail(String shopId) async {
    final payload = await _apiClient.getData('/user/shops/$shopId');
    return ShopDetail.fromJson(Map<String, dynamic>.from(payload as Map));
  }

  Future<void> redeemOffer(String offerId) =>
      _apiClient.postData('/user/offer/$offerId/redeem');

  Future<void> saveOffer(String offerId) =>
      _apiClient.postData('/user/offer/$offerId/save');

  Future<void> rateOffer(
    String offerId, {
    required int rating,
    String? comment,
  }) => _apiClient.postData(
    '/user/offer/$offerId/rate',
    data: {'rating': rating, 'comment': comment},
  );

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) => _apiClient.putData(
    '/user/profile',
    data: {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
    },
  );

  Future<void> uploadFcmToken(String token) =>
      _apiClient.postData('/user/fcm-token', data: {'token': token});

  Future<List<OfferSummary>> getNearbyOffers({
    double? lat,
    double? lng,
    required double radiusKm,
    String? category,
    List<String>? tags,
  }) async {
    final payload = await _apiClient.getData(
      '/user/offers/nearby',
      queryParameters: {
        ...?lat != null ? {'lat': lat} : null,
        ...?lng != null ? {'lng': lng} : null,
        'radiusKm': radiusKm,
        ...?category != null && category.isNotEmpty
            ? {'category': category}
            : null,
        ...?tags != null && tags.isNotEmpty ? {'tags': tags} : null,
      },
    );
    return (payload as List<dynamic>)
        .map(
          (item) =>
              OfferSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return const [];
    }

    try {
      final response = await _photonDio.get<Map<String, dynamic>>(
        '/api',
        queryParameters: {'q': query, 'limit': 8},
      );
      final features = response.data?['features'] as List<dynamic>? ?? const [];
      return features
          .map(
            (item) => PlaceSuggestion.fromPhoton(item as Map<String, dynamic>),
          )
          .where(
            (item) => item.point.latitude != 0 || item.point.longitude != 0,
          )
          .toList();
    } catch (_) {
      final payload = await _apiClient.getData(
        '/places/search',
        queryParameters: {'query': query},
        authenticated: false,
      );
      return (payload as List<dynamic>)
          .map(
            (item) =>
                PlaceSuggestion.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
  }

  Future<String> reverseGeocode(GeoPoint point) async {
    final response = await _photonDio.get<Map<String, dynamic>>(
      '/reverse',
      queryParameters: {'lat': point.latitude, 'lon': point.longitude},
    );
    final features = response.data?['features'] as List<dynamic>? ?? const [];
    if (features.isEmpty) {
      return 'Current location';
    }
    final label =
        ((features.first as Map<String, dynamic>)['properties']
            as Map<String, dynamic>?)?['label'];
    return label?.toString() ?? 'Current location';
  }

  Future<RoutePlan> buildRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    try {
      final response = await _osrmDio.get<Map<String, dynamic>>(
        '/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}',
        queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
      );

      final routes = response.data?['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) {
        return _fallbackRoute(origin, destination);
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>? ?? const {};
      final coordinates = geometry['coordinates'] as List<dynamic>? ?? const [];

      return RoutePlan(
        points: coordinates
            .map((item) => item as List<dynamic>)
            .where((item) => item.length >= 2)
            .map(
              (item) => GeoPoint(
                latitude: _doubleFrom(item[1]),
                longitude: _doubleFrom(item[0]),
              ),
            )
            .toList(),
        distanceKm: _doubleFrom(route['distance']) / 1000,
        durationMinutes: (_doubleFrom(route['duration']) / 60).round(),
        approximate: false,
      );
    } catch (_) {
      return _fallbackRoute(origin, destination);
    }
  }

  Future<String> startJourney({
    required String startName,
    required GeoPoint startPoint,
    required String type,
    required List<String> tags,
    String? destinationName,
    GeoPoint? destinationPoint,
  }) async {
    final payload = await _apiClient.postData(
      '/user/journeys/start',
      data: {
        'startName': startName,
        'startLat': startPoint.latitude,
        'startLng': startPoint.longitude,
        'type': type,
        'tags': tags,
        'destinationName': destinationName,
        'destLat': destinationPoint?.latitude,
        'destLng': destinationPoint?.longitude,
      },
    );
    return payload['journeyId']?.toString() ?? '';
  }

  Future<void> updateJourneyProgress({
    required String journeyId,
    required GeoPoint currentPoint,
    required double distanceMeters,
    required int durationSeconds,
    required List<String> shopsEncountered,
  }) => _apiClient.postData(
    '/user/journeys/$journeyId/progress',
    data: {
      'currentLat': currentPoint.latitude,
      'currentLng': currentPoint.longitude,
      'distance': distanceMeters,
      'duration': durationSeconds,
      'shopsEncountered': shopsEncountered,
    },
  );

  Future<void> endJourney({
    required String journeyId,
    required String endName,
    required GeoPoint endPoint,
    required double distanceMeters,
    required int durationSeconds,
    required List<String> shopsEncountered,
  }) => _apiClient.postData(
    '/user/journeys/$journeyId/end',
    data: {
      'endName': endName,
      'endLat': endPoint.latitude,
      'endLng': endPoint.longitude,
      'distance': distanceMeters,
      'duration': durationSeconds,
      'shopsEncountered': shopsEncountered,
    },
  );

  RoutePlan _fallbackRoute(GeoPoint origin, GeoPoint destination) {
    final midLatitude = (origin.latitude + destination.latitude) / 2;
    final midLongitude = (origin.longitude + destination.longitude) / 2;
    final arcOffset =
        max(
          (origin.latitude - destination.latitude).abs(),
          (origin.longitude - destination.longitude).abs(),
        ) /
        3;
    final curvedMid = GeoPoint(
      latitude: midLatitude + arcOffset,
      longitude: midLongitude - arcOffset,
    );

    return RoutePlan(
      points: [origin, curvedMid, destination],
      distanceKm: _distanceMeters(origin, destination) / 1000,
      durationMinutes: max(
        1,
        (_distanceMeters(origin, destination) / 900).round(),
      ),
      approximate: true,
    );
  }

  double _distanceMeters(GeoPoint a, GeoPoint b) {
    const earthRadius = 6371000.0;
    final dLat = _radians(b.latitude - a.latitude);
    final dLon = _radians(b.longitude - a.longitude);
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);

    final haversine =
        sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    return earthRadius * 2 * atan2(sqrt(haversine), sqrt(1 - haversine));
  }

  double _radians(double degrees) => degrees * pi / 180;
}

double _doubleFrom(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}
