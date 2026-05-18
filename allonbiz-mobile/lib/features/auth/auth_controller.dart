import 'package:flutter/foundation.dart';

import '../../core/models/app_models.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/storage/app_storage.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required AppStorage storage,
  }) : _repository = repository,
       _storage = storage;

  final AuthRepository _repository;
  final AppStorage _storage;

  bool _initialized = false;
  bool _loading = false;
  String? _errorMessage;
  SessionUser? _user;
  bool _hasSeenOnboarding = false;

  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  SessionUser? get user => _user;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isAuthenticated => _user != null;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _hasSeenOnboarding = _storage.hasSeenOnboarding;
    _errorMessage = null;

    try {
      _user = await _repository
          .restoreSession()
          .timeout(const Duration(seconds: 8), onTimeout: () => null);
    } catch (error) {
      _user = null;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    await _storage.setHasSeenOnboarding(true);
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    await _run(() async {
      _user = await _repository.login(email, password);
    });
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await _run(() async {
      _user = await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
    });
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    await _repository.logout();
    _user = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> forgotPassword(String email) =>
      _run(() => _repository.forgotPassword(email));

  Future<void> sendOtp(String email) => _run(() => _repository.sendOtp(email));

  Future<String> verifyOtp({required String email, required String otp}) async {
    var token = '';
    await _run(() async {
      token = await _repository.verifyOtp(email: email, otp: otp);
    });
    return token;
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => _run(
    () => _repository.resetPassword(token: token, newPassword: newPassword),
  );

  Future<void> forceLogout() async {
    await _storage.clearTokens();
    _user = null;
    notifyListeners();
  }

  void updateLocalProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) {
    final current = _user;
    if (current == null) {
      return;
    }

    _user = current.copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phoneNumber: phoneNumber.trim(),
    );
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
