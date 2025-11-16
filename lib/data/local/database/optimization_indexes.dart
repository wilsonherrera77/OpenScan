/// Database Optimization: Indexes and Query Performance
/// FASE 4.1: Escalabilidad - Optimización de Base de Datos
///
/// This module handles all database optimization strategies:
/// 1. Strategic indexes for fast queries
/// 2. Query optimization patterns
/// 3. Query performance monitoring
/// 4. Migration scripts

import 'package:sqflite/sqflite.dart';

/// Database indexes configuration for optimal query performance
class DatabaseIndexes {
  /// Create all optimized indexes
  /// CRITICAL: Execute BEFORE any production usage
  static Future<void> createOptimizedIndexes(Database db) async {
    try {
      // Assignment table indexes
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_assignment_user_id
        ON assignment_person(user_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_assignment_status
        ON assignment_person(status)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_assignment_created_date
        ON assignment_person(created_date)
      ''');

      // Composite index for common filter combination
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_assignment_user_status_date
        ON assignment_person(user_id, status, created_date)
      ''');

      // Document table indexes
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_document_assignment_id
        ON document(assignment_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_document_status
        ON document(status)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_document_upload_date
        ON document(upload_date)
      ''');

      // Person table indexes
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_person_first_name
        ON person(first_name)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_person_last_name
        ON person(last_name)
      ''');

      // Composite for person search
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_person_name_search
        ON person(first_name, last_name)
      ''');

      // Census table indexes
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_census_person_id
        ON census_data(person_id)
      ''');

      print('✅ Database indexes created successfully');
    } catch (e) {
      print('❌ Error creating indexes: $e');
      rethrow;
    }
  }

  /// Analyze indexes performance
  /// Returns statistics about index effectiveness
  static Future<Map<String, dynamic>> analyzeIndexPerformance(Database db) async {
    try {
      final stats = <String, dynamic>{};

      // Get table statistics
      final tables = ['assignment_person', 'document', 'person', 'census_data'];

      for (final table in tables) {
        try {
          final result = await db.rawQuery('EXPLAIN QUERY PLAN SELECT * FROM $table LIMIT 1');
          stats[table] = result;
        } catch (e) {
          print('⚠️  Could not analyze table $table: $e');
        }
      }

      return stats;
    } catch (e) {
      print('❌ Error analyzing indexes: $e');
      return {};
    }
  }
}

/// Query optimization helpers
class OptimizedQueries {
  /// Get assignments with pagination for better performance
  /// Avoids loading entire dataset into memory
  static Future<List<Map<String, dynamic>>> getAssignmentsPaginated(
    Database db, {
    required int page,
    required int pageSize,
    String? status,
    int? userId,
  }) async {
    final offset = (page - 1) * pageSize;

    String query = '''
      SELECT a.*, COUNT(d.id) as document_count
      FROM assignment_person a
      LEFT JOIN document d ON a.id = d.assignment_id
      WHERE 1=1
    ''';

    final params = <dynamic>[];

    if (status != null) {
      query += ' AND a.status = ?';
      params.add(status);
    }

    if (userId != null) {
      query += ' AND a.user_id = ?';
      params.add(userId);
    }

    query += '''
      GROUP BY a.id
      ORDER BY a.created_date DESC
      LIMIT ? OFFSET ?
    ''';

    params.addAll([pageSize, offset]);

    return await db.rawQuery(query, params);
  }

  /// Search persons efficiently using LIKE with indexes
  static Future<List<Map<String, dynamic>>> searchPersonsByName(
    Database db,
    String searchTerm,
  ) async {
    // Use indexes on first_name and last_name
    final term = '%$searchTerm%';

    return await db.rawQuery('''
      SELECT * FROM person
      WHERE first_name LIKE ? OR last_name LIKE ?
      ORDER BY first_name ASC, last_name ASC
      LIMIT 100
    ''', [term, term]);
  }

