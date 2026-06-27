// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_operation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingOperationModelAdapter extends TypeAdapter<PendingOperationModel> {
  @override
  final int typeId = 5;

  @override
  PendingOperationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingOperationModel(
      id: fields[0] as String,
      type: fields[1] as String,
      payload: (fields[2] as Map).cast<String, dynamic>(),
      userId: fields[3] as String?,
      familyId: fields[4] as String?,
      timestamp: fields[5] as DateTime,
      retryCount: fields[6] as int,
      syncStatus: fields[7] as String,
      lastError: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingOperationModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.familyId)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.syncStatus)
      ..writeByte(8)
      ..write(obj.lastError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingOperationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
