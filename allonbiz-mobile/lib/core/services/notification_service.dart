import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes/app_router.dart';
import '../constants/app_colors.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Ref? _ref;

  NotificationService([this._ref]);

  Future<void> init() async {
    // Local notifications setup
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty && _ref != null) {
          _ref.read(appRouterProvider).push(payload);
        }
      },
    );
  }



  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'deals_channel',
      'Nearby Deals',
      channelDescription:
          'Notifications for offers discovered along your route.',
      importance: Importance.max,
      priority: Priority.high,
      color: AppColors.primary,
    );

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// Initialize + Start Background Service
  Future<void> initBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'location_channel',
        initialNotificationTitle: 'Locator',
        initialNotificationContent: 'Tracking location for active trip...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Start the service
    await service.startService();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;

/// Background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 1. MUST BE FIRST: Initialize plugin bridge for isolate
  DartPluginRegistrant.ensureInitialized();
  // 2. MUST BE SECOND: Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    // Create the notification channel from Dart side
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_channel',
      'Location Tracking',
      description: 'Used for background location & trip tracking',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.setAsForegroundService();
    await service.setForegroundNotificationInfo(
      title: 'Locator Active Trip',
      content: 'Running in background',
    );
  }

  // Periodic background logic (e.g., location/notification updates)
  Timer? timer;
  timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        await service.setForegroundNotificationInfo(
          title: 'Locator Tracking Active',
          content: 'Updated: ${DateTime.now().hour}:${DateTime.now().minute}',
        );
      }
    }
  });

  // Consolidate stop service logic
  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
