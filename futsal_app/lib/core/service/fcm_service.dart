import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received: ${message.messageId}');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Check permission status (don't request automatically)
      NotificationSettings settings = await _firebaseMessaging
          .getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted notification permission');
        }
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        if (kDebugMode) {
          print('User granted provisional notification permission');
        }
      } else {
        if (kDebugMode) {
          print('Notification permission not granted yet');
        }
        // Don't return early - still initialize other FCM features
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        // TODO: Send new token to backend
        _sendTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification when app is launched from terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      if (kDebugMode) {
        print('FCM Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
    }
  }

  /// Initialize flutter_local_notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'futsal_notifications',
      'Futsal Notifications',
      description: 'Notifications for bookings, payments, and updates',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message: ${message.notification?.title}');
    }

    // Show local notification
    _showLocalNotification(message);

    // Add to in-app notification list
    _addToInAppNotifications(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'futsal_notifications',
            'Futsal Notifications',
            channelDescription:
                'Notifications for bookings, payments, and updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Add notification to in-app notification list
  void _addToInAppNotifications(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Determine notification type from data
    final typeString = message.data['type'] as String?;
    NotificationType type = NotificationType.bookingConfirmed;

    if (typeString != null) {
      switch (typeString) {
        case 'booking_confirmed':
          type = NotificationType.bookingConfirmed;
          break;
        case 'booking_reminder':
          type = NotificationType.bookingReminder;
          break;
        case 'booking_cancelled':
          type = NotificationType.bookingCancelled;
          break;
        case 'booking_completed':
          type = NotificationType.bookingCompleted;
          break;
        case 'review_reminder':
          type = NotificationType.reviewReminder;
          break;
        case 'payment_success':
          type = NotificationType.paymentSuccess;
          break;
        case 'payment_failed':
          type = NotificationType.paymentFailed;
          break;
      }
    }

    // Add to in-app notification service
    NotificationService().showNotification(
      title: notification.title ?? 'Notification',
      body: notification.body ?? '',
      type: type,
      data: message.data,
    );
  }

  /// Handle notification tap (when user taps notification)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.data}');
    }

    // Add to in-app notifications if not already added
    _addToInAppNotifications(message);

    // TODO: Navigate to appropriate screen based on notification type
    // This will be handled in the main app navigation
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Local notification tapped: ${response.payload}');
    }
    // TODO: Handle navigation
  }

  /// Send token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      // TODO: Implement API call to send token to backend
      // Example:
      // await ApiService().post('/users/fcm-token', {'token': token});
      if (kDebugMode) {
        print('TODO: Send FCM token to backend: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending token to backend: $e');
      }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      if (kDebugMode) {
        print('FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting token: $e');
      }
    }
  }
}
