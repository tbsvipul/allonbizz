import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundTrackingCoordinator {
  final FlutterBackgroundService _service = FlutterBackgroundService();
  bool _configured = false;

  Future<void> prepareForStartup({required bool hasActiveJourney}) async {
    await configure();
    if (!hasActiveJourney) {
      await stop();
    }
  }

  Future<void> configure() async {
    if (_configured) {
      return;
    }

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _backgroundEntryPoint,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        foregroundServiceNotificationId: 8120,
        initialNotificationTitle: 'allonbiz tracking',
        initialNotificationContent: 'Proximity discovery is running',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _backgroundEntryPoint,
        onBackground: _onIosBackground,
      ),
    );

    _configured = true;
  }

  Future<void> start() async {
    await configure();
    await _service.startService();
  }

  Future<void> stop() async {
    final running = await _service.isRunning();
    if (running) {
      _service.invoke('stopService');
    }
  }
}

@pragma('vm:entry-point')
void _backgroundEntryPoint(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  service.on('stopService').listen((_) {
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async => true;
