/// Batch Processing Service - FASE 4.3: Escalabilidad
///
/// Handles efficient batch operations:
/// 1. Batch document uploads
/// 2. Batch database operations
/// 3. Parallel processing with controlled concurrency
/// 4. Progress tracking and error recovery

import 'dart:async';
import 'dart:io';
import 'package:lumara_scan/services/logger_adapter.dart';

/// Batch processor for handling large-scale operations
class BatchProcessor<T, R> {
  final LoggerAdapter _logger = LoggerAdapter();

  // Configuration
  final int maxConcurrentTasks;
  final Duration timeout;
  final bool stopOnError;

  // State
  int _totalItems = 0;
  int _processedItems = 0;
  int _failedItems = 0;
  final List<String> _errors = [];

  // Callbacks
  final void Function(int progress, int total)? onProgress;
  final void Function(String error)? onError;

  BatchProcessor({
    this.maxConcurrentTasks = 3,
    this.timeout = const Duration(seconds: 30),
    this.stopOnError = false,
    this.onProgress,
    this.onError,
  });

  /// Process items in batches with controlled concurrency
  Future<List<R>> processBatch(
    List<T> items,
    Future<R> Function(T item) processor,
  ) async {
    _totalItems = items.length;
    _processedItems = 0;
    _failedItems = 0;
    _errors.clear();

    _logger.i('🔄 Starting batch processing: ${items.length} items '
        '(max $maxConcurrentTasks concurrent)');

    final results = <R>[];
    final queue = <T>[...items];

    while (queue.isNotEmpty) {
      // Process in chunks of maxConcurrentTasks
      final batch = queue.take(maxConcurrentTasks).toList();
      queue.removeRange(0, batch.length);

      final batchResults = await Future.wait(
        batch.map((item) => _processItem(item, processor)),
        eagerError: stopOnError,
      );

      // Handle results
      for (final result in batchResults) {
        if (result != null) {
          results.add(result as R);
        }
      }
    }

    _printBatchSummary();

    return results;
  }

  /// Process item with timeout and error handling
  Future<R?> _processItem(
    T item,
    Future<R> Function(T item) processor,
  ) async {
    try {
      final result = await processor(item).timeout(timeout);

      _processedItems++;
      _updateProgress();

      return result;
    } catch (e, stackTrace) {
      _failedItems++;
      _errors.add('Item $item: ${e.toString()}');

      _logger.w('⚠️  Batch item failed: $e', error: e, stackTrace: stackTrace);
      onError?.call(e.toString());

      if (stopOnError) {
        rethrow;
      }

      return null;
    }
  }

  void _updateProgress() {
    onProgress?.call(_processedItems, _totalItems);
  }

  void _printBatchSummary() {
    print('\n📊 Batch Processing Summary');
    print('═══════════════════════════════════');
    print('Total items: $_totalItems');
    print('Processed: $_processedItems');
    print('Failed: $_failedItems');
    print('Success rate: ${(_processedItems / _totalItems * 100).toStringAsFixed(1)}%');

    if (_errors.isNotEmpty) {
      print('\n❌ Errors:');
      for (final error in _errors.take(5)) {
        print('  - $error');
      }
      if (_errors.length > 5) {
        print('  ... and ${_errors.length - 5} more');
      }
    }

    print('═══════════════════════════════════\n');
  }
}

/// Batch document upload manager
class BatchUploadManager {
  final LoggerAdapter _logger = LoggerAdapter();

  // Configuration
  final int maxConcurrentUploads = 2; // Lower for network efficiency
  final Duration uploadTimeout = const Duration(minutes: 5);

  // State
  int _totalDocuments = 0;
  int _uploadedDocuments = 0;
  final Map<String, UploadStatus> _uploadStatus = {};

  // Callbacks
  final void Function(int uploadedCount, int totalCount)? onProgress;
  final void Function(String documentId, String error)? onUploadError;
  final void Function(String documentId, int bytes)? onUploadComplete;

  BatchUploadManager({
    this.onProgress,
    this.onUploadError,
    this.onUploadComplete,
  });

