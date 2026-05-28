import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../main.dart';
import '../screens/organization_management/task_assignment_progress_screen.dart';
import '../screens/organization_management/task_details_screen.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/task.dart';

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
        _handleNotificationTap(response.payload);
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

  // Handle notification tap navigation
  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      // Parse the payload - it might be a JSON string from Firebase data
      Map<String, dynamic> data = {};
      if (payload.startsWith('{')) {
        data = jsonDecode(payload);
      }

      final type = data['type'] ?? '';
      final taskId = data['task_id'];

      switch (type) {
        case 'task_assigned':
          if (taskId != null) {
            // Navigate to specific task details
            navigateToTaskDetails(taskId);
          } else {
            // Fallback to task list screen
            _navigateToTaskScreen();
          }
          break;
        default:
          debugPrint('Unknown notification type: $type');
          break;
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  void _navigateToTaskScreen() {
    debugPrint('🔔 Navigating to Task Assignment screen for task notification');
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => const TaskAssignmentProgressScreen(),
      ),
    );
  }

  void navigateToTaskDetails(dynamic taskId) async {
    debugPrint('🔔 Navigating to Task Details screen for task ID: $taskId');

    // Get the current context to access providers
    final context = navigatorKey.currentState?.context;
    if (context == null) {
      debugPrint('❌ Context not available for navigation');
      return;
    }

    try {
      // Get auth provider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.originalToken ?? user?.token;

      if (user == null || token == null) {
        debugPrint('❌ User not logged in, cannot fetch task details');
        // Fallback to task list
        _navigateToTaskScreen();
        return;
      }

      // Fetch all tasks and find the specific one
      final apiService = ApiService();
      await apiService.loadCookies();
      final tasks = await apiService.fetchAssignedTasks(user, token);

      Task? task;
      try {
        task = tasks.firstWhere(
          (t) => t.id == int.parse(taskId.toString()),
        );
      } catch (e) {
        debugPrint('Task not found: $e');
        _navigateToTaskScreen();
        return;
      }

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => TaskDetailsScreen(task: task!),
        ),
      );
        } catch (e) {
      debugPrint('❌ Error fetching task details: $e');
      // Fallback to task list
      _navigateToTaskScreen();
    }
  }

  // Test method to verify local notifications work
  Future<void> testLocalNotification() async {
    await _showLocalNotification(
      title: 'Test Task Notification',
      body: 'This is a test notification to verify task notification navigation works',
      payload: jsonEncode({'type': 'task_assigned', 'task_title': 'Test Task'}),
    );
    debugPrint('🔔 Test local notification sent');
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');

  // Show local notification for background messages as well for consistency
  if (message.notification != null) {
    await NotificationService._showLocalNotification(
      title: message.notification!.title ?? 'Notification',
      body: message.notification!.body ?? '',
      payload: jsonEncode(message.data), // Use JSON encoded data for proper parsing
    );
  }
}

void _handleForegroundMessage(RemoteMessage message) {
  debugPrint('Foreground message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');

  // Show local notification for foreground messages
  if (message.notification != null) {
    NotificationService._showLocalNotification(
      title: message.notification!.title ?? 'Notification',
      body: message.notification!.body ?? '',
      payload: jsonEncode(message.data), // Use JSON encoded data for proper parsing
    );
  }
}

void _handleMessageOpenedApp(RemoteMessage message) {
  debugPrint('Message opened app: ${message.messageId}');
  debugPrint('Data: ${message.data}');

  // Handle navigation when notification is tapped from terminated state
  final type = message.data['type'] ?? '';
  final taskId = message.data['task_id'];

  if (type == 'task_assigned') {
    if (taskId != null) {
      // Navigate to specific task details
      NotificationService().navigateToTaskDetails(taskId);
    } else {
      // Fallback to task list screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const TaskAssignmentProgressScreen(),
        ),
      );
    }
  }
}