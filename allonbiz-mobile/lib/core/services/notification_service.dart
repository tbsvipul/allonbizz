import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes/app_router.dart';
import '../../app/routes/app_routes.dart';
import '../../features/navigate/presentation/controllers/navigation_controller.dart';
import '../constants/app_colors.dart';

class NotificationService {
  NotificationService([this._ref]);

  static const int activeJourneyNotificationId = 888;
  static const String _dealsChannelId = 'deals_channel';
  static const String _journeyChannelId = 'active_journey_channel';
  static const String _backgroundJourneyChannelId = 'location_channel';
  static const String _defaultJourneyTitle = 'Journey Active';
  static const String _defaultJourneyBody =
      'Your current journey is still running.';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Ref? _ref;
  Future<void>? _initFuture;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    if (_initFuture != null) {
      return _initFuture!;
    }

    _initFuture = _initialize();
    await _initFuture;
  }

  Future<void> _initialize() async {
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        if (details.actionId == 'end_journey') {
          if (_ref != null) {
            _ref.read(navigationControllerProvider.notifier).clearRoute();
          }
          return;
        }
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty && _ref != null) {
          _ref.read(appRouterProvider).go(payload);
        }
      },
    );

    await _createNotificationChannels();
    _isInitialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      return;
    }

    await init();

    const androidDetails = AndroidNotificationDetails(
      _dealsChannelId,
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
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> startJourneyTracking({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    // PRESERVED: active journey notifications and background service state must
    // remain aligned with persisted navigation sessions.
    await init();
    await showActiveJourneyNotification(title: title, body: body);
    await initBackgroundService(title: title, body: body);
  }

  Future<void> updateJourneyTracking({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    await init();
    await showActiveJourneyNotification(title: title, body: body);

    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('updateJourneyNotification', {
        'title': title,
        'content': body,
      });
    }
  }

  Future<void> stopJourneyTracking() async {
    if (kIsWeb) {
      return;
    }

    await init();
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }

    await _notifications.cancel(activeJourneyNotificationId);
  }

  Future<void> showActiveJourneyNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    await init();
    const androidDetails = AndroidNotificationDetails(
      _journeyChannelId,
      'Active Journey',
      channelDescription:
          'Persistent status for an active journey in progress.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      autoCancel: false,
      showWhen: false,
      channelShowBadge: false,
      color: AppColors.primary,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'end_journey',
          'End',
          cancelNotification: false,
          showsUserInterface: true,
        ),
      ],
    );

    await _notifications.show(
      activeJourneyNotificationId,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: AppRoutes.navigate,
    );
  }

  Future<void> initBackgroundService({
    String title = _defaultJourneyTitle,
    String body = _defaultJourneyBody,
  }) async {
    if (kIsWeb) {
      return;
    }

    await init();
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('updateJourneyNotification', {
        'title': title,
        'content': body,
      });
      return;
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _backgroundJourneyChannelId,
        initialNotificationTitle: title,
        initialNotificationContent: body,
        foregroundServiceNotificationId: activeJourneyNotificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
    service.invoke('updateJourneyNotification', {
      'title': title,
      'content': body,
    });
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _journeyChannelId,
        'Active Journey',
        description: 'Persistent notifications for journeys in progress.',
        importance: Importance.low,
        playSound: false,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _backgroundJourneyChannelId,
        'Location Tracking',
        description: 'Used for background location and active journey status.',
        importance: Importance.low,
        playSound: false,
        showBadge: false,
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  String title = NotificationService._defaultJourneyTitle;
  String content = NotificationService._defaultJourneyBody;

  if (service is AndroidServiceInstance) {
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      NotificationService._backgroundJourneyChannelId,
      'Location Tracking',
      description: 'Used for background location and active journey status.',
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

    Future<void> updateNotification(String t, String c) async {
      const androidDetails = AndroidNotificationDetails(
        NotificationService._backgroundJourneyChannelId,
        'Location Tracking',
        channelDescription:
            'Used for background location and active journey status.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        channelShowBadge: false,
        ongoing: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'end_journey',
            'End',
            cancelNotification: false,
            showsUserInterface: true,
          ),
        ],
      );
      await notificationsPlugin.show(
        NotificationService.activeJourneyNotificationId,
        t,
        c,
        const NotificationDetails(android: androidDetails),
      );
    }

    await updateNotification(title, content);
  }

  service.on('updateJourneyNotification').listen((event) async {
    title = event?['title']?.toString().trim().isNotEmpty == true
        ? event!['title'].toString()
        : NotificationService._defaultJourneyTitle;
    content = event?['content']?.toString().trim().isNotEmpty == true
        ? event!['content'].toString()
        : NotificationService._defaultJourneyBody;

    if (service is AndroidServiceInstance) {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        NotificationService._backgroundJourneyChannelId,
        'Location Tracking',
        channelDescription:
            'Used for background location and active journey status.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        channelShowBadge: false,
        ongoing: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'end_journey',
            'End',
            cancelNotification: false,
            showsUserInterface: true,
          ),
        ],
      );
      await notificationsPlugin.show(
        NotificationService.activeJourneyNotificationId,
        title,
        content,
        const NotificationDetails(android: androidDetails),
      );
    }
  });

  Timer? heartbeat;
  heartbeat = Timer.periodic(const Duration(minutes: 1), (_) async {
    if (service is AndroidServiceInstance &&
        await service.isForegroundService()) {
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        NotificationService._backgroundJourneyChannelId,
        'Location Tracking',
        channelDescription:
            'Used for background location and active journey status.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        channelShowBadge: false,
        ongoing: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'end_journey',
            'End',
            cancelNotification: false,
            showsUserInterface: true,
          ),
        ],
      );
      await notificationsPlugin.show(
        NotificationService.activeJourneyNotificationId,
        title,
        content,
        const NotificationDetails(android: androidDetails),
      );
    }
  });

  service.on('stopService').listen((event) {
    heartbeat?.cancel();
    service.stopSelf();
  });
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
