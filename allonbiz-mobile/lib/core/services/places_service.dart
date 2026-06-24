import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../network/api_client.dart';
import '../network/base_api.dart';
import '../utils/app_logger.dart';
import '../utils/background_executor.dart';

class PlaceSuggestion {
  final String placeId;
  final String name;
  final String city;
  final String country;
  final double lat;
  final double lon;
  final String description;
  final bool isCurrentLocation;

  // Extra detailed fields for advanced features
  final String? state;
  final String? postcode;
  final String? street;
  final String? houseNumber;

  PlaceSuggestion({
    required this.placeId,
    required this.name,
    required this.city,
    required this.country,
    required this.lat,
    required this.lon,
    required this.description,
    this.isCurrentLocation = false,
    this.state,
    this.postcode,
    this.street,
    this.houseNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'city': city,
      'country': country,
      'lat': lat,
      'lon': lon,
      'description': description,
      'isCurrentLocation': isCurrentLocation,
      'state': state,
      'postcode': postcode,
      'street': street,
      'houseNumber': houseNumber,
    };
  }

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['placeId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      isCurrentLocation: json['isCurrentLocation'] as bool? ?? false,
      state: json['state']?.toString(),
      postcode: json['postcode']?.toString(),
      street: json['street']?.toString(),
      houseNumber: json['houseNumber']?.toString(),
    );
  }

  factory PlaceSuggestion.fromNominatimJson(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
    final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;
    final address = item['address'] as Map<String, dynamic>? ?? {};

    final street =
        address['road']?.toString() ?? address['pedestrian']?.toString();
    final houseNumber = address['house_number']?.toString();

    final name = item['name']?.toString() ?? street ?? '';
    final city =
        address['city']?.toString() ??
        address['town']?.toString() ??
        address['village']?.toString() ??
        address['county']?.toString() ??
        '';
    final state = address['state']?.toString() ?? '';
    final country = address['country']?.toString() ?? '';
    final postcode = address['postcode']?.toString();

    final streetLine = [
      if (street != null) houseNumber != null ? '$street $houseNumber' : street,
    ].join(' ');

    // Prioritize specific name, then street/address, then city/area
    final mainName = name.isNotEmpty
        ? name
        : streetLine.isNotEmpty
        ? streetLine
        : city.isNotEmpty
        ? city
        : item['display_name']?.toString()?.split(',').first ??
              'Selected Location';

    final secondaryParts = [
      if (city.isNotEmpty && city != name) city,
      if (state.isNotEmpty && state != city) state,
      country,
    ].where((s) => s.isNotEmpty).toList();

    final secondary = secondaryParts.join(', ');

    return PlaceSuggestion(
      placeId: '${item['place_id'] ?? item['osm_id'] ?? '$lat-$lon'}',
      name: mainName,
      city: city,
      country: country,
      lat: lat,
      lon: lon,
      description: name.isNotEmpty && secondary.isNotEmpty
          ? '$name, $secondary'
          : (secondary.isNotEmpty
                ? secondary
                : (item['display_name']?.toString() ?? '')),
      isCurrentLocation: false,
      state: state.isNotEmpty ? state : null,
      postcode: postcode,
      street: street,
      houseNumber: houseNumber,
    );
  }

  factory PlaceSuggestion.currentLocation({
    required String label,
    required LatLng position,
  }) {
    return PlaceSuggestion(
      placeId: 'current_location',
      name: label,
      city: '',
      country: '',
      lat: position.latitude,
      lon: position.longitude,
      description: 'Using GPS • Live location',
      isCurrentLocation: true,
    );
  }
}

class PlacesService {
  final ApiClient _apiClient;

  PlacesService({required ApiClient apiClient}) : _apiClient = apiClient;

  final Map<String, List<PlaceSuggestion>> _suggestionsCache = {};

  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(String input) async {
    final query = input.trim();
    if (query.length < 2) {
      return const [];
    }

    if (_suggestionsCache.containsKey(query)) {
      return _suggestionsCache[query]!;
    }

    // Fire network sources concurrently to minimize latency
    final results = await Future.wait([
      _fetchNominatimSuggestions(query),
      _fetchSuggestionsFromApis(query),
    ]);

    final nominatimSuggestions = results[0];
    final apiSuggestions = results[1];

    final merged = <PlaceSuggestion>[];
    final seen = <String>{};

    // Mix results (API first, then Nominatim)
    for (final s in [...apiSuggestions, ...nominatimSuggestions]) {
      final key = _dedupeKey(s);
      if (seen.add(key)) {
        merged.add(s);
      }
    }

    if (merged.isNotEmpty) {
      _suggestionsCache[query] = merged;
      return merged;
    }

    final fallbacks = _localFallbackSuggestions(query);
    if (fallbacks.isNotEmpty) {
      _suggestionsCache[query] = fallbacks;
    }
    return fallbacks;
  }

