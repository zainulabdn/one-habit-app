import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/habit_repo.dart';
import '../../utils/date.dart';
import '../../widgets/habit_tile.dart';
import 'dart:math' as math;
import 'dart:ui';

enum HabitFilter { all, done, todo }

final habitFilterProvider = StateProvider<HabitFilter>((_) => HabitFilter.all);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitListProvider);
    final repo = ref.read(habitRepoProvider);
    final todayKey = ymd(today());

    final doneCount = habits.where((h) => h.checkinSet.contains(todayKey)).length;
    final total = habits.length;
    final progress = total == 0 ? 0.0 : doneCount / total;

    final filter = ref.watch(habitFilterProvider);
    final filtered = switch (filter) {
      HabitFilter.all => habits,
      HabitFilter.done => habits.where((h) => h.checkinSet.contains(todayKey)).toList(),
      HabitFilter.todo => habits.where((h) => !h.checkinSet.contains(todayKey)).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('One-Tap Habit'),
        actions: [
          IconButton(
            tooltip: 'Stats',
            onPressed: () => context.push('/stats'),
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
          if (total > 0 && doneCount < total)
            IconButton(
              tooltip: 'Mark all done',
              onPressed: () async {
                // Mark all remaining as done today
                for (final h in habits.where((h) => !h.checkinSet.contains(todayKey))) {
                  await ref.read(habitListProvider.notifier).toggle(h);
                }
                // Tiny celebration
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nice! All $total habits checked for today ✅')),
                  );
                }
              },
              icon: const Icon(Icons.checklist_rtl),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: _ProgressHeader(
            progress: progress,
            doneCount: doneCount,
            total: total,
            filter: filter,
            onFilterChanged: (f) => ref.read(habitFilterProvider.notifier).state = f,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: AnimatedSwitcher(
          duration: 350.ms,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: filtered.isEmpty
              ? _EmptyState(
            key: const ValueKey('empty'),
            onAdd: () => context.push('/add'),
            showHint: total > 0, // shows hint when filter hides items
          )
              : ListView.separated(
        key: const ValueKey('list'),
        physics: const BouncingScrollPhysics(),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final h = filtered[i];
          final done = h.checkinSet.contains(todayKey);
          final streak = repo.currentStreak(h);

          // bottom-to-top stagger (bottom items animate first)
          final delay = Duration(milliseconds: 40 * (filtered.length - 1 - i));

          return Dismissible(
            key: ValueKey(h.id),
            direction: DismissDirection.endToStart,
            background: _DeleteBg(),
            confirmDismiss: (_) async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete habit?'),
                  content: Text('Remove “${h.name}”? This can’t be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              return yes ?? false;
            },
            onDismissed: (_) async {
              await ref.read(habitListProvider.notifier).removeHabit(h.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted “${h.name}”'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        await ref.read(habitRepoProvider).create(
                          name: h.name,
                          colorValue: h.colorValue,
                          emoji: h.emoji,
                        );
                        ref.read(habitListProvider.notifier).refresh();
                      },
                    ),
                  ),
                );
              }
            },
            child: HabitTile(
              habit: h,
              doneToday: done,
              streak: streak,
              onToggle: () => ref.read(habitListProvider.notifier).toggle(h),
            )
                .animate()
                .fadeIn(
              duration: 280.ms,
              delay: delay,
              curve: Curves.easeOutCubic,
            )
                .slideY(
              begin: 0.16, // start lower for a clearer rise
              end: 0,
              duration: 420.ms,
              delay: delay,
              curve: Curves.easeOutBack, // a tiny, classy overshoot
            ),
          );
        },
      ),

    ),
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-hero',            // 👈 match the tag on the target screen
        onPressed: () => context.push('/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Habit'),
      ),

    );
  }
}


// REPLACE your _ProgressHeader with this:
class _ProgressHeader extends StatefulWidget {
  final double progress;
  final int doneCount;
  final int total;
  final HabitFilter filter;
  final ValueChanged<HabitFilter> onFilterChanged;

