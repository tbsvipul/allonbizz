import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, kProfileMode, visibleForTesting, ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../errors/failures.dart';
import '../models/api_response.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/background_executor.dart';
import 'api_parsers.dart';
import 'base_api.dart';

typedef ApiEnvelopeParser<T> = T Function(Object? response);
typedef JsonMapParser<T> = T Function(Map<String, dynamic> json);

/// Riverpod provider for ApiClient.
final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final baseUrl = BaseApi.backendBaseUrl;
  return ApiClient(baseUrl: baseUrl, storageService: storageService);
});

enum ApiCacheSource { memory, disk, network }

class ApiReadOptions {
  const ApiReadOptions({
    this.cacheKey,
    this.ttl,
    this.decodeInBackground = false,
    this.dedupeInFlight = true,
  });

  final String? cacheKey;
  final Duration? ttl;
  final bool decodeInBackground;
  final bool dedupeInFlight;
}

class CachedApiValue<T> {
  const CachedApiValue({
    required this.value,
    required this.fetchedAt,
    required this.payload,
    required this.source,
  });

  final T value;
  final DateTime fetchedAt;
  final String payload;
  final ApiCacheSource source;

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(fetchedAt) <= ttl;
  }
}

class ApiReadMetrics {
  const ApiReadMetrics({
    required this.endpoint,
    required this.cacheSource,
    required this.networkDuration,
    required this.decodeDuration,
    required this.parseDuration,
    required this.usedBackgroundDecode,
    required this.usedBackgroundParse,
    required this.deduped,
  });

  final String endpoint;
  final ApiCacheSource cacheSource;
  final Duration networkDuration;
  final Duration decodeDuration;
  final Duration parseDuration;
  final bool usedBackgroundDecode;
  final bool usedBackgroundParse;
  final bool deduped;
}

class _MemoryCacheEntry {
  const _MemoryCacheEntry({
    required this.payload,
    required this.fetchedAt,
    this.value,
  });

  final String payload;
  final DateTime fetchedAt;
  final Object? value;

  _MemoryCacheEntry copyWith({
    String? payload,
    DateTime? fetchedAt,
    Object? value,
  }) {
    return _MemoryCacheEntry(
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      value: value ?? this.value,
    );
  }
}

class _DecodedPayload {
  const _DecodedPayload({required this.rawPayload, required this.decodedBody});

  final String rawPayload;
  final Object? decodedBody;
}

