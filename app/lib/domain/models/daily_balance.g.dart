// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_balance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyBalanceAdapter extends TypeAdapter<DailyBalance> {
  @override
  final int typeId = 6;

  @override
  DailyBalance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyBalance(
      lastResetDate: fields[0] as String?,
      freeBalance: fields[1] as int? ?? 0,
      earnedBalance: fields[4] as int? ?? 0,
      debtMinutes: fields[5] as int? ?? 0,
      debtCreditRemaining: fields[6] as int? ?? 0,
      lastDebtDate: fields[7] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, DailyBalance obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.lastResetDate)
      ..writeByte(1)
      ..write(obj.freeBalance)
      ..writeByte(4)
      ..write(obj.earnedBalance)
      ..writeByte(5)
      ..write(obj.debtMinutes)
      ..writeByte(6)
      ..write(obj.debtCreditRemaining)
      ..writeByte(7)
      ..write(obj.lastDebtDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyBalanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
