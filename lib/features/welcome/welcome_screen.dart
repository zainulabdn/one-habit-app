import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl; // loops background + blobs
  late final AnimationController _uiCtrl; // intro of text/buttons

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _uiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _uiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textAnim =
    CurvedAnimation(parent: _uiCtrl, curve: Curves.easeOutCubic);
    final btnAnim = CurvedAnimation(
      parent: _uiCtrl,
      curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // HERO
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1) Animated gradient background
                      AnimatedBuilder(
                        animation: _bgCtrl,
                        builder: (_, __) {
                          final t = _bgCtrl.value * 2 * math.pi;
                          final begin = Alignment(
                              math.sin(t) * 0.8, math.cos(t) * 0.8);
                          final end = Alignment(
                              math.cos(t * 0.7) * -0.8,
                              math.sin(t * 0.7) * -0.8);
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: begin,
                                end: end,
                                colors: const [
                                  Color(0xFF7C4DFF), // purple
                                  Color(0xFF26A69A), // teal
                                  Color(0xFFFFC107), // amber
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // 2) Floating blurred “glass” blobs
                      _FloatingBlob(
                        ctrl: _bgCtrl,
                        size: 180,
                        xPhase: 0.0,
                        yPhase: 0.0,
                        color: Colors.white.withOpacity(0.18),
                      ),
                      _FloatingBlob(
                        ctrl: _bgCtrl,
                        size: 140,
                        xPhase: 1.2,
                        yPhase: 0.8,
                        color: Colors.white.withOpacity(0.14),
                      ),
                      _FloatingBlob(
                        ctrl: _bgCtrl,
                        size: 220,
                        xPhase: 2.1,
                        yPhase: 1.6,
                        color: Colors.white.withOpacity(0.10),
                      ),

                      // 3) Bobbing SVG illustration (your asset)
                      AnimatedBuilder(
                        animation: _bgCtrl,
                        builder: (context, _) {
                          final t = _bgCtrl.value * 2 * math.pi;
                          final dy = math.sin(t) * 8; // gentle bobbing
                          final scale =
                              1.0 + math.sin(t * 0.7) * 0.01; // subtle pulse
                          return Transform.translate(
                            offset: Offset(0, dy),
                            child: Transform.scale(
                              scale: scale,
                              child: SvgPicture.asset(
                                'assets/Jogging-pana.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),

                      // 4) Soft vignette for readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.transparent
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),

                      // 5) Glassy brand chip
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: const Text(
                                'One-Tap Habit',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // HEADLINE (slide/fade in)
              FadeTransition(
                opacity: textAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(textAnim),
                  child: Text(
                    'Build tiny habits with one joyful tap.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // BUTTONS (slide/fade slightly delayed)
              FadeTransition(
                opacity: btnAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Get Started'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingBlob extends StatelessWidget {
  final AnimationController ctrl;
  final double size;
  final double xPhase;
  final double yPhase;
  final Color color;
  const _FloatingBlob({
    required this.ctrl,
    required this.size,
    required this.xPhase,
    required this.yPhase,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value * 2 * math.pi;
        // normalized path within the Stack
        final x = 0.5 + math.sin(t + xPhase) * 0.35; // 0..1
        final y = 0.5 + math.cos(t * 0.9 + yPhase) * 0.35;
        final w = MediaQuery.of(context).size.width;
        final h = MediaQuery.of(context).size.height * 0.45; // hero height guess
        return Positioned(
          left: (w - size) * x,
          top: (h - size) * y,
          child: _BlurCircle(size: size, color: color),
        );
      },
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
