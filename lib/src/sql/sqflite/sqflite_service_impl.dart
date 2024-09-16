import 'dart:async';

import 'package:database_service/database_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

typedef OnCreate = FutureOr<void> Function(Database, int)?;
typedef OnUpgrade = FutureOr<void> Function(Database, int, int)?;

class SqfliteServiceImpl implements SqfliteService {
  SqfliteServiceImpl({
    required this.databaseFileName,
    this.defaultConflictAlgorithm = ConflictAlgorithm.ignore,
  }) : assert(
          databaseFileName.split('.').last == 'db',
          'File name format should be like this: Filename.db',
        );

  final String databaseFileName;
  final ConflictAlgorithm defaultConflictAlgorithm;
  Database? database;

  Future<String> _getSqliteDatabaseFullPath() async {
    try {
      final path = await getDatabasesPath();
      return join(path, databaseFileName);
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  @override
  Future<JobDone> openSqliteDatabase({
    int databaseVersion = 1,
    OnCreate onCreate,
    OnUpgrade onUpgrade,
  }) async {
    try {
      final databasePath = await _getSqliteDatabaseFullPath();
      database = await databaseFactory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: databaseVersion,
          onConfigure: _onConfigure,
          onCreate: (db, version) => onCreate?.call(db, version),
          onUpgrade: (db, oldVersion, newVersion) => onUpgrade?.call(
            db,
            oldVersion,
            newVersion,
          ),
        ),
      );
      return const JobDone();
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<JobDone> closeSqliteDatabase() async {
    try {
      if (database == null) {
        throw const DatabaseServiceException(error: 'Database object was null');
      }
      await database!.close();
      return const JobDone();
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<JobDone> deleteSqliteDatabase() async {
    try {
      final databasePath = await _getSqliteDatabaseFullPath();
      await databaseFactory.deleteDatabase(databasePath);
      return const JobDone();
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<List<Map<String, Object?>>> read(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryResult = await database!.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
      return queryResult;
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<Map<String, Object?>> readFirst(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryResult = await database!.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
      return queryResult.isNotEmpty ? queryResult.first : <String, Object?>{};
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<bool> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    try {
      final result = await database!.insert(
        table,
        values,
        nullColumnHack: nullColumnHack,
        conflictAlgorithm: conflictAlgorithm ?? defaultConflictAlgorithm,
      );
      if (result == 1) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<bool> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    try {
      final result = await database!.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm ?? defaultConflictAlgorithm,
      );
      if (result == 1) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<bool> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      final result = await database!.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
      if (result == 1) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<JobDone> excuteRawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    try {
      await database!.execute(sql, arguments);
      return const JobDone();
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<int> countRows(String table) async {
    try {
      final result = await database!.rawQuery('SELECT COUNT(*) FROM $table');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }
}
