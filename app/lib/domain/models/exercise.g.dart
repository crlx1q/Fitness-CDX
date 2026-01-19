// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseSessionAdapter extends TypeAdapter<ExerciseSession> {
  @override
  final int typeId = 1;

  @override
  ExerciseSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseSession(
      id: fields[0] as String,
      type: fields[1] as ExerciseType,
      count: fields[2] as int,
      earnedMinutes: fields[3] as int,
      timestamp: fields[4] as DateTime,
      durationSeconds: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.count)
      ..writeByte(3)
      ..write(obj.earnedMinutes)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseTypeAdapter extends TypeAdapter<ExerciseType> {
  @override
  final int typeId = 0;

  @override
  ExerciseType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExerciseType.pushUp;
      case 1:
        return ExerciseType.squat;
      case 2:
        return ExerciseType.plank;
      case 3:
        return ExerciseType.lunge;
      case 4:
        return ExerciseType.jumpingJack;
      case 5:
        return ExerciseType.highKnees;
      case 6:
        return ExerciseType.freeActivity;
      default:
        return ExerciseType.pushUp;
    }
  }

  @override
  void write(BinaryWriter writer, ExerciseType obj) {
    switch (obj) {
      case ExerciseType.pushUp:
        writer.writeByte(0);
        break;
      case ExerciseType.squat:
        writer.writeByte(1);
        break;
      case ExerciseType.plank:
        writer.writeByte(2);
        break;
      case ExerciseType.lunge:
        writer.writeByte(3);
        break;
      case ExerciseType.jumpingJack:
        writer.writeByte(4);
        break;
      case ExerciseType.highKnees:
        writer.writeByte(5);
        break;
      case ExerciseType.freeActivity:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
