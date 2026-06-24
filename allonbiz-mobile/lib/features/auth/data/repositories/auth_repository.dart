import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kProfileMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/base_api.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../profile/data/repositories/profile_repository.dart';

/// Riverpod provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    storageService: ref.watch(storageServiceProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// Stream of auth state changes.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Repository for Backend Authentication and user profile management.
class AuthRepository {
  AuthRepository({
    ApiClient? apiClient,
    StorageService? storageService,
    ProfileRepository? profileRepository,
  }) : _apiClient =
           apiClient ??
           ApiClient(
             baseUrl: BaseApi.backendBaseUrl,
             storageService: StorageService(),
           ),
       _storageService = storageService ?? StorageService(),
       _profileRepository = profileRepository {
    _init();
  }

  final ApiClient _apiClient;
  final StorageService _storageService;
  final ProfileRepository? _profileRepository;

  final _authController = StreamController<AppUser?>.broadcast();
  final _forcedLogoutController = StreamController<String>.broadcast();
  AppUser? _currentUser;
  bool _isInitialized = false;

  Stream<AppUser?> get authStateChanges async* {
    if (_isInitialized) {
      yield _currentUser;
    }
    yield* _authController.stream;
  }

  Stream<String> get onForcedLogout => _forcedLogoutController.stream;

  AppUser? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;

  Future<void> _init() async {
    _apiClient.onAuthFailed.listen((reason) {
      if (_storageService.backendAccessToken != null) {
        _logAuthFlow(
          'global-auth-failed',
          details: {'action': 'clearing session', 'reason': reason},
        );
        _storageService.backendAccessToken = null;
        _storageService.backendRefreshToken = null;
        _updateState(null);

        if (reason != null && (reason.toLowerCase().contains('banned') || reason.toLowerCase().contains('suspended'))) {
          _forcedLogoutController.add('$reason\nPlease contact routentsupport@gmail.com for assistance.');
        }
      }
    });

    final token = _storageService.backendAccessToken;
    _logAuthFlow('init', details: {'hasStoredAccessToken': token != null});
    if (token != null) {
      try {
        await refreshProfile();
      } catch (e) {
        _logAuthFlow('init-refresh-profile-failed');
        if (e is ServerFailure && e.statusCode == 401) {
          // Already handled in refreshProfile
        } else if (e is NetworkFailure) {
          // Keep user authenticated if offline
          _logAuthFlow('init-refresh-profile-network-failure');
          // Mark as initialized but keep existing user state to retain session
          _isInitialized = true;
          _authController.add(_currentUser);
        } else {
          _updateState(null);
        }
      }
    } else {
      _updateState(null);
    }
  }

  void _updateState(AppUser? user) {
    _currentUser = user;
    _isInitialized = true;
    _authController.add(user);
  }

  Future<AppUser?> refreshProfile() async {
    _logAuthFlow('refresh-profile-start');
    try {
      final user =
          await (_profileRepository?.getProfile() ??
              _apiClient
                  .get('/user/profile')
                  .then((r) => AppUser.fromJson(r['data'])));

      _updateState(user);
      _logAuthFlow(
        'refresh-profile-success',
        details: {
          'userId': user.uid,
          'email': user.email == null ? null : _maskEmail(user.email!),
        },
      );

      return user;
    } catch (e) {
      _logAuthFlow('refresh-profile-failure', details: {'error': e.toString()});
      rethrow;
    }
  }

