import 'dart:io';
import 'package:flutter/services.dart';
import '../services/logger_adapter.dart';

/// Service for deleting files from shared storage on Android
///
/// Android 10+ (API 29+) introduced Scoped Storage which restricts
/// direct file deletion from shared storage like /storage/emulated/0/Documents/
///
/// This service uses MediaStore API via MethodChannel to properly delete files
/// on Android 10+ while maintaining backwards compatibility.
class FileDeletionService {
  static const MethodChannel _channel = MethodChannel('com.ethereal.lumara/file_deletion');
  final LoggerAdapter _logger = LoggerAdapter();

  /// Delete a file from storage
  ///
  /// For Android 10+ (API 29+): Uses MediaStore API via native code
  /// For Android < 10: Uses direct File.delete()
  ///
  /// Returns true if file was deleted successfully or didn't exist
  /// Returns false if deletion failed
  Future<bool> deleteFile(String filePath) async {
    try {
      // Check if file exists first
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.d('File already deleted or doesn\'t exist: $filePath');
        return true;
      }

      // Try native MediaStore deletion first (Android 10+)
      if (Platform.isAndroid) {
        try {
          final result = await _channel.invokeMethod<bool>(
            'deleteFile',
            {'filePath': filePath},
          );

          if (result == true) {
            _logger.i('✅ File deleted via MediaStore: ${filePath.split('/').last}');
            return true;
          } else {
            _logger.w('⚠️ MediaStore deletion returned false, trying direct delete');
          }
        } on PlatformException catch (e) {
          _logger.w('⚠️ MediaStore deletion failed: ${e.message}');
          _logger.w('   Trying direct file deletion as fallback');
        } on MissingPluginException catch (e) {
          _logger.w('⚠️ Native file deletion not available: $e');
          _logger.w('   Trying direct file deletion as fallback');
        }
      }

      // Fallback: Try direct file deletion (works for private app storage)
      try {
        await file.delete();

        // Verify deletion
        if (!await file.exists()) {
          _logger.i('✅ File deleted via direct method: ${filePath.split('/').last}');
          return true;
        } else {
          _logger.e('❌ File still exists after deletion attempt: $filePath');
          return false;
        }
      } catch (e) {
        _logger.e('❌ Direct file deletion failed: $e');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ File deletion error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete multiple files
  ///
  /// Returns a map with file paths as keys and deletion success as values
  Future<Map<String, bool>> deleteFiles(List<String> filePaths) async {
    final results = <String, bool>{};

    for (final path in filePaths) {
      results[path] = await deleteFile(path);
    }

    return results;
  }

  /// Delete all files in a directory
  ///
  /// WARNING: This is a destructive operation. Use with caution.
  /// Returns the number of files successfully deleted
  Future<int> deleteDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);

      if (!await directory.exists()) {
        _logger.d('Directory doesn\'t exist: $directoryPath');
        return 0;
      }

      int deletedCount = 0;
      final files = await directory.list(recursive: false).where((entity) => entity is File).toList();

      for (final file in files) {
        if (await deleteFile(file.path)) {
          deletedCount++;
        }
      }

      _logger.i('🗑️ Deleted $deletedCount/${files.length} files from $directoryPath');
      return deletedCount;
    } catch (e, stackTrace) {
      _logger.e('❌ Directory deletion error: $e', error: e, stackTrace: stackTrace);
      return 0;
    }
  }
}
