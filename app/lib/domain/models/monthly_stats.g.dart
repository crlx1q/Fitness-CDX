// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlyStatsAdapter extends TypeAdapter<MonthlyStats> {
  @override
  final int typeId = 7;

  @override
  MonthlyStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlyStats(
      monthKey: fields[0] as String,
      pushUps: fields[1] as int? ?? 0,
      squats: fields[2] as int? ?? 0,
      plankSeconds: fields[3] as int? ?? 0,
      earnedMinutes: fields[4] as int? ?? 0,
      spentMinutes: fields[5] as int? ?? 0,
      workoutCount: fields[6] as int? ?? 0,
      freeActivitySeconds: fields[7] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlyStats obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.monthKey)
      ..writeByte(1)
      ..write(obj.pushUps)
      ..writeByte(2)
      ..write(obj.squats)
      ..writeByte(3)
      ..write(obj.plankSeconds)
      ..writeByte(4)
      ..write(obj.earnedMinutes)
      ..writeByte(5)
      ..write(obj.spentMinutes)
      ..writeByte(6)
      ..write(obj.workoutCount)
      ..writeByte(7)
      ..write(obj.freeActivitySeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
