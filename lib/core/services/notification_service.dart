import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef NotificationTapCallback = void Function(String? payload);

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'trabajohub_high_importance_v1';
  static const String channelName = 'TrabajoHub Notifications';
  static const String channelDescription =
      'Important TrabajoHub shift, message, and account notifications.';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static NotificationTapCallback? _onNotificationTap;

  static Future<void> init({NotificationTapCallback? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationTap?.call(response.payload);
      },
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }
}
