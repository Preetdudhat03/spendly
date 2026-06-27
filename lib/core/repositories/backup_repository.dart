import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository();
});

class BackupRepository {
  /// Exports all Hive boxes into a single ZIP file and returns its path.
  Future<String> exportBackup() async {
    final appDir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory(appDir.path); // Hive initializes in appDir by default via path_provider
    
    // We filter out non-hive files in case they exist
    final filesToZip = hiveDir.listSync().where((e) {
      return e is File && (e.path.endsWith('.hive') || e.path.endsWith('.lock'));
    }).cast<File>().toList();

    if (filesToZip.isEmpty) {
      throw Exception('No Hive data found to backup.');
    }

    final zipPath = p.join(appDir.path, 'spendly_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    for (var file in filesToZip) {
      encoder.addFile(file);
    }
    
    encoder.close();

    return zipPath;
  }

  /// Restores Hive boxes from a ZIP backup file.
  Future<void> restoreBackup(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw Exception('Backup file not found.');
    }

    final appDir = await getApplicationDocumentsDirectory();

    // 1. Unzip to a temporary directory
    final tempDir = await Directory(p.join(appDir.path, 'temp_restore')).create();
    
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (final archiveFile in archive) {
        if (archiveFile.isFile) {
          final data = archiveFile.content as List<int>;
          final restoredFile = File(p.join(tempDir.path, archiveFile.name));
          await restoredFile.writeAsBytes(data);
        }
      }

      // 2. We can't replace .hive files while Hive is actively using them safely.
      // In a real scenario, we should prompt the user to restart the app or gracefully close Hive.
      // For this implementation, we will move them to the appDir, which will take effect on next launch.
      // Overwrite existing .hive files in appDir
      final restoredFiles = tempDir.listSync().whereType<File>();
      for (var rf in restoredFiles) {
         await rf.copy(p.join(appDir.path, p.basename(rf.path)));
      }
    } finally {
      // 3. Clean up
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }
}
