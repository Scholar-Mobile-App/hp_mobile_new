import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_provider.dart';
import 'services/notification_service.dart';

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - app works without it)
  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
    debugPrint('Firebase and notifications initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('App will run without push notifications. Setup Firebase for full functionality.');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
        child: MaterialApp(
          title: 'Gaps To Growth',
          navigatorKey: navigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              iconTheme: IconThemeData(color: Colors.white),
            ),
            colorScheme: ColorScheme(
              primary: const Color(0xFF1F2A6D), // Dark Blue
              onPrimary: Colors.white,
              primaryContainer: const Color(0xFF2E3A8C),
              onPrimaryContainer: Colors.white,
              secondary: const Color(0xFFFF6A00), // Bright Orange
              onSecondary: Colors.white,
              secondaryContainer: const Color(0xFFFF7A1A),
              onSecondaryContainer: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              surfaceContainerHighest: Colors.grey[100]!,
              onSurfaceVariant: Colors.grey[700]!,
              outline: Colors.grey[400]!,
              error: Colors.red,
              onError: Colors.white,
              brightness: Brightness.light,
            ),
          ),
           home: SplashScreen(),
        ),
    );
  }
}


