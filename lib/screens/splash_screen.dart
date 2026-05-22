import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_provider.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoGlowAnimation;
  late Animation<double> _logoFloatAnimation;
  late AnimationController _continuousRotationController;
  late AnimationController _glowPulseController;
  late Animation<double> _continuousRotationAnimation;
  late Animation<double> _glowPulseAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<int> _titleAnimation;
  late Animation<int> _subtitleAnimation;
  late String _displayedTitle;
  late String _displayedSubtitle;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));

    _logoRotationAnimation = Tween<double>(
      begin: -0.2,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _logoGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _logoFloatAnimation = Tween<double>(
      begin: 0.0,
      end: -10.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOutSine),
    ));

    _continuousRotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _continuousRotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(_continuousRotationController);

    _glowPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowPulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_glowPulseController);

    // Text slide animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _textScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.elasticOut,
    ));

    _titleAnimation = IntTween(begin: 0, end: 'Gaps To Growth'.length).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    ));

    _subtitleAnimation = IntTween(begin: 0, end: 'Your Journey to Excellence'.length).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    ));

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutBack,
    ));

    // Start animations
    _startAnimations();

    // Initialize app after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _startAnimations() {
    // Start logo animation
    _logoController.forward();

    // Start text animation after logo
    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });

    // Start progress animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _continuousRotationController.dispose();
    _glowPulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Simulate some loading time for splash
    await Future.delayed(const Duration(seconds: 3));

    // Check if widget is still mounted
    if (!mounted) return;

    // Check session
    await context.read<AuthProvider>().checkSession();

    // Check again if widget is still mounted after async operation
    if (!mounted) return;

    // Navigate
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1F2A6D),
              Color(0xFF2E3A8C),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _logoFloatAnimation.value),
                    child: FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: RotationTransition(
                        turns: AlwaysStoppedAnimation(_logoRotationAnimation.value + _continuousRotationAnimation.value),
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              BoxShadow(
                                color: const Color(0xFFFFE4B5).withOpacity(_logoGlowAnimation.value * _glowPulseAnimation.value * 0.6),
                                blurRadius: 30,
                                spreadRadius: _logoGlowAnimation.value * 10,
                              ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFE4B5), Color(0xFFFFF0D6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFE4B5).withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/crop.png',
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              // Animated Text
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  _displayedTitle = 'Gaps To Growth'.substring(0, _titleAnimation.value);
                  _displayedSubtitle = 'Your Journey to Excellence'.substring(0, _subtitleAnimation.value);
                  return SlideTransition(
                    position: _textSlideAnimation,
                    child: ScaleTransition(
                      scale: _textScaleAnimation,
                      child: FadeTransition(
                        opacity: _textController,
                        child: Column(
                          children: [
                            Text(
                              _displayedTitle,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _displayedSubtitle,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              // Animated Progress Indicator
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return Column(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
                          strokeWidth: 6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
