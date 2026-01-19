// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_app.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlockedAppAdapter extends TypeAdapter<BlockedApp> {
  @override
  final int typeId = 2;

  @override
  BlockedApp read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockedApp(
      packageName: fields[0] as String,
      appName: fields[1] as String,
      isBlocked: fields[2] as bool,
      totalBlockedMinutes: fields[3] as int,
      totalUsedMinutes: fields[4] as int,
      iconBase64: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BlockedApp obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.isBlocked)
      ..writeByte(3)
      ..write(obj.totalBlockedMinutes)
      ..writeByte(4)
      ..write(obj.totalUsedMinutes)
      ..writeByte(5)
      ..write(obj.iconBase64);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedAppAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
