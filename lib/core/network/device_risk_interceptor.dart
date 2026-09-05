import 'package:dio/dio.dart';

import '../security/app_security.dart';

/// Attaches the freeRASP-derived client risk band to every API request
/// (security plan W2.5).
///
/// `X-Device-Risk: clean | suspicious | compromised` is *reported telemetry*,
/// not an authentication factor: the server folds it into its graduated risk
/// policy (W3.5) and never trusts it as proof of anything — a hostile client
/// simply omits or forges the header. Its value is on honest clients, where a
/// rooted device hitting T4 endpoints becomes visible server-side.
class DeviceRiskInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppSecurity.riskLevel > 0) {
      options.headers['X-Device-Risk'] = AppSecurity.riskHeader;
    }
    handler.next(options);
  }
}
