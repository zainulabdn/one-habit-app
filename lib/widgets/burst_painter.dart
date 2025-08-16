import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class Burst extends StatefulWidget {
  final Color color;
  const Burst({required this.color});
  @override
  State<Burst> createState() => _BurstState();
}
class _BurstState extends State<Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_P> _parts;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
    final rnd = math.Random();
    _parts = List.generate(36, (_) {
      final a = rnd.nextDouble() * math.pi * 2;
      final v = rnd.nextDouble() * 140 + 90; // speed
      final r = rnd.nextDouble() * 6 + 3;    // radius
      return _P(angle: a, velocity: v, radius: r);
    });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _BurstPainter(
            t: Curves.easeOutCubic.transform(_ctrl.value),
            color: widget.color,
            parts: _parts,
          ),
        );
      },
    );
  }
}
class _P { final double angle, velocity, radius; _P({required this.angle, required this.velocity, required this.radius}); }

class _BurstPainter extends CustomPainter {
  final double t; // 0..1
  final Color color;
  final List<_P> parts;
  _BurstPainter({required this.t, required this.color, required this.parts});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final fade = (1 - t).clamp(0.0, 1.0);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in parts) {
      final dist = p.velocity * t;
      final dx = math.cos(p.angle) * dist;
      final dy = math.sin(p.angle) * dist;
      final r = p.radius * (1 - t); // shrink
      paint.color = color.withOpacity(0.25 + 0.45 * fade);
      canvas.drawCircle(center + Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t || old.color != color || old.parts != parts;
}
