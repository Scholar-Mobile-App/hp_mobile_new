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
              primary: const Color(0xFFFF6A00), // Logo Orange
              onPrimary: Colors.white,
              primaryContainer: const Color(0xFFFFEDE0),
              onPrimaryContainer: const Color(0xFF5C2E00),
              secondary: const Color(0xFF2F80FF), // Complementary Blue
              onSecondary: Colors.white,
              secondaryContainer: const Color(0xFFE0F0FF),
              onSecondaryContainer: const Color(0xFF0D3B66),
              surface: Colors.white,
              onSurface: const Color(0xFF1A1A1A),
              surfaceContainerLowest: const Color(0xFFF7F8FC),
              surfaceContainerLow: const Color(0xFFF8FAFC),
              surfaceContainerHighest: const Color(0xFFF1F5F9),
              onSurfaceVariant: const Color(0xFF475569),
              outline: const Color(0xFFE2E8F0),
              outlineVariant: const Color(0xFFE2E8F0),
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


