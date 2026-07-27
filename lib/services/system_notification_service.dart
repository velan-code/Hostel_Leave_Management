import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SystemNotificationService {
  static final SystemNotificationService _instance =
      SystemNotificationService._internal();
  factory SystemNotificationService() => _instance;
  SystemNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _isOuterNotificationEnabled = true;

  bool get isOuterNotificationEnabled => _isOuterNotificationEnabled;

  void setOuterNotificationEnabled(bool enabled) {
    _isOuterNotificationEnabled = enabled;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('OS System Notification clicked: ${details.payload}');
        },
      );

      // Create Android Notification Channel
      final androidPlatformChannelSpecifics =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatformChannelSpecifics != null) {
        await androidPlatformChannelSpecifics.createNotificationChannel(
          const AndroidNotificationChannel(
            'hostel_leave_channel',
            'Hostel Leave Approvals',
            description:
                'High priority notifications for leave request status and approvals',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing SystemNotificationService: $e');
    }
  }

  Future<bool> requestNotificationPermission() async {
    if (!_isInitialized) {
      await initialize();
    }
    bool granted = false;
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? androidGranted =
            await androidImplementation.requestNotificationsPermission();
        granted = androidGranted ?? false;
      }

      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final bool? iosGranted =
            await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = iosGranted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
    return granted;
  }

  final Set<String> _shownNotifKeys = {};

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final deduplicationKey = '${id}_${payload ?? title}';
    if (_shownNotifKeys.contains(deduplicationKey)) {
      debugPrint('Skipping duplicate OS notification: $deduplicationKey');
      return;
    }
    _shownNotifKeys.add(deduplicationKey);

    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'hostel_leave_channel',
      'Hostel Leave Approvals',
      channelDescription:
          'High priority notifications for leave request status and approvals',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error triggering OS system notification: $e');
    }
  }
}
