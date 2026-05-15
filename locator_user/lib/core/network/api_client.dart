import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, kDebugMode, kProfileMode;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../services/storage_service.dart';
import '../errors/failures.dart';

/// Riverpod provider for ApiClient.
final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final baseUrl = _resolveBaseUrl(dotenv.env['API_BASE_URL']);
  return ApiClient(baseUrl: baseUrl, storageService: storageService);
});

String _resolveBaseUrl(String? rawUrl) {
  final configuredUrl = rawUrl?.trim();
  const fallbackUrl = kIsWeb
      ? 'http://localhost:5247/api/v1'
      : 'http://10.0.2.2:5247/api/v1';

  if (configuredUrl == null || configuredUrl.isEmpty) {
    return fallbackUrl;
  }

  final uri = Uri.tryParse(configuredUrl);
  if (uri == null || uri.host.isEmpty) {
    return fallbackUrl;
  }

  final normalized = configuredUrl.endsWith('/')
      ? configuredUrl.substring(0, configuredUrl.length - 1)
      : configuredUrl;

  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      _isLoopbackHost(uri.host)) {
    return uri.replace(host: '10.0.2.2').toString();
  }

  return normalized;
}

bool _isLoopbackHost(String host) {
  final normalized = host.trim().toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '0.0.0.0';
}

/// A lightweight HTTP client that automatically attaches the backend AccessToken
/// from StorageService and handles basic error throwing.
class ApiClient {
  final String baseUrl;
  final StorageService storageService;
  final http.Client _client;
  bool _isRefreshing = false;

  ApiClient({
    required this.baseUrl,
    required this.storageService,
    http.Client? client,
  }) : _client = client ?? _createDefaultClient();

  /// Creates a platform-appropriate client with security hardening.
  static http.Client _createDefaultClient() {
    if (kIsWeb) return http.Client();

    final SecurityContext context = SecurityContext(withTrustedRoots: true);

    final HttpClient httpClient = HttpClient(context: context)
      ..connectionTimeout = const Duration(seconds: 15);

    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      if (kDebugMode || kProfileMode) {
        final isLocalHost = host == '10.0.2.2' ||
            host == 'localhost' ||
            host == '127.0.0.1' ||
            host == '0.0.0.0';
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

      if (files != null || fields != null) {
        final multipartRequest = http.MultipartRequest(method, uri);
        multipartRequest.headers.addAll(_headers);
        if (fields != null) multipartRequest.fields.addAll(fields);
        if (files != null) multipartRequest.files.addAll(files);
        request = multipartRequest;
      } else {
        final httpRequest = http.Request(method, uri);
        httpRequest.headers.addAll(_headers);
        if (body != null) httpRequest.body = jsonEncode(body);
        request = httpRequest;
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 && !isRetry && !_isRefreshing) {
        final success = await _tryRefreshToken();
        if (success) {
          return _request(method, endpoint,
              body: body, files: files, fields: fields, isRetry: true);
        }
      }

      _handleErrorResponse(response);
      return _decodeBody(response);
    } on http.ClientException {
      throw const NetworkFailure();
    } on SocketException {
      throw const NetworkFailure();
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw const NetworkFailure();
    }
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = storageService.backendRefreshToken;
    if (refreshToken == null) return false;

    _isRefreshing = true;
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
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
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _handleErrorResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {}
    }

    final message = _extractErrorMessage(body) ??
        'Server returned status: ${response.statusCode}';
    throw ServerFailure(message, response.statusCode);
  }

  String? _extractErrorMessage(dynamic body) {
    if (body is! Map) return null;

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
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}
