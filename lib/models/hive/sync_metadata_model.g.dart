// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_metadata_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncMetadataModelAdapter extends TypeAdapter<SyncMetadataModel> {
  @override
  final int typeId = 6;

  @override
  SyncMetadataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMetadataModel(
      key: fields[0] as String,
      value: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadataModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