  Future<List<PlaceSuggestion>> _fetchSuggestionsFromApis(String query) async {
    // PRESERVED: backend search endpoint order is intentionally layered.
    final seenKeys = <String>{};
    final mergedSuggestions = <PlaceSuggestion>[];
    final candidateBaseUrls = <String>{
      BaseApi.normalizeUrl(_apiClient.baseUrl),
      ...BaseApi.candidatePlacesBaseUrls,
    };

    for (final baseUrl in candidateBaseUrls) {
      if (baseUrl.isEmpty) continue;
      final suggestions = await _fetchSuggestionsFromBaseUrl(baseUrl, query);
      for (final suggestion in suggestions) {
        final key = _dedupeKey(suggestion);
        if (seenKeys.add(key)) {
          mergedSuggestions.add(suggestion);
        }
      }
      if (mergedSuggestions.isNotEmpty) {
        return mergedSuggestions;
      }
    }

    return const [];
  }

  Future<List<PlaceSuggestion>> _fetchSuggestionsFromBaseUrl(
    String baseUrl,
    String query,
  ) async {
    final endpoints = [
      '/places/search?query=${Uri.encodeComponent(query)}',
      '/user/search/places?query=${Uri.encodeComponent(query)}',
      '/nav/search?query=${Uri.encodeComponent(query)}',
    ];

    // Fire all candidate endpoints concurrently for faster response
    final futures = endpoints.map((endpoint) async {
      try {
        final response = await _rawGet(baseUrl, endpoint);
        return await _parseSuggestionsResponse(response);
      } catch (_) {
        return const <PlaceSuggestion>[];
      }
    });

    final results = await Future.wait(futures);

    // Merge all non-empty results
    final merged = <PlaceSuggestion>[];
    final seen = <String>{};
    for (final suggestions in results) {
      for (final s in suggestions) {
        if (seen.add(_dedupeKey(s))) {
          merged.add(s);
        }
      }
    }

    return merged;
  }

  Future<dynamic> _rawGet(String baseUrl, String endpoint) async {
    final token = _apiClient.storageService.backendAccessToken;
    final response = await http
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    if (response.body.isEmpty) {
      return null;
    }

    return json.decode(response.body);
  }

  Future<List<PlaceSuggestion>> _parseSuggestionsResponse(dynamic response) {
    return runInBackground(() {
      if (response is! Map) {
        return const <PlaceSuggestion>[];
      }

      final successFlag = response['success'] ?? response['isSuccess'];
      if (successFlag is bool && !successFlag) {
        return const <PlaceSuggestion>[];
      }

      final data =
          response['data'] ?? response['results'] ?? response['places'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (json) => _suggestionFromApiJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }

      final features = response['features'];
      if (features is List) {
        return features
            .whereType<Map>()
            .map(
              (feature) => PlaceSuggestion.fromNominatimJson(
                Map<String, dynamic>.from(feature),
              ),
            )
            .toList();
      }

      return const <PlaceSuggestion>[];
    });
  }

