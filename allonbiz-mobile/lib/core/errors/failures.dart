import 'package:equatable/equatable.dart';

/// Base class for custom application failures.
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when device has no network connection.
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'No internet connection. Please check your network and try again.',
  ]);
}

/// Thrown for Authentication or validation errors.
final class AuthFailure extends Failure {
  final String code;
  const AuthFailure([
    this.code = 'unknown',
    super.message = 'Authentication failed. Please check your credentials.',
  ]);

  @override
  List<Object?> get props => [code, message];
}

/// Thrown when expected data is not found in the backend/storage.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'The requested resource could not be found.',
  ]);
}

/// Platform-specific errors (e.g. Permission Denied).
final class PlatformFailure extends Failure {
  const PlatformFailure([
    super.message = 'Device permission denied or platform operation failed.',
  ]);
}

/// Backend Database errors.
final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'A database error occurred.']);
}

/// Catch-all for unexpected exceptions.
final class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred. Please try again.',
  ]);
}

/// Thrown when the backend server API returns an error status code.
final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([
    super.message = 'A server error occurred. Please try again later.',
    this.statusCode,
  ]);

  @override
  List<Object?> get props => [message, statusCode];
}
