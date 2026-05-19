import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../network/base_api.dart';
import '../network/api_client.dart';
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

  /// factory LocationModel.fromJson (Aligned with blueprint)
  factory PlaceSuggestion.fromPhotonFeature(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coords = geometry['coordinates'] as List? ?? [0.0, 0.0];

    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    final name = (props['name'] ?? '') as String;
    final city =
        (props['city'] ?? props['county'] ?? props['state'] ?? '') as String;
    final country = (props['country'] ?? '') as String;
    final state = props['state'] as String?;
    final postcode = props['postcode'] as String?;
    final street = props['street'] as String?;
    final houseNumber = props['housenumber'] as String?;

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
        : 'Selected Location';

    // Build description: "City, State (if any), Country"
    final secondaryParts = [
      if (city.isNotEmpty && city != name) city,
      if (state != null && state != city) state,
      country,
    ].where((s) => s.isNotEmpty).toList();

    final secondary = secondaryParts.join(', ');

    return PlaceSuggestion(
      placeId:
          '${props['osm_id'] ?? props['name']?.hashCode ?? feature.hashCode}',
      name: mainName,
      city: city,
      country: country,
      lat: lat,
      lon: lon,
      description: name.isNotEmpty ? '$name, $secondary' : secondary,
      isCurrentLocation: false,
      state: state,
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

    final apiSuggestions = await _fetchSuggestionsFromApis(query);
    if (apiSuggestions.isNotEmpty) {
      _suggestionsCache[query] = apiSuggestions;
      return apiSuggestions;
    }

    final photonSuggestions = await _fetchPhotonSuggestions(query);
    if (photonSuggestions.isNotEmpty) {
      _suggestionsCache[query] = photonSuggestions;
      return photonSuggestions;
    }

    final fallbacks = _localFallbackSuggestions(query);
    if (fallbacks.isNotEmpty) {
      _suggestionsCache[query] = fallbacks;
    }
    return fallbacks;
  }

  Future<List<PlaceSuggestion>> _fetchSuggestionsFromApis(String query) async {
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

    for (final endpoint in endpoints) {
      try {
        final response = await _rawGet(baseUrl, endpoint);
        final suggestions = await _parseSuggestionsResponse(response);
        if (suggestions.isNotEmpty) {
          return suggestions;
        }
      } catch (_) {
        // Quietly continue to the next source. Search already has layered fallbacks.
      }
    }

    return const [];
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

      final data = response['data'] ?? response['results'] ?? response['places'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((json) => _suggestionFromApiJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      final features = response['features'];
      if (features is List) {
        return features
            .whereType<Map>()
            .map(
              (feature) => PlaceSuggestion.fromPhotonFeature(
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

  Future<List<PlaceSuggestion>> _fetchPhotonSuggestions(String query) async {
    final url = Uri.parse(BaseApi.photonSearchUrl).replace(
      queryParameters: {'q': query, 'limit': '8'},
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent':
                  'allonbiz App (https://github.com/techbrein/locator)',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return const [];
      }

      final parsed = await runInBackground(() {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? const [];
        return features
            .whereType<Map>()
            .map(
              (feature) => PlaceSuggestion.fromPhotonFeature(
                Map<String, dynamic>.from(feature),
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
    final url = Uri.parse(BaseApi.photonReverseUrl).replace(
      queryParameters: {
        'lat': lat.toStringAsFixed(6),
        'lon': lon.toStringAsFixed(6),
      },
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent':
                  'allonbiz App (https://github.com/techbrein/locator)',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return await runInBackground(() {
          final data = json.decode(response.body);
          final features = data['features'] as List? ?? [];
          if (features.isNotEmpty) {
            return PlaceSuggestion.fromPhotonFeature(
              features.first as Map<String, dynamic>,
            );
          }
          return null;
        });
      }
    } catch (e) {
      if (kIsWeb && e is http.ClientException) {
        debugPrint(
          'Reverse geocoding is unavailable in this browser session. Falling back to a generic location label.',
        );
      } else if (e.toString().contains('SocketException')) {
        Logger().e(
          'Photon Reverse API Lookup Failed: Please check your internet connection or DNS settings. ($e)',
        );
      } else {
        Logger().e('Photon Reverse API error: $e');
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
