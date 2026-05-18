import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_models.dart';

class LocalAlertService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initSettings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> showOfferAlert(OfferSummary offer) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'allonbiz_proximity',
        'allonbiz proximity alerts',
        channelDescription: 'Nearby offer alerts while exploring',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      offer.offerId.hashCode,
      offer.title,
      '${offer.shopName} is close to your route.',
      details,
      payload: offer.offerId,
    );
  }
}
