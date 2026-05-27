abstract class Failure {
  final String message;

  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure([super.message = 'Server failure occurred']);
}

class CacheFailure extends Failure {
  CacheFailure([super.message = 'Cache failure occurred']);
}

class DatabaseFailure extends Failure {
  DatabaseFailure([super.message = 'Database failure occurred']);
}
