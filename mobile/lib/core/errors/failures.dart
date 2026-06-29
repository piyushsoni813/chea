/// Typed failures propagated from the data layer to the presentation layer.
/// Keeps HTTP status codes away from UI code.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure      extends Failure { const NetworkFailure(super.m); }
class ServerFailure       extends Failure {
  final int? statusCode;
  const ServerFailure(super.m, {this.statusCode});
}
class UnauthorizedFailure extends Failure { const UnauthorizedFailure([super.m = 'Session expired. Please log in again.']); }
class NotFoundFailure     extends Failure { const NotFoundFailure(super.m); }
class ValidationFailure   extends Failure { const ValidationFailure(super.m); }
class CacheFailure        extends Failure { const CacheFailure(super.m); }
class UnknownFailure      extends Failure { const UnknownFailure([super.m = 'An unexpected error occurred.']); }
