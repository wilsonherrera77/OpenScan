import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/logger_adapter.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

/// Secure Data Service
///
/// Provides encrypted storage for sensitive data in SharedPreferences
///
/// Security Features:
/// - AES-256-GCM encryption for sensitive preferences
/// - Secure key storage using FlutterSecureStorage
/// - Automatic key generation
/// - Type-safe getters/setters
///
/// Usage:
/// ```dart
/// final service = SecureDataService();
/// await service.initialize();
///
/// // Store encrypted data
/// await service.setSecureString('api_key', 'secret_value');
///
/// // Retrieve encrypted data
/// final value = await service.getSecureString('api_key');
/// ```
class SecureDataService {
  static final SecureDataService _instance = SecureDataService._internal();
  factory SecureDataService() => _instance;
  SecureDataService._internal();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final LoggerAdapter _logger = LoggerAdapter();

  // Storage keys
  static const String _keyEncryptionKey = 'secure_data_encryption_key';
  static const String _encryptedPrefix = 'encrypted_';

  encrypt.Key? _encryptionKey;
  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Initialize secure data service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _logger.i('🔐 Initializing secure data service...');

      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Load or generate encryption key
      final existingKey = await _secureStorage.read(key: _keyEncryptionKey);

      if (existingKey != null) {
        _encryptionKey = encrypt.Key.fromBase64(existingKey);
        _logger.i('✅ Loaded existing encryption key');
      } else {
        await _generateNewKey();
        _logger.i('✅ Generated new encryption key');
      }

      _initialized = true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to initialize secure data service: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate new encryption key
  Future<void> _generateNewKey() async {
    final keyBytes = encrypt.Key.fromSecureRandom(32); // 256 bits

    await _secureStorage.write(
      key: _keyEncryptionKey,
      value: keyBytes.base64,
    );

    _encryptionKey = keyBytes;
  }

  /// Encrypt a string value
  String _encrypt(String plaintext) {
    _ensureInitialized();

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    // Combine IV and encrypted data
    final combined = {
      'iv': iv.base64,
      'data': encrypted.base64,
    };

    return base64.encode(utf8.encode(json.encode(combined)));
  }