  PlaceSuggestion _suggestionFromApiJson(Map<String, dynamic> json) {
    final lat =
        (json['latitude'] as num?)?.toDouble() ??
        (json['lat'] as num?)?.toDouble() ??
        (json['Latitude'] as num?)?.toDouble() ??
        0.0;
    final lon =
        (json['longitude'] as num?)?.toDouble() ??
        (json['lng'] as num?)?.toDouble() ??
        (json['lon'] as num?)?.toDouble() ??
        (json['Longitude'] as num?)?.toDouble() ??
        0.0;
    final name =
        (json['name'] ??
                json['Name'] ??
                json['title'] ??
                json['displayName'] ??
                json['address'] ??
                'Unknown Place')
            .toString();
    final address =
        (json['address'] ??
                json['formattedAddress'] ??
                json['description'] ??
                json['Address'] ??
                '')
            .toString();

    return PlaceSuggestion(
      placeId:
          (json['googlePlaceId'] ??
                  json['placeId'] ??
                  json['id'] ??
                  '$name-$lat-$lon')
              .toString(),
      name: name,
      city: (json['city'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      lat: lat,
      lon: lon,
      description: address,
      state: json['state']?.toString(),
      postcode: json['postcode']?.toString(),
      street: json['street']?.toString(),
      houseNumber: json['houseNumber']?.toString(),
    );
  }

  Future<List<PlaceSuggestion>> _fetchNominatimSuggestions(String query) async {
    final url = Uri.parse(BaseApi.nominatimSearchUrl).replace(
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '8',
      },
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent':
                  'routent App (https://github.com/techbrein/locator)',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return const [];
      }

      final parsed = await runInBackground(() {
        final data = json.decode(response.body);
        final list = data as List? ?? const [];
        return list
            .whereType<Map>()
            .map(
              (item) => PlaceSuggestion.fromNominatimJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      });

      return List<PlaceSuggestion>.from(parsed);
    } catch (_) {
      return const [];
    }
  }

  List<PlaceSuggestion> _localFallbackSuggestions(String query) {
    final normalizedQuery = query.toLowerCase();

    return _fallbackPlaces.where((suggestion) {
      final haystack =
          '${suggestion.name} ${suggestion.description} ${suggestion.city} ${suggestion.country}'
              .toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  String _dedupeKey(PlaceSuggestion suggestion) {
    return '${suggestion.name}|${suggestion.lat}|${suggestion.lon}';
  }

  Future<PlaceSuggestion?> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(BaseApi.nominatimReverseUrl).replace(
      queryParameters: {
        'lat': lat.toStringAsFixed(6),
        'lon': lon.toStringAsFixed(6),
        'format': 'jsonv2',
        'addressdetails': '1',
      },
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent':
                  'routent App (https://github.com/techbrein/locator)',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return await runInBackground(() {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data.containsKey('place_id')) {
            return PlaceSuggestion.fromNominatimJson(data);
          }
          return null;
        });
      }
    } catch (e) {
      if (e is TimeoutException) {
        AppLogger.warning('Nominatim reverse API timed out after 8 seconds. Falling back to generic label.');
      } else if (kIsWeb && e is http.ClientException) {
        AppLogger.warning(
          'Reverse geocoding is unavailable in this browser session. Falling '
          'back to a generic location label.',
        );
      } else if (e.toString().contains('SocketException')) {
        AppLogger.error(
          'Nominatim reverse API lookup failed. Check internet or DNS settings.',
          error: e,
        );
      } else {
        AppLogger.error('Nominatim reverse API error', error: e);
      }
    }
    return null;
  }

  List<PlaceSuggestion> get _fallbackPlaces => [
    PlaceSuggestion(
      placeId: 'fallback_ranip',
      name: 'Ranip',
      city: 'Ahmedabad',
      country: 'India',
      lat: 23.0817,
      lon: 72.5597,
      description: 'Ranip, Ahmedabad, Gujarat',
    ),
    PlaceSuggestion(
      placeId: 'fallback_ahmedabad',
      name: 'Ahmedabad',
      city: 'Ahmedabad',
      country: 'India',
      lat: 23.0225,
      lon: 72.5714,
      description: 'Ahmedabad, Gujarat',
    ),
    PlaceSuggestion(
      placeId: 'fallback_satellite',
      name: 'Satellite',
      city: 'Ahmedabad',
      country: 'India',
      lat: 23.0273,
      lon: 72.5269,
      description: 'Satellite, Ahmedabad, Gujarat',
    ),
    PlaceSuggestion(
      placeId: 'fallback_sg_highway',
      name: 'SG Highway',
      city: 'Ahmedabad',
      country: 'India',
      lat: 23.0703,
      lon: 72.5163,
      description: 'SG Highway, Ahmedabad, Gujarat',
    ),
    PlaceSuggestion(
      placeId: 'fallback_mumbai',
      name: 'Mumbai',
      city: 'Mumbai',
      country: 'India',
      lat: 19.0760,
      lon: 72.8777,
      description: 'Mumbai, Maharashtra',
    ),
    PlaceSuggestion(
      placeId: 'fallback_pune',
      name: 'Pune',
      city: 'Pune',
      country: 'India',
      lat: 18.5204,
      lon: 73.8567,
      description: 'Pune, Maharashtra',
    ),
    PlaceSuggestion(
      placeId: 'fallback_delhi',
      name: 'Delhi',
      city: 'Delhi',
      country: 'India',
      lat: 28.6139,
      lon: 77.2090,
      description: 'Delhi, India',
    ),
    PlaceSuggestion(
      placeId: 'fallback_bengaluru',
      name: 'Bengaluru',
      city: 'Bengaluru',
      country: 'India',
      lat: 12.9716,
      lon: 77.5946,
      description: 'Bengaluru, Karnataka',
    ),
    PlaceSuggestion(
      placeId: 'fallback_hyderabad',
      name: 'Hyderabad',
      city: 'Hyderabad',
      country: 'India',
      lat: 17.3850,
      lon: 78.4867,
      description: 'Hyderabad, Telangana',
    ),
    PlaceSuggestion(
      placeId: 'fallback_chennai',
      name: 'Chennai',
      city: 'Chennai',
      country: 'India',
      lat: 13.0827,
      lon: 80.2707,
      description: 'Chennai, Tamil Nadu',
    ),
    PlaceSuggestion(
      placeId: 'fallback_surat',
      name: 'Surat',
      city: 'Surat',
      country: 'India',
      lat: 21.1702,
      lon: 72.8311,
      description: 'Surat, Gujarat',
    ),
    PlaceSuggestion(
      placeId: 'fallback_vadodara',
      name: 'Vadodara',
      city: 'Vadodara',
      country: 'India',
      lat: 22.3072,
      lon: 73.1812,
      description: 'Vadodara, Gujarat',
    ),
  ];
}

final placesServiceProvider = Provider<PlacesService>((ref) {
  return PlacesService(apiClient: ref.watch(apiClientProvider));
});
