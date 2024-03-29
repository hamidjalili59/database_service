import 'package:dartz/dartz.dart';
import 'package:database_service/src/database_errors.dart';
import 'package:database_service/src/database_service.dart';
import 'package:database_service/src/no_param.dart';

/// This class includes common functionality of database service with error handling
class DatabaseCommonOperations<R> {
  final String boxName;
  final DatabaseService databaseService;

  DatabaseCommonOperations({
    required this.boxName,
    required this.databaseService,
  });

  /// This method save data with the type [R] to the database service.
  /// If some data is already in the database then it will override data.
  Future<Either<DatabaseError, NoParam>> cacheData({
    required String fieldKey,
    required R value,
  }) async =>
      await databaseService.addOrUpdate(boxName, fieldKey, value).then(
            (res) => res.fold(
              (dbError) => left<DatabaseError, NoParam>(
                dbError,
              ),
              (response) => right<DatabaseError, NoParam>(
                const NoParam(),
              ),
            ),
          );

  /// This method save data with the type [R] to the database service.
  /// If some data is already in the database then it will override data.
  Future<Either<DatabaseError, NoParam>> removeData(
          {required String fieldKey}) async =>
      await databaseService.delete(boxName, fieldKey).then(
            (res) => res.fold(
              (dbError) => left<DatabaseError, NoParam>(
                dbError,
              ),
              (response) => right<DatabaseError, NoParam>(
                const NoParam(),
              ),
            ),
          );

  /// Retrive the data from the database.
  Future<Either<DatabaseError, R?>> getCachedData({
    required String fieldKey,
  }) async =>
      await databaseService
          .read(boxName, fieldKey)
          .then(
            (res) => res.fold(
              (dbError) => left<DatabaseError, R?>(
                dbError,
              ),
              (response) => right<DatabaseError, R?>(
                response as R?,
              ),
            ),
          )
          .catchError(
            (e) => left<DatabaseError, R?>(
              DatabaseError(errorMessage: e.toString()),
            ),
          );
}