  const _ProgressHeader({
    required this.progress,
    required this.doneCount,
    required this.total,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<_ProgressHeader> createState() => _ProgressHeaderState();
}

class _ProgressHeaderState extends State<_ProgressHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineCtrl;
  double _prevProgress = 0;
  int _prevDone = 0;

  @override
  void initState() {
    super.initState();
    _prevProgress = widget.progress;
    _prevDone = widget.doneCount;
    _shineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant _ProgressHeader old) {
    super.didUpdateWidget(old);
    // keep previous values so TweenAnimationBuilder can animate from old -> new
    if (old.progress != widget.progress) _prevProgress = old.progress;
    if (old.doneCount != widget.doneCount) _prevDone = old.doneCount;
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(0.15), cs.tertiary.withOpacity(0.10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        border: Border.all(color: cs.primary.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: ring + Today + animated count
          Row(
            children: [
              // animated ring
              TweenAnimationBuilder<double>(
                tween: Tween(begin: _prevProgress, end: widget.progress),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => CustomPaint(
                  painter: _RingPainter(
                    progress: value,
                    trackColor: cs.outlineVariant.withOpacity(.35),
                    fillColor: cs.primary,
                    thickness: 4,
                  ),
                  size: const Size(26, 26),
                ),
              ),
              const SizedBox(width: 8),
              Text('Today', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              // animated done counter
              TweenAnimationBuilder<double>(
                tween: Tween(begin: _prevDone.toDouble(), end: widget.doneCount.toDouble()),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => Text('${val.round()} / ${widget.total}'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // progress bar with subtle moving sheen
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                // animated fill
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: _prevProgress, end: widget.progress),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainerHighest.withOpacity(0.4),
                    color: cs.primary,
                  ),
                ),
                // sheen
                AnimatedBuilder(
                  animation: _shineCtrl,
                  builder: (_, __) {
                    final t = _shineCtrl.value;
                    return Transform.translate(
                      offset: Offset((MediaQuery.of(context).size.width) * (t * 1.2 - .6), 0),
                      child: Container(
                        height: 8,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(.0), Colors.white.withOpacity(.35), Colors.white.withOpacity(.0)],
                            stops: const [0, .5, 1],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          // Filters (slide in a touch)
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            offset: const Offset(0, .05),
            child: SegmentedButton<HabitFilter>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
              ),
              segments: const [
                ButtonSegment(value: HabitFilter.all, label: Text('All'), icon: Icon(Icons.all_inclusive, size: 16)),
                ButtonSegment(value: HabitFilter.done, label: Text('Done'), icon: Icon(Icons.check, size: 16)),
                ButtonSegment(value: HabitFilter.todo, label: Text('To-do'), icon: Icon(Icons.pending_outlined, size: 16)),
              ],
              selected: {widget.filter},
              onSelectionChanged: (set) => widget.onFilterChanged(set.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double thickness;
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    final fill = Paint()
      ..shader = SweepGradient(
        colors: [fillColor.withOpacity(.6), fillColor],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * progress,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness;

    // track
    canvas.drawCircle(center, radius, track);
    // arc
    final start = -math.pi / 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, 2 * math.pi * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
          oldDelegate.trackColor != trackColor ||
          oldDelegate.fillColor != fillColor ||
          oldDelegate.thickness != thickness;
}


class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final bool showHint;
  const _EmptyState({super.key, required this.onAdd, this.showHint = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.radar_rounded, size: 96),
          const SizedBox(height: 12),
          Text('Create your first habit', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            showHint ? 'No items match this filter.' : 'Keep it tiny. Tap once a day. Celebrate wins.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAdd, child: const Text('Add Habit')),
        ],
      ),
    );
  }
}

class _DeleteBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete_forever, color: cs.onErrorContainer),
    );
  }
}
