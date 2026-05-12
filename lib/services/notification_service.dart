import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle messages when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Initialize local notifications
      await _initializeLocalNotifications();

      debugPrint('Firebase notification service initialized successfully');
    } catch (e) {
      debugPrint('Firebase notification service initialization failed: $e');
      debugPrint('Push notifications will not work. Setup Firebase for full functionality.');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('Local notifications initialized successfully');
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  Future<void> sendTokenToBackend(String userId, String token, String authToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://hp.triz.co.in/api/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': token,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token sent to backend successfully');
      } else {
        debugPrint('❌ Failed to send FCM token to backend: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM token to backend: $e');
    }
  }

  Future<void> updateTokenWithUser(String userId, String authToken) async {
    try {
      final token = await getToken();
      if (token != null) {
        debugPrint('📱 FCM Token: $token');
        await sendTokenToBackend(userId, token, authToken);

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          debugPrint('🔄 FCM Token refreshed: $newToken');
          await sendTokenToBackend(userId, newToken, authToken);
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Log for debugging - actual notification will be shown by the calling screen
    debugPrint('📱 Push notification requested:');
    debugPrint('  📌 Title: $title');
    debugPrint('  📝 Body: $body');
    debugPrint('  🔑 Token: $token');
    debugPrint('  📊 Data: $data');
    debugPrint('💡 Note: In-app notification shown to user. Push notifications require backend server implementation');
  }

  // Test method to verify local notifications work
  Future<void> testLocalNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification to verify the notification drawer works',
      payload: 'test_payload',
    );
    debugPrint('🔔 Test local notification sent');
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');

  // Show local notification for background messages as well for consistency
  if (message.notification != null) {
    await NotificationService._showLocalNotification(
      title: message.notification!.title ?? 'Notification',
      body: message.notification!.body ?? '',
      payload: message.data.toString(),
    );
  }
}

void _handleForegroundMessage(RemoteMessage message) {
  debugPrint('Foreground message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');

  // Show local notification for foreground messages
  if (message.notification != null) {
    NotificationService._showLocalNotification(
      title: message.notification!.title ?? 'Notification',
      body: message.notification!.body ?? '',
      payload: message.data.toString(),
    );
  }
}

void _handleMessageOpenedApp(RemoteMessage message) {
  debugPrint('Message opened app: ${message.messageId}');
  // Handle navigation when notification is tapped
}