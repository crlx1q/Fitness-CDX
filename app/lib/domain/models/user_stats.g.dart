// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserStatsAdapter extends TypeAdapter<UserStats> {
  @override
  final int typeId = 3;

  @override
  UserStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStats(
      availableMinutes: fields[0] as int,
      totalEarnedMinutes: fields[1] as int,
      totalSpentMinutes: fields[2] as int,
      currentStreak: fields[3] as int,
      longestStreak: fields[4] as int,
      lastWorkoutDate: fields[5] as DateTime?,
      totalPushUps: fields[6] as int,
      totalSquats: fields[7] as int,
      totalPlankSeconds: fields[8] as int,
      totalWorkouts: fields[9] as int,
      totalLunges: fields[11] as int,
      totalJumpingJacks: fields[12] as int,
      totalHighKnees: fields[13] as int,
      totalFreeActivitySeconds: fields[14] as int,
      createdAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserStats obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.availableMinutes)
      ..writeByte(1)
      ..write(obj.totalEarnedMinutes)
      ..writeByte(2)
      ..write(obj.totalSpentMinutes)
      ..writeByte(3)
      ..write(obj.currentStreak)
      ..writeByte(4)
      ..write(obj.longestStreak)
      ..writeByte(5)
      ..write(obj.lastWorkoutDate)
      ..writeByte(6)
      ..write(obj.totalPushUps)
      ..writeByte(7)
      ..write(obj.totalSquats)
      ..writeByte(8)
      ..write(obj.totalPlankSeconds)
      ..writeByte(9)
      ..write(obj.totalWorkouts)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.totalLunges)
      ..writeByte(12)
      ..write(obj.totalJumpingJacks)
      ..writeByte(13)
      ..write(obj.totalHighKnees)
      ..writeByte(14)
      ..write(obj.totalFreeActivitySeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyStatsAdapter extends TypeAdapter<DailyStats> {
  @override
  final int typeId = 4;

  @override
  DailyStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyStats(
      dateKey: fields[0] as String,
      pushUps: fields[1] as int,
      squats: fields[2] as int,
      plankSeconds: fields[3] as int,
      earnedMinutes: fields[4] as int,
      spentMinutes: fields[5] as int,
      workoutCount: fields[6] as int,
      freeActivitySeconds: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyStats obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.dateKey)
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
      other is DailyStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
