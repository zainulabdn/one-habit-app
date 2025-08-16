import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/habit_repo.dart';
import '../../widgets/burst_painter.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});
  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController(text: '✨');

  final _nameFocus = FocusNode();
  final _emojiFocus = FocusNode();

  late final AnimationController _bgCtrl; // background/halo loop
  late final AnimationController _uiCtrl; // intro animation
  late final AnimationController _saveCtrl; // save pulse

  int _color = Colors.teal.value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: 12.seconds)..repeat();
    _uiCtrl = AnimationController(vsync: this, duration: 700.ms)..forward();
    _saveCtrl = AnimationController(vsync: this, duration: 400.ms);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _uiCtrl.dispose();
    _saveCtrl.dispose();
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _nameFocus.dispose();
    _emojiFocus.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && _emojiCtrl.text.trim().isNotEmpty;
  Future<void> _celebrate() async {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(child: Burst(color: Color(_color))),
      ),
    );
    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 650));
    entry.remove();
  }

  Future<void> _save() async {
    if (_saving) return; // double-tap guard

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    _saveCtrl.forward(from: 0); // pulse

    final messenger = ScaffoldMessenger.of(context); // capture BEFORE pop
    final nav = Navigator.of(context);

    final name = _nameCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim().isEmpty ? '✨' : _emojiCtrl.text.trim();

    try {
      await ref.read(habitListProvider.notifier).addHabit(name, _color, emoji);


      if (!mounted) return;
      HapticFeedback.selectionClick();

      nav.pop(); // pop first so snackbar shows on previous screen
      messenger.showSnackBar(SnackBar(content: Text('Added $emoji  $name')));
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Habit')),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              final t = _bgCtrl.value * 6.28318; // 2π
              final begin = Alignment(math.sin(t) * .8, math.cos(t) * .8);
              final end = Alignment(
                math.cos(t * .7) * -.8,
                math.sin(t * .7) * -.8,
              );
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: begin,
                    end: end,
                    colors: [
                      cs.primary.withOpacity(.10),
                      cs.tertiary.withOpacity(.10),
                      Color(_color).withOpacity(.10),
                    ],
                  ),
                ),
              );
            },
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  // Live preview card
                  Hero(
                        tag: 'add-hero',
                        child: _PreviewCard(
                          name: _nameCtrl.text.trim(),
                          emoji: _emojiCtrl.text.trim(),
                          color: _color,
                          bgCtrl: _bgCtrl,
                        ),
                      )
                      .animate(controller: _uiCtrl)
                      .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: .08, end: 0, duration: 350.ms),

                  const SizedBox(height: 16),

                  // Form card
                  Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: cs.primary.withOpacity(.15)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Form(
                            key: _formKey,
                            onChanged: () => setState(() {}),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // NAME
                                _AppField(
                                  controller: _nameCtrl,
                                  focusNode: _nameFocus,
                                  label: 'Habit name',
                                  hint: 'e.g. Drink Water',
                                  icon: Icons.edit_outlined,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                  onClear: () {
                                    _nameCtrl.clear();
                                    setState(() {});
                                  },
                                ),

                                const SizedBox(height: 12),

                                // EMOJI
                                _AppField(
                                  controller: _emojiCtrl,
                                  focusNode: _emojiFocus,
                                  label: 'Emoji',
                                  hint: 'e.g. 🚰',
                                  icon: Icons.emoji_emotions_outlined,
                                  textInputAction: TextInputAction.done,
                                  // optional: keep emojis tiny (1–2 chars)
                                  maxLength: 2,
                                ),

                                const SizedBox(height: 8),
                                // Emoji suggestions
                                _EmojiRow(
                                  onPick: (e) {
                                    _emojiCtrl.text = e;
                                    setState(() {});
                                  },
                                ),

                                const SizedBox(height: 16),
                                Text(
                                  'Color',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final c in _presetColors)
                                      _ColorDot(
                                        color: c,
                                        selected: _color == c.value,
                                        controller: _bgCtrl,
                                        onTap: () =>
                                            setState(() => _color = c.value),
                                      ),
                                    // random
                                    InkWell(
                                      onTap: () {
                                        final rnd =
                                            _presetColors[math.Random().nextInt(
                                              _presetColors.length,
                                            )];
                                        setState(() => _color = rnd.value);
                                      },
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: cs.primary.withOpacity(.35),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.casino,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      )
                      .animate(controller: _uiCtrl)
                      .fadeIn(duration: 380.ms)
                      .slideY(begin: .06, end: 0, duration: 380.ms),

                  const SizedBox(height: 16),

                  // Save button (sticky-ish)
                  SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _canSave && !_saving ? _save : null,
                          icon: ScaleTransition(
                            scale: Tween(begin: 1.0, end: 1.08).animate(
                              CurvedAnimation(
                                parent: _saveCtrl,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: const Icon(Icons.check),
                          ),
                          label: Text(_saving ? 'Saving...' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      )
                      .animate(controller: _uiCtrl)
                      .fadeIn(duration: 420.ms)
                      .slideY(begin: .05, end: 0, duration: 420.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final VoidCallback? onClear;
  final int? maxLength;

  const _AppField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.textInputAction,
    this.keyboardType,
    this.onClear,
    this.maxLength,
  });

  @override
  State<_AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<_AppField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _haloCtrl;

  @override
  void initState() {
    super.initState();
    _haloCtrl = AnimationController(
      vsync: this,
      duration: 280.ms,
      lowerBound: 0,
      upperBound: 1,
    );
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    _haloCtrl.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (widget.focusNode.hasFocus) {
      _haloCtrl.forward();
    } else {
      _haloCtrl.reverse();
    }
    setState(() {});
  }

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Glow/halo behind the field
        AnimatedBuilder(
          animation: _haloCtrl,
          builder: (_, __) {
            final t = _haloCtrl.value;
            return Opacity(
              opacity: 0.25 * t,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            );
          },
        ),
        // Field surface (glass + border)
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedContainer(
              duration: 220.ms,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.focusNode.hasFocus
                      ? cs.primary.withOpacity(0.45)
                      : cs.outlineVariant.withOpacity(0.45),
                ),
                color: cs.surface.withOpacity(0.55),
              ),
              padding: const EdgeInsets.all(2),
              child: _buildTextFormField(context, cs),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField(BuildContext context, ColorScheme cs) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
      inputFormatters: [
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: Colors.transparent,
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: Icon(
          widget.icon,
          color: widget.focusNode.hasFocus ? cs.primary : cs.onSurfaceVariant,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onClear != null && _hasText)
              IconButton(
                tooltip: 'Clear',
                onPressed: widget.onClear,
                icon: const Icon(Icons.clear),
              ),
            AnimatedOpacity(
              opacity: _hasText ? 1 : 0,
              duration: 180.ms,
              child: Icon(Icons.check_circle, color: cs.primary),
            ),
            const SizedBox(width: 8),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.8)),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String name;
  final String emoji;
  final int color;
  final AnimationController bgCtrl;

  const _PreviewCard({
    required this.name,
    required this.emoji,
    required this.color,
    required this.bgCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final title = name.isEmpty ? 'New Habit' : name;
    final em = (emoji.isEmpty ? '✨' : emoji);
    final c = Color(color);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          // subtle tinted backdrop
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.withOpacity(.20), c.withOpacity(.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: c.withOpacity(.25)),
            ),
          ),
          // floating highlight halo
          AnimatedBuilder(
            animation: bgCtrl,
            builder: (_, __) {
              final t = bgCtrl.value;
              final dx = lerpDouble(-20, 20, t)!;
              final dy = lerpDouble(10, -10, t)!;
              return Positioned(
                left: 40 + dx,
                top: 30 + dy,
                child: _Glow(size: 80, color: c.withOpacity(.35)),
              );
            },
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.withOpacity(.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.withOpacity(.35)),
                    ),
                    child: Text(em, style: const TextStyle(fontSize: 28)),
                  ).animate().scale(
                    begin: const Offset(.98, .98),
                    end: const Offset(1, 1),
                    duration: 250.ms,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap once each day • Streaks will glow',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 30, spreadRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiRow extends StatelessWidget {
  final void Function(String) onPick;
  const _EmojiRow({required this.onPick});
  @override
  Widget build(BuildContext context) {
    const recents = ['✨', '💧', '📖', '🧘', '🚶', '🍎', '🧠', '☀️'];
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Text('Suggestions:  '),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: 80,
                child: Row(
                  children: [
                    for (final e in recents)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _BouncyEmojiChip(
                          emoji: e,
                          onPick: () => onPick(e),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }
}
class _BouncyEmojiChip extends StatefulWidget {
  final String emoji;
  final VoidCallback onPick;
  const _BouncyEmojiChip({required this.emoji, required this.onPick});

  @override
  State<_BouncyEmojiChip> createState() => _BouncyEmojiChipState();
}

class _BouncyEmojiChipState extends State<_BouncyEmojiChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = TweenSequence<double>([
      // down to 0.9, then back to 1.0
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.90), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);          // play the bounce
    HapticFeedback.selectionClick(); // optional
    widget.onPick();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surfaceVariant; // safe, version-agnostic

    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: surface,
              border: Border.all(color: cs.primary.withOpacity(.18)),
            ),
            child: Text(widget.emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}


class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final AnimationController controller;
  final VoidCallback onTap;
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ring = selected ? 3.0 : 1.0;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final pulse = selected
            ? (1 + (math.sin(controller.value * 6.28318) * 0.04))
            : 1.0;
        return Transform.scale(
          scale: pulse,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: selected
                      ? Colors.black.withOpacity(.75)
                      : Colors.white.withOpacity(.85),
                  width: ring,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(.6),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : const [],
              ),
              child: selected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
        );
      },
    );
  }
}

const _templates = [
  {'name': 'Drink Water', 'emoji': '💧', 'color': 0xFF26A69A},
  {'name': 'Read 5 pages', 'emoji': '📖', 'color': 0xFF7C4DFF},
  {'name': 'Meditate', 'emoji': '🧘', 'color': 0xFFFFC107},
  {'name': 'Walk 10 min', 'emoji': '🚶', 'color': 0xFF4CAF50},
];

final _presetColors = <Color>[
  Colors.teal,
  Colors.indigo,
  Colors.pink,
  Colors.amber,
  Colors.deepOrange,
  Colors.green,
  Colors.cyan,
  Colors.purple,
  Colors.blueGrey,
  const Color(0xFF7C4DFF),
  const Color(0xFF26A69A),
];

class _TemplatesRow extends StatelessWidget {
  final void Function(String name, String emoji, int color) onPick;
  const _TemplatesRow({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          for (final t in _templates) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Text(
                  t['emoji'] as String,
                  style: const TextStyle(fontSize: 16),
                ),
                label: Text(t['name'] as String),
                onPressed: () => onPick(
                  t['name'] as String,
                  t['emoji'] as String,
                  t['color'] as int,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
