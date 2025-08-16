import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../utils/date.dart';

class HabitRepo {
  static const _boxName = 'habits_box';
  static late Box<Habit> _box;
  static final _uuid = const Uuid();

  static Future<void> open() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }
    _box = await Hive.openBox<Habit>(_boxName);
  }

  List<Habit> all() {
    final list = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<Habit> create({required String name, required int colorValue, required String emoji}) async {
    final h = Habit(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
    await _box.put(h.id, h);
    return h;
  }

  Future<void> update(Habit h) => _box.put(h.id, h);

  Future<void> delete(String id) => _box.delete(id);

  Future<Habit> toggleToday(Habit h) async {
    final d = ymd(today());
    final set = h.checkinSet;
    if (set.contains(d)) {
      set.remove(d);
    } else {
      set.add(d);
    }
    final updated = h.copyWith(checkins: set.toList());
    await update(updated);
    return updated;
  }

  int currentStreak(Habit h) {
    final set = h.checkinSet;
    int streak = 0;
    for (final d in lastNDays(365)) {
      if (set.contains(ymd(d))) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  List<int> last7AggCounts(List<Habit> habits) {
    // Aggregate check-ins across all habits for the last 7 days (today..-6)
    final days = lastNDays(7).toList().reversed.toList();
    return [
      for (final d in days)
        habits.where((h) => h.checkinSet.contains(ymd(d))).length
    ];
  }
}

final habitRepoProvider = Provider<HabitRepo>((ref) => HabitRepo());

class HabitListNotifier extends StateNotifier<List<Habit>> {
  final HabitRepo repo;
  HabitListNotifier(this.repo) : super(repo.all());

  void refresh() => state = repo.all();

  Future<void> addHabit(String name, int color, String emoji) async {
    await repo.create(name: name, colorValue: color, emoji: emoji);
    refresh();
  }

  Future<void> removeHabit(String id) async {
    await repo.delete(id);
    refresh();
  }

  Future<void> toggle(Habit h) async {
    await repo.toggleToday(h);
    refresh();
  }
}

final habitListProvider = StateNotifierProvider<HabitListNotifier, List<Habit>>(
      (ref) => HabitListNotifier(ref.read(habitRepoProvider)),
);