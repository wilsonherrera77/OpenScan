/// Cache Service - FASE 4.4: Escalabilidad
///
/// Implements multi-level caching strategy:
/// 1. Memory cache (in-memory, fastest, limited size)
/// 2. Disk cache (persistent, larger capacity)
/// 3. Smart invalidation with TTL
/// 4. Cache statistics for monitoring

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:lumara_scan/services/logger_adapter.dart';

/// Multi-level caching service with memory + disk support
class CacheService {
  static final CacheService _instance = CacheService._internal();

  final LoggerAdapter _logger = LoggerAdapter();

  // Memory cache
  final Map<String, CacheEntry> _memoryCache = {};

  // Disk cache settings
  late Directory _cacheDir;
  final int maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  final int maxDiskCacheSize = 500 * 1024 * 1024; // 500MB
  final Duration defaultTTL = const Duration(hours: 24);

  // Statistics
  int _hits = 0;
  int _misses = 0;
  int _totalMemoryUsed = 0;

  CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  /// Initialize cache service
  Future<void> initialize() async {
    try {
      _cacheDir = await getApplicationCacheDirectory();

      // Ensure cache directory exists
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }

      _logger.i('✅ Cache service initialized at: ${_cacheDir.path}');

      // Clean up expired entries on startup
      await _cleanupExpiredEntries();
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize cache service: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Get value from cache (memory first, then disk)
  Future<dynamic> get(String key) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;

        // Check if expired
        if (_isExpired(entry)) {
          _memoryCache.remove(key);
          _misses++;
          return null;
        }

        _hits++;
        _logger.d('💾 Cache HIT (memory): $key');
        return entry.value;
      }

      // Check disk cache
      final diskFile = File(path.join(_cacheDir.path, _sanitizeKey(key)));

      if (await diskFile.exists()) {
        try {
          final content = await diskFile.readAsString();
          final cacheData = jsonDecode(content) as Map<String, dynamic>;
          final value = cacheData['value'];

          // Check if expired
          final expiresAt = DateTime.parse(cacheData['expiresAt'] as String);
          if (DateTime.now().isAfter(expiresAt)) {
            await diskFile.delete();
            _misses++;
            return null;
          }

          // Load into memory for faster access next time
          _memoryCache[key] = CacheEntry(
            value,
            expiresAt,
          );

          _hits++;
          _logger.d('💾 Cache HIT (disk): $key');
          return value;
        } catch (e) {
          _logger.w('⚠️  Failed to read disk cache for $key: $e');
          await diskFile.delete();
        }
      }

