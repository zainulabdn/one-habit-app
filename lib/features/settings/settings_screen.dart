import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/habit_repo.dart';
import '../../models/habit.dart';


final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

final accentColorProvider = StateProvider<Color>((_) => const Color(0xFFE91E63));

final hapticsProvider = StateProvider<bool>((_) => true);


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);
    final haptics = ref.watch(hapticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          // animated soft gradient backdrop
          const _AnimatedBackdrop(),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SectionCard(
                title: 'Appearance',
                subtitle: 'Theme & color mood',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme mode
                    Text('Theme mode', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_suggest)),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).state = s.first,
                      style: const ButtonStyle(visualDensity: VisualDensity.comfortable),
                    ),
                    const SizedBox(height: 16),

                    // Accent color
                    Text('Accent color', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in _accentPalette)
                          _AccentDot(
                            color: c,
                            selected: accent.value == c.value,
                            onTap: () => ref.read(accentColorProvider.notifier).state = c,
                          ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 280.ms).slideY(begin: .04, end: 0),

              _SectionCard(
                title: 'Feedback',
                subtitle: 'Vibration & taps',
                child: SwitchListTile.adaptive(
                  value: haptics,
                  onChanged: (v) => ref.read(hapticsProvider.notifier).state = v,
                  title: const Text('Haptics'),
                  subtitle: const Text('Vibrate on check-in and milestones'),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: .04, end: 0),

              _SectionCard(
                title: 'Data',
                subtitle: 'Backup & restore',
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: const Text('Export to clipboard'),
                      subtitle: const Text('Copy all habits as JSON'),
                      onTap: () async {
                        final habits = ref.read(habitListProvider);
                        final payload = [
                          for (final h in habits)
                            {
                              'id': h.id,
                              'name': h.name,
                              'colorValue': h.colorValue,
                              'emoji': h.emoji,
                              'createdAt': h.createdAt.toIso8601String(),
                              'checkins': h.checkins,
                            }
                        ];
                        final text = const JsonEncoder.withIndent('  ').convert(payload);
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Exported to clipboard')),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Import from JSON'),
                      subtitle: const Text('Paste data previously exported'),
                      onTap: () => _showImportDialog(context, ref),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 320.ms).slideY(begin: .04, end: 0),

              _SectionCard(
                title: 'Danger zone',
                subtitle: 'Don’t tap by accident',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: cs.error),
                  title: Text('Delete all habits', style: TextStyle(color: cs.error)),
                  subtitle: const Text('Remove every habit and its history'),
                  onTap: () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete all habits?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          FilledButton.tonal(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(foregroundColor: cs.onErrorContainer, backgroundColor: cs.errorContainer),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (yes == true) {
                      final repo = ref.read(habitRepoProvider);
                      final habits = ref.read(habitListProvider);
                      for (final h in habits) {
                        await repo.delete(h.id);
                      }
                      ref.read(habitListProvider.notifier).refresh();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All habits deleted')));
                      }
                    }
                  },
                ),
              ).animate().fadeIn(duration: 340.ms).slideY(begin: .04, end: 0),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final textCtrl = TextEditingController();
    bool replaceAll = false;

    // Try to prefill from clipboard if it looks like JSON
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      final txt = clip?.text?.trim();
      if (txt != null && txt.startsWith('[') && txt.endsWith(']')) {
        textCtrl.text = txt;
      }
    } catch (_) {}

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Import from JSON'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Paste the JSON you exported earlier.'),
                const SizedBox(height: 8),
                TextField(
                  controller: textCtrl,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: '[ { "name": "Water", "emoji": "💧", ... } ]',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (ctx, set) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: replaceAll,
                    onChanged: (v) => set(() => replaceAll = v ?? false),
                    title: const Text('Replace existing habits'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final repo = ref.read(habitRepoProvider);

    try {
      final raw = jsonDecode(textCtrl.text);
      if (raw is! List) {
        throw 'Root must be a JSON array.';
      }

      if (replaceAll) {
        final existing = ref.read(habitListProvider);
        for (final h in existing) {
          await repo.delete(h.id);
        }
      }

      for (final item in raw) {
        if (item is! Map) continue;

        final name = (item['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final emoji = (item['emoji'] ?? '✨').toString();
        final colorValue = int.tryParse(item['colorValue']?.toString() ?? '') ?? Colors.teal.value;

        DateTime? createdAt;
        final createdStr = item['createdAt']?.toString();
        if (createdStr != null) {
          createdAt = DateTime.tryParse(createdStr);
        }

        final checkins = (item['checkins'] is List)
            ? List<String>.from((item['checkins'] as List).map((e) => e.toString()))
            : <String>[];

        // Create with a new id, then patch fields so we preserve history.
        final newHabit = await repo.create(name: name, colorValue: colorValue, emoji: emoji);
        final patched = newHabit.copyWith(
          createdAt: createdAt ?? newHabit.createdAt,
          checkins: checkins,
        );
        await repo.update(patched);
      }

      ref.read(habitListProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import complete')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

}

// ============== Helpers & UI bits ==============

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withOpacity(.12)),
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(.06), cs.tertiary.withOpacity(.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AccentDot extends StatefulWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _AccentDot({required this.color, required this.selected, required this.onTap});

  @override
  State<_AccentDot> createState() => _AccentDotState();
}

class _AccentDotState extends State<_AccentDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1000.ms)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = widget.selected ? (1 + (math.sin(_ctrl.value * math.pi * 2) * 0.05)) : 1.0;
    return Transform.scale(
      scale: pulse,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: widget.selected
                ? [BoxShadow(color: widget.color.withOpacity(.6), blurRadius: 16, spreadRadius: 1)]
                : [],
            border: Border.all(
              color: widget.selected ? Colors.black.withOpacity(.75) : Colors.white.withOpacity(.85),
              width: widget.selected ? 3 : 1.5,
            ),
          ),
          child: widget.selected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
        ),
      ),
    );
  }
}

class _AnimatedBackdrop extends StatefulWidget {
  const _AnimatedBackdrop();

  @override
  State<_AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<_AnimatedBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: 12.seconds)..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (_, __) {
        final t = _bgCtrl.value * 6.28318; // 2π
        final begin = Alignment(math.sin(t) * .8, math.cos(t) * .8);
        final end = Alignment(math.cos(t * .7) * -.8, math.sin(t * .7) * -.8);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: [
                cs.primary.withOpacity(.06),
                cs.tertiary.withOpacity(.06),
                cs.primaryContainer.withOpacity(.04),
              ],
            ),
          ),
        );
      },
    );
  }
}

const _accentPalette = <Color>[
  Color(0xFFE91E63), // pink
  Color(0xFF7C4DFF), // purple
  Color(0xFF26A69A), // teal
  Color(0xFFFFC107), // amber
  Color(0xFF00BCD4), // cyan
  Color(0xFF4CAF50), // green
  Color(0xFFEF5350), // red
];
