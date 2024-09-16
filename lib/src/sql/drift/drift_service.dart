import 'package:drift/drift.dart';

abstract interface class DriftService {
  const DriftService();

  Future<List<D>> getAll<T extends Table, D>();

  Future<D?> getSingle<T extends Table, D>(
    Expression<bool> Function(T) filter,
  );

  Future<int> insert<T extends Table, D>(
    Insertable<D> entity, {
    InsertMode mode = InsertMode.insertOrReplace,
    UpsertClause<T, D>? onConflict,
  });

  Future<bool> update<T extends Table, D>(Insertable<D> entity);

  Future<int> delete<T extends Table, D>(
    Expression<bool> Function(T) filter,
  );

  Future<void> closeDatabase();
}