/// A lightweight HTTP client that automatically attaches the backend AccessToken
/// from StorageService and handles basic error throwing.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.storageService,
    http.Client? client,
  }) : _client = client ?? _createDefaultClient();

  final String baseUrl;
  final StorageService storageService;
  final http.Client _client;

  final LinkedHashMap<String, _MemoryCacheEntry> _memoryCache = LinkedHashMap<String, _MemoryCacheEntry>();
  static const int _maxCacheEntries = 100;
  final Map<String, Future<http.Response>> _inFlightGets = {};
  final StreamController<String?> _authFailedController =
      StreamController<String?>.broadcast();

  // Global state to track if the server is unreachable
  static final ValueNotifier<bool> isServerOffline = ValueNotifier<bool>(false);

  Stream<String?> get onAuthFailed => _authFailedController.stream;

  Future<bool>? _refreshFuture;

  @visibleForTesting
  ApiReadMetrics? lastReadMetrics;

  /// Creates a platform-appropriate client with security hardening.
  static http.Client _createDefaultClient() {
    if (kIsWeb) {
      return http.Client();
    }

    final context = SecurityContext(withTrustedRoots: true);
    final httpClient = HttpClient(context: context)
      ..connectionTimeout = const Duration(seconds: 15);

    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          if (kDebugMode || kProfileMode) {
            final isLocalHost = BaseApi.isTrustedDevelopmentHost(host);
            return isLocalHost;
          }
          return false;
        };

    return IOClient(httpClient);
  }

  Map<String, String> get _headers {
    final token = storageService.backendAccessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) => _request('GET', endpoint);

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) =>
      _request('POST', endpoint, body: body);

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) =>
      _request('PUT', endpoint, body: body);

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) =>
      _request('PATCH', endpoint, body: body);

  Future<dynamic> delete(String endpoint) => _request('DELETE', endpoint);

  Future<dynamic> postMultipart(
    String endpoint, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
  }) async {
    return _request('POST', endpoint, files: files, fields: fields);
  }

  Future<T> getParsed<T>(
    String endpoint, {
    required ApiEnvelopeParser<T> parser,
    ApiReadOptions options = const ApiReadOptions(),
  }) async {
    final cacheKey = _resolveCacheKey(endpoint, options);

    if (cacheKey != null && options.ttl != null) {
      final cached = await getCachedParsed<T>(
        parser: parser,
        options: options,
        cacheKey: cacheKey,
      );
      if (cached != null && cached.isFresh(options.ttl!)) {
        _recordMetrics(
          ApiReadMetrics(
            endpoint: endpoint,
            cacheSource: cached.source,
            networkDuration: Duration.zero,
            decodeDuration: Duration.zero,
            parseDuration: Duration.zero,
            usedBackgroundDecode: false,
            usedBackgroundParse: false,
            deduped: false,
          ),
        );
        return cached.value;
      }
    }

    try {
      return await _fetchParsedFromNetwork<T>(
        endpoint,
        parser: parser,
        options: options,
        cacheKey: cacheKey,
      );
    } catch (error) {
      if (cacheKey == null) {
        rethrow;
      }

      final cached = await getCachedParsed<T>(
        parser: parser,
        options: options,
        cacheKey: cacheKey,
      );
      if (cached != null) {
        return cached.value;
      }
      rethrow;
    }
  }

  Stream<T> watchParsed<T>(
    String endpoint, {
    required ApiEnvelopeParser<T> parser,
    ApiReadOptions options = const ApiReadOptions(),
  }) async* {
    final cacheKey = _resolveCacheKey(endpoint, options);
    CachedApiValue<T>? cached;

    if (cacheKey != null) {
      cached = await getCachedParsed<T>(
        parser: parser,
        options: options,
        cacheKey: cacheKey,
      );
      if (cached != null) {
        yield cached.value;
      }
    }

    try {
      final fresh = await _fetchParsedFromNetwork<T>(
        endpoint,
        parser: parser,
        options: options,
        cacheKey: cacheKey,
      );

      if (cached == null || cached.payload != _payloadForCacheValue(cacheKey)) {
        yield fresh;
      }
    } catch (error) {
      if (cached == null) {
        rethrow;
      }
    }
  }

  Future<CachedApiValue<T>?> getCachedParsed<T>({
    required ApiEnvelopeParser<T> parser,
    required ApiReadOptions options,
    required String cacheKey,
  }) async {
    final scopedKey = _scopeCacheKey(cacheKey);
    final memoryEntry = _memoryCache[scopedKey];

    if (memoryEntry != null) {
      // Move to end for LRU
      _memoryCache.remove(scopedKey);
      _memoryCache[scopedKey] = memoryEntry;
      if (memoryEntry.value is T) {
        return CachedApiValue<T>(
          value: memoryEntry.value as T,
          fetchedAt: memoryEntry.fetchedAt,
          payload: memoryEntry.payload,
          source: ApiCacheSource.memory,
        );
      }

      final parsed = await _parsePayload<T>(
        memoryEntry.payload,
        parser: parser,
        decodeInBackground: options.decodeInBackground,
      );
      _memoryCache[scopedKey] = memoryEntry.copyWith(value: parsed);
      return CachedApiValue<T>(
        value: parsed,
        fetchedAt: memoryEntry.fetchedAt,
        payload: memoryEntry.payload,
        source: ApiCacheSource.memory,
      );
    }

    final diskEntry = storageService.getCachedResponse(scopedKey);
    if (diskEntry == null) {
      return null;
    }

    final parsed = await _parsePayload<T>(
      diskEntry.payload,
      parser: parser,
      decodeInBackground: options.decodeInBackground,
    );
    final memoryEntryCache = _MemoryCacheEntry(
      payload: diskEntry.payload,
      fetchedAt: diskEntry.fetchedAt,
      value: parsed,
    );
    _memoryCache[scopedKey] = memoryEntryCache;
    if (_memoryCache.length > _maxCacheEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    return CachedApiValue<T>(
      value: parsed,
      fetchedAt: diskEntry.fetchedAt,
      payload: diskEntry.payload,
      source: ApiCacheSource.disk,
    );
  }

  Future<T> getObject<T>(
    String endpoint, {
    required JsonMapParser<T> parser,
    ApiReadOptions options = const ApiReadOptions(),
  }) {
    return getParsed<T>(
      endpoint,
      parser: (response) => parser(extractEnvelopeDataMap(response)),
      options: options,
    );
  }

  Stream<T> watchObject<T>(
    String endpoint, {
    required JsonMapParser<T> parser,
    ApiReadOptions options = const ApiReadOptions(),
  }) {
    return watchParsed<T>(
      endpoint,
      parser: (response) => parser(extractEnvelopeDataMap(response)),
      options: options,
    );
  }

  Future<List<T>> getList<T>(
    String endpoint, {
    required JsonMapParser<T> parser,
    ApiReadOptions options = const ApiReadOptions(),
  }) {
    return getParsed<List<T>>(
      endpoint,
      parser: (response) =>
          extractEnvelopeDataList(response).map(parser).toList(growable: false),
      options: options,
    );
  }

  Stream<List<T>> watchList<T>(
    String endpoint, {
    required JsonMapParser<T> parser,
    ApiReadOptions options = const ApiReadOptions(),
  }) {
    return watchParsed<List<T>>(
      endpoint,
      parser: (response) =>
          extractEnvelopeDataList(response).map(parser).toList(growable: false),
      options: options,
    );
  }

  Future<ApiPage<T>> getPage<T>(
    String endpoint, {
    required JsonMapParser<T> parser,
    ApiReadOptions options = const ApiReadOptions(),
  }) {
    return getParsed<ApiPage<T>>(
      endpoint,
      parser: (response) => ApiPage.fromJson(
        asJsonMap(response),
        (json) => parser(asJsonMap(json)),
      ),
      options: options,
    );
  }

  Future<void> invalidateCacheKey(String cacheKey) async {
    final scopedKey = _scopeCacheKey(cacheKey);
    _memoryCache.remove(scopedKey);
    await storageService.removeCachedResponse(scopedKey);
  }

  Future<void> invalidateCacheByPrefix(String prefix) async {
    final scopedPrefix = _scopeCacheKey(prefix);
    final matchingKeys = _memoryCache.keys
        .where((key) => key.startsWith(scopedPrefix))
        .toList(growable: false);

    for (final key in matchingKeys) {
      _memoryCache.remove(key);
    }

    await storageService.removeCachedResponsesWithPrefix(scopedPrefix);
  }

  Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    List<http.MultipartFile>? files,
    Map<String, String>? fields,
    bool isRetry = false,
  }) async {
    try {
      http.BaseRequest request;
      final uri = Uri.parse('$baseUrl$endpoint');
      _logTrackedAuthRequest(
        method,
        endpoint,
        uri,
        body: body,
        fields: fields,
        hasFiles: files?.isNotEmpty ?? false,
      );

      if (files != null || fields != null) {
        final multipartRequest = http.MultipartRequest(method, uri);
        multipartRequest.headers.addAll(_headers);
        if (fields != null) {
          multipartRequest.fields.addAll(fields);
        }
        if (files != null) {
          multipartRequest.files.addAll(files);
        }
        request = multipartRequest;
      } else {
        final httpRequest = http.Request(method, uri);
        httpRequest.headers.addAll(_headers);
        if (body != null) {
          httpRequest.body = jsonEncode(body);
        }
        request = httpRequest;
      }

      final responseFuture = _client.send(request).then(
        (streamed) => http.Response.fromStream(streamed),
      );
      final response = await responseFuture.timeout(const Duration(seconds: 15));
      _logTrackedAuthResponse(endpoint, response);

      // Successfully reached server, clear offline state if set
      if (isServerOffline.value) {
        isServerOffline.value = false;
      }

      if (response.statusCode == 401 && !isRetry) {
        final success = await _tryRefreshToken();
        if (success) {
          if (files != null && files.isNotEmpty) {
            // Cannot reuse http.MultipartFile streams after they've been consumed
            throw const NetworkFailure();
          }
          return _request(
            method,
            endpoint,
            body: body,
            files: files,
            fields: fields,
            isRetry: true,
          );
        } else {
          String? msg;
          try { msg = _extractErrorMessage(jsonDecode(response.body)); } catch (_) {}
          _authFailedController.add(msg);
        }
      } else if (response.statusCode == 401 && isRetry) {
        String? msg;
        try { msg = _extractErrorMessage(jsonDecode(response.body)); } catch (_) {}
        _authFailedController.add(msg);
      }

      _handleErrorResponse(response);
      return _decodeBody(response);
    } on http.ClientException catch (error) {
      isServerOffline.value = true;
      _logTrackedAuthException(method, endpoint, error);
      throw const NetworkFailure();
    } on SocketException catch (error) {
      isServerOffline.value = true;
      _logTrackedAuthException(method, endpoint, error);
      throw const NetworkFailure();
    } on TimeoutException catch (error) {
      isServerOffline.value = true;
      _logTrackedAuthException(method, endpoint, error);
      throw const NetworkFailure();
    } catch (error) {
      _logTrackedAuthException(method, endpoint, error);
      if (error is Failure) {
        rethrow;
      }
      rethrow; // Do not swallow unknown errors as NetworkFailure
    }
  }

  Future<T> _fetchParsedFromNetwork<T>(
    String endpoint, {
    required ApiEnvelopeParser<T> parser,
    required ApiReadOptions options,
    required String? cacheKey,
  }) async {
    final networkStopwatch = Stopwatch()..start();
    final response = await _sendGetResponse(
      endpoint,
      dedupeInFlight: options.dedupeInFlight,
    );
    networkStopwatch.stop();

    final decodeStopwatch = Stopwatch()..start();
    final decodedPayload = await _decodeResponse(
      response.bodyBytes,
      decodeInBackground: options.decodeInBackground,
    );
    decodeStopwatch.stop();

    final parseStopwatch = Stopwatch()..start();
    final parsed = await _parseDecodedBody<T>(
      decodedPayload.decodedBody,
      parser: parser,
      parseInBackground: options.decodeInBackground,
    );
    parseStopwatch.stop();

    if (cacheKey != null) {
      await _storeCacheValue<T>(
        cacheKey,
        payload: decodedPayload.rawPayload,
        value: parsed,
      );
    }

    _recordMetrics(
      ApiReadMetrics(
        endpoint: endpoint,
        cacheSource: ApiCacheSource.network,
        networkDuration: networkStopwatch.elapsed,
        decodeDuration: decodeStopwatch.elapsed,
        parseDuration: parseStopwatch.elapsed,
        usedBackgroundDecode: options.decodeInBackground,
        usedBackgroundParse: options.decodeInBackground,
        deduped: options.dedupeInFlight,
      ),
    );

    return parsed;
  }

  Future<http.Response> _sendGetResponse(
    String endpoint, {
    required bool dedupeInFlight,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final dedupeKey = _requestIdentityKey('GET', uri);

    if (dedupeInFlight) {
      final pending = _inFlightGets[dedupeKey];
      if (pending != null) {
        return pending;
      }
    }

    final requestFuture = _sendGetResponseUncached(
      endpoint,
      uri,
      isRetry: false,
    );
    if (!dedupeInFlight) {
      return requestFuture;
    }

    _inFlightGets[dedupeKey] = requestFuture;
    try {
      return await requestFuture;
    } finally {
      _inFlightGets.remove(dedupeKey);
    }
  }

  Future<http.Response> _sendGetResponseUncached(
    String endpoint,
    Uri uri, {
    required bool isRetry,
  }) async {
    try {
      final request = http.Request('GET', uri)..headers.addAll(_headers);
      final responseFuture = _client.send(request).then(
        (streamed) => http.Response.fromStream(streamed),
      );
      final response = await responseFuture.timeout(const Duration(seconds: 15));

      // Successfully reached server, clear offline state if set
      if (isServerOffline.value) {
        isServerOffline.value = false;
      }

      if (response.statusCode == 401 && !isRetry) {
        final success = await _tryRefreshToken();
        if (success) {
          final refreshedUri = Uri.parse('$baseUrl$endpoint');
          return _sendGetResponseUncached(
            endpoint,
            refreshedUri,
            isRetry: true,
          );
        } else {
          String? msg;
          try { msg = _extractErrorMessage(jsonDecode(response.body)); } catch (_) {}
          _authFailedController.add(msg);
        }
      } else if (response.statusCode == 401 && isRetry) {
        String? msg;
        try { msg = _extractErrorMessage(jsonDecode(response.body)); } catch (_) {}
        _authFailedController.add(msg);
      }

      _handleErrorResponse(response);
      return response;
    } on http.ClientException {
      isServerOffline.value = true;
      throw const NetworkFailure();
    } on SocketException {
      isServerOffline.value = true;
      throw const NetworkFailure();
    } on TimeoutException {
      isServerOffline.value = true;
      throw const NetworkFailure();
    }
  }

  Future<bool> _tryRefreshToken() {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = _doRefreshToken().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<bool> _doRefreshToken() async {
    final refreshToken = storageService.backendRefreshToken;
    if (refreshToken == null) {
      return false;
    }

    try {
      // PRESERVED: refresh-token endpoint and storage update keys must remain
      // unchanged to avoid breaking persisted auth sessions.
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        if (data != null && data['accessToken'] != null) {
          storageService.backendAccessToken = data['accessToken'];
          if (data['refreshToken'] != null) {
            storageService.backendRefreshToken = data['refreshToken'];
          }
          return true;
        }
      } else if (response.statusCode == 401) {
        _authFailedController.add('Session expired. Please log in again.');
      }

      return false;
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (_) {
      return false;
    }
  }

  Future<_DecodedPayload> _decodeResponse(
    List<int> bodyBytes, {
    required bool decodeInBackground,
  }) async {
    final parts = decodeInBackground
        ? await runInBackground(() => _decodeBodyBytes(bodyBytes))
        : _decodeBodyBytes(bodyBytes);

    return _DecodedPayload(
      rawPayload: parts[0] as String,
      decodedBody: parts[1],
    );
  }

  Future<T> _parseDecodedBody<T>(
    Object? decodedBody, {
    required ApiEnvelopeParser<T> parser,
    required bool parseInBackground,
  }) async {
    if (parseInBackground) {
      return runInBackground(() => parser(decodedBody));
    }
    return parser(decodedBody);
  }

  Future<T> _parsePayload<T>(
    String payload, {
    required ApiEnvelopeParser<T> parser,
    required bool decodeInBackground,
  }) async {
    final decodeStopwatch = Stopwatch()..start();
    final parts = decodeInBackground
        ? await runInBackground(() => _decodeBodyString(payload))
        : _decodeBodyString(payload);
    decodeStopwatch.stop();

    final parseStopwatch = Stopwatch()..start();
    final parsed = decodeInBackground
        ? await runInBackground(() => parser(parts[1]))
        : parser(parts[1]);
    parseStopwatch.stop();

    _recordMetrics(
      ApiReadMetrics(
        endpoint: 'cache-read',
        cacheSource: ApiCacheSource.disk,
        networkDuration: Duration.zero,
        decodeDuration: decodeStopwatch.elapsed,
        parseDuration: parseStopwatch.elapsed,
        usedBackgroundDecode: decodeInBackground,
        usedBackgroundParse: decodeInBackground,
        deduped: false,
      ),
    );

    return parsed;
  }

  Future<void> _storeCacheValue<T>(
    String cacheKey, {
    required String payload,
    required T value,
  }) async {
    final fetchedAt = DateTime.now();
    final scopedKey = _scopeCacheKey(cacheKey);
    _memoryCache[scopedKey] = _MemoryCacheEntry(
      payload: payload,
      fetchedAt: fetchedAt,
      value: value,
    );
    if (_memoryCache.length > _maxCacheEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    await storageService.putCachedResponse(
      scopedKey,
      payload: payload,
      fetchedAt: fetchedAt,
    );
  }

  String? _resolveCacheKey(String endpoint, ApiReadOptions options) {
    final trimmed = options.cacheKey?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return endpoint;
  }

  String _scopeCacheKey(String cacheKey) {
    return '${_authScopeKey()}:$cacheKey';
  }

  String _authScopeKey() {
    final tokenSeed =
        storageService.backendRefreshToken ??
        storageService.backendAccessToken ??
        'anonymous';
    final encoded = base64UrlEncode(utf8.encode(tokenSeed));
    return encoded.length <= 16 ? encoded : encoded.substring(0, 16);
  }

  String _requestIdentityKey(String method, Uri uri) {
    final authHeader = _headers['Authorization'] ?? 'anonymous';
    return '$method|${uri.toString()}|$authHeader';
  }

  String? _payloadForCacheValue(String? cacheKey) {
    if (cacheKey == null) {
      return null;
    }
    return _memoryCache[_scopeCacheKey(cacheKey)]?.payload;
  }

  void _recordMetrics(ApiReadMetrics metrics) {
    lastReadMetrics = metrics;

    if (!kDebugMode && !kProfileMode) {
      return;
    }

    final source = metrics.cacheSource.name;
    final networkMs = metrics.networkDuration.inMilliseconds;
    final decodeMs = metrics.decodeDuration.inMilliseconds;
    final parseMs = metrics.parseDuration.inMilliseconds;
    final background =
        metrics.usedBackgroundDecode || metrics.usedBackgroundParse;

    // Lightweight observability for local profiling without pulling in
    // a full telemetry dependency.
    AppLogger.debug(
      '[ApiClient] ${metrics.endpoint} source=$source network=${networkMs}ms decode=${decodeMs}ms parse=${parseMs}ms background=$background deduped=${metrics.deduped}',
    );
  }

  bool _shouldLogTrackedAuthEndpoint(String endpoint) {
    return endpoint == '/auth/user-login' || endpoint == '/auth/register-user';
  }

  void _logTrackedAuthRequest(
    String method,
    String endpoint,
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, String>? fields,
    required bool hasFiles,
  }) {
    if (!_shouldLogTrackedAuthEndpoint(endpoint) ||
        (!kDebugMode && !kProfileMode)) {
      return;
    }

    AppLogger.debug('[AuthApi] request method=$method url=$uri');

    if (body != null) {
      AppLogger.debug(
        '[AuthApi] request-body ${_logValue(_redactSensitive(body))}',
      );
      return;
    }

    if (fields != null && fields.isNotEmpty) {
      AppLogger.debug(
        '[AuthApi] request-fields ${_logValue(_redactSensitive(fields))}',
      );
      return;
    }

    if (hasFiles) {
      AppLogger.debug('[AuthApi] request-body <multipart-files>');
    }
  }

  void _logTrackedAuthResponse(String endpoint, http.Response response) {
    if (!_shouldLogTrackedAuthEndpoint(endpoint) ||
        (!kDebugMode && !kProfileMode)) {
      return;
    }

    AppLogger.debug(
      '[AuthApi] response status=${response.statusCode} url=${response.request?.url ?? endpoint}',
    );

    if (response.body.isEmpty) {
      AppLogger.debug('[AuthApi] response-body <empty>');
      return;
    }

    try {
      final decoded = jsonDecode(response.body);
      AppLogger.debug(
        '[AuthApi] response-body ${_logValue(_redactSensitive(decoded))}',
      );
    } catch (_) {
      AppLogger.debug(
        '[AuthApi] response-body ${_truncateForLog(response.body)}',
      );
    }
  }

  void _logTrackedAuthException(String method, String endpoint, Object error) {
    if (!_shouldLogTrackedAuthEndpoint(endpoint) ||
        (!kDebugMode && !kProfileMode)) {
      return;
    }

    AppLogger.debug(
      '[AuthApi] exception method=$method endpoint=$endpoint type=${error.runtimeType} error=$error',
    );
  }

  Object? _redactSensitive(Object? value) {
    if (value is Map) {
      return value.map((key, entryValue) {
        final normalizedKey = key.toString().toLowerCase();
        if (_isSensitiveLogKey(normalizedKey)) {
          return MapEntry(key, '***');
        }
        return MapEntry(key, _redactSensitive(entryValue));
      });
    }

    if (value is List) {
      return value.map(_redactSensitive).toList(growable: false);
    }

    return value;
  }

  bool _isSensitiveLogKey(String key) {
    return key.contains('password') ||
        key.contains('token') ||
        key.contains('authorization') ||
        key.contains('secret');
  }

  String _logValue(Object? value) {
    return _truncateForLog(value.toString());
  }

  String _truncateForLog(String value, {int maxLength = 1600}) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...<truncated>';
  }

  void _handleErrorResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {}
    }

    final message =
        _extractErrorMessage(body) ??
        'Server returned status: ${response.statusCode}';
    throw ServerFailure(message, response.statusCode);
  }

  String? _extractErrorMessage(dynamic body) {
    if (body is! Map) {
      return null;
    }

    final directMessage = body['message']?.toString();
    if (directMessage != null && directMessage.isNotEmpty) {
      return directMessage;
    }

    final detail = body['detail']?.toString();
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }

    final error = body['error'];
    if (error is Map) {
      final nestedMessage = error['message']?.toString();
      if (nestedMessage != null && nestedMessage.isNotEmpty) {
        return nestedMessage;
      }
    }

    final errors = body['errors'] ?? body['Errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return firstError.toString();
    }

    final title = body['title']?.toString();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    return null;
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }
}

List<Object?> _decodeBodyBytes(List<int> bytes) {
  final rawPayload = utf8.decode(bytes);
  if (rawPayload.isEmpty) {
    return <Object?>[rawPayload, null];
  }
  return <Object?>[rawPayload, jsonDecode(rawPayload)];
}

List<Object?> _decodeBodyString(String payload) {
  if (payload.isEmpty) {
    return <Object?>[payload, null];
  }
  return <Object?>[payload, jsonDecode(payload)];
}
