library;

import '../network/api_exception.dart';

sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {this.code});
  final ApiErrorCode? code;
  factory NetworkFailure.fromApi(ApiException e) =>
      NetworkFailure(e.message, code: e.code);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors});
  final Map<String, dynamic>? fieldErrors;
}
