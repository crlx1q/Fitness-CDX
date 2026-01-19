// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 5;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      difficultyIndex: fields[0] as int,
      pushUpRewardMinutes: fields[1] as int,
      squatRewardMinutes: fields[2] as int,
      plankRewardMinutes: fields[3] as int,
      pushUpRequirement: fields[4] as int,
      squatRequirement: fields[5] as int,
      plankSecondRequirement: fields[6] as int,
      strikeModeEnabled: fields[7] as bool,
      notificationsEnabled: fields[8] as bool,
      hasCompletedOnboarding: fields[9] as bool,
      hasGrantedPermissions: fields[10] as bool,
      soundEnabled: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.difficultyIndex)
      ..writeByte(1)
      ..write(obj.pushUpRewardMinutes)
      ..writeByte(2)
      ..write(obj.squatRewardMinutes)
      ..writeByte(3)
      ..write(obj.plankRewardMinutes)
      ..writeByte(4)
      ..write(obj.pushUpRequirement)
      ..writeByte(5)
      ..write(obj.squatRequirement)
      ..writeByte(6)
      ..write(obj.plankSecondRequirement)
      ..writeByte(7)
      ..write(obj.strikeModeEnabled)
      ..writeByte(8)
      ..write(obj.notificationsEnabled)
      ..writeByte(9)
      ..write(obj.hasCompletedOnboarding)
      ..writeByte(10)
      ..write(obj.hasGrantedPermissions)
      ..writeByte(11)
      ..write(obj.soundEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
