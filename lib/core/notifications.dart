import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ParkNotifications {
  ParkNotifications();

  final _plugin = FlutterLocalNotificationsPlugin();
  void Function(String action)? onAction;

  static const paidId = 'paid';
  static const passengerId = 'passenger';
  static const snoozeId = 'snooze';
  static const putParkingId = 'put_parking';
  static const notParkingId = 'not_parking';

  Future<void> init() async {
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(iOS: ios),
      onDidReceiveNotificationResponse: (r) {
        final action = r.actionId;
        if (action != null && action.isNotEmpty) onAction?.call(action);
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showParkingPrompt() async {
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'PARKING_PROMPT',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
    await _plugin.show(
      1,
      'Parking check',
      'Looks like you stopped — Put parking or Already paid?',
      details,
      payload: 'parking_prompt',
    );
  }

  Future<void> showSnoozeReminder() async {
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
    await _plugin.show(
      2,
      'Parking reminder',
      'Still need to put parking?',
      details,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
