class DatabaseServiceException implements Exception {
  const DatabaseServiceException({this.error});

  final dynamic error;

  @override
  String toString() => 'DatabaseServiceException: $error';
}
