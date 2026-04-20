import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/auth_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
        child: MaterialApp(
          title: 'Gaps To Growth',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme(
              primary: Color(0xFF1F2A6D), // Dark Blue
              onPrimary: Colors.white,
              primaryContainer: Color(0xFF2E3A8C),
              onPrimaryContainer: Colors.white,
              secondary: Color(0xFFFF6A00), // Bright Orange
              onSecondary: Colors.white,
              secondaryContainer: Color(0xFFFF7A1A),
              onSecondaryContainer: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              surfaceVariant: Colors.grey[100]!,
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