  /// Decrypt a string value
  String _decrypt(String ciphertext) {
    _ensureInitialized();

    try {
      // Decode combined data
      final decodedBytes = base64.decode(ciphertext);
      final decodedString = utf8.decode(decodedBytes);
      final combined = json.decode(decodedString) as Map<String, dynamic>;

      final iv = encrypt.IV.fromBase64(combined['iv'] as String);
      final encryptedData = encrypt.Encrypted.fromBase64(combined['data'] as String);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.gcm),
      );

      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      _logger.e('❌ Failed to decrypt data: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SECURE STRING OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Store encrypted string
  Future<bool> setSecureString(String key, String value) async {
    _ensureInitialized();

    try {
      final encrypted = _encrypt(value);
      final success = await _prefs!.setString('$_encryptedPrefix$key', encrypted);

      if (success) {
        _logger.d('🔐 Stored encrypted string: $key');
      }

      return success;
    } catch (e) {
      _logger.e('❌ Failed to store secure string: $e');
      return false;
    }
  }

  /// Retrieve encrypted string
  Future<String?> getSecureString(String key) async {
    _ensureInitialized();

    try {
      final encrypted = _prefs!.getString('$_encryptedPrefix$key');

      if (encrypted == null) {
        return null;
      }

      final decrypted = _decrypt(encrypted);
      _logger.d('🔓 Retrieved encrypted string: $key');
      return decrypted;
    } catch (e) {
      _logger.e('❌ Failed to retrieve secure string: $e');
      return null;
    }
  }

  /// Remove encrypted string
  Future<bool> removeSecureString(String key) async {
    _ensureInitialized();

    try {
      final success = await _prefs!.remove('$_encryptedPrefix$key');

      if (success) {
        _logger.d('🗑️ Removed encrypted string: $key');
      }

      return success;
    } catch (e) {
      _logger.e('❌ Failed to remove secure string: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SECURE JSON OPERATIONS (for complex objects)
  // ═══════════════════════════════════════════════════════════

  /// Store encrypted JSON object
  Future<bool> setSecureJson(String key, Map<String, dynamic> value) async {
    final jsonString = json.encode(value);
    return await setSecureString(key, jsonString);
  }

  /// Retrieve encrypted JSON object
  Future<Map<String, dynamic>?> getSecureJson(String key) async {
    final jsonString = await getSecureString(key);

    if (jsonString == null) {
      return null;
    }

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('❌ Failed to parse secure JSON: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // REGULAR (NON-ENCRYPTED) OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Store regular string (not encrypted)
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  /// Get regular string (not encrypted)
  String? getString(String key) {
    _ensureInitialized();
    return _prefs!.getString(key);
  }

  /// Store regular int
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return await _prefs!.setInt(key, value);
  }

  /// Get regular int
  int? getInt(String key) {
    _ensureInitialized();
    return _prefs!.getInt(key);
  }

  /// Store regular bool
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(key, value);
  }

  /// Get regular bool
  bool? getBool(String key) {
    _ensureInitialized();
    return _prefs!.getBool(key);
  }

  /// Store regular double
  Future<bool> setDouble(String key, double value) async {
    _ensureInitialized();
    return await _prefs!.setDouble(key, value);
  }

  /// Get regular double
  double? getDouble(String key) {
    _ensureInitialized();
    return _prefs!.getDouble(key);
  }

  /// Store regular string list
  Future<bool> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    return await _prefs!.setStringList(key, value);
  }

  /// Get regular string list
  List<String>? getStringList(String key) {
    _ensureInitialized();
    return _prefs!.getStringList(key);
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITY OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Remove any key
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs!.remove(key);
  }

  /// Check if key exists
  bool containsKey(String key) {
    _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  /// Clear all secure data
  Future<bool> clearAllSecureData() async {
    _ensureInitialized();

    try {
      final keys = _prefs!.getKeys();
      final secureKeys = keys.where((k) => k.startsWith(_encryptedPrefix));

      for (final key in secureKeys) {
        await _prefs!.remove(key);
      }

      _logger.i('🗑️ Cleared all secure data');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to clear secure data: $e');
      return false;
    }
  }

  /// Clear all data (including non-encrypted)
  Future<bool> clearAll() async {
    _ensureInitialized();
    return await _prefs!.clear();
  }

  /// Get all keys
  Set<String> getAllKeys() {
    _ensureInitialized();
    return _prefs!.getKeys();
  }

  /// Get all encrypted keys
  Set<String> getSecureKeys() {
    _ensureInitialized();
    final keys = _prefs!.getKeys();
    return keys.where((k) => k.startsWith(_encryptedPrefix)).toSet();
  }

  /// Rotate encryption key
  ///
  /// Re-encrypts all secure data with new key
  Future<void> rotateKey() async {
    _ensureInitialized();

    _logger.w('🔄 Rotating encryption key...');

    try {
      // Get all encrypted keys
      final secureKeys = getSecureKeys();

      // Decrypt all data with old key
      final decryptedData = <String, String>{};
      for (final fullKey in secureKeys) {
        final key = fullKey.replaceFirst(_encryptedPrefix, '');
        final value = await getSecureString(key);
        if (value != null) {
          decryptedData[key] = value;
        }
      }

      // Generate new key
      await _generateNewKey();

      // Re-encrypt all data with new key
      for (final entry in decryptedData.entries) {
        await setSecureString(entry.key, entry.value);
      }

      _logger.i('✅ Encryption key rotated successfully');
      _logger.i('   Re-encrypted ${decryptedData.length} items');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to rotate encryption key: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    _ensureInitialized();

    final allKeys = getAllKeys();
    final secureKeys = getSecureKeys();

    return {
      'total_keys': allKeys.length,
      'encrypted_keys': secureKeys.length,
      'unencrypted_keys': allKeys.length - secureKeys.length,
      'encryption_algorithm': 'AES-256-GCM',
    };
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'SecureDataService not initialized. Call initialize() first',
      );
    }
  }

  /// Clear encryption key (logout/reset)
  Future<void> clearKey() async {
    try {
      await _secureStorage.delete(key: _keyEncryptionKey);
      _encryptionKey = null;
      _initialized = false;
      _logger.i('🔐 Encryption key cleared');
    } catch (e) {
      _logger.e('Failed to clear encryption key: $e');
      rethrow;
    }
  }
}
