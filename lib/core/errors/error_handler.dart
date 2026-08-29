import 'package:dio/dio.dart';

import '../network/api_exception.dart';
import 'failures.dart';

/// Maps any thrown object → [Failure] for presentation layer.
abstract final class ErrorHandler {
  static Failure handle(Object error, [StackTrace? _]) {
    if (error is ApiException) {
      if (error.isValidation) {
        return ValidationFailure(error.message, fieldErrors: error.errors);
      }
      return NetworkFailure.fromApi(error);
    }
    if (error is DioException) {
      final api = error.error;
      if (api is ApiException) return NetworkFailure.fromApi(api);
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const NetworkFailure('Connection failed. Check internet.');
      }
      return NetworkFailure(error.message ?? 'Network error');
    }
    return NetworkFailure(error.toString());
  }
}
