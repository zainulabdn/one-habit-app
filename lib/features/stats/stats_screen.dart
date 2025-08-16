import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../data/habit_repo.dart';
import '../../utils/date.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});
  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _chartCtrl;

  @override
  void initState() {
    super.initState();
    _chartCtrl = AnimationController(vsync: this, duration: 700.ms)..forward();
  }

  @override
  void dispose() {
    _chartCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitListProvider);
    final repo = ref.read(habitRepoProvider);
    final data = repo.last7AggCounts(habits); // oldest..today
    final days = lastNDays(7).toList().reversed.toList(); // DateTimes aligned to data

    final total = data.fold<int>(0, (a, b) => a + b);
    final maxVal = (data.isEmpty ? 0 : data.reduce(math.max));
    final bestIdx = data.indexOf(maxVal.clamp(0, 1 << 30));
    final avg = data.isEmpty ? 0 : total / data.length;

    final cs = Theme.of(context).colorScheme;
    final dfShort = DateFormat('E'); // Mon, Tue...

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // header + chips
          Text('Check-ins (last 7 days)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _InfoChip(label: 'Total', value: '$total', color: cs.primary),
                const SizedBox(width: 8),
                _InfoChip(label: 'Best', value: maxVal == 0 ? '—' : '${dfShort.format(days[bestIdx])} • $maxVal', color: cs.tertiary),
                const SizedBox(width: 8),
                _InfoChip(label: 'Avg/Day', value: avg.toStringAsFixed(1), color: cs.secondary),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // chart
          Expanded(
            child: AnimatedBuilder(
              animation: _chartCtrl,
              builder: (_, __) {
                final t = Curves.easeOutCubic.transform(_chartCtrl.value);
                return BarChart(
                  BarChartData(
                    maxY: (maxVal == 0 ? 4 : (maxVal + 2)).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final day = days[groupIndex];
                          return BarTooltipItem(
                            '${dfShort.format(day)}\n',
                            TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${rod.toY.toInt()} check-ins',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          );
                        },
                        tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        tooltipRoundedRadius: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                        ),
                      ),
                      rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= days.length) return const SizedBox.shrink();
                            final d = days[i];
                            final isToday = i == days.length - 1;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                isToday ? 'Today' : dfShort.format(d),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: cs.outlineVariant.withOpacity(.3),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    alignment: BarChartAlignment.spaceBetween,
                    barGroups: List.generate(7, (i) {
                      final y = data[i].toDouble() * t;
                      return BarChartGroupData(
                        x: i,
                        barsSpace: 2,
                        barRods: [
                          BarChartRodData(
                            toY: y,
                            width: 18,
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                cs.primary.withOpacity(.15),
                                cs.primary,
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          Text('Habits: ${habits.length}'),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withOpacity(.15),
          color.withOpacity(.30),
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: color.withOpacity(.6), blurRadius: 8, spreadRadius: 1)
            ]),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: on.withOpacity(.9))),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: on,
            ),
          ),
        ],
      ),
    );
  }
}
