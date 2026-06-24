import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/auth_repository.dart';

/// State for auth controller.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final bool isEmailVerified;
  final bool hasResolvedSession;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isEmailVerified = false,
    this.hasResolvedSession = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool? isEmailVerified,
    bool? hasResolvedSession,
    bool clearUser = false,
    bool clearError = false,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : (user ?? this.user),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    hasResolvedSession: hasResolvedSession ?? this.hasResolvedSession,
  );
}

/// Auth controller managing sign-in states.
class AuthController extends StateNotifier<AuthState> {
  static const String _genericAuthError =
      'Something went wrong. Please try again.';

  final AuthRepository _repo;
  StreamSubscription? _authSub;
  StreamSubscription? _forcedLogoutSub;
  bool _isManualAuth = false;

  AuthController(this._repo) : super(const AuthState()) {
    _init();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _forcedLogoutSub?.cancel();
    super.dispose();
  }

  void _init() {
    // 1. Listen for all future updates
    _authSub = _repo.authStateChanges.listen((user) {
      if (_isManualAuth) return;
      _handleUpdate(user);
    });

    _forcedLogoutSub = _repo.onForcedLogout.listen((message) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
        clearUser: true,
      );
    });
  }

  void _handleUpdate(AppUser? user) {
    if (user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        hasResolvedSession: true,
      );
    } else {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        hasResolvedSession: true,
      );
    }
  }

  /// Sign in with Email/Password.
  Future<void> signInWithEmail(String email, String password) async {
    _isManualAuth = true;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _repo.signInWithEmailAndPassword(email, password);
      if (user != null) {
        _handleUpdate(user);
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          hasResolvedSession: true,
        );
      }
    } on Failure catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _genericAuthError,
      );
    } finally {
      _isManualAuth = false;
    }
  }

  /// Register with Email/Password.
  Future<void> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _isManualAuth = true;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _repo.createUserWithEmailAndPassword(
        email,
        password,
        name,
      );
      if (user != null) {
        _handleUpdate(user);
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          hasResolvedSession: true,
        );
      }
    } on Failure catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _genericAuthError,
      );
    } finally {
      _isManualAuth = false;
    }
  }

  /// Reset Password.
  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repo.sendPasswordResetEmail(email);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        hasResolvedSession: true,
      );
    } on Failure catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _genericAuthError,
      );
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      hasResolvedSession: true,
    );
  }

  /// Clear any existing error state.
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(status: AuthStatus.initial, clearError: true);
    }
  }

  /// Refresh current user profile data.
  Future<void> refreshProfile() async {
    try {
      final user = await _repo.refreshProfile();
      if (user != null) {
        _handleUpdate(user);
      }
    } catch (e) {
      if (e is! AuthFailure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: _genericAuthError,
        );
      }
      // If refresh fails due to 401, _repo already updates state to null
    }
  }
}

/// Riverpod provider for AuthController.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);
