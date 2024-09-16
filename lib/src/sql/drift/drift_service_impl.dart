import 'package:database_service/src/common/database_service_exception.dart';
import 'package:database_service/src/sql/drift/drift_service.dart';
import 'package:drift/drift.dart';

class DriftServiceImpl implements DriftService {
  const DriftServiceImpl(this._database);

  final GeneratedDatabase _database;

  @override
  Future<List<D>> getAll<T extends Table, D>() async {
    try {
      final table = _getTable<T, D>();
      final result = await _database.select(table).get();
      return result;
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<D?> getSingle<T extends Table, D>(
    Expression<bool> Function(T) filter,
  ) async {
    try {
      final table = _getTable<T, D>();
      final result =
          await (_database.select(table)..where(filter)).getSingleOrNull();
      return result;
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<int> insert<T extends Table, D>(
    Insertable<D> entity, {
    InsertMode mode = InsertMode.insertOrAbort,
    UpsertClause<T, D>? onConflict,
  }) async {
    try {
      final table = _getTable<T, D>();
      final result = await _database.into(table).insert(
            entity,
            mode: mode,
            onConflict: onConflict,
          );
      return result;
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<bool> update<T extends Table, D>(Insertable<D> entity) async {
    try {
      final table = _getTable<T, D>();
      final result = await _database.update(table).replace(entity);
      return result;
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<int> delete<T extends Table, D>(
    Expression<bool> Function(T) filter,
  ) async {
    try {
      final table = _getTable<T, D>();
      final result = await (_database.delete(table)..where(filter)).go();
      return result;
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  @override
  Future<void> closeDatabase() async {
    try {
      await _database.close();
    } catch (e) {
      throw DatabaseServiceException(error: e);
    }
  }

  TableInfo<T, D> _getTable<T extends Table, D>() {
    final table =
        _database.allTables.firstWhere((t) => t is T) as TableInfo<T, D>;
    return table;
  }
}