  /// Count documents by status efficiently
  static Future<Map<String, int>> getDocumentStatusCounts(Database db) async {
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM document
      GROUP BY status
    ''');

    final counts = <String, int>{};
    for (final row in result) {
      counts[row['status'] as String] = row['count'] as int;
    }

    return counts;
  }

  /// Get recent assignments with limited data (optimization for UI)
  static Future<List<Map<String, dynamic>>> getRecentAssignments(
    Database db, {
    int limit = 20,
  }) async {
    return await db.rawQuery('''
      SELECT
        a.id,
        a.user_id,
        a.status,
        a.created_date,
        COUNT(d.id) as document_count
      FROM assignment_person a
      LEFT JOIN document d ON a.id = d.assignment_id
      GROUP BY a.id
      ORDER BY a.created_date DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Batch query documents by assignment IDs (more efficient than individual queries)
  static Future<Map<int, List<Map<String, dynamic>>>> getDocumentsByAssignmentIds(
    Database db,
    List<int> assignmentIds,
  ) async {
    if (assignmentIds.isEmpty) return {};

    final placeholders = List.filled(assignmentIds.length, '?').join(',');
    final documents = await db.rawQuery('''
      SELECT * FROM document
      WHERE assignment_id IN ($placeholders)
      ORDER BY assignment_id, upload_date DESC
    ''', assignmentIds);

    final result = <int, List<Map<String, dynamic>>>{};
    for (final doc in documents) {
      final assignmentId = doc['assignment_id'] as int;
      result.putIfAbsent(assignmentId, () => []).add(doc);
    }

    return result;
  }
}

/// Database maintenance utilities
class DatabaseMaintenance {
  /// Optimize database by running VACUUM
  /// Defragments database file and frees unused space
  static Future<void> optimizeDatabase(Database db) async {
    try {
      await db.execute('VACUUM');
      print('✅ Database optimization (VACUUM) completed');
    } catch (e) {
      print('❌ Error during VACUUM: $e');
    }
  }

  /// Enable WAL mode for better concurrency
  /// Recommended for apps with multiple concurrent reads
  static Future<void> enableWALMode(Database db) async {
    try {
      // Check if WAL is already enabled
      final result = await db.rawQuery('PRAGMA journal_mode');
      if (result.isNotEmpty && result[0]['journal_mode'] != 'wal') {
        await db.execute('PRAGMA journal_mode = WAL');
        print('✅ WAL mode enabled');
      }
    } catch (e) {
      print('❌ Error enabling WAL mode: $e');
    }
  }

  /// Set appropriate cache size
  static Future<void> configureCacheSize(Database db) async {
    try {
      // -64000 means 64MB cache (negative value indicates megabytes)
      await db.execute('PRAGMA cache_size = -64000');
      print('✅ Cache size configured');
    } catch (e) {
      print('❌ Error configuring cache: $e');
    }
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getDatabaseStats(Database db) async {
    try {
      final stats = <String, dynamic>{};

      // Page count and page size
      final pageInfo = await db.rawQuery('PRAGMA page_count');
      final pageSize = await db.rawQuery('PRAGMA page_size');

      if (pageInfo.isNotEmpty && pageSize.isNotEmpty) {
        stats['pageCount'] = pageInfo[0]['page_count'];
        stats['pageSize'] = pageSize[0]['page_size'];
        stats['totalSizeBytes'] = (pageInfo[0]['page_count'] as int) * (pageSize[0]['page_size'] as int);
      }

      // Foreign keys status
      final fkStatus = await db.rawQuery('PRAGMA foreign_keys');
      stats['foreignKeysEnabled'] = fkStatus.isNotEmpty && fkStatus[0]['foreign_keys'] == 1;

      // Journal mode
      final journalMode = await db.rawQuery('PRAGMA journal_mode');
      stats['journalMode'] = journalMode.isNotEmpty ? journalMode[0]['journal_mode'] : 'unknown';

      return stats;
    } catch (e) {
      print('❌ Error getting database stats: $e');
      return {};
    }
  }

  /// Cleanup old data to keep database lean
  /// Removes documents older than specified days
  static Future<int> cleanupOldDocuments(
    Database db, {
    required int olderThanDays,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      final deleted = await db.delete(
        'document',
        where: 'upload_date < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );

      print('✅ Cleaned up $deleted old documents');
      return deleted;
    } catch (e) {
      print('❌ Error cleaning up documents: $e');
      return 0;
    }
  }
}

/// Query performance monitoring
class QueryPerformanceMonitor {
  static final Map<String, Duration> _queryTimes = {};

  /// Log query execution time
  static void logQueryTime(String queryName, Duration duration) {
    _queryTimes[queryName] = duration;

    // Warn if query takes too long
    if (duration.inMilliseconds > 500) {
      print('⚠️  SLOW QUERY: $queryName took ${duration.inMilliseconds}ms');
    }
  }

  /// Get average query times
  static Map<String, double> getAverageQueryTimes() {
    final averages = <String, double>{};

    _queryTimes.forEach((query, duration) {
      averages[query] = duration.inMilliseconds.toDouble();
    });

    return averages;
  }

  /// Reset performance metrics
  static void reset() {
    _queryTimes.clear();
  }

  /// Print performance report
  static void printPerformanceReport() {
    print('\n📊 Query Performance Report');
    print('═══════════════════════════════════');

    final sortedQueries = _queryTimes.entries.toList()
      ..sort((a, b) => b.value.inMilliseconds.compareTo(a.value.inMilliseconds));

    for (final entry in sortedQueries.take(10)) {
      print('${entry.key}: ${entry.value.inMilliseconds}ms');
    }

    print('═══════════════════════════════════\n');
  }
}
