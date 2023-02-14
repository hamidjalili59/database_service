import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:database_service/src/database_errors.dart';
import 'package:database_service/src/database_security.dart';
import 'package:database_service/src/database_service.dart';
import 'package:database_service/src/no_param.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class DatabaseServiceImpl extends DatabaseService {
  final DatabaseSecurity _databaseSecurity = DatabaseSecurity();

  DatabaseServiceImpl();

  Future<Directory> _getDatabaseDirectory() async {
    try {
      /// Retrive the device document directory
      final appDocumentDirectory =
          await path_provider.getApplicationDocumentsDirectory();
      return Directory('${appDocumentDirectory.path}/database');
    } catch (_) {
      throw DatabaseError();
    }
  }

  /// Database initialization setup
  @override
  Future initialize() async {
    try {
      await _databaseSecurity.createSecureKey();

      /// Initialize the database with a path
      Hive.initFlutter((await _getDatabaseDirectory()).path);
    } on path_provider.MissingPlatformDirectoryException {
      /// Initialize the database without any path
      Hive.initFlutter();
    } catch (_) {}
  }

  /// Opens a box only with encryption key. If there is no encryption key then
  /// throw `DatabaseError`
  @override
  Future<Box> openBox(String boxName) async {
    try {
      final HiveCipher? secureKey =
          await _databaseSecurity.readEncryptionCipher();
      if (secureKey == null) {
        throw DatabaseError(
          errorMessage: 'read_secure_key_failed',
        );
      }
      return await Hive.openBox(
        boxName,
        encryptionCipher: secureKey,
      );
    } catch (e) {
      throw DatabaseError(errorMessage: e.toString());
    }
  }

  /// Close all open boxes
  @override
  Future<Either<DatabaseError, NoParam>> closeDatabase() async {
    try {
      await Hive.close();
      return const Right(NoParam());
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Close a single box of the database
  @override
  Future<Either<DatabaseError, NoParam>> closeBox(
    String boxName,
  ) async {
    try {
      final Box box = await openBox(boxName);
      await box.compact();
      await box.close();
      return const Right(NoParam());
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Add a new entry to the database. If the key already exists then return [DatabaseError]
  @override
  Future<Either<DatabaseError, NoParam>> write(
    String boxName,
    String key,
    dynamic value,
  ) async {
    try {
      final Box box = await openBox(boxName);
      if (box.containsKey(key)) {
        return Left(DatabaseError(errorMessage: 'key_already_exist'));
      } else {
        box.put(key, value);
        return const Right(NoParam());
      }
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Add a set of new entries to the database
  @override
  Future<Either<DatabaseError, NoParam>> writeMultiple(
    String boxName,
    Map<dynamic, dynamic> enteries,
  ) async {
    try {
      final Box box = await openBox(boxName);
      box.putAll(enteries);
      return const Right(NoParam());
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Retrieve a single value from the database
  @override
  Future<Either<DatabaseError, dynamic>> read(
    String boxName,
    String key, {
    dynamic defaultValue,
  }) async {
    try {
      final Box box = await openBox(boxName);
      final dbFetchResult = box.get(
        key,
        defaultValue: defaultValue,
      );
      return Right(dbFetchResult);
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// If the provided [key] exist in the database then update it, otherwise return [DatabaseError]
  @override
  Future<Either<DatabaseError, NoParam>> update(
    String boxName,
    String key,
    dynamic value,
  ) async {
    try {
      final Box box = await openBox(boxName);
      if (box.containsKey(boxName)) {
        box.put(key, value);
        return const Right(NoParam());
      } else {
        return Left(DatabaseError(errorMessage: 'key_not_exist'));
      }
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Add new data to database and if provided key already exists then update it
  @override
  Future<Either<DatabaseError, NoParam>> addOrUpdate(
    String boxName,
    String key,
    dynamic value,
  ) async {
    try {
      final Box box = await openBox(boxName);
      box.put(key, value);
      return const Right(NoParam());
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Delete a single entery from the database
  @override
  Future<Either<DatabaseError, NoParam>> delete(
    String boxName,
    String key,
  ) async {
    try {
      final Box box = await openBox(boxName);
      box.delete(key);
      return const Right(NoParam());
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Delete a set of enteries from the database
  @override
  Future<Either<DatabaseError, NoParam>> deleteMultiple(
    String boxName,
    Iterable keys,
  ) async {
    try {
      final Box box = await openBox(boxName);
      box.deleteAll(keys);
      return const Right(NoParam());
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Delete all enteries from the database
  @override
  Future<Either<DatabaseError, int>> clearBox(
    String boxName,
  ) async {
    try {
      final Box box = await openBox(boxName);
      final int deletedRowsCount = await box.clear();
      return Right(deletedRowsCount);
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Detele box file from the device storage
  @override
  Future<Either<DatabaseError, NoParam>> deleteBoxFromDisk(
    String boxName,
  ) async {
    try {
      final Box box = await openBox(boxName);
      box.deleteFromDisk();
      return const Right(NoParam());
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Delete the database file and secure key from device storage. Make sure to call the [initialize] method if
  /// you want to use database after calling this method.
  @override
  Future<Either<DatabaseError, NoParam>> deleteDatabaseFromDisk() async {
    try {
      final dbDirectory = await _getDatabaseDirectory();
      await dbDirectory.delete(recursive: true);
      await _databaseSecurity.deleteSecureKey();
      return const Right(NoParam());
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Check if provided property exists in the database
  @override
  Future<Either<DatabaseError, bool>> hasProperty(
    String boxName,
    String key,
  ) async {
    try {
      final Box box = await openBox(boxName);
      final bool hasProperty = box.containsKey(key);
      return Right(hasProperty);
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }

  /// Registers a Hive adapter
  /// If another adapter with same typeId had been already registered,
  /// the adapter will be overridden if [override] set to `true`
  @override
  Future<Either<DatabaseError, NoParam>> registerAdapter<T>(
    TypeAdapter<T> adapter, {
    bool override = false,
  }) async {
    try {
      Hive.registerAdapter<T>(
        adapter,
        override: override,
      );
      return const Right(NoParam());
    } catch (e) {
      return Left(DatabaseError(errorMessage: e.toString()));
    }
  }
}
