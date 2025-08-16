import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'animated_ring.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final bool doneToday;
  final int streak;
  final VoidCallback onToggle;

  const HabitTile({
    super.key,
    required this.habit,
    required this.doneToday,
    required this.streak,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          AnimatedRing(progress: doneToday ? 1 : 0, onTap: onToggle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${habit.emoji}  ${habit.name}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Streak: $streak day${streak == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}