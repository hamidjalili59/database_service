import 'package:database_service/database_service.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class SqfliteService {
  const SqfliteService();

  Future<JobDone> openSqliteDatabase({
    int databaseVersion = 1,
    OnCreate onCreate,
    OnUpgrade onUpgrade,
  });

  Future<JobDone> closeSqliteDatabase();

  Future<JobDone> deleteSqliteDatabase();

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
  });

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
  });

  Future<bool> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm conflictAlgorithm,
  });

  Future<bool> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  });

  Future<bool> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// Executes a raw SQL query with optional arguments and returns
  /// a [Future] that completes with a [JobDone] object.
  ///
  /// The [sql] parameter is the raw SQL query to execute.
  ///
  /// The [arguments] parameter is an optional list of arguments
  ///  to replace placeholders in the [sql] query.
  ///
  /// Example usage:
  /// ```dart
  /// final result = await excuteRawQuery(
  ///   'SELECT * FROM users WHERE age > ?', [18],
  /// );
  /// ```
  Future<JobDone> excuteRawQuery(String sql, [List<Object?>? arguments]);

  Future<int> countRows(String table);
}
