import 'package:dio/dio.dart';

import '../../app/localization/l10n.dart';
import '../network/api_exception.dart';
import '../network/api_failure.dart';
import 'failures.dart';

/// Maps any thrown object → [Failure] for presentation layer.
abstract final class ErrorHandler {
  static Failure handle(Object error, [StackTrace? _]) {
    if (error is ApiException) {
      if (error.isMaintenance) {
        return MaintenanceFailure(error.message);
      }
      if (error.isValidation) {
        return ValidationFailure(error.message, fieldErrors: error.fieldErrors);
      }
      return NetworkFailure.fromApi(error);
    }
    if (error is DioException) {
      // `toApiException` is the one place that knows how to speak for a
      // transport failure — timeout, unreachable host, bad certificate — and
      // it does so in the user's language. Duplicating that mapping here is
      // how hardcoded English fallbacks came to exist.
      final inner = error.error;
      if (inner is ApiException) return NetworkFailure.fromApi(inner);
      return NetworkFailure.fromApi(toApiException(error));
    }
    // The server answered 2xx with a body the documented contract does not
    // describe. Rare, never the user's fault, and printing the exception type
    // at them is not an answer.
    if (error is ContractViolation) {
      return NetworkFailure(appL10n().errContractDrift);
    }
    // Anything else is a client-side fault (TypeError, StateError, …). A
    // Dart runtime error string is not user copy — same principle as the
    // ContractViolation branch above; the real exception still reaches the
    // crash reporter through the global handlers.
    return NetworkFailure(appL10n().errRequestFailed);
  }
}