      _misses++;
      _logger.d('💾 Cache MISS: $key');
      return null;
    } catch (e, stackTrace) {
      _logger.e('❌ Error retrieving from cache: $e',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Set value in cache (memory + disk for persistence)
  Future<void> set(
    String key,
    dynamic value, {
    Duration? ttl,
  }) async {
    try {
      final expiresAt = DateTime.now().add(ttl ?? defaultTTL);
      final entry = CacheEntry(value, expiresAt);

      // Store in memory cache
      _memoryCache[key] = entry;
      _totalMemoryUsed += _estimateSize(value);

      // Check memory limit and evict if necessary
      if (_totalMemoryUsed > maxMemoryCacheSize) {
        _evictFromMemoryCache();
      }

      // Store in disk cache for persistence
      final diskFile = File(path.join(_cacheDir.path, _sanitizeKey(key)));

      final cacheData = {
        'value': value,
        'expiresAt': expiresAt.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      await diskFile.writeAsString(jsonEncode(cacheData));

      _logger.d('✅ Cached: $key (TTL: ${ttl?.inHours ?? 24}h)');
    } catch (e, stackTrace) {
      _logger.e('❌ Error setting cache: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// Remove specific key from cache
  Future<void> remove(String key) async {
    try {
      _memoryCache.remove(key);

      final diskFile = File(path.join(_cacheDir.path, _sanitizeKey(key)));
      if (await diskFile.exists()) {
        await diskFile.delete();
      }

      _logger.d('🗑️  Removed from cache: $key');
    } catch (e, stackTrace) {
      _logger.e('❌ Error removing from cache: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    try {
      _memoryCache.clear();
      _totalMemoryUsed = 0;

      // Delete all cache files
      await for (final file in _cacheDir.list()) {
        if (file is File) {
          await file.delete();
        }
      }

      _logger.i('✅ Cache cleared completely');
    } catch (e, stackTrace) {
      _logger.e('❌ Error clearing cache: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Get cache statistics
  CacheStatistics getStatistics() {
    final totalRequests = _hits + _misses;
    final hitRate =
        totalRequests > 0 ? (_hits / totalRequests * 100).toStringAsFixed(1) : 'N/A';

    return CacheStatistics(
      hits: _hits,
      misses: _misses,
      hitRate: hitRate,
      memoryEntriesCount: _memoryCache.length,
      memoryUsedBytes: _totalMemoryUsed,
      totalRequests: totalRequests,
    );
  }

  /// Print cache statistics
  void printStatistics() {
    final stats = getStatistics();
    print('\n📊 Cache Statistics');
    print('═════════════════════════════════════');
    print('Hits: ${stats.hits}');
    print('Misses: ${stats.misses}');
    print('Hit Rate: ${stats.hitRate}%');
    print('Memory Entries: ${stats.memoryEntriesCount}');
    print('Memory Used: ${_formatBytes(stats.memoryUsedBytes)}');
    print('Total Requests: ${stats.totalRequests}');
    print('═════════════════════════════════════\n');
  }

  /// Warm up cache with common queries (call on app startup)
  Future<void> warmUpCache(List<CacheWarmerEntry> entries) async {
    _logger.i('🔥 Warming up cache with ${entries.length} entries...');

    for (final entry in entries) {
      try {
        final value = await entry.dataLoader();
        await set(entry.key, value, ttl: entry.ttl);
      } catch (e) {
        _logger.w('⚠️  Failed to warm cache entry ${entry.key}: $e');
      }
    }

    _logger.i('✅ Cache warm-up complete');
  }

  // ═══════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════

  bool _isExpired(CacheEntry entry) {
    return DateTime.now().isAfter(entry.expiresAt);
  }

  String _sanitizeKey(String key) {
    // Replace invalid characters with underscores
    return key.replaceAll(RegExp(r'[^\w\-]'), '_');
  }

  int _estimateSize(dynamic value) {
    try {
      final jsonStr = jsonEncode(value);
      return jsonStr.length;
    } catch (e) {
      return 1024; // Estimate 1KB if encoding fails
    }
  }

  void _evictFromMemoryCache() {
    // Simple LRU eviction: remove 25% of oldest entries
    if (_memoryCache.isEmpty) return;

    final entriesToRemove = (_memoryCache.length * 0.25).ceil();
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));

    for (int i = 0; i < entriesToRemove && i < sortedEntries.length; i++) {
      _memoryCache.remove(sortedEntries[i].key);
    }

    _logger.w('⚠️  Evicted $entriesToRemove entries from memory cache');
  }

  Future<void> _cleanupExpiredEntries() async {
    try {
      int removedCount = 0;

      await for (final file in _cacheDir.list()) {
        if (file is File) {
          try {
            final content = await file.readAsString();
            final cacheData = jsonDecode(content) as Map<String, dynamic>;
            final expiresAt = DateTime.parse(cacheData['expiresAt'] as String);

            if (DateTime.now().isAfter(expiresAt)) {
              await file.delete();
              removedCount++;
            }
          } catch (e) {
            // If file is corrupted, delete it
            await file.delete();
            removedCount++;
          }
        }
      }

      if (removedCount > 0) {
        _logger.i('🧹 Cleaned up $removedCount expired cache entries');
      }
    } catch (e) {
      _logger.w('⚠️  Error during cache cleanup: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Cache entry with TTL
class CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  CacheEntry(this.value, this.expiresAt);
}

/// Cache statistics
class CacheStatistics {
  final int hits;
  final int misses;
  final String hitRate;
  final int memoryEntriesCount;
  final int memoryUsedBytes;
  final int totalRequests;

  CacheStatistics({
    required this.hits,
    required this.misses,
    required this.hitRate,
    required this.memoryEntriesCount,
    required this.memoryUsedBytes,
    required this.totalRequests,
  });
}

/// Cache warmer entry for preloading
class CacheWarmerEntry {
  final String key;
  final Future<dynamic> Function() dataLoader;
  final Duration ttl;

  CacheWarmerEntry({
    required this.key,
    required this.dataLoader,
    this.ttl = const Duration(hours: 24),
  });
}