  Future<AppUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    _logAuthFlow(
      'login-start',
      details: {'email': _maskEmail(email), 'baseUrl': _apiClient.baseUrl},
    );
    try {
      final response = await _apiClient.post(
        '/auth/user-login',
        body: {'email': email, 'password': password},
      );

      final data = response['data'];
      if (data != null) {
        _storageService.backendAccessToken = data['accessToken'];
        _storageService.backendRefreshToken = data['refreshToken'];
        _logAuthFlow(
          'login-success-auth-payload',
          details: {
            'hasAccessToken': data['accessToken'] != null,
            'hasRefreshToken': data['refreshToken'] != null,
          },
        );
        _logAuthFlow('login-refresh-profile-start');
        return await refreshProfile();
      }
      _logAuthFlow('login-invalid-response');
      throw const AuthFailure('login-failed', 'Invalid response from server');
    } on ServerFailure catch (e) {
      _logAuthFlow(
        'login-server-failure',
        details: {'statusCode': e.statusCode, 'message': e.message},
      );
      if (e.statusCode == 401) {
        String msg = e.message;
        if (msg.toLowerCase().contains('banned') || msg.toLowerCase().contains('suspended')) {
          msg = '$msg\nPlease contact routentsupport@gmail.com for assistance.';
        } else if (msg == 'Unauthorized' || msg.isEmpty) {
          msg = 'Invalid email or password';
        }
        throw AuthFailure('unauthorized', msg);
      }
      throw AuthFailure('error', e.message);
    } catch (e) {
      _logAuthFlow(
        'login-unexpected-failure',
        details: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<AppUser?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    _logAuthFlow(
      'register-start',
      details: {'email': _maskEmail(email), 'baseUrl': _apiClient.baseUrl},
    );
    try {
      final names = name.trim().split(RegExp(r'\s+'));
      final fn = names.first;
      final ln = names.length > 1 ? names.sublist(1).join(' ') : 'User';

      final response = await _apiClient.post(
        '/auth/register-user',
        body: {
          'firstName': fn,
          'lastName': ln,
          'email': email,
          'password': password,
        },
      );
      final data = response['data'];
      if (data != null) {
        _storageService.backendAccessToken = data['accessToken'];
        _storageService.backendRefreshToken = data['refreshToken'];
        _logAuthFlow(
          'register-success-auth-payload',
          details: {
            'hasAccessToken': data['accessToken'] != null,
            'hasRefreshToken': data['refreshToken'] != null,
          },
        );
        _logAuthFlow('register-refresh-profile-start');
        return await refreshProfile();
      }
      _logAuthFlow('register-invalid-response');
      throw const AuthFailure(
        'registration-failed',
        'Could not create account',
      );
    } on ServerFailure catch (e) {
      _logAuthFlow(
        'register-server-failure',
        details: {'statusCode': e.statusCode, 'message': e.message},
      );
      if (e.statusCode == 409) {
        throw const AuthFailure(
          'email-already-in-use',
          'Email is already registered',
        );
      }
      throw AuthFailure('error', e.message);
    } catch (e) {
      _logAuthFlow(
        'register-unexpected-failure',
        details: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (_storageService.backendAccessToken != null) {
        await _apiClient.post('/auth/logout');
      }
    } catch (_) {
    } finally {
      _storageService.backendAccessToken = null;
      _storageService.backendRefreshToken = null;
      _updateState(null);
    }
  }

  void dispose() {
    _authController.close();
    _forcedLogoutController.close();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _apiClient.post('/auth/forgot-password', body: {'email': email});
    } on ServerFailure catch (e) {
      if (e.statusCode == 404) {
        throw const AuthFailure(
          'user-not-found',
          'No user found for that email.',
        );
      }
      throw AuthFailure('forgot-password-failed', e.message);
    }
  }

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/verify-otp',
        body: {'email': email, 'otp': otp},
      );
      final token = response['data']?['resetToken']?.toString();
      if (token == null || token.trim().isEmpty) {
        throw const AuthFailure('invalid-otp', 'Invalid or expired OTP.');
      }
      return token;
    } on ServerFailure catch (e) {
      throw AuthFailure('invalid-otp', e.message);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post(
        '/auth/reset-password',
        body: {'token': token, 'newPassword': newPassword},
      );
    } on ServerFailure catch (e) {
      throw AuthFailure('reset-password-failed', e.message);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post(
        '/auth/change-password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on ServerFailure catch (e) {
      throw AuthFailure('change-password-failed', e.message);
    }
  }

  void _logAuthFlow(String step, {Map<String, Object?>? details}) {
    if (!kDebugMode && !kProfileMode) {
      return;
    }

    if (details == null || details.isEmpty) {
      AppLogger.debug('[AuthFlow] $step');
      return;
    }

    AppLogger.debug('[AuthFlow] $step $details');
  }

  String _maskEmail(String email) {
    final trimmed = email.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 1) {
      return '***';
    }

    final localPart = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex);
    if (localPart.length <= 2) {
      return '${localPart[0]}***$domain';
    }

    return '${localPart.substring(0, 2)}***$domain';
  }
}
