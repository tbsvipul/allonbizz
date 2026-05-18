import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../storage/app_storage.dart';

class _AuthRepositoryException implements Exception {
  const _AuthRepositoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({required AppConfig config, required AppStorage storage})
    : _storage = storage,
      _dio = Dio(
        BaseOptions(
          baseUrl: config.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Content-Type': 'application/json'},
        ),
      );

  final AppStorage _storage;
  final Dio _dio;

  Future<SessionUser?> restoreSession() async {
    final tokens = _storage.readTokens();
    if (tokens == null) {
      return null;
    }

    try {
      return await _fetchCurrentUser(tokens.accessToken);
    } on _AuthRepositoryException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
    }

    final refreshed = await _refreshTokens();
    if (refreshed == null) {
      await _storage.clearTokens();
      return null;
    }

    return _fetchCurrentUser(refreshed.accessToken);
  }

  Future<SessionUser> login(String email, String password) async {
    final payload = await _postAuth('/auth/user-login', {
      'email': email.trim(),
      'password': password,
    });
    final tokens = AuthTokens.fromJson(payload);
    await _storage.writeTokens(tokens);
    return _fetchCurrentUser(tokens.accessToken);
  }

  Future<SessionUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final payload = await _postAuth('/auth/register-user', {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'password': password,
    });
    final tokens = AuthTokens.fromJson(payload);
    await _storage.writeTokens(tokens);
    return _fetchCurrentUser(tokens.accessToken);
  }

  Future<void> logout() async {
    final tokens = _storage.readTokens();
    if (tokens != null) {
      try {
        await _dio.post<Map<String, dynamic>>(
          '/auth/logout',
          options: Options(
            headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
          ),
        );
      } catch (_) {
        // Clearing local state is more important than transport success here.
      }
    }

    await _storage.clearTokens();
  }

  Future<void> forgotPassword(String email) =>
      _postVoid('/auth/forgot-password', {'email': email.trim()});

  Future<void> sendOtp(String email) =>
      _postVoid('/auth/send-otp', {'email': email.trim()});

  Future<String> verifyOtp({required String email, required String otp}) async {
    final payload = await _postAuth('/auth/verify-otp', {
      'email': email.trim(),
      'otp': otp.trim(),
    });
    return payload['resetToken']?.toString() ?? '';
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => _postVoid('/auth/reset-password', {
    'token': token,
    'newPassword': newPassword,
  });

  Future<Map<String, dynamic>> _postAuth(
    String path,
    Map<String, dynamic> data,
  ) => _runRequest(() async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: data);
    return _unwrap(response.data);
  });

  Future<void> _postVoid(String path, Map<String, dynamic> data) =>
      _runRequest(() async {
        final response = await _dio.post<Map<String, dynamic>>(path, data: data);
        _unwrap(response.data);
      });

  Future<SessionUser> _fetchCurrentUser(String accessToken) => _runRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/user/profile',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final payload = _unwrap(response.data);
    return SessionUser.fromJson(payload);
  });

  Future<AuthTokens?> _refreshTokens() async {
    final tokens = _storage.readTokens();
    if (tokens == null) {
      return null;
    }

    try {
      final payload = await _runRequest(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/refresh-token',
          data: {'refreshToken': tokens.refreshToken},
        );
        return _unwrap(response.data);
      });
      final refreshed = AuthTokens.fromJson(payload);
      await _storage.writeTokens(refreshed);
      return refreshed;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? payload) {
    final body = payload ?? const <String, dynamic>{};
    if (body['success'] == false) {
      final error = body['error'] as Map<String, dynamic>?;
      throw _AuthRepositoryException(
        error?['message']?.toString() ?? 'Authentication failed.',
      );
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }

  Future<T> _runRequest<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw _AuthRepositoryException(
        _extractErrorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  String _extractErrorMessage(DioException error) {
    final payload = error.response?.data;

    if (payload is Map) {
      final body = Map<String, dynamic>.from(payload);

      final envelopeError = body['error'];
      if (envelopeError is Map) {
        final message = envelopeError['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      final detail = body['detail']?.toString().trim();
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }

      final errors = body['errors'];
      if (errors is Map) {
        final messages = <String>[];
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List) {
            for (final item in value) {
              final text = item.toString().trim();
              if (text.isNotEmpty) {
                messages.add(text);
              }
            }
          } else if (value != null) {
            final text = value.toString().trim();
            if (text.isNotEmpty) {
              messages.add(text);
            }
          }
        }
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      final title = body['title']?.toString().trim();
      if (title != null &&
          title.isNotEmpty &&
          title != 'One or more validation errors occurred.') {
        return title;
      }
    }

    if (payload is String && payload.trim().isNotEmpty) {
      return payload.trim();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond.';
      case DioExceptionType.connectionError:
        return 'Could not connect to the server. Check your network and API URL.';
      default:
        break;
    }

    return switch (error.response?.statusCode) {
      400 => 'The request was rejected by the server.',
      401 => 'Invalid credentials.',
      403 => 'You are not allowed to perform this action.',
      404 => 'Service endpoint not found.',
      500 => 'The server hit an unexpected error.',
      final statusCode? => 'Request failed with status $statusCode.',
      _ => 'Authentication request failed.',
    };
  }
}
