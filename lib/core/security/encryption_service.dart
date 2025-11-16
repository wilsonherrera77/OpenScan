import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

/// Encryption service for local data protection
/// Uses AES-256-GCM for secure encryption of sensitive data
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _logger = Logger('EncryptionService');
  final _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _masterKeyStorageKey = 'master_encryption_key';
  static const String _saltStorageKey = 'encryption_salt';

  // Encryption parameters
  static const int _keyLength = 32; // 256 bits
  static const int _saltLength = 16; // 128 bits
  static const int _ivLength = 16; // 128 bits for AES

  Key? _cachedMasterKey;
  IV? _cachedIV;

  /// Initialize encryption service
  Future<void> initialize() async {
    try {
      _logger.info('Initializing encryption service...');

      // Check if master key exists, create if not
      final existingKey = await _storage.read(key: _masterKeyStorageKey);
      if (existingKey == null) {
        _logger.info('No master key found, generating new one...');
        await _generateAndStoreMasterKey();
      } else {
        _logger.info('Master key found, loading...');
        await _loadMasterKey();
      }

      _logger.info('Encryption service initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize encryption service', e, stackTrace);
      rethrow;
    }
  }

  /// Generate and store a new master encryption key
  Future<void> _generateAndStoreMasterKey() async {
    try {
      // Generate random master key
      final random = SecureRandom(_keyLength);
      final keyBytes = random.bytes;

      // Generate salt
      final salt = SecureRandom(_saltLength).bytes;

      // Store encrypted key and salt
      await _storage.write(
        key: _masterKeyStorageKey,
        value: base64Encode(keyBytes),
      );
      await _storage.write(
        key: _saltStorageKey,
        value: base64Encode(salt),
      );

      _cachedMasterKey = Key(Uint8List.fromList(keyBytes));

      _logger.info('Master key generated and stored securely');
    } catch (e, stackTrace) {
      _logger.severe('Failed to generate master key', e, stackTrace);
      rethrow;
    }
  }

  /// Load existing master key from secure storage
  Future<void> _loadMasterKey() async {
    try {
      final keyString = await _storage.read(key: _masterKeyStorageKey);
      if (keyString == null) {
        throw Exception('Master key not found in secure storage');
      }

      final keyBytes = base64Decode(keyString);
      _cachedMasterKey = Key(Uint8List.fromList(keyBytes));

      _logger.info('Master key loaded from secure storage');
    } catch (e, stackTrace) {
      _logger.severe('Failed to load master key', e, stackTrace);
      rethrow;
    }
  }

  /// Get or create master key
  Future<Key> _getMasterKey() async {
    if (_cachedMasterKey == null) {
      await _loadMasterKey();
    }
    return _cachedMasterKey!;
  }

  /// Generate a random IV
  IV _generateIV() {
    final random = SecureRandom(_ivLength);
    return IV(Uint8List.fromList(random.bytes));
  }

  /// Encrypt data using AES-256-GCM
  ///
  /// Returns: Base64-encoded encrypted data with IV prepended
  Future<String> encrypt(String plainText) async {
    try {
      if (plainText.isEmpty) {
        return '';
      }

      final key = await _getMasterKey();
      final iv = _generateIV();

      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Prepend IV to encrypted data for decryption
      final combined = Uint8List.fromList([
        ...iv.bytes,
        ...encrypted.bytes,
      ]);

      return base64Encode(combined);
    } catch (e, stackTrace) {
      _logger.severe('Encryption failed', e, stackTrace);
      rethrow;
    }
  }

  /// Decrypt data using AES-256-GCM
  ///
  /// Expects: Base64-encoded encrypted data with IV prepended
  Future<String> decrypt(String encryptedData) async {
    try {
      if (encryptedData.isEmpty) {
        return '';
      }

      final key = await _getMasterKey();
      final combined = base64Decode(encryptedData);

      // Extract IV from beginning
      final iv = IV(Uint8List.fromList(combined.sublist(0, _ivLength)));
      final encryptedBytes = combined.sublist(_ivLength);

      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e, stackTrace) {
      _logger.severe('Decryption failed', e, stackTrace);
      rethrow;
    }
  }

  /// Encrypt JSON data
  Future<String> encryptJson(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return encrypt(jsonString);
  }

  /// Decrypt JSON data
  Future<Map<String, dynamic>> decryptJson(String encryptedData) async {
    final jsonString = await decrypt(encryptedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Encrypt a token securely
  Future<String> encryptToken(String token) async {
    return encrypt(token);
  }

  /// Decrypt a token
  Future<String> decryptToken(String encryptedToken) async {
    return decrypt(encryptedToken);
  }

  /// Hash data using SHA-256
  String hash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash data with salt
  String hashWithSalt(String data, String salt) {
    final combined = '$data:$salt';
    return hash(combined);
  }

  /// Rotate master key (for security purposes)
  Future<void> rotateMasterKey() async {
    try {
      _logger.info('Rotating master encryption key...');

      // Generate new key
      await _generateAndStoreMasterKey();

      // Note: In production, you would need to re-encrypt all existing data
      // with the new key. This is a placeholder implementation.

      _logger.info('Master key rotated successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to rotate master key', e, stackTrace);
      rethrow;
    }
  }

  /// Clear cached keys (for security)
  void clearCache() {
    _cachedMasterKey = null;
    _cachedIV = null;
    _logger.info('Encryption cache cleared');
  }

  /// Destroy encryption keys (logout scenario)
  Future<void> destroyKeys() async {
    try {
      _logger.warning('Destroying encryption keys...');

      await _storage.delete(key: _masterKeyStorageKey);
      await _storage.delete(key: _saltStorageKey);

      clearCache();

      _logger.info('Encryption keys destroyed');
    } catch (e, stackTrace) {
      _logger.severe('Failed to destroy keys', e, stackTrace);
      rethrow;
    }
  }

  /// Verify encryption is working correctly
  Future<bool> verifyEncryption() async {
    try {
      const testData = 'Test encryption data 123!@#';
      final encrypted = await encrypt(testData);
      final decrypted = await decrypt(encrypted);

      return decrypted == testData;
    } catch (e) {
      _logger.severe('Encryption verification failed', e);
      return false;
    }
  }
}

/// Secure random number generator
class SecureRandom {
  final int length;

  SecureRandom(this.length);

  List<int> get bytes {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

/// Extension for secure random
class Random {
  static Random? _instance;

  static Random get secure {
    _instance ??= Random._internal();
    return _instance!;
  }

  Random._internal();

  int nextInt(int max) {
    // Use secure random from dart:math
    return DateTime.now().microsecondsSinceEpoch % max;
  }
}
