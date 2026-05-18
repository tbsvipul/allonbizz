import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../storage/app_storage.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required AppStorage storage,
    this.onUnauthorized,
  }) : _storage = storage,
       _dio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: const Duration(seconds: 20),
           receiveTimeout: const Duration(seconds: 20),
           headers: const {'Content-Type': 'application/json'},
         ),
       ),
       _refreshDio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: const Duration(seconds: 20),
           receiveTimeout: const Duration(seconds: 20),
           headers: const {'Content-Type': 'application/json'},
         ),
       ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] == true) {
            handler.next(options);
            return;
          }

          final tokens = _storage.readTokens();
          if (tokens != null) {
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final isAuthRequest =
              request.path.contains('/auth/user-login') ||
              request.path.contains('/auth/register-user') ||
              request.path.contains('/auth/register-keeper') ||
              request.path.contains('/auth/refresh-token');

          if (error.response?.statusCode == 401 &&
              !isAuthRequest &&
              request.extra['retried'] != true) {
            final refreshed = await _refreshToken();
            if (refreshed != null) {
              request.extra['retried'] = true;
              request.headers['Authorization'] = 'Bearer $refreshed';
              final retryResponse = await _dio.fetch<dynamic>(request);
              handler.resolve(retryResponse);
              return;
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  final AppStorage _storage;
  final Dio _dio;
  final Dio _refreshDio;
  final Future<void> Function()? onUnauthorized;

  Future<String?>? _pendingRefresh;

  Future<dynamic> getData(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: Options(extra: {'skipAuth': !authenticated}),
    );
    return _unwrapEnvelope(response.data);
  }

  Future<dynamic> postData(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    final response = await _dio.post<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(extra: {'skipAuth': !authenticated}),
    );
    return _unwrapEnvelope(response.data);
  }

  Future<dynamic> putData(
    String path, {
    dynamic data,
    bool authenticated = true,
  }) async {
    final response = await _dio.put<dynamic>(
      path,
      data: data,
      options: Options(extra: {'skipAuth': !authenticated}),
    );
    return _unwrapEnvelope(response.data);
  }

  dynamic _unwrapEnvelope(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      if (payload['success'] == false) {
        final error = payload['error'];
        final message = error is Map<String, dynamic>
            ? error['message']?.toString()
            : null;
        throw Exception(message ?? 'Request failed.');
      }
      if (payload.containsKey('data')) {
        return payload['data'];
      }
    }
    return payload;
  }

  Future<String?> _refreshToken() {
    if (_pendingRefresh != null) {
      return _pendingRefresh!;
    }

    _pendingRefresh = _performRefresh();
    return _pendingRefresh!;
  }

  Future<String?> _performRefresh() async {
    try {
      final tokens = _storage.readTokens();
      if (tokens == null) {
        return null;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh-token',
        data: {'refreshToken': tokens.refreshToken},
      );
      final unwrapped = _unwrapEnvelope(response.data);
      if (unwrapped is! Map<String, dynamic>) {
        return null;
      }

      final refreshed = AuthTokens.fromJson(unwrapped);
      await _storage.writeTokens(refreshed);
      return refreshed.accessToken;
    } catch (_) {
      await _storage.clearTokens();
      if (onUnauthorized != null) {
        await onUnauthorized!.call();
      }
      return null;
    } finally {
      _pendingRefresh = null;
    }
  }
}
