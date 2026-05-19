import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'package:allonbiz_mobile/core/errors/failures.dart';
import 'package:allonbiz_mobile/core/network/api_client.dart';
import 'package:allonbiz_mobile/core/network/api_parsers.dart';
import 'package:allonbiz_mobile/core/services/storage_service.dart';
import 'package:allonbiz_mobile/features/discover/data/repositories/deals_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'allonbiz_api_client_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  group('ApiClient', () {
    test('coalesces concurrent identical GET requests into one network call', () async {
      final storage = await _TestStorageHarness.create();
      addTearDown(storage.dispose);

      final client = _CountingHttpClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _jsonResponse({
          'data': [
            {'id': '1', 'title': 'Coffee Deal'},
          ],
        });
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        storageService: storage.storage,
        client: client,
      );

      final results = await Future.wait([
        apiClient.getParsed<List<dynamic>>(
          '/user/offers/nearby',
          parser: parseOffersEnvelope,
          options: const ApiReadOptions(
            cacheKey: 'offers:coalesce',
            decodeInBackground: true,
          ),
        ),
        apiClient.getParsed<List<dynamic>>(
          '/user/offers/nearby',
          parser: parseOffersEnvelope,
          options: const ApiReadOptions(
            cacheKey: 'offers:coalesce',
            decodeInBackground: true,
          ),
        ),
        apiClient.getParsed<List<dynamic>>(
          '/user/offers/nearby',
          parser: parseOffersEnvelope,
          options: const ApiReadOptions(
            cacheKey: 'offers:coalesce',
            decodeInBackground: true,
          ),
        ),
      ]);

      expect(client.requestCount, 1);
      expect(results, everyElement(hasLength(1)));
    });

    test('uses background decode and parses mixed-case offer payloads', () async {
      final storage = await _TestStorageHarness.create();
      addTearDown(storage.dispose);

      final client = _CountingHttpClient((request) async {
        return _jsonResponse({
          'Data': [
            {
              'OfferId': 'A1',
              'Name': 'Cafe Deal',
              'Description': 'Free coffee',
              'Category': 'food',
              'Latitude': 21.1702,
              'Longitude': 72.8311,
              'Tags': 'coffee,breakfast',
            },
          ],
        });
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        storageService: storage.storage,
        client: client,
      );

      final offers = await apiClient.getParsed(
        '/user/offers/nearby',
        parser: parseOffersEnvelope,
        options: const ApiReadOptions(
          cacheKey: 'offers:mixed-case',
          ttl: Duration(minutes: 1),
          decodeInBackground: true,
        ),
      );

      expect(offers.single.id, 'A1');
      expect(offers.single.title, 'Cafe Deal');
      expect(offers.single.category, 'food');
      expect(offers.single.tags, ['coffee', 'breakfast']);
      expect(apiClient.lastReadMetrics?.usedBackgroundDecode, isTrue);
      expect(apiClient.lastReadMetrics?.usedBackgroundParse, isTrue);
    });

    test('returns a fresh cached value without a second network call', () async {
      final storage = await _TestStorageHarness.create();
      addTearDown(storage.dispose);

      final client = _CountingHttpClient((request) async {
        return _jsonResponse({
          'data': [
            {'id': '1', 'title': 'Cached Deal'},
          ],
        });
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        storageService: storage.storage,
        client: client,
      );

      final first = await apiClient.getParsed(
        '/user/offers/nearby',
        parser: parseOffersEnvelope,
        options: const ApiReadOptions(
          cacheKey: 'offers:fresh-cache',
          ttl: Duration(minutes: 1),
          decodeInBackground: true,
        ),
      );

      final second = await apiClient.getParsed(
        '/user/offers/nearby',
        parser: parseOffersEnvelope,
        options: const ApiReadOptions(
          cacheKey: 'offers:fresh-cache',
          ttl: Duration(minutes: 1),
          decodeInBackground: true,
        ),
      );

      expect(client.requestCount, 1);
      expect(first.single.title, 'Cached Deal');
      expect(second.single.title, 'Cached Deal');
    });

    test('watchParsed emits stale cached data first and then fresh data', () async {
      final storage = await _TestStorageHarness.create();
      addTearDown(storage.dispose);

      await storage.storage.putCachedResponse(
        _scopedCacheKey('offers:swr'),
        payload: jsonEncode({
          'data': [
            {'id': '1', 'title': 'Cached Deal'},
          ],
        }),
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final client = _CountingHttpClient((request) async {
        return _jsonResponse({
          'data': [
            {'id': '1', 'title': 'Fresh Deal'},
          ],
        });
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        storageService: storage.storage,
        client: client,
      );

      final emissions = await apiClient
          .watchParsed<List<dynamic>>(
            '/user/offers/nearby',
            parser: parseOffersEnvelope,
            options: const ApiReadOptions(
              cacheKey: 'offers:swr',
              ttl: Duration(minutes: 1),
              decodeInBackground: true,
            ),
          )
          .toList();

      expect(emissions, hasLength(2));
      expect(emissions.first.single.title, 'Cached Deal');
      expect(emissions.last.single.title, 'Fresh Deal');
    });

    test('reuses the same nearby-offers cache key for small location drift', () async {
      final storage = await _TestStorageHarness.create();
      addTearDown(storage.dispose);

      final client = _CountingHttpClient((request) async {
        return _jsonResponse({
          'data': [
            {'id': '1', 'title': 'Quantized Deal'},
          ],
        });
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        storageService: storage.storage,
        client: client,
      );
      final repository = DealsRepository(apiClient: apiClient);

      final first = await repository.fetchOffers(
        lat: 23.02241,
        lng: 72.57141,
      );
      final second = await repository.fetchOffers(
        lat: 23.02249,
        lng: 72.57149,
      );

      expect(client.requestCount, 1);
      expect(first.single.title, 'Quantized Deal');
      expect(second.single.title, 'Quantized Deal');
    });

    test('watchParsed suppresses the second emission when payload is unchanged', () async {
      final storage = await _TestStorageHarness.create();
      addTearDown(storage.dispose);

      final payload = jsonEncode({
        'data': [
          {'id': '1', 'title': 'Same Deal'},
        ],
      });

      await storage.storage.putCachedResponse(
        _scopedCacheKey('offers:unchanged'),
        payload: payload,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final client = _CountingHttpClient((request) async {
        return _jsonResponseString(payload);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        storageService: storage.storage,
        client: client,
      );

      final emissions = await apiClient
          .watchParsed<List<dynamic>>(
            '/user/offers/nearby',
            parser: parseOffersEnvelope,
            options: const ApiReadOptions(
              cacheKey: 'offers:unchanged',
              ttl: Duration(minutes: 1),
              decodeInBackground: true,
            ),
          )
          .toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.single.title, 'Same Deal');
    });

    test('returns cached data when revalidation fails and cache exists', () async {
      final storage = await _TestStorageHarness.create();
      addTearDown(storage.dispose);

      await storage.storage.putCachedResponse(
        _scopedCacheKey('offers:error-fallback'),
        payload: jsonEncode({
          'data': [
            {'id': '1', 'title': 'Cached Deal'},
          ],
        }),
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final client = _CountingHttpClient((request) async {
        return _jsonResponse(
          {'message': 'Server blew up'},
          statusCode: 500,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        storageService: storage.storage,
        client: client,
      );

      final emissions = await apiClient
          .watchParsed<List<dynamic>>(
            '/user/offers/nearby',
            parser: parseOffersEnvelope,
            options: const ApiReadOptions(
              cacheKey: 'offers:error-fallback',
              ttl: Duration(minutes: 1),
              decodeInBackground: true,
            ),
          )
          .toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.single.title, 'Cached Deal');
    });

    test('throws when the network fails and there is no cache to fall back to', () async {
      final storage = await _TestStorageHarness.create();
      addTearDown(storage.dispose);

      final client = _CountingHttpClient((request) async {
        return _jsonResponse(
          {'message': 'Server blew up'},
          statusCode: 500,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://example.com',
        storageService: storage.storage,
        client: client,
      );

      expect(
        () => apiClient.getParsed<List<dynamic>>(
          '/user/offers/nearby',
          parser: parseOffersEnvelope,
          options: const ApiReadOptions(
            cacheKey: 'offers:no-cache',
            ttl: Duration(minutes: 1),
            decodeInBackground: true,
          ),
        ),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}

class _CountingHttpClient extends http.BaseClient {
  _CountingHttpClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;

  int requestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount += 1;
    return _handler(request);
  }
}

class _TestStorageHarness {
  _TestStorageHarness._(this.storage, this._boxes);

  static int _counter = 0;

  final StorageService storage;
  final List<Box<dynamic>> _boxes;

  static Future<_TestStorageHarness> create() async {
    final suffix = _counter++;
    final prefs = await Hive.openBox<dynamic>('prefs_$suffix');
    final responses = await Hive.openBox<dynamic>('responses_$suffix');
    final routes = await Hive.openBox<dynamic>('routes_$suffix');

    return _TestStorageHarness._(
      StorageService(
        prefs: prefs,
        responseCache: responses,
        routes: routes,
      ),
      [prefs, responses, routes],
    );
  }

  Future<void> dispose() async {
    for (final box in _boxes) {
      final name = box.name;
      await box.clear();
      await box.close();
      await Hive.deleteBoxFromDisk(name);
    }
  }
}

http.StreamedResponse _jsonResponse(
  Object body, {
  int statusCode = 200,
}) {
  return _jsonResponseString(jsonEncode(body), statusCode: statusCode);
}

http.StreamedResponse _jsonResponseString(
  String body, {
  int statusCode = 200,
}) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(body)),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}

String _scopedCacheKey(String cacheKey) {
  final encoded = base64UrlEncode(utf8.encode('anonymous'));
  final scope = encoded.length <= 16 ? encoded : encoded.substring(0, 16);
  return '$scope:$cacheKey';
}