  /// Upload multiple documents in batches
  Future<BatchUploadResult> uploadDocumentsBatch(
    List<File> documents,
    Future<bool> Function(File file, Function onProgress) uploadFunction,
  ) async {
    _totalDocuments = documents.length;
    _uploadedDocuments = 0;
    _uploadStatus.clear();

    _logger.i('📤 Starting batch upload: ${documents.length} documents');

    final processor = BatchProcessor<File, bool>(
      maxConcurrentTasks: maxConcurrentUploads,
      timeout: uploadTimeout,
      stopOnError: false,
      onProgress: (processed, total) {
        _uploadedDocuments = processed;
        onProgress?.call(processed, total);
      },
      onError: (error) {
        onUploadError?.call('unknown', error);
      },
    );

    final results = await processor.processBatch(documents, (file) async {
      try {
        final success = await uploadFunction(file, (bytes) {
          onUploadComplete?.call(file.path, bytes);
        });

        if (success) {
          _uploadStatus[file.path] = UploadStatus.completed;
        } else {
          _uploadStatus[file.path] = UploadStatus.failed;
        }

        return success;
      } catch (e) {
        _uploadStatus[file.path] = UploadStatus.failed;
        throw e;
      }
    });

    return BatchUploadResult(
      totalDocuments: _totalDocuments,
      successfulUploads: results.where((r) => r).length,
      failedUploads: _totalDocuments - results.where((r) => r).length,
      uploadStatus: _uploadStatus,
    );
  }

  /// Get upload progress
  double getProgress() {
    if (_totalDocuments == 0) return 0;
    return _uploadedDocuments / _totalDocuments;
  }

  /// Cancel batch upload
  void cancel() {
    _logger.i('⏹️  Batch upload cancelled');
  }
}

/// Batch database operations manager
class BatchDatabaseOperations {
  final LoggerAdapter _logger = LoggerAdapter();

  /// Batch insert multiple documents
  /// More efficient than individual inserts
  Future<int> batchInsertDocuments(
    List<Map<String, dynamic>> documents,
    Future<int> Function(Map<String, dynamic>) insertFunction,
  ) async {
    _logger.i('💾 Batch inserting ${documents.length} documents...');

    int insertedCount = 0;

    final processor = BatchProcessor<Map<String, dynamic>, int>(
      maxConcurrentTasks: 5,
      timeout: const Duration(seconds: 10),
      onProgress: (processed, total) {
        insertedCount = processed;
        print('  Progress: $processed/$total documents');
      },
    );

    final results = await processor.processBatch(
      documents,
      insertFunction,
    );

    insertedCount = results.length;
    _logger.i('✅ Batch insert complete: $insertedCount documents');

    return insertedCount;
  }

  /// Batch update documents
  Future<int> batchUpdateDocuments(
    List<Map<String, dynamic>> updates,
    Future<int> Function(Map<String, dynamic>) updateFunction,
  ) async {
    _logger.i('🔄 Batch updating ${updates.length} documents...');

    int updatedCount = 0;

    final processor = BatchProcessor<Map<String, dynamic>, int>(
      maxConcurrentTasks: 5,
      timeout: const Duration(seconds: 10),
      onProgress: (processed, total) {
        updatedCount = processed;
      },
    );

    final results = await processor.processBatch(
      updates,
      updateFunction,
    );

    updatedCount = results.length;
    _logger.i('✅ Batch update complete: $updatedCount documents');

    return updatedCount;
  }

  /// Bulk delete documents
  Future<int> batchDeleteDocuments(
    List<String> documentIds,
    Future<int> Function(String id) deleteFunction,
  ) async {
    _logger.i('🗑️  Batch deleting ${documentIds.length} documents...');

    int deletedCount = 0;

    final processor = BatchProcessor<String, int>(
      maxConcurrentTasks: 10, // Can delete faster
      timeout: const Duration(seconds: 10),
      onProgress: (processed, total) {
        deletedCount = processed;
      },
    );

    final results = await processor.processBatch(
      documentIds,
      deleteFunction,
    );

    deletedCount = results.length;
    _logger.i('✅ Batch delete complete: $deletedCount documents');

    return deletedCount;
  }
}

/// Upload status enum
enum UploadStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

/// Result of batch upload
class BatchUploadResult {
  final int totalDocuments;
  final int successfulUploads;
  final int failedUploads;
  final Map<String, UploadStatus> uploadStatus;

  BatchUploadResult({
    required this.totalDocuments,
    required this.successfulUploads,
    required this.failedUploads,
    required this.uploadStatus,
  });

  double get successRate =>
      totalDocuments > 0 ? successfulUploads / totalDocuments * 100 : 0;

  bool get isSuccessful => failedUploads == 0;

  @override
  String toString() {
    return '''
BatchUploadResult:
  Total: $totalDocuments
  Successful: $successfulUploads
  Failed: $failedUploads
  Success Rate: ${successRate.toStringAsFixed(1)}%
''';
  }
}
