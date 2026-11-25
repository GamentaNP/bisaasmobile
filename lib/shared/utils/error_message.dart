/// The single place that turns a caught error into controller-facing copy.
library;

import '../../core/network/api_exception.dart';

/// Server-authored message when the failure came from `/api/v1`.
///
/// Controllers show this string verbatim: it is already localized by the server
/// and carries the actionable detail (insufficient coins, rate limit, …).
/// Errors that did not come from the API are described by the thrown object.
String errorMessage(Object e) => e is ApiException ? e.message : e.toString();
