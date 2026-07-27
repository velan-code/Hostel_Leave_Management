import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import './system_notification_service.dart';
import './firebase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final notification = message.notification;
    if (notification != null) {
      await SystemNotificationService().showNotification(
        id: message.messageId.hashCode,
        title: notification.title ?? 'Hostel Leave Update',
        body: notification.body ?? 'You have a new leave approval update.',
        payload: message.data['leaveRequestId'] ?? '',
      );
    }
  } catch (e) {
    debugPrint('Error in FCM background handler: $e');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  FirebaseMessaging? get _fcm {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseMessaging.instance;
      }
    } catch (e) {
      debugPrint('FCM instance access error: $e');
    }
    return null;
  }

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final fcm = _fcm;
    if (fcm == null) {
      debugPrint('Firebase messaging skipped because Firebase is not ready.');
      return;
    }

    try {
      // 1. Request Push Notification Permissions
      final settings = await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
          'FCM Notification Permission status: ${settings.authorizationStatus}');

      // 2. Set Background Message Handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 3. Enable Foreground Presentation Options (iOS / macOS)
      await fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Retrieve FCM Device Push Token safely (handling APNS token delay on iOS/Simulator)
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
          final apnsToken = await fcm.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('APNS token not available yet on iOS device/simulator. FCM token will refresh automatically.');
          } else {
            _fcmToken = await fcm.getToken();
          }
        } else {
          _fcmToken = await fcm.getToken();
        }
        if (_fcmToken != null) {
          debugPrint('FCM Device Push Token: $_fcmToken');
        }
      } catch (tokenErr) {
        debugPrint('FCM Token fetch deferred gracefully: $tokenErr');
      }

      // Listen to Token Refresh
      fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Device Push Token Refreshed: $_fcmToken');
      });

      // 5. Handle Foreground Push Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            'Foreground Push Notification received: ${message.notification?.title}');
        final notification = message.notification;
        if (notification != null) {
          SystemNotificationService().showNotification(
            id: message.messageId.hashCode,
            title: notification.title ?? 'Hostel Leave Update',
            body: notification.body ?? 'You have a new leave approval update.',
            payload: message.data['leaveRequestId'] ?? '',
          );
        }
      });

      // 6. Handle App Opened from Terminated / Background Push Notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
            'App opened from Push Notification: ${message.notification?.title}');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing PushNotificationService (FCM): $e');
    }
  }

  Future<void> _saveFcmTokenToFirestore(String docId, String token) async {
    if (docId.isNotEmpty) {
      try {
        final firestore = FirebaseService().firestore;
        if (firestore != null) {
          await firestore.collection('users').doc(docId).set({
            'fcmToken': token,
            'lastUpdatedToken': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Error saving FCM Token to Firestore: $e');
      }
    }
  }

  Future<void> registerCurrentUserFcmToken(String userId) async {
    if (_fcmToken != null && userId.isNotEmpty) {
      await _saveFcmTokenToFirestore(userId, _fcmToken!);
    }
  }
}
