import 'dart:async';

import 'package:dio/dio.dart';

/// Tracks whether the API is actually reachable, from evidence of real traffic.
///
/// `connectivity_plus` only reports whether the device has a network
/// interface. That is not the same question, and on a real device the two
/// disagree in both directions: a captive portal, a VPN, a blocked
/// `/api/v1`, or a proxy with no route all report "connected" while every
/// request fails — and the app then told the user "You're offline, progress
/// will sync when you reconnect" while its requests were failing, or
/// (equally bad) that it was online while nothing could be reached.
///
/// The important subtlety is that a *response* of any status proves
/// reachability. A 401, a 403, a 422 and even a 500 all mean bytes came back
/// over a working connection; treating those as "offline" is what made the
/// banner lie. Only a transport failure — no socket, DNS failure, timeout —
/// is evidence of unreachability.
class ApiReachability {
  ApiReachability();

  final _controller = StreamController<bool>.broadcast();

  bool _reachable = true;
  bool _hasEvidence = false;

  /// Last known reachability. Starts optimistic so a first-launch user is not
  /// shown an "offline" strip before any request has been attempted.
  bool get isReachable => _reachable;

  /// False until a request has actually completed. Callers can distinguish
  /// "we do not know yet" from "we know it is down".
  bool get hasEvidence => _hasEvidence;

  Stream<bool> get onChanged => _controller.stream;

  /// Call from a Dio interceptor's `onResponse` and `onError`.
  void observeResponse(Response<dynamic> response) {
    _record(true);
  }

  void observeError(DioException error) {
    _record(!_isTransportFailure(error));
  }

  /// Only transport-level failures count as unreachable.
  ///
  /// `badResponse` is explicitly *not* one of them: the server answered.
  /// `transformTimeout` is treated as reachable too — the request reached the
  /// server and the failure happened while decoding the reply, so claiming the
  /// API is down would be wrong and would hide a real bug.
  static bool _isTransportFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
        return false;
      case DioExceptionType.unknown:
        // Unclassified. Dio uses this for platform-channel errors, which say
        // nothing about the network, so assume reachable rather than accuse the
        // API of being down.
        return false;
    }
  }

  void _record(bool reachable) {
    final changed = !_hasEvidence || _reachable != reachable;
    _reachable = reachable;
    _hasEvidence = true;
    if (changed && !_controller.isClosed) {
      _controller.add(reachable);
    }
  }

  /// Test seam.
  void reset() {
    _reachable = true;
    _hasEvidence = false;
  }

  void dispose() => _controller.close();
}
