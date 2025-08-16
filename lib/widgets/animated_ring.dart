import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedRing extends StatelessWidget {
  final double progress; // 0..1
  final VoidCallback onTap;
  const AnimatedRing({super.key, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: 400.ms,
        curve: Curves.easeOutBack,
        builder: (_, value, __) {
          return SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(value: value, strokeWidth: 8),
                Center(
                  child: Text(
                    value >= 1 ? '✓' : '${(value * 100).round()}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              ],
            ),
          ).animate().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 200.ms);
        },
      ),
    );
  }
}