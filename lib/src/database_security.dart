import 'dart:convert';
import 'dart:typed_data';

import 'package:database_service/src/database_errors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseSecurity {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _secureKey = 's_key';

  /// Generate an encryption key for AES data encryption
  Future createSecureKey() async {
    try {
      final String? secureStorageKey = await _secureStorage.read(
        key: _secureKey,
      );

      /// If we didn't generate encryption key before then generate it
      if (secureStorageKey == null) {
        final List<int> key = Hive.generateSecureKey();
        await _secureStorage.write(
          key: _secureKey,
          value: base64UrlEncode(key),
        );
      }
    } catch (_) {}
  }

  /// Delete the encryption key from secure storage
  Future deleteSecureKey() async {
    try {
      await _secureStorage.delete(key: _secureKey);
    } catch (_) {}
  }

  /// Retrive the encryption key from secure storage
  Future<HiveCipher?> readEncryptionCipher() async {
    try {
      final secureStorageKey = await _secureStorage.read(key: _secureKey);
      if (secureStorageKey != null) {
        final Uint8List encryptionKey = base64Url.decode(secureStorageKey);
        return HiveAesCipher(encryptionKey);
      }
      return null;
    } catch (e) {
      throw DatabaseError(errorMessage: e.toString());
    }
  }
}
