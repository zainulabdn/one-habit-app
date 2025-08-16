import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  int colorValue; // ARGB
  @HiveField(3)
  String emoji;   // simple emoji icon
  @HiveField(4)
  DateTime createdAt;
  @HiveField(5)
  List<String> checkins; // store as list for Hive compatibility

  Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.emoji,
    required this.createdAt,
    List<String>? checkins,
  }) : checkins = checkins ?? [];

  Set<String> get checkinSet => checkins.toSet();

  Habit copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? emoji,
    DateTime? createdAt,
    List<String>? checkins,
  }) {
    // NOTE: HiveObject.key is read-only. Do NOT try to set it.
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      checkins: checkins ?? this.checkins,
    );
  }
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int,
      emoji: fields[3] as String,
      createdAt: fields[4] as DateTime,
      checkins: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.checkins);
  }
}