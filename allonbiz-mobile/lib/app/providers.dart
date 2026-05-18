import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/repositories/app_repository.dart';
import '../core/repositories/auth_repository.dart';
import '../core/services/background_tracking_coordinator.dart';
import '../core/services/local_alert_service.dart';
import '../core/storage/app_storage.dart';
import '../features/auth/auth_controller.dart';
import '../features/navigate/navigation_controller.dart';
import '../features/profile/preferences_controller.dart';

final appStorageProvider = Provider<AppStorage>((ref) => AppStorage());

final backgroundTrackingCoordinatorProvider =
    Provider<BackgroundTrackingCoordinator>(
      (ref) => BackgroundTrackingCoordinator(),
    );

final localAlertServiceProvider = Provider<LocalAlertService>(
  (ref) => LocalAlertService(),
);

final bootstrapProvider = FutureProvider<void>((ref) async {
  await AppConfig.load();
  final storage = ref.read(appStorageProvider);
  await storage.initialize();

  await ref.read(authControllerProvider).initialize();
});

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnv());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    config: ref.read(appConfigProvider),
    storage: ref.read(appStorageProvider),
  );
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    repository: ref.read(authRepositoryProvider),
    storage: ref.read(appStorageProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.read(appConfigProvider),
    storage: ref.read(appStorageProvider),
    onUnauthorized: () async {
      await ref.read(authControllerProvider).forceLogout();
    },
  );
});

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(
    apiClient: ref.read(apiClientProvider),
    config: ref.read(appConfigProvider),
  );
});

final preferencesControllerProvider =
    ChangeNotifierProvider<PreferencesController>((ref) {
      return PreferencesController(ref.read(appStorageProvider));
    });

final navigationControllerProvider =
    ChangeNotifierProvider<NavigationController>((ref) {
      return NavigationController(
        repository: ref.read(appRepositoryProvider),
        storage: ref.read(appStorageProvider),
        preferencesController: ref.read(preferencesControllerProvider),
        localAlertService: ref.read(localAlertServiceProvider),
        backgroundTrackingCoordinator: ref.read(
          backgroundTrackingCoordinatorProvider,
        ),
      );
    });
