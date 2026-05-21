import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

class EnrollmentSuccessDialog extends StatefulWidget {
  final String courseName;
  final VoidCallback? onStartLearning;

  const EnrollmentSuccessDialog({
    super.key,
    required this.courseName,
    this.onStartLearning,
  });

  @override
  State<EnrollmentSuccessDialog> createState() => _EnrollmentSuccessDialogState();
}

class _EnrollmentSuccessDialogState extends State<EnrollmentSuccessDialog> {
  late ConfettiController _confettiController;
  late ConfettiController _confettiController2;
  late ConfettiController _confettiController3;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController2 = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController3 = ConfettiController(duration: const Duration(seconds: 4));

    // Start the celebration immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      _confettiController2.play();
      _confettiController3.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _confettiController2.dispose();
    _confettiController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main celebration card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Big celebratory icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),

                // Success title
                const Text(
                  'Enrolled Successfully!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2A6D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Course name
                Text(
                  widget.courseName,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                const Text(
                  'You\'re all set to start learning.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (widget.onStartLearning != null) {
                        widget.onStartLearning!();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Start Learning',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating flower emojis (rising petals effect)
          Positioned.fill(
            child: IgnorePointer(
              child: _FloatingFlowers(),
            ),
          ),

          // Festive Confetti layers - multiple directions for rich effect
          // Top center blast
          Positioned(
            top: 0,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFFFF6A00),
                Color(0xFF10B981),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
                Color(0xFFF59E0B),
                Color(0xFF3B82F6),
              ],
              numberOfParticles: 30,
              gravity: 0.3,
              emissionFrequency: 0.05,
              minimumSize: const Size(8, 8),
              maximumSize: const Size(14, 14),
            ),
          ),

          // Left side flowers/particles
          Positioned(
            left: 0,
            top: 100,
            child: ConfettiWidget(
              confettiController: _confettiController2,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFFEC4899),
                Color(0xFFF472B6),
                Color(0xFFFB923C),
                Color(0xFFFBBF24),
              ],
              numberOfParticles: 20,
              gravity: 0.25,
              emissionFrequency: 0.08,
              minimumSize: const Size(10, 10),
              maximumSize: const Size(18, 18),
            ),
          ),

          // Right side
          Positioned(
            right: 0,
            top: 100,
            child: ConfettiWidget(
              confettiController: _confettiController3,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF8B5CF6),
                Color(0xFFA78BFA),
                Color(0xFF22C55E),
                Color(0xFF4ADE80),
              ],
              numberOfParticles: 20,
              gravity: 0.25,
              emissionFrequency: 0.08,
              minimumSize: const Size(10, 10),
              maximumSize: const Size(18, 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== FLOATING FLOWER EMOJIS ====================

class _FloatingFlowers extends StatelessWidget {
  const _FloatingFlowers();

  @override
  Widget build(BuildContext context) {
    // Define several flowers with different characteristics for natural look
    final flowers = [
      _FlowerConfig(emoji: '🌸', left: 25, delayMs: 0, durationMs: 2600, size: 22, sway: 16),
      _FlowerConfig(emoji: '🌺', left: 95, delayMs: 180, durationMs: 3100, size: 26, sway: 20),
      _FlowerConfig(emoji: '🌼', left: 165, delayMs: 420, durationMs: 2400, size: 20, sway: 14),
      _FlowerConfig(emoji: '🌷', left: 55, delayMs: 650, durationMs: 2900, size: 24, sway: 18),
      _FlowerConfig(emoji: '🪷', left: 210, delayMs: 120, durationMs: 2700, size: 23, sway: 15),
      _FlowerConfig(emoji: '💐', left: 130, delayMs: 780, durationMs: 3300, size: 21, sway: 22),
      _FlowerConfig(emoji: '🌸', left: 70, delayMs: 950, durationMs: 2500, size: 19, sway: 12),
      _FlowerConfig(emoji: '✨', left: 185, delayMs: 300, durationMs: 2800, size: 18, sway: 10),
      _FlowerConfig(emoji: '🌿', left: 40, delayMs: 1100, durationMs: 3000, size: 20, sway: 17),
    ];

    return Stack(
      children: flowers.map((config) {
        return _AnimatedFlower(config: config);
      }).toList(),
    );
  }
}

class _FlowerConfig {
  final String emoji;
  final double left;
  final int delayMs;
  final int durationMs;
  final double size;
  final double sway;

  const _FlowerConfig({
    required this.emoji,
    required this.left,
    required this.delayMs,
    required this.durationMs,
    required this.size,
    required this.sway,
  });
}

class _AnimatedFlower extends StatefulWidget {
  final _FlowerConfig config;

  const _AnimatedFlower({super.key, required this.config});

  @override
  State<_AnimatedFlower> createState() => _AnimatedFlowerState();
}

class _AnimatedFlowerState extends State<_AnimatedFlower>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: widget.config.durationMs),
      vsync: this,
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Start with a delay for staggered effect
    Future.delayed(Duration(milliseconds: widget.config.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final progress = _progress.value;

        // Vertical movement: start near bottom of dialog, rise to top
        // The dialog content is roughly 400px tall. We start below the card.
        final startY = 380.0;
        final endY = -60.0;
        final y = startY + (endY - startY) * progress;

        // Gentle horizontal sway using sine wave
        final swayOffset = math.sin(progress * math.pi * 2.5) * widget.config.sway;

        // Fade out as it goes higher
        final opacity = (1.0 - progress * 0.7).clamp(0.0, 1.0);

        // Slight scale down as it rises (petals getting smaller in distance)
        final scale = 1.0 - (progress * 0.25);

        return Positioned(
          left: widget.config.left + swayOffset,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(
                widget.config.emoji,
                style: TextStyle(
                  fontSize: widget.config.size,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
