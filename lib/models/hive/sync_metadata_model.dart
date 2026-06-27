import 'package:hive/hive.dart';

part 'sync_metadata_model.g.dart';

@HiveType(typeId: 6)
class SyncMetadataModel extends HiveObject {
  @override
  @HiveField(0)
  final String key; // e.g. 'last_sync_timestamp'

  @HiveField(1)
  final DateTime value;

  SyncMetadataModel({
    required this.key,
    required this.value,
  });
}
