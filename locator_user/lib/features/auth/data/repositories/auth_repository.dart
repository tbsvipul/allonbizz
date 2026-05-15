import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../../profile/data/repositories/profile_repository.dart';

/// Riverpod provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    notificationService: ref.watch(notificationServiceProvider),
    apiClient: ref.watch(apiClientProvider),
    storageService: ref.watch(storageServiceProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
  );
});

/// Stream of auth state changes.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Repository for Backend Authentication and user profile management.
class AuthRepository {
  AuthRepository({
    NotificationService? notificationService,
    ApiClient? apiClient,
    StorageService? storageService,
    ProfileRepository? profileRepository,
  }) : _notificationService = notificationService ?? NotificationService(),
       _apiClient = apiClient ?? ApiClient(baseUrl: '', storageService: StorageService()),
       _storageService = storageService ?? StorageService(),
       _profileRepository = profileRepository {
    _init();
  }

  final NotificationService _notificationService;
  final ApiClient _apiClient;
  final StorageService _storageService;
  final ProfileRepository? _profileRepository;

  final _authController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  Stream<AppUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  AppUser? get currentUser => _currentUser;

  Future<void> _init() async {
    final token = _storageService.backendAccessToken;
    if (token != null) {
      try {
        await refreshProfile();
      } catch (_) {
        _updateState(null);
      }
    } else {
      _updateState(null);
    }
  }

  void _updateState(AppUser? user) {
    _currentUser = user;
    _authController.add(user);
  }

  Future<AppUser?> refreshProfile() async {
    try {
      final user = await (_profileRepository?.getProfile() ?? 
        _apiClient.get('/user/profile').then((r) => AppUser.fromJson(r['data'])));
      
      _updateState(user);

      return user;
    } catch (e) {
      if (e is ServerFailure && e.statusCode == 401) {
        _updateState(null);
      }
      rethrow;
    }
  }

  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/user-login',
        body: {'email': email, 'password': password},
      );

      final data = response['data'];
      if (data != null) {
        _storageService.backendAccessToken = data['accessToken'];
        _storageService.backendRefreshToken = data['refreshToken'];
        return await refreshProfile();
      }
      throw const AuthFailure('login-failed', 'Invalid response from server');
    } on ServerFailure catch (e) {
      if (e.statusCode == 401) throw const AuthFailure('unauthorized', 'Invalid email or password');
      throw AuthFailure('error', e.message);
    }
  }

  Future<AppUser?> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      final names = name.trim().split(' ');
      final fn = names.first;
      final ln = names.length > 1 ? names.sublist(1).join(' ') : '';

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
        return await refreshProfile();
      }
      throw const AuthFailure('registration-failed', 'Could not create account');
    } on ServerFailure catch (e) {
      if (e.statusCode == 409) throw const AuthFailure('email-already-in-use', 'Email is already registered');
      throw AuthFailure('error', e.message);
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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _apiClient.post('/auth/forgot-password', body: {'email': email});
    } on ServerFailure catch (e) {
      throw AuthFailure('forgot-password-failed', e.message);
    }
  }

}
