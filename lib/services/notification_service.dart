import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initializes the notification service and sets up Android/iOS channels
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      // Request notification permissions on Android 13+ / iOS
      await _requestPermissions();

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Sends a push notification when a credit card is successfully added
  Future<void> showCardSuccessNotification({
    required String cardType,
    required String last4Digits,
  }) async {
    await init();
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'card_vault_success_channel',
        'Card Validation Notifications',
        channelDescription:
            'Notifications sent when a credit card is validated or captured.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '💳 Card Added Successfully',
        'Your $cardType card ending in $last4Digits has been validated and saved.',
        details,
      );
    } catch (e) {
      debugPrint('Error showing success notification: $e');
    }
  }

  /// Sends a push notification when card submission fails (e.g. banned country, duplicate, invalid Luhn)
  Future<void> showCardFailureNotification({
    required String reason,
  }) async {
    await init();
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'card_vault_failure_channel',
        'Card Failure Alerts',
        channelDescription:
            'Notifications sent when a credit card fails validation or compliance check.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '🚫 Card Submission Blocked',
        reason,
        details,
      );
    } catch (e) {
      debugPrint('Error showing failure notification: $e');
    }
  }
}
